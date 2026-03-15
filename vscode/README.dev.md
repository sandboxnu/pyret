Borrows heavily from <https://github.com/microsoft/vscode-extension-samples/tree/main/custom-editor-sample>

To run, first you must symlink `build` to a the `build/` directory of
`code.pyret.org`. You can get one by cloning `code.pyret.org` elsewhere and
symlinking to it.

Then, to test the web extension (in a new `github.dev`-like browser environment):

```
npm i
npm run compile
npx vscode-test-web --browserType=chromium --extensionDevelopmentPath . ./sampleFiles/
```

To test locally without the web extension (say, to test or debug a feature that
is not yet properly supported on the web), the easiest way to do so is to
1. Open up `src/extension.ts`, then
2. Press F5 (or run `Debug: Start Debugging` from the Command Palette)

User settings for avoiding diff views using the fancy editor; put in
`.vscode/settings.json` (or set via the menu):

```
{
    "workbench.editorAssociations": {
        "{git}:/**/*.{arr}": "default"
    }
}
```

(Courtesy of <https://github.com/microsoft/vscode-discussions/discussions/799>)

Grammar and language-configuration contributed by Seth Poulsen.
