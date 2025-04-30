import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_battery_method_channel.dart';

abstract class FlutterBatteryPlatform extends PlatformInterface {
  /// Constructs a FlutterBatteryPlatform.
  FlutterBatteryPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBatteryPlatform _instance = MethodChannelFlutterBattery();

  /// The default instance of [FlutterBatteryPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBattery].
  static FlutterBatteryPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBatteryPlatform] when
  /// they register themselves.
  static set instance(FlutterBatteryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  
  /// 获取电池电量百分比
  Future<int?> getBatteryLevel() {
    throw UnimplementedError('getBatteryLevel() has not been implemented.');
  }
  
  /// 调度一个延迟通知
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) {
    throw UnimplementedError('scheduleNotification() has not been implemented.');
  }
  
  /// 立即显示一个通知
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) {
    throw UnimplementedError('showNotification() has not been implemented.');
  }
}
