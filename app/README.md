# IoT Shell (Flutter)

Flutter 混生外壳，聚合 `flutter_battery` 插件与 `android-iot-native` Kotlin 模块：

- `lib/`：设备页、仪表盘、电量曲线、设置页以及统一 `MethodChannel('iot/native')` + `EventChannel('iot/stream')` bridge。
- `android/`：自定义 `MainActivity`，在 `MethodChannel` 里转发到 Kotlin IoT manager，并订阅事件流。
- `pubspec.yaml`：通过 `path: ../` 使用本地 `flutter_battery` 插件。
