# Website

This website is built using [Docusaurus](https://docusaurus.io/), a modern static website generator.

## Installation

```bash
npm ci
```

## Local Development

```bash
npm run dev
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

## Deployment on Github

```bash
npm run deploy
```

## Versioning & Release Workflow

To publish a new version of Unique Engine and update its documentation:

1. **From Game Maker, save and export the local package**
   - Save all your changes in Game Maker.
   - Export the local package as `ue.yymps` (from the menu: Tools → Export Local Package).

2. **Add the new version to the Download page**
   - Edit `src/pages/download.md` and add a new row to the table:
     ```markdown
     | 0.0.2 | [See changes](/changelog/0.0.2) | [Download](https://github.com/manuel-di-iorio/unique-engine/releases/tag/0.0.2) |
     ```
3. **Add the changelog page**
   - Create a new page in `src/pages/changelog/0.0.2.md` with the release notes.

4. **Freeze the documentation for the new version**
   - Run the Docusaurus command to "freeze" the current docs:
     ```bash
     npx docusaurus docs:version 0.0.2
     ```
   - This command creates a copy of the documentation in the `versioned_docs` folder and updates the version selector.

65. **Commit and push**
   - Commit all changes from the root folder of Unique Engine (including the new versioned docs and changelog).
   - Push to GitHub:
     ```bash
     git add .
     git commit -m "Release 0.0.2"
     git push
     ```

6. **Tag a new version on GitHub**
   - Go to the [GitHub Releases page](https://github.com/manuel-di-iorio/unique-engine/releases) and create a new release.
   - Enter the new tag name (e.g. `0.0.2`) and fill in the release notes, if necessary.

7. **Deploy the documentation**

```bash
cd docs
npm run deploy
```
