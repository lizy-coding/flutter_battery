import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_assistant_method_channel.dart';

abstract class FlutterAssistantPlatform extends PlatformInterface {
  /// Constructs a FlutterAssistantPlatform.
  FlutterAssistantPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAssistantPlatform _instance = MethodChannelFlutterAssistant();

  /// The default instance of [FlutterAssistantPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAssistant].
  static FlutterAssistantPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAssistantPlatform] when
  /// they register themselves.
  static set instance(FlutterAssistantPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
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
