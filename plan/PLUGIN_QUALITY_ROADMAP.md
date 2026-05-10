# Flutter Plugin Quality Roadmap

## Current Rating

Overall rating: **C+ / 62**

Current status:

- `flutter analyze` passes.
- `flutter test` passes.
- `cd example && flutter test` passes.
- `cd example && flutter build macos --debug` passes.
- `flutter pub publish --dry-run` reports `0 warnings`.

The package is technically publishable, but it is not yet at the quality level expected from a mature open-source Flutter plugin.

## Target

Target rating after this roadmap: **A- / 85+**

Primary goals:

- Make plugin metadata and publishing files production-ready.
- Make platform support explicit and truthful.
- Separate core battery functionality from demo/integration-only code.
- Stabilize Android/macOS channel contracts.
- Improve documentation, CI, and maintainability.

## Milestone P0: Publication Readiness

Goal: make the package safe and credible to publish.

Priority: blocking

### Scope

Files likely affected:

- `LICENSE`
- `pubspec.yaml`
- `README.md`
- `CHANGELOG.md`
- `.pubignore`
- `macos/flutter_battery.podspec`

### Steps

1. Replace placeholder license.

   Current `LICENSE` contains placeholder text. Replace it with a real license, preferably one of:

   - MIT
   - BSD-3-Clause
   - Apache-2.0

2. Fix package metadata.

   Update `pubspec.yaml`:

   ```yaml
   homepage: <real project homepage>
   repository: <real git repository URL>
   issue_tracker: <real issue tracker URL>
   topics:
     - battery
     - plugin
     - android
     - macos
   ```

3. Fix macOS podspec metadata.

   Update `macos/flutter_battery.podspec`:

   - `s.version` must match `pubspec.yaml`.
   - `s.homepage` must be real.
   - `s.author` must not use template values.
   - `s.license` must match the root license.

4. Add `.pubignore`.

   Exclude internal planning and agent files from published archives:

   ```text
   AGENTS.md
   ARCHITECTURE_REFACTOR_PLAN.yaml
   IOT_UPGRADE_PLAN.md
   workflow_context.md
   .cursorrules
   .idea/
   integration/channel/contracts/macos_battery_evolution_plan.yaml
   ```

   Keep contract files only if they are meant to be public package artifacts.

5. Update README support matrix.

   README must explicitly state support by platform:

   | Feature | Android | macOS |
   |---|---:|---:|
   | Battery level | yes | yes |
   | Battery info | yes | yes |
   | Temperature | yes | best effort |
   | Voltage | yes | best effort |
   | Battery health | yes | best effort |
   | Native notifications | yes | no |
   | BLE peer sync | yes | no |
   | IoT demo bridge | example-only | no |

6. Align CHANGELOG with actual code.

   Add an unreleased section or bump version if publishing.

### Acceptance Criteria

Run:

```sh
flutter analyze
flutter test
cd example && flutter test
cd example && flutter build macos --debug
flutter pub publish --dry-run
flutter pub outdated
```

Required result:

- `analyze` has no issues.
- tests pass.
- macOS debug build succeeds.
- dry-run has no warnings.
- published archive does not include internal roadmap/agent files.
- `LICENSE` is no longer placeholder text.
- podspec version equals pubspec version.

## Milestone P1: Platform Capability Model

Goal: make platform differences explicit and remove raw unsupported-platform failures from user-facing APIs.

Priority: high

### Scope

Files likely affected:

- `lib/src/platform_capabilities.dart`
- `lib/src/battery_channel_contract.dart`
- `lib/flutter_battery.dart`
- `lib/flutter_battery_platform_interface.dart`
- `lib/flutter_battery_method_channel.dart`
- `lib/flutter_bluetooth.dart`
- `lib/flutter_bluetooth_method_channel.dart`
- `lib/peer_battery_service.dart`
- `example/lib/main.dart`
- `example/lib/pages/dashboard_page.dart`
- `example/lib/pages/low_battery_notification_page.dart`
- `macos/flutter_battery/Classes/FlutterBatteryPlugin.swift`
- `android/src/main/kotlin/com/example/flutter_battery/channel/MethodChannelHandler.kt`

### Steps

1. Finalize public capability API.

   Ensure these APIs are stable and documented:

   ```dart
   enum BatteryFeature { ... }
   class BatteryPlatformCapabilities { ... }

   Future<BatteryPlatformCapabilities> FlutterBattery.getPlatformCapabilities();
   Future<bool> FlutterBattery.isFeatureSupported(BatteryFeature feature);
   ```

2. Define platform feature matrix.

   Android should report:

   - `batteryLevel: true`
   - `batteryInfo: true`
   - `batteryHealth: true`
   - `batteryLevelStream: true`
   - `batteryInfoStream: true`
   - `batteryHealthStream: true`
   - `lowBatteryMonitoring: true`
   - `nativeNotifications: true`
   - `scheduledNotifications: true`
   - `blePeerSync: true`
   - `iotExampleBridge: true` only if retained as example/integration bridge

   macOS should report:

   - `batteryLevel: true`
   - `batteryInfo: true`
   - `batteryHealth: true`
   - `batteryLevelStream: true`
   - `batteryInfoStream: true`
   - `batteryHealthStream: true`
   - `lowBatteryMonitoring: false` unless fully implemented
   - `nativeNotifications: false`
   - `scheduledNotifications: false`
   - `blePeerSync: false`
   - `iotExampleBridge: false`

