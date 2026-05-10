import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_battery/flutter_battery.dart';

abstract class ExamplePlatformAdapter {
  const ExamplePlatformAdapter();

  String get platformName;

  BatteryPlatformCapabilities get capabilities;

  Stream<Object?> get iotEvents;

  Future<void> invokeIotMethod(String method, [Object? arguments]);

  static ExamplePlatformAdapter current() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidExamplePlatformAdapter();
    }
    return UnsupportedExamplePlatformAdapter(
        platformName: defaultTargetPlatform.name);
  }
}

class AndroidExamplePlatformAdapter extends ExamplePlatformAdapter {
  const AndroidExamplePlatformAdapter();

  static const MethodChannel _iotMethod = MethodChannel('iot/native');
  static const EventChannel _iotEvent = EventChannel('iot/stream');

  @override
  String get platformName => 'android';

  @override
  BatteryPlatformCapabilities get capabilities =>
      const BatteryPlatformCapabilities(features: {
        BatteryFeature.batteryLevel: true,
        BatteryFeature.batteryInfo: true,
        BatteryFeature.batteryHealth: true,
        BatteryFeature.batteryLevelStream: true,
        BatteryFeature.batteryInfoStream: true,
        BatteryFeature.batteryHealthStream: true,
        BatteryFeature.lowBatteryMonitoring: true,
        BatteryFeature.nativeNotifications: true,
        BatteryFeature.scheduledNotifications: true,
        BatteryFeature.blePeerSync: true,
        BatteryFeature.iotExampleBridge: true,
      });

  @override
  Stream<Object?> get iotEvents => _iotEvent.receiveBroadcastStream();

  @override
  Future<void> invokeIotMethod(String method, [Object? arguments]) {
    return _iotMethod.invokeMethod<void>(method, arguments);
  }
}

class UnsupportedExamplePlatformAdapter extends ExamplePlatformAdapter {
  const UnsupportedExamplePlatformAdapter({required this.platformName});

  @override
  final String platformName;

  @override
  BatteryPlatformCapabilities get capabilities =>
      const BatteryPlatformCapabilities(features: {
        BatteryFeature.batteryLevel: true,
        BatteryFeature.batteryInfo: true,
        BatteryFeature.batteryHealth: true,
        BatteryFeature.batteryLevelStream: true,
        BatteryFeature.batteryInfoStream: true,
        BatteryFeature.batteryHealthStream: true,
        BatteryFeature.lowBatteryMonitoring: true,
        BatteryFeature.nativeNotifications: false,
        BatteryFeature.scheduledNotifications: false,
        BatteryFeature.blePeerSync: false,
        BatteryFeature.iotExampleBridge: false,
      });

  @override
  Stream<Object?> get iotEvents {
    return Stream<Object?>.value(
      'IoT native controls are Android-only. Current platform: $platformName.',
    );
  }

  @override
  Future<void> invokeIotMethod(String method, [Object? arguments]) {
    throw UnsupportedBatteryFeatureException(
      BatteryFeature.iotExampleBridge,
      'IoT native controls are Android-only. Current platform: $platformName.',
    );
  }
}
