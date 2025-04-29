import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_assistant_platform_interface.dart';

/// An implementation of [FlutterAssistantPlatform] that uses method channels.
class MethodChannelFlutterAssistant extends FlutterAssistantPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_assistant');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
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
