# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: Dart API; `flutter_battery.dart` exposes `FlutterBattery`, and the platform interface plus MethodChannel default live alongside it.
- `android/`, `ios/`: Native implementations; keep channel names and payloads in sync with the Dart interface and avoid committing `build/`.
- `example/`: Demo app for manual QA and showcasing notifications; run it on a device/emulator to validate flows.
- `test/`: Unit tests (`*_test.dart`) covering public API and channel behavior.
- `integration/channel/contracts/channel_contract.yaml`: Contract for method/event channels; edit together with Dart and native changes.
- `scripts/bootstrap_iot.sh`: Recreate integration scaffolding if a clean checkout is missing folders.

## Build, Test, and Development Commands
- `flutter pub get`: Fetch dependencies (root and `example/` when editing the demo).
- `flutter analyze`: Static analysis via `flutter_lints`; keep warnings at zero.
- `dart format lib test example`: Standard 2-space formatting for Dart sources.
- `flutter test`: Run unit tests in `test/`.
- `cd example && flutter run -d <device>`: Smoke-test the plugin end-to-end.

## Coding Style & Naming Conventions
- Follow `flutter_lints` (`analysis_options.yaml` relaxes `constant_identifier_names` for platform constants).
- Files use `snake_case.dart`; classes/enums `PascalCase`; members and locals `camelCase`.
- Keep channel method/event names and payload keys aligned with `FlutterBatteryPlatform`.
- Favor small, nullable-safe methods and concise comments only where intent is non-obvious.

## Testing Guidelines
- Place new cases beside the feature under test; use descriptive `feature_behavior_test.dart` names.
- Mock the platform interface for unit coverage of MethodChannel and stream behaviors; avoid hardware dependencies.
- For native changes, run the `example/` app once on Android (and iOS when available) to verify battery readings and event streams.

## Commit & Pull Request Guidelines
- Use history-aligned prefixes (`feat:`, `style:`, `fix:`, `docs:`) plus an imperative summary.
- PRs should include a brief description, commands executed (analyze/test/run), linked issues, and device/simulator details for manual checks.
- Add screenshots or short clips when UI/notification output changes via the demo.

## Security & Configuration Tips
- Exclude secrets, keystores, and generated `build/` artifacts.
- Request only minimum permissions when editing manifests.
- When releasing, bump `pubspec.yaml` version and update `CHANGELOG.md` together.
