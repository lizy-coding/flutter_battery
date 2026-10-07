import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_battery_platform_interface.dart';
import 'src/battery_channel_contract.dart';
import 'src/platform_capabilities.dart';

class MethodChannelFlutterBattery extends FlutterBatteryPlatform {
  @visibleForTesting
  final MethodChannel methodChannel;

  @visibleForTesting
  final EventChannel eventChannel;

  Function(int batteryLevel)? _lowBatteryCallback;
  Function(int batteryLevel)? _batteryLevelChangeCallback;
  Function(Map<String, dynamic> batteryInfo)? _batteryInfoChangeCallback;
  Function(Map<String, dynamic> batteryHealth)? _batteryHealthChangeCallback;

  MethodChannelFlutterBattery()
      : methodChannel = const MethodChannel(BatteryChannelNames.methodChannel),
        eventChannel = const EventChannel(BatteryChannelNames.eventChannel) {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case BatteryMethodNames.onLowBattery:
        final int batteryLevel =
            call.arguments[BatteryPayloadKeys.batteryLevel] as int;
        if (_lowBatteryCallback != null) {
          _lowBatteryCallback!(batteryLevel);
        }
        return true;
      case BatteryMethodNames.onBatteryLevelChanged:
        final int batteryLevel =
            call.arguments[BatteryPayloadKeys.batteryLevel] as int;
        if (_batteryLevelChangeCallback != null) {
          _batteryLevelChangeCallback!(batteryLevel);
        }
        return true;
      case BatteryMethodNames.onBatteryInfoChanged:
        if (call.arguments is Map && _batteryInfoChangeCallback != null) {
          final map = call.arguments as Map<dynamic, dynamic>;
          _batteryInfoChangeCallback!(map.cast<String, dynamic>());
        }
        return true;
      case BatteryMethodNames.onBatteryHealthChanged:
        if (call.arguments is Map && _batteryHealthChangeCallback != null) {
          final map = call.arguments as Map<dynamic, dynamic>;
          _batteryHealthChangeCallback!(map.cast<String, dynamic>());
        }
        return true;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: '${call.method} has not been implemented.',
        );
    }
  }

  Future<dynamic> _invoke(String method, [dynamic args]) {
    return methodChannel.invokeMethod(method, args);
  }

  @override
  Future<BatteryPlatformCapabilities> getPlatformCapabilities() async {
    try {
      final result = await methodChannel.invokeMapMethod<String, bool>(
        BatteryMethodNames.getPlatformCapabilities,
      );
      if (result == null) {
        return const BatteryPlatformCapabilities(features: {});
      }
      return BatteryPlatformCapabilities.fromMap(
          result.cast<String, dynamic>());
    } on MissingPluginException {
      return const BatteryPlatformCapabilities(features: {});
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await _invoke(BatteryMethodNames.getPlatformVersion);
    return version as String?;
  }

  @override
  Future<int?> getBatteryLevel() async {
    final level = await _invoke(BatteryMethodNames.getBatteryLevel);
    return level as int?;
  }

  @override
  Future<Map<String, dynamic>> getBatteryInfo() async {
    final result =
        await methodChannel.invokeMapMethod(BatteryMethodNames.getBatteryInfo);
    if (result == null) {
      return <String, dynamic>{
        BatteryPayloadKeys.error: 'Failed to get battery info'
      };
    }
    return result.cast<String, dynamic>();
  }

  @override
  Future<List<String>> getBatteryOptimizationTips() async {
    final result = await methodChannel.invokeListMethod(
      BatteryMethodNames.getBatteryOptimizationTips,
    );
    if (result == null) return <String>[];
    return result.map((item) => item.toString()).toList();
  }

  @override
  Future<Map<String, dynamic>> getBatteryHealth() async {
    final result = await methodChannel
        .invokeMapMethod(BatteryMethodNames.getBatteryHealth);
    if (result == null) {
      return <String, dynamic>{
        BatteryPayloadKeys.error: 'Failed to get battery health'
      };
    }
    return result.cast<String, dynamic>();
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
  void setBatteryInfoChangeCallback(
      Function(Map<String, dynamic> batteryInfo) callback) {
    _batteryInfoChangeCallback = callback;
  }

  @override
  void setBatteryHealthChangeCallback(
      Function(Map<String, dynamic> batteryHealth) callback) {
    _batteryHealthChangeCallback = callback;
  }

  @override
  Future<bool?> startBatteryLevelListening() async {
    final result = await _invoke(BatteryMethodNames.startBatteryLevelListening);
    return result as bool?;
  }

  @override
  Future<bool?> stopBatteryLevelListening() async {
    final result = await _invoke(BatteryMethodNames.stopBatteryLevelListening);
    return result as bool?;
  }

  @override
  Future<bool?> startBatteryInfoListening({int intervalMs = 5000}) async {
    final result = await _invoke(BatteryMethodNames.startBatteryInfoListening, {
      BatteryPayloadKeys.intervalMs: intervalMs,
    });
    return result as bool?;
  }

  @override
  Future<bool?> stopBatteryInfoListening() async {
    final result = await _invoke(BatteryMethodNames.stopBatteryInfoListening);
    return result as bool?;
  }

  @override
  Future<bool?> startBatteryHealthListening({int intervalMs = 10000}) async {
    final result =
        await _invoke(BatteryMethodNames.startBatteryHealthListening, {
      BatteryPayloadKeys.intervalMs: intervalMs,
    });
    return result as bool?;
  }

  @override
  Future<bool?> stopBatteryHealthListening() async {
    final result = await _invoke(BatteryMethodNames.stopBatteryHealthListening);
    return result as bool?;
  }

  @override
  Stream<Map<String, dynamic>> get batteryStream {
    return eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is! Map) {
        return <String, dynamic>{
          BatteryPayloadKeys.batteryLevel: 0,
          BatteryPayloadKeys.timestamp: DateTime.now().millisecondsSinceEpoch,
          BatteryPayloadKeys.error: 'Invalid event format',
        };
      }
      final raw = Map<String, dynamic>.from(event);
      final type = raw[BatteryPayloadKeys.type] as String?;
      if (type == null && raw.containsKey(BatteryPayloadKeys.batteryLevel)) {
        raw[BatteryPayloadKeys.type] = BatteryEventTypes.batteryLevel;
      }
      return raw;
    });
  }

  @override
  Future<bool?> setPushInterval({
    required int intervalMs,
    bool enableDebounce = true,
  }) async {
    final result = await _invoke(BatteryMethodNames.setPushInterval, {
      BatteryPayloadKeys.intervalMs: intervalMs,
      BatteryPayloadKeys.enableDebounce: enableDebounce,
    });
    return result as bool?;
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
    if (useFlutterRendering && onLowBattery != null) {
      setLowBatteryCallback(onLowBattery);
    }
    final result = await _invoke(BatteryMethodNames.setBatteryLevelThreshold, {
      BatteryPayloadKeys.threshold: threshold,
      BatteryPayloadKeys.title: title,
      BatteryPayloadKeys.message: message,
      BatteryPayloadKeys.intervalMinutes: intervalMinutes,
      BatteryPayloadKeys.useFlutterRendering: useFlutterRendering,
    });
    return result as bool?;
  }

  @override
  Future<bool?> stopBatteryMonitoring() async {
    final result = await _invoke(BatteryMethodNames.stopBatteryMonitoring);
    return result as bool?;
  }

  @override
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) async {
    try {
      final result = await _invoke(BatteryMethodNames.scheduleNotification, {
        BatteryPayloadKeys.title: title,
        BatteryPayloadKeys.message: message,
        BatteryPayloadKeys.delayMinutes: delayMinutes,
      });
      return result as bool?;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) async {
    try {
      final result = await _invoke(BatteryMethodNames.showNotification, {
        BatteryPayloadKeys.title: title,
        BatteryPayloadKeys.message: message,
      });
      return result as bool?;
    } on MissingPluginException {
      return null;
    }
  }
}
