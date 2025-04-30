import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_battery_platform_interface.dart';

/// An implementation of [FlutterBatteryPlatform] that uses method channels.
class MethodChannelFlutterBattery extends FlutterBatteryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_battery');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
  
  @override
  Future<int?> getBatteryLevel() async {
    final level = await methodChannel.invokeMethod<int>('getBatteryLevel');
    return level;
  }
  
  @override
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'scheduleNotification',
      {
        'title': title,
        'message': message,
        'delayMinutes': delayMinutes,
      },
    );
    return result;
  }
  
  @override
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'showNotification',
      {
        'title': title,
        'message': message,
      },
    );
    return result;
  }
}
