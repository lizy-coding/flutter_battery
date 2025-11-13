## Session Context Snapshot

- Core repo artifacts:
  - `flutter_battery/` (current root) — plugin supplying `FlutterBattery`, `BatteryInfo`, `BatteryAnimation`.
  - `app/` — Flutter IoT shell driven by `app_shell.dart` with NavigationBar tabs (设备/仪表盘/电量曲线/设置).
  - `android-iot-native/` — Kotlin library skeleton emitting telemetry/connection/device events via shared flow.
  - `integration/channel/contracts/channel_contract.yaml` — Method/Event channel contract (`iot/native`, `iot/stream`).
  - `scripts/bootstrap_iot.sh` — helper for recreating directory scaffold.

- App structure highlights:
  - `app/lib/app_shell.dart`: root MaterialApp that buffers `NativeBridge.events` and routes to feature tabs.
  - `app/lib/core/native_bridge.dart`: singleton bridge exposing `events` stream plus `scan/connect/startTelemetry/requestBatterySnapshot` wrappers aligned with channel contract.
  - `app/lib/features/device/device_page.dart`: renders discovery events, connect + telemetry toggles using callbacks from `app_shell`.
  - `app/lib/features/dashboard/dashboard_page.dart`: consumes buffered events + current battery level to drive `BatteryAnimation`, telemetry cards, and trend placeholder.
  - `app/lib/features/settings/settings_page.dart`: shows battery status, runtime toggles, and re-scan actions within the tab layout.
  - `app/lib/shared/widgets/{gauge.dart,line_chart.dart}`: placeholder widgets for charts.

- Plugin linkage:
  - `app/pubspec.yaml` depends on `flutter_battery` via `path: ../flutter_battery`.
  - Dashboard imports `package:flutter_battery/flutter_battery.dart` and shared animation.

- Outstanding work / reminders:
  - Local Flutter/Dart CLI uses CRLF shebang; running `flutter pub get` / `flutter run` currently fails (`/usr/bin/env: 'bash\r'`). Need environment with proper SDK (or fix scripts) before building.
  - Android runner still needs channel wiring to new `android-iot-native` module for full functionality.
  - Tests not run; once SDK available, execute `flutter pub get` inside `app/` and `flutter test`.

Use this file as a continuity note for future sessions.