3. Normalize unsupported feature behavior.

   Introduce or finalize:

   ```dart
   class UnsupportedBatteryFeatureException implements Exception { ... }
   ```

   Raw `MissingPluginException` should not leak for known optional features such as:

   - BLE peer sync on macOS
   - native notifications on macOS
   - IoT demo bridge on macOS

4. Gate example UI by capabilities.

   Pages should not hardcode platform checks. They should consume `BatteryPlatformCapabilities`.

5. Document capability behavior.

   README must explain that features are runtime-queryable and optional.

### Acceptance Criteria

Run:

```sh
flutter analyze
flutter test
cd example && flutter test
```

Required result:

- Capability tests cover Android-like and macOS-like feature maps.
- Example dashboard disables unsupported features from capability object.
- Calling unsupported optional features produces a typed unsupported-feature failure or disabled UI, not raw `MissingPluginException`.
- README documents `getPlatformCapabilities()`.

## Milestone P2: Channel Contract Stabilization

Goal: make Android and macOS payloads consistent and testable.

Priority: high

### Scope

Files likely affected:

- `integration/channel/contracts/channel_contract.yaml`
- `lib/src/battery_channel_contract.dart`
- `lib/flutter_battery.dart`
- `lib/flutter_battery_method_channel.dart`
- `android/src/main/kotlin/com/example/flutter_battery/channel/EventChannelHandler.kt`
- `android/src/main/kotlin/com/example/flutter_battery/channel/MethodChannelHandler.kt`
- `macos/flutter_battery/Classes/BatteryMonitor.swift`
- `macos/flutter_battery/Classes/FlutterBatteryPlugin.swift`
- `test/flutter_battery_test.dart`
- `test/flutter_battery_method_channel_test.dart`

### Steps

1. Make `channel_contract.yaml` authoritative.

   Add schemas for:

   - `flutter_battery`
   - `flutter_battery/battery_stream`
   - `flutter_battery/peer_methods`
   - `flutter_battery/peer_events`

2. Normalize event types.

   Required event types:

   ```text
   BATTERY_LEVEL
   BATTERY_INFO
   BATTERY_HEALTH
   BATTERY_UNAVAILABLE
   BATTERY_ERROR
   ```

3. Normalize payload keys.

   For level events:

   ```yaml
   type: BATTERY_LEVEL
   batteryLevel: int
   level: int
   timestamp: int
   ```

   For info events:

   ```yaml
   type: BATTERY_INFO
   batteryLevel: int
   level: int
   isCharging: bool
   state: string
   temperature: double
   voltage: double
   timestamp: int
   ```

   For health events:

   ```yaml
   type: BATTERY_HEALTH
   state: string
   statusLabel: string
   isGood: bool
   riskLevel: string
   recommendations: list
   temperature: double
   voltage: double
   timestamp: int
   ```

4. Ensure Dart parser accepts both legacy and normalized payloads.

   Required compatibility:

   - Android legacy `batteryLevel`
   - macOS legacy `level`
   - normalized payload with both keys

5. Add contract-focused tests.

   Test names should be explicit:

   - `batteryInfoStream_accepts_level_key`
   - `batteryInfoStream_accepts_batteryLevel_key`
   - `batteryHealthStream_accepts_macos_payload`
   - `method_channel_payload_constants_match_contract`

### Acceptance Criteria

Run:

```sh
flutter analyze
flutter test
cd example && flutter test
```

Required result:

- Android and macOS emit the same event type names.
- Dart stream parsers do not assume one platform-specific key.
- Health stream works on macOS.
- Contract file documents all public plugin channels.

## Milestone P3: Scope Cleanup

Goal: reduce package scope and avoid publishing demo/integration code as core plugin code.

Priority: medium

### Scope

Files/directories likely affected:

- `android/src/main/kotlin/com/example/iot/nativekit/**`
- `scripts/bootstrap_iot.sh`
- `integration/channel/contracts/channel_contract.yaml`
- `example/lib/pages/iot_controls_page.dart`
- `example/lib/platform/example_platform_adapter.dart`
- `README.md`

### Steps

1. Decide whether IoT bridge is part of public plugin API.

   Recommended decision: no.

2. Move IoT nativekit out of plugin source.

   Options:

   - move to `example/android/...`
   - move to a separate package
   - keep only under `integration/` and exclude from published package

3. Decide whether BLE peer sync belongs in this package.

   Recommended long-term split:

   - `flutter_battery`: battery only
   - `flutter_battery_peer_sync`: BLE peer sync

4. Update README and support matrix.

   Make clear which features are core and which are demos.

5. Update `.pubignore`.

   Exclude non-public implementation experiments.

### Acceptance Criteria

Required result:

- Published archive does not include unrelated IoT implementation unless explicitly documented.
- README has a clear "Core API" and "Example-only features" split.
- Public package surface matches package name.
- `flutter pub publish --dry-run` archive listing is clean.

