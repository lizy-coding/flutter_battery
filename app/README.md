# IoT Shell (Flutter)

Flutter 混生外壳，聚合 `flutter_battery` 插件与 `android-iot-native` Kotlin 模块：

- `lib/`：设备页、仪表盘、电量曲线、设置页以及统一 `MethodChannel('iot/native')` + `EventChannel('iot/stream')` bridge。
- `android/`：自定义 `MainActivity`，在 `MethodChannel` 里转发到 Kotlin IoT manager，并订阅事件流。
- `pubspec.yaml`：通过 `path: ../` 使用本地 `flutter_battery` 插件。

## 模块关系（app/lib ↔ flutter_battery）
- `app/lib/core/native_bridge.dart`：只负责 IoT 设备和 Telemetry 的原生通信；电池相关逻辑全部交给 `flutter_battery` 插件，避免重复实现。
- `flutter_battery/lib/flutter_battery.dart`：提供 `FlutterBattery`、`BatteryInfo`、`batteryStream` 等 API；同一路径下的 `battery_animation.dart` 也会被 `DashboardPage` 复用。
- `app/lib/features/dashboard/dashboard_page.dart`：通过 `FlutterBattery().batteryInfoStream` 获取电池百分比并复用 `BatteryAnimation`，实现“电池子系统 SDK”→App Shell 的单向依赖。
- 其他页面 (`devices_page.dart`, `settings_page.dart`) 仅依赖 `NativeBridge` 或 Flutter UI，不与 `flutter_battery` 耦合。
