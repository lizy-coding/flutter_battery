import 'dart:async';

import 'package:flutter/services.dart';

import 'models/native_event.dart';

class NativeBridge {
  NativeBridge._();

  static final NativeBridge instance = NativeBridge._();

  static const MethodChannel _methodChannel = MethodChannel('iot/native');
  static const EventChannel _eventChannel = EventChannel('iot/stream');

  Stream<NativeEvent>? _cachedStream;

  Stream<NativeEvent> get events =>
      _cachedStream ??= _eventChannel.receiveBroadcastStream().map((event) {
        return NativeEvent.fromDynamic(event);
      }).whereType<NativeEvent>().asBroadcastStream();

  Future<void> startScan({Map<String, dynamic>? filters}) async {
    await _methodChannel.invokeMethod<void>(
      'scanDevices',
      filters ?? const <String, dynamic>{},
    );
  }

  Future<void> connect({required String deviceId}) async {
    await _methodChannel.invokeMethod<void>('connect', {'deviceId': deviceId});
  }

  Future<void> startTelemetry({required String deviceId}) async {
    await _methodChannel.invokeMethod<void>('startTelemetry', {
      'deviceId': deviceId,
      'metrics': ['battery', 'temperature', 'voltage'],
    });
  }

  Future<void> stopTelemetry() async {
    await _methodChannel.invokeMethod<void>('stopTelemetry');
  }

  Future<void> requestBatterySnapshot({String? deviceId}) async {
    await _methodChannel.invokeMethod<void>('requestBatterySnapshot', {
      if (deviceId != null) 'deviceId': deviceId,
    });
  }
}
