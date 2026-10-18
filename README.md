# The Everlasting Delve

A 2D, single-player fantasy campaign built with Godot. Choose one of four race/class heroes, follow the Dungeon Master's contextual prompts or enter a custom action, and keep XP, gold, inventory, and campaign progress between sessions.

The campaign runs offline. Its Dungeon Master is a rules-based narrative system—not a live generative-AI service. The first arc has five authored quests; numbered Chronicles continue by cycling through that set. Saves stay in the browser profile and are not cloud-synced. See [GAME_GUIDE.md](GAME_GUIDE.md) for player instructions.

## Play

The GitHub Pages site is [https://mogwi1983.github.io/everlasting/](https://mogwi1983.github.io/everlasting/).

## Build and deploy

Install Godot 4.7.2 with its Web export template, then run:

```sh
npm run stage-pages
```

This exports the Godot Web build to `dist/` and stages the portable files in `docs/`. Commit and push the updated source and `docs/` directory to `main`; the GitHub Actions workflow in `.github/workflows/pages.yml` deploys the site. It uses the repository's `GITHUB_TOKEN`; no API key or backend service is required.

## Source layout

- `project.godot`, `scenes/`, `scripts/`, and `autoload/` are the Godot game source.
- `assets/` includes local runtime art, fonts, and licenses needed for a standalone build.
- `docs/` contains the deployable web export and supporting project notes.
