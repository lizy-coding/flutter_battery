# Example App Guidelines

## Purpose
Demo application for manual QA and visual verification of the `flutter_battery` plugin. Showcases all battery monitoring features, BLE peer sync, and IoT native bridge demos.

## Project Structure
- `lib/main.dart`: App entry point; wires battery bootstrap, IoT event listeners, route generation gated by `BatteryPlatformCapabilities`.
- `lib/pages/`: Feature demo pages (`dashboard_page.dart`, `battery_details_page.dart`, `low_battery_notification_page.dart`, `iot_controls_page.dart`, `event_stream_page.dart`).
- `lib/platform/example_platform_adapter.dart`: Platform adapter returning `BatteryPlatformCapabilities` per platform. Android reports all features supported; other platforms report unsupported for BLE peer sync and IoT bridge.
- `lib/routes.dart`: Route constants for all demo pages.
- `test/widget_test.dart`: Widget test verifying dashboard disables features based on capability object.

## Key Patterns
- **Capability-gated routing**: Routes check `BatteryPlatformCapabilities.isSupported()` before navigating; unsupported features show `_UnsupportedFeaturePage` or disable the ListTile.
- **IoT isolation**: `iot/native` and `iot/stream` channels are example-only, accessed exclusively through `ExamplePlatformAdapter`. Not part of the plugin's public API.
- **Battery bootstrap**: `_bootstrapBattery()` configures all callbacks and monitoring via `configureBatteryCallbacks` + `configureBatteryMonitor`.

## Testing
- `cd example && flutter test`: Run widget tests.
- `cd example && flutter run -d <device>`: Manual QA on device/emulator.

## Development Workflow
- After modifying plugin Dart code, run `flutter pub get` in both root and example.
- Use `BatteryFeature` enum values from `package:flutter_battery/flutter_battery.dart` (re-exported via `lib/src/platform_capabilities.dart`) for capability checks — never hardcode platform strings.
