import 'dart:async';

import 'package:flutter/services.dart';

class NativeBridge {
  NativeBridge() {
    _devicesController.add(List.unmodifiable(_devices));
    _subscribeToNativeStream();
  }

  static const MethodChannel _methodChannel = MethodChannel('iot/native');
  static const EventChannel _eventChannel = EventChannel('iot/stream');

  final StreamController<List<Map<String, dynamic>>> _devicesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();

  final List<Map<String, dynamic>> _devices = <Map<String, dynamic>>[];
  StreamSubscription<dynamic>? _eventSubscription;

  Stream<List<Map<String, dynamic>>> get devicesStream =>
      _devicesController.stream;
  Stream<Map<String, dynamic>> get telemetryStream =>
      _telemetryController.stream;

  Future<void> startScan() => _invoke<void>('scanDevices');

  Future<void> stopScan() => _invoke<void>('stopScan');

  Future<void> connect(String deviceId) =>
      _invoke<void>('connect', {'deviceId': deviceId});

  Future<void> disconnect(String deviceId) =>
      _invoke<void>('disconnect', {'deviceId': deviceId});

  Future<void> startSync() => _invoke<void>('startSync');

  Future<void> stopSync() => _invoke<void>('stopSync');

  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? arguments]) async {
    try {
      return await _methodChannel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  void _subscribeToNativeStream() {
    try {
      _eventSubscription = _eventChannel
          .receiveBroadcastStream()
          .listen(_handleNativeEvent, onError: (_) {});
    } on MissingPluginException {
      // Native side not ready; stay silent.
    }
  }

  void _handleNativeEvent(dynamic event) {
    final payload = _asMap(event);
    if (payload == null) return;
    switch (payload['type']) {
      case 'discovered':
      case 'device':
        _upsertDevice(payload['data']);
        break;
      case 'telemetry':
        final data = _asMap(payload['data']);
        if (data != null) {
          _telemetryController.add(data);
        }
        break;
      default:
        break;
    }
  }

  void _upsertDevice(dynamic data) {
    final device = _asMap(data);
    if (device == null) return;
    final id = device['id']?.toString();
    if (id == null || id.isEmpty) return;
    final index = _devices.indexWhere((element) => element['id'] == id);
    if (index >= 0) {
      _devices[index] = Map<String, dynamic>.from(device);
    } else {
      _devices.add(Map<String, dynamic>.from(device));
    }
    _devicesController.add(List.unmodifiable(_devices));
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _devicesController.close();
    await _telemetryController.close();
  }
}
