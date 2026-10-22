# macos-better-darkmode

A macOS menu-bar app that switches between light and dark mode from ambient signals instead of a schedule.

It scores how dark it should be from:

- the MacBook's **ambient light sensor** (private HID API, Apple Silicon laptops only),
- the **sun's elevation** computed offline from your coordinates, adjusted by **cloud cover** (Open-Meteo).

If the sun is well below the horizon it's always dark. Otherwise the weighted score decides, with hysteresis and a minimum time between switches. Changing the appearance by hand pauses auto-switching until the automatic decision next flips.

## Build and run

```bash
./scripts/build-app.sh   # builds SmartMode.app
open SmartMode.app
```

Use the menu's **Launch at login** toggle to start it automatically. macOS ties this to the app's location, so move `SmartMode.app` to `/Applications` first.

The first switch asks for permission to control System Events. Config lives at `~/.config/smart-mode/config.json` (created on first launch, hot-reloaded). Set your `latitude` and `longitude`; see `config.example.json` for every tunable.

## Tests

```bash
swift test         # with full Xcode
./scripts/test.sh  # with only the Command Line Tools
```

The light-sensor path uses undocumented private APIs and may break with a macOS update.