## Milestone P4: Documentation and API Polish

Goal: improve pub.dev documentation score and developer trust.

Priority: medium

### Scope

Files likely affected:

- `README.md`
- `example/README.md`
- `lib/flutter_battery.dart`
- `lib/src/platform_capabilities.dart`
- `lib/src/battery_channel_contract.dart`
- `CHANGELOG.md`

### Steps

1. Add English dartdoc to public API.

   Required public types:

   - `FlutterBattery`
   - `BatteryInfo`
   - `BatteryHealth`
   - `BatteryFeature`
   - `BatteryPlatformCapabilities`
   - `BatteryMonitorConfig`
   - `BatteryLevelMonitorConfig`

2. Add README quick start.

   Include:

   ```dart
   final battery = FlutterBattery();
   final level = await battery.getBatteryLevel();
   final info = await battery.getBatteryInfo();
   final capabilities = await battery.getPlatformCapabilities();
   ```

3. Add platform notes.

   Document:

   - macOS temperature/voltage are best-effort from `AppleSmartBattery`.
   - macOS health is best-effort and may return `UNKNOWN`.
   - native notifications are Android-only.
   - BLE peer sync is Android-only.

4. Add troubleshooting.

   Include:

   - macOS `Failed to foreground app; open returned 1` is a Flutter tool foregrounding issue.
   - no-battery desktop Macs return unavailable/zero fallback depending on API.

5. Keep CHANGELOG aligned with actual release.

### Acceptance Criteria

Required result:

- README has install, usage, support matrix, feature capability, troubleshooting sections.
- Public API has useful dartdoc.
- CHANGELOG has accurate version entry.
- `flutter pub publish --dry-run` has no warnings.

## Milestone P5: CI and Release Automation

Goal: make project quality reproducible.

Priority: medium

### Scope

Files likely affected:

- `.github/workflows/ci.yaml`
- `.github/workflows/publish_dry_run.yaml`
- `README.md`

### Steps

1. Add CI workflow.

   Required jobs:

   ```sh
   flutter pub get
   flutter analyze
   dart format --set-exit-if-changed lib test example
   flutter test
   cd example && flutter test
   ```

2. Add macOS build job.

   On macOS runner:

   ```sh
   cd example
   flutter build macos --debug
   ```

3. Add Android build smoke test if feasible.

   Example:

   ```sh
   cd example
   flutter build apk --debug
   ```

4. Add publish dry-run job.

   ```sh
   flutter pub publish --dry-run
   ```

5. Add status badge to README.

### Acceptance Criteria

Required result:

- CI passes on every pull request.
- macOS build is verified in CI.
- publish dry-run is verified before release.
- formatting is enforced.

## Milestone P6: Swift Package Manager Support

Goal: align with modern Flutter Apple-platform plugin expectations.

Priority: medium

### Scope

Files likely affected:

- `macos/flutter_battery/Package.swift`
- `macos/flutter_battery.podspec`
- `pubspec.yaml`
- `README.md`

### Steps

1. Add SwiftPM package definition for macOS plugin.

2. Verify source layout works for both CocoaPods and SwiftPM.

3. Document Apple platform requirements.

4. Re-run macOS build.

### Acceptance Criteria

Required result:

- SwiftPM package exists for macOS plugin source.
- CocoaPods build still works.
- `cd example && flutter build macos --debug` passes.
- README documents macOS minimum version.

## Milestone P7: Federated Plugin Evaluation

Goal: decide whether to split into federated packages.

Priority: long-term

### Recommended Future Structure

```text
flutter_battery/
flutter_battery_platform_interface/
flutter_battery_android/
flutter_battery_macos/
```

### Steps

1. Keep current single-package plugin until public API stabilizes.

2. Extract platform interface only after:

   - capabilities API is stable
   - channel contract is stable
   - Android/macOS behavior is tested

3. Extract platform implementations only if:

   - more platforms are added
   - platform code grows independently
   - separate release cadence is needed

### Acceptance Criteria

Required result:

- Decision documented in README or architecture notes.
- If federated split is done, app-facing package depends on platform packages through endorsed implementations.
- Existing users keep source-compatible imports where possible.

## Final Release Checklist

Before publishing a production-quality release:

```sh
dart format --set-exit-if-changed lib test example
flutter analyze
flutter test
cd example && flutter test
cd example && flutter build macos --debug
flutter pub publish --dry-run
```

Manual checks:

- Android device or emulator:
  - battery level
  - battery info
  - battery health
  - notification capability
  - BLE peer sync only if still in scope

- macOS MacBook:
  - battery level
  - temperature
  - voltage
  - health status does not falsely report severe degradation when capacity data is unavailable
  - unsupported Android-only features are disabled

Documentation checks:

- `LICENSE` is valid.
- `pubspec.yaml` metadata is real.
- `README.md` has support matrix.
- `CHANGELOG.md` matches release.
- `.pubignore` excludes internal files.

Target outcome:

- pub.dev dry-run clean.
- CI clean.
- package scope understandable from name and README.
- platform differences explicit and testable.
