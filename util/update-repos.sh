#!/bin/zsh

# For each subrepo branch, pulls in any new commits from the upstream remote.
# Then merges any updated branches back into the current branch.

typeset -A repos=(
  ["embed"]="git@github.com:jpolitz/pyret-embed.git"
  ["vscode"]="git@github.com:jpolitz/pyret-parley-vscode.git"
  ["npm"]="git@github.com:brownplt/pyret-npm.git"
  ["pyret.org"]="git@github.com:brownplt/pyret.org.git"
  ["docs"]="git@github.com:brownplt/pyret-docs.git"
  ["codemirror-mode"]="git@github.com:brownplt/pyret-codemirror-mode.git"
  ["code.pyret.org"]="git@github.com:brownplt/code.pyret.org.git"
  ["lang"]="git@github.com:brownplt/pyret-lang.git"
)

set -e

start_branch=$(git rev-parse --abbrev-ref HEAD)
# Remote that tracks the monorepo's integration branches (e.g. "origin").
# Used to fetch missing subrepo integration branches with proper history.
monorepo_remote=$(git config "branch.${start_branch}.remote" 2>/dev/null) || monorepo_remote="origin"
updated=()

# Track current operation so cleanup can print reproduction commands.
current_phase=""
current_branch=""
current_upstream=""

# Return to the starting branch on exit (covers both success and error paths).
# If a merge conflict left us in MERGING state, print the commands to reproduce
# that state, then abort it so checkout works.
cleanup() {
  local git_dir
  git_dir=$(git rev-parse --git-dir 2>/dev/null) || return
  if [[ -f "$git_dir/MERGE_HEAD" ]]; then
    echo ""
    echo "Merge conflict detected. To reproduce this state, run:"
    if [[ "$current_phase" == "pull" ]]; then
      echo "  git switch $current_branch"
      echo "  git -c merge.directoryRenames=true pull --no-ff $current_upstream"
    elif [[ "$current_phase" == "merge" ]]; then
      echo "  git switch $start_branch"
      echo "  git -c merge.directoryRenames=true merge --no-ff $current_branch -m \"Merge branch '$current_branch'\""
    fi
    echo ""
    echo "Aborting in-progress merge..."
    git merge --abort
  fi
  git switch "$start_branch"
}
trap cleanup EXIT

for branch in "${(@k)repos}"; do
  upstream="${repos[$branch]}"
  current_phase="pull"
  current_branch="$branch"
  current_upstream="$upstream"

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git switch "$branch"
  else
    # Look for a cached remote-tracking ref carrying the integration history.
    remote_ref=""
    candidates=("refs/remotes/${monorepo_remote}/${branch}")
    if [[ "$monorepo_remote" != "origin" ]]; then
      candidates+=("refs/remotes/origin/${branch}")
    fi
    for candidate in "${candidates[@]}"; do
      if git show-ref --verify --quiet "$candidate"; then
        remote_ref="$candidate"
        break
      fi
    done
    if [[ -n "$remote_ref" ]]; then
      echo "==> Branch '$branch' missing locally; creating from $remote_ref"
      git switch -c "$branch" "$remote_ref"
    else
      echo "ERROR: '$branch' not found locally or as a remote-tracking ref." >&2
      echo "The integration branch must exist somewhere with shared history with $start_branch." >&2
      exit 1
    fi
  fi
  before=$(git rev-parse HEAD)

  echo "==> Checking $branch ($upstream)"
  # directoryRenames=true auto-applies directory-rename detection rather than
  # surfacing it as a conflict (e.g. new files at upstream root land under
  # this branch's $branch/ subdirectory automatically).
  git -c merge.directoryRenames=true pull --no-ff "$upstream"

  after=$(git rev-parse HEAD)
  if [[ "$before" != "$after" ]]; then
    updated+=("$branch")
  fi
done

git switch "$start_branch"

echo ""
echo "==> Merging updated branches: ${updated[*]}"
for branch in "${updated[@]}"; do
  current_phase="merge"
  current_branch="$branch"
  git -c merge.directoryRenames=true merge --no-ff "$branch" -m "Merge branch '$branch'"
done

echo ""
echo "Done."
