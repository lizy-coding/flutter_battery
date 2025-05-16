import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_battery_platform_interface.dart';

/// An implementation of [FlutterBatteryPlatform] that uses method channels.
class MethodChannelFlutterBattery extends FlutterBatteryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_battery');
  
  /// The event channel used to receive battery updates
  @visibleForTesting
  final eventChannel = const EventChannel('flutter_battery/battery_stream');
  
  // 电池低电量回调
  Function(int batteryLevel)? _lowBatteryCallback;
  
  // 电池电量变化回调
  Function(int batteryLevel)? _batteryLevelChangeCallback;

  MethodChannelFlutterBattery() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }
  
  // 处理来自原生层的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLowBattery':
        final int batteryLevel = call.arguments['batteryLevel'] as int;
        if (_lowBatteryCallback != null) {
          _lowBatteryCallback!(batteryLevel);
        }
        return true;
      case 'onBatteryLevelChanged':
        final int batteryLevel = call.arguments['batteryLevel'] as int;
        if (_batteryLevelChangeCallback != null) {
          _batteryLevelChangeCallback!(batteryLevel);
        }
        return true;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: '${call.method} 尚未实现',
        );
    }
  }

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
  void setLowBatteryCallback(Function(int batteryLevel) callback) {
    _lowBatteryCallback = callback;
  }
  
  @override
  void setBatteryLevelChangeCallback(Function(int batteryLevel) callback) {
    _batteryLevelChangeCallback = callback;
  }
  
  @override
  Future<bool?> startBatteryLevelListening() async {
    final result = await methodChannel.invokeMethod<bool>('startBatteryLevelListening');
    return result;
  }
  
  @override
  Future<bool?> stopBatteryLevelListening() async {
    final result = await methodChannel.invokeMethod<bool>('stopBatteryLevelListening');
    return result;
  }
  
  @override
  Stream<Map<String, dynamic>> get batteryStream {
    return eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is! Map) {
        return <String, dynamic>{
          'batteryLevel': 0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'error': 'Invalid event format',
        };
      }
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      return map.cast<String, dynamic>();
    });
  }
  
  @override
  Future<bool?> setPushInterval({
    required int intervalMs,
    bool enableDebounce = true,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'setPushInterval',
      {
        'intervalMs': intervalMs,
        'enableDebounce': enableDebounce,
      },
    );
    return result;
  }
  
  @override
  Future<bool?> setBatteryLevelThreshold({
    required int threshold,
    required String title,
    required String message,
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    dynamic Function(int)? onLowBattery,
  }) async {
    final result = await methodChannel.invokeMethod<bool>(
      'setBatteryLevelThreshold',
      {
        'threshold': threshold,
        'title': title,
        'message': message,
        'intervalMinutes': intervalMinutes,
        'useFlutterRendering': useFlutterRendering,
      },
    );
    return result;
  }
  
  @override
  Future<bool?> stopBatteryMonitoring() async {
    final result = await methodChannel.invokeMethod<bool>('stopBatteryMonitoring');
    return result;
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
