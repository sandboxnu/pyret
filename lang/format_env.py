import json
import re
import sys
from collections import defaultdict


def extract_balanced(s, start):
    """Return the substring from s[start] (which must be '(') to its matching ')'."""
    assert s[start] == '('
    depth = 0
    for i in range(start, len(s)):
        if s[i] == '(':
            depth += 1
        elif s[i] == ')':
            depth -= 1
            if depth == 0:
                return s[start:i+1], i+1
    raise ValueError("Unbalanced parentheses")


def parse_dict_entries(raw):
    """
    Parse entries from a string-dict or mutable-string-dict string.
    Each entry looks like:  <key>, value-bind(...)
    Returns list of (key, value_bind_str).
    """
    body = re.sub(r'^\[(?:mutable-)?string-dict:\s*', '', raw.strip())
    body = re.sub(r'\]$', '', body.strip())

    entries = []
    pos = 0
    while pos < len(body):
        vb_idx = body.find('value-bind(', pos)
        if vb_idx == -1:
            break

        key_raw = body[pos:vb_idx].strip().rstrip(',').strip()
        key_raw = key_raw.lstrip(',').strip()

        vb_str, end = extract_balanced(body, vb_idx + len('value-bind'))
        entries.append((key_raw, 'value-bind' + vb_str))
        pos = end

    return entries


def parse_value_bind(vb):
    """Pull out kind, name, and source location from a value-bind(...) string."""
    kind_m = re.search(r'\b(vb-letrec|vb-let)\b', vb)
    kind = kind_m.group(1) if kind_m else '?'

    g = re.search(r's-global\(([^)]+)\)', vb)
    a = re.search(r's-atom\(([^,)]+)', vb)
    name_m = g or a
    name = name_m.group(1).strip() if name_m else '?'

    # srcloc(path, start_line, start_col, start_offset, end_line, end_col, end_offset)
    srclocs = re.findall(
        r'srcloc\(([^,)]+),\s*(\d+),\s*(\d+),\s*\d+,\s*(\d+),\s*(\d+)',
        vb
    )
    if srclocs:
        path, sl, sc, el, ec = srclocs[0]
        path = path.split('/')[-1]
        if sl == el:
            loc = path + ':' + sl + ':' + sc + '-' + ec
        else:
            loc = path + ':' + sl + ':' + sc + '-' + el + ':' + ec
    else:
        b = re.search(r'builtin\(([^)]+)\)', vb)
        loc = 'builtin(' + b.group(1) + ')' if b else 'unknown'

    return kind, name, loc


def group_name(loc):
    mapping = {
        'builtin://global':    'global builtins',
        'builtin://lists':     'lists',
        'builtin://sets':      'sets',
        'builtin://arrays':    'arrays',
        'builtin://option':    'option',
        'builtin://constants': 'constants',
    }
    for k, v in mapping.items():
        if k in loc:
            return v
    if loc.startswith('builtin'):
        return 'other builtins'
    return 'user-defined'


def format_section(raw, title):
    entries = parse_dict_entries(raw)
    groups = defaultdict(list)
    for key, vb in entries:
        kind, name, loc = parse_value_bind(vb)
        groups[group_name(loc)].append((key, kind, name, loc))

    lines = ['\n' + '='*72, '  ' + title + '  (' + str(len(entries)) + ' entries)', '='*72]
    order = ['global builtins', 'lists', 'sets', 'arrays',
             'option', 'constants', 'other builtins', 'user-defined']
    for grp in order:
        if grp not in groups:
            continue
        lines.append('\n  [' + grp + ']')
        for key, kind, name, loc in sorted(groups[grp], key=lambda x: x[0]):
            lines.append('    ' + key.ljust(45) + kind.ljust(12) + name.ljust(30) + loc)
    return '\n'.join(lines)


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1]) as f:
            raw = f.read()
    else:
        raw = sys.stdin.read()

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print('JSON parse error: ' + str(e), file=sys.stderr)
        sys.exit(1)

    pce = data.get('post-compile-env', {})
    for title, key in [('Bindings', 'bindings'), ('Environment', 'env')]:
        section = pce.get(key, '')
        if section:
            print(format_section(section, title))


if __name__ == '__main__':
    main()
