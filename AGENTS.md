# Repository Guidelines

## Project Structure & Module Organization
- `lib/`: Dart API; `flutter_battery.dart` exposes `FlutterBattery` + typed models; `lib/src/` holds internal contracts (`battery_channel_contract.dart`) and platform capability models (`platform_capabilities.dart`). `flutter_battery_platform_interface.dart` and `flutter_battery_method_channel.dart` live alongside it.
- `android/`: Native implementation. Channel names and payloads must stay in sync with `lib/src/battery_channel_contract.dart`. Avoid committing `build/`.
- `macos/`: macOS native implementation. Explicitly returns unsupported capabilities via `getPlatformCapabilities` for notifications/BLE/peer sync.
- `example/`: Demo app for manual QA and showcasing notifications. IoT demo (`iot/native`, `iot/stream`) is example-only (not part of plugin public API). Run it on a device/emulator to validate flows.
- `test/`: Unit tests (`*_test.dart`) covering public API, channel behavior, and capability queries.
- `integration/channel/contracts/channel_contract.yaml`: Single source of truth for method/event channel contracts; edit together with Dart and native changes.
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
- Channel method/event names and payload keys must use `BatteryChannelNames`, `BatteryMethodNames`, `BatteryEventTypes`, `BatteryPayloadKeys` from `lib/src/battery_channel_contract.dart` — no raw string literals outside native registration.
- Favor small, nullable-safe methods. Comments only where intent is non-obvious.

## Testing Guidelines
- Place new cases beside the feature under test; use descriptive `feature_behavior_test.dart` names.
- Mock the platform interface for unit coverage of MethodChannel, stream behaviors, and capability queries; avoid hardware dependencies.
- For native changes, run the `example/` app on Android and macOS to verify battery readings, event streams, and capability-based feature gating.

## Commit & Pull Request Guidelines
- Use history-aligned prefixes (`feat:`, `style:`, `fix:`, `docs:`) plus an imperative summary.
- PRs should include a brief description, commands executed (analyze/test/run), linked issues, and device/simulator details for manual checks.
- Add screenshots or short clips when UI/notification output changes via the demo.

## Security & Configuration Tips
- Exclude secrets, keystores, and generated `build/` artifacts.
- Request only minimum permissions when editing manifests.
- When releasing, bump `pubspec.yaml` version and update `CHANGELOG.md` together.

## Key Architecture Decisions (post-refactor)
- **Channel Contract Constants**: All channel names, method names, event types, and payload keys are centralized in `lib/src/battery_channel_contract.dart`. Raw string literals are banned from business logic.
- **Platform Capabilities**: `BatteryFeature` enum + `BatteryPlatformCapabilities` value object. Query via `FlutterBattery.getPlatformCapabilities()` or `isFeatureSupported(BatteryFeature)`. macOS explicitly returns `false` for notifications/BLE/peer sync.
- **Predictable Failure**: `MissingPluginException` for optional features is mapped to `UnsupportedBatteryFeatureException` so consumers never see raw `MissingPluginException`.
- **Normalized Events**: Event stream payloads always include a `type` field (`BATTERY_LEVEL`, `BATTERY_INFO`, `BATTERY_HEALTH`, `BATTERY_UNAVAILABLE`). Both `level` and `batteryLevel` keys are present for backward compatibility.
- **macOS Callback Bridge**: `BatteryMonitor` has callback setters wired through `FlutterBatteryPlugin` to invoke MethodChannel methods (`onBatteryLevelChanged`, `onBatteryInfoChanged`, `onBatteryHealthChanged`).
- **No iOS**: iOS platform declaration removed from `pubspec.yaml` until a native implementation is added.
- **Example IoT Isolation**: `iot/native` and `iot/stream` channels are example-only, not part of plugin public API. Documented in `channel_contract.yaml` under `example_only_android`.
