# The Everlasting Delve

A 2D, single-player fantasy campaign built with Godot. Choose one of four race/class heroes, follow the Dungeon Master's contextual prompts or enter a custom action, and keep XP, gold, inventory, and campaign progress between sessions.

The campaign runs offline. Its Dungeon Master is a rules-based narrative system—not a live generative-AI service. The first arc has five authored quests; numbered Chronicles continue by cycling through that set. Saves stay in the browser profile and are not cloud-synced. See [GAME_GUIDE.md](GAME_GUIDE.md) for player instructions.

## Play

The GitHub Pages deployment is intended to be available at [https://mogwi1983.github.io/everlasting/](https://mogwi1983.github.io/everlasting/).

## Build and stage for GitHub Pages

Install Godot 4.7.2 with its Web export template, then run:

```sh
npm run stage-pages
```

This exports the Godot Web build to `dist/` and copies the portable files to `docs/`. Commit and push the updated `docs/` directory to the `main` branch to update the Pages site. No API key or backend service is required. The GitHub Pages source is configured to `main` / `docs`.

## Source layout

- `project.godot`, `scenes/`, `scripts/`, and `autoload/` are the Godot game source.
- `assets/` includes the local runtime art, fonts, and licenses needed for a standalone build.
- `docs/` contains the deployable web export and supporting project notes.
