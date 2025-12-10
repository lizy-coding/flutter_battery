# flutter_battery example

This app exercises the public API exposed by `lib/flutter_battery.dart` and the Android bridge (MethodChannel/EventChannel + `PushNotificationManager`).

## What’s inside
- **Dashboard**: current battery level, info, health, and quick links.
- **Battery details**: live level/temperature/voltage/health with manual refresh.
- **Low-battery notification demo**: configures `configureBatteryMonitoring` to trigger native system notifications (or Flutter callbacks) when the threshold is hit, plus instant/1‑minute test notifications via `sendNotification`.
- **Peer battery sync**: master/slave BLE demo (select role and sync battery state).
- **IoT native controls**: sample MethodChannel calls for unrelated native stubs.
- **Event stream log**: shows messages from the demo EventChannel.

## Run the example
```bash
flutter pub get
flutter run -d <device_id>
```

## Low-battery notification flow
1) Open **低电量系统通知** from the dashboard.  
2) Adjust threshold/interval/title/message. Enable “同时使用 Flutter 回调” if you want Dart to handle `onLowBattery` in addition to native notifications.  
3) Tap **开启监控**. The plugin calls `configureBatteryMonitoring`, which forwards to the Android `PushNotificationManager` for threshold checks.  
4) Optional: use **立即测试通知** or **1 分钟后提醒** to verify `sendNotification` → native notification delivery without waiting for real low battery.  
5) On Android 13+, accept the notification permission prompt when it appears.

## Notes
- The main app wires up battery callbacks and monitoring once at startup; the low-battery page is a focused scenario demonstrating the same platform APIs.
- If you change demo code, run `dart format example/lib/main.dart` and `flutter analyze` before committing.
- Navigation uses named routes in `lib/routes.dart`, with feature pages organized under `lib/pages/` to keep `main.dart` small.
