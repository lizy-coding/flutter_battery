import 'dart:async';

import 'package:flutter/services.dart';

import 'flutter_bluetooth_platform_interface.dart';

class MethodChannelFlutterBluetooth extends FlutterBluetoothPlatform {
  static const MethodChannel _methodChannel = MethodChannel('flutter_battery/ble_methods');
  static const EventChannel _scanEventChannel = EventChannel('flutter_battery/ble_scan_events');
  static const EventChannel _connectionEventChannel =
      EventChannel('flutter_battery/ble_connection_events');

  Stream<List<BleDevice>>? _scanStream;
  Stream<BleConnectionEvent>? _connectionStream;

  final Map<String, Stream<List<int>>> _notificationStreams = {};

  @override
  Future<bool> isBleAvailable() async {
    final result = await _methodChannel.invokeMethod<bool>('isBleAvailable');
    return result ?? false;
  }

  @override
  Future<bool> isBleEnabled() async {
    final result = await _methodChannel.invokeMethod<bool>('isBleEnabled');
    return result ?? false;
  }

  @override
  Stream<List<BleDevice>> scanDevices({String? serviceUuid}) {
    _scanStream ??= _scanEventChannel.receiveBroadcastStream({'serviceUuid': serviceUuid}).map(
          (event) {
            final list = (event as List).cast<Object?>();
            return list
                .map((e) {
                  final map = Map<String, Object?>.from(e as Map);
                  return BleDevice.fromJson(map);
                })
                .toList();
          },
        ).asBroadcastStream();
    return _scanStream!;
  }

  @override
  Future<void> startScan({String? serviceUuid}) async {
    await _methodChannel.invokeMethod('startScan', {
      'serviceUuid': serviceUuid,
    });
  }

  @override
  Future<void> stopScan() async {
    await _methodChannel.invokeMethod('stopScan');
  }

  @override
  Stream<BleConnectionEvent> connectionEvents() {
    _connectionStream ??= _connectionEventChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, Object?>.from(event as Map);
      return BleConnectionEvent.fromJson(map);
    }).asBroadcastStream();
    return _connectionStream!;
  }

  @override
  Future<void> connect(String deviceId, {bool autoConnect = false}) async {
    await _methodChannel.invokeMethod('connect', {
      'deviceId': deviceId,
      'autoConnect': autoConnect,
    });
  }

  @override
  Future<void> disconnect([String? deviceId]) async {
    await _methodChannel.invokeMethod('disconnect', {
      'deviceId': deviceId,
    });
  }

  @override
  Future<bool> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    bool withResponse = true,
  }) async {
    final result = await _methodChannel.invokeMethod<bool>('writeCharacteristic', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
      'value': value,
      'withResponse': withResponse,
    });
    return result ?? false;
  }

  @override
  Stream<List<int>> subscribeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    throw UnimplementedError('subscribeToCharacteristic is not implemented on this platform.');
  }

  @override
  Future<void> unsubscribeFromCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    await _methodChannel.invokeMethod('unsubscribeFromCharacteristic', {
      'deviceId': deviceId,
      'serviceUuid': serviceUuid,
      'characteristicUuid': characteristicUuid,
    });
    final key = '$deviceId|$serviceUuid|$characteristicUuid';
    _notificationStreams.remove(key);
  }
}
