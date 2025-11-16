# Flutter Battery → 标准 Flutter 混生 Android IoT 改造文档

## 0. Repo Snapshot (当前 /mnt/e/flutter_battery)
- flutter_battery/: 现有插件，Android 入口 `com.example.flutter_battery.FlutterBatteryPlugin`
- android/: 插件 Android 工程 (AAR)；Gradle Wrapper 可沿用
- example/: Flutter 示例 Runner，可作为新 app/ 的 UI 参考
- lib/, test/, analysis_options.yaml: 插件 Dart 层逻辑，需保留
- pubspec.yaml: SDK 约束 `>=3.0.0 <4.0.0`，升级时保持兼容

## 1. 目标目录与职责
```
repo-root/
├─ flutter_battery/                # 电池子系统 SDK，MethodChannel/EventChannel 仅做电池能力
├─ app/                            # Flutter 混生外壳，UI/状态管理 + channel 统一封装
│  ├─ lib/                         # 设备页/仪表盘/曲线/设置 + bloc/provider
│  ├─ android/app/                 # Runner，集成 android-iot-native + flutter_battery
│  └─ ios/                         # 预留，最小依赖 flutter_battery
├─ android-iot-native/             # Kotlin/Jetpack BLE+Foreground Service+Telemetry Library
│  ├─ src/main/java|kotlin/…       # BLE 扫描/连接/指令、Service、Repository
│  ├─ src/main/res/                # Foreground 通知、布局、string
│  └─ src/main/AndroidManifest.xml # Service + permission 声明
├─ integration/                    # Channel contract、proto、bridge 测试桩
├─ scripts/                        # 重组脚本、CI helper、bootstrap
├─ build.gradle / settings.gradle  # 根构建脚本，统一版本 catalog
└─ .github/workflows/… (可选)        # CI，包含 flutter build + gradle lint
```

## 2. 改造步骤清单
1. `git mv example app` 或 `flutter create --platforms=android -a kotlin --project-name iot_shell app` (推荐新建，避免插件示例耦合)
2. `flutter pub add --path ../flutter_battery flutter_battery` (在 app/)
3. `mkdir -p android-iot-native/src/main/{java,kotlin,res}` 并初始化 `build.gradle.kts`
4. 根目录建立 `settings.gradle.kts`，`include(":app", ":android-iot-native", ":flutter_battery")`
5. `app/android/app/build.gradle`：应用插件 `com.android.application`，`implementation(project(":android-iot-native"))`
6. `android-iot-native` 中实现 `MethodChannel("iot/native")` handler + `EventChannel("iot/stream")` emitter，通过 `BinaryMessenger` 注入 (App Runner 或 FlutterEngine)
7. `flutter_battery` 暴露的 `FlutterBatteryPlugin` 保持不变；在 app/lib 建立 `BatterySubsystemRepository` 聚合插件 + native stream
8. `integration/channel` 维护 `channel_contract.yaml`，描述 Method/args/Event payloads，供 Dart/Android 双向验证
9. 根级 `gradle/libs.versions.toml` 统一版本：`kotlin=1.9.x、agp=8.1.x、coreKtx=1.12.x、lifecycle=2.6.x、room=2.5.x、coroutines=1.7.x`
10. Android Studio/Gradle Sync，确认 `android-iot-native` 作为 library，`app` 为 application，`flutter_battery` 仍由 Flutter tool 管理

## 3. 模块创建命令 & Gradle 关联
```bash
# Flutter 外壳 (repo 根执行)
flutter create --project-name iot_shell --platforms=android -a kotlin app

# Kotlin 库模块
mkdir -p android-iot-native/src/main/{java,kotlin,res}
cat <<'GRADLE' > android-iot-native/build.gradle.kts
plugins {
    id("com.android.library")
    kotlin("android")
    id("kotlin-kapt")
}
android {
    namespace = "com.example.iot.native"
    compileSdk = libs.versions.compileSdk.get().toInt()
    defaultConfig {
        minSdk = 26
        targetSdk = 34
    }
}
dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime)
    implementation(libs.androidx.activity.ktx)
    implementation(libs.androidx.room.runtime)
    kapt(libs.androidx.room.compiler)
    implementation(libs.kotlinx.coroutines.android)
}
GRADLE
```
```kotlin
// 根 settings.gradle.kts
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
include(":app", ":android-iot-native", ":flutter_battery")
project(":flutter_battery").projectDir = file("flutter_battery")
```
```groovy
// app/android/app/build.gradle (精简)
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}
android {
    namespace "com.example.iot.shell"
    compileSdk rootProject.ext.compileSdk
    defaultConfig {
        applicationId "com.example.iot.shell"
        minSdk 26
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
}
dependencies {
    implementation project(':android-iot-native')
    implementation project(':flutter_battery')
    implementation "org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion"
}
```

