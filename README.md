# SystemLens

SystemLens is a local-only Flutter desktop dashboard for Linux that surfaces storage, CPU, memory, Docker, network, sensors, battery, and system details in a single Material 3 UI.

## What’s in this repo

- Flutter desktop app shell with dark/light/system theming
- Riverpod-based state management
- Linux system probes for `/proc`, `/sys`, and safe command execution
- Storage, Docker, system, and network dashboards
- Settings persistence in a local JSON file
- Parser tests for `lsblk`, `/proc/meminfo`, `/proc/stat`, and Docker output

## Run

When Flutter desktop tooling is available:

```bash
flutter run -d linux
```

## Build

```bash
flutter build linux --release
```

## Desktop integration

- Launcher metadata is provided in [`linux/systemlens.desktop`](/home/akshay-linson/Projects/Linux App/linux/systemlens.desktop)
- A simple application icon asset is included at [`assets/systemlens_icon.svg`](/home/akshay-linson/Projects/Linux App/assets/systemlens_icon.svg)

## Notes

- The app is intentionally local-only and does not require a backend.
- Docker features degrade safely if Docker is missing or inaccessible.
- I couldn’t validate a desktop build in this environment because `flutter` and `dart` are not installed here.
# Linux-APP