## 4. 权限与 Manifest 归属 (API 31+)
| Permission/API             | 归属 | 用途/说明 |
|---------------------------|------|-----------|
| `android.permission.BLUETOOTH_SCAN` (31)| app Manifest `<uses-permission android:usesPermissionFlags="neverForLocation"/>` + feature `android.hardware.bluetooth_le` |
| `android.permission.BLUETOOTH_CONNECT` | app Manifest |
| `android.permission.BLUETOOTH_ADVERTISE` (可选) | app Manifest |
| `android.permission.ACCESS_FINE_LOCATION` | app Manifest，BLE 扫描需要 |
| `android.permission.ACCESS_COARSE_LOCATION` | app Manifest，兼容旧机 |
| `android.permission.ACCESS_BACKGROUND_LOCATION` (maxSdk30) | app Manifest Queries/back-compat |
| `android.permission.POST_NOTIFICATIONS` | app Manifest，前台 Service 通知 |
| `android.permission.FOREGROUND_SERVICE` | app Manifest |
| `android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE` (34+) | 库 Manifest (android-iot-native) |
| `<service android:name=".telemetry.TelemetryService" android:foregroundServiceType="dataSync|connectedDevice"/>` | 库 Manifest |
| `<provider android:name="androidx.startup.InitializationProvider" ...>` (若使用 App Startup) | 库 Manifest |
| `<queries>` (BLE 扫描) | app Manifest |

## 5. Channel/交互约束
- MethodChannel `iot/native`: `scanDevices(args: {filters, timeout})`, `connect(deviceId)`, `startTelemetry(battery=true, sensors=true)`, `stopTelemetry()`, `requestBatterySnapshot()`
- EventChannel `iot/stream`: payload schema `{type, deviceId, ts, data}`；type 包括 `telemetry`, `battery`, `connection`
- app/lib 建立 `NativeBridge`，所有 UI 与 native 通信在此模块；flutter_battery 暴露的 `BatteryLevelStream` 作为 `type=battery` 的唯一来源
- android-iot-native 内部模块：`ble`, `service`, `telemetry`, `batteryreport`，均通过 `ChannelBridge` 统一出口

## 6. Bootstrap 脚本 (scripts/bootstrap_iot.sh)
```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

mkdir -p app/lib app/android app/ios
mkdir -p android-iot-native/src/main/{java,kotlin,res}
mkdir -p integration/channel/contracts
mkdir -p scripts

: > app/lib/main.dart
: > app/android/app_build_notes.md
: > android-iot-native/build.gradle.kts
: > android-iot-native/src/main/AndroidManifest.xml
: > integration/channel/contracts/channel_contract.yaml
```

## 7. 验收 Checklist
- `./gradlew :app:assembleDebug`, `:android-iot-native:assemble`, `flutter build apk` 均成功
- Gradle Sync / `./gradlew tasks` 无 module 丢失；`settings.gradle.kts` 含三个模块
- Manifest Merge report (Android Studio → Analyzer) 无冲突；所需权限全部在最终 merged manifest
- `./gradlew :app:lintRelease` 与 `:android-iot-native:lint` 通过，BLE 权限告警关闭
- Flutter `MethodChannel`、`EventChannel` 注册点存在 (`app/android/app/src/main/kotlin/.../MainActivity.kt`)；`NativeBridge` Dart 层 API 与 android-iot-native 对齐
- Telemetry ForegroundService 在 Android 12+ 正常弹出通知 (手动验证)；POST_NOTIFICATIONS runtime grant 流程完成
