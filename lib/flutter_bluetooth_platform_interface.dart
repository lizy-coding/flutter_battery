import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_bluetooth_method_channel.dart';

class BleDevice {
  final String id;
  final String name;
  final int rssi;

  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'rssi': rssi,
      };

  factory BleDevice.fromJson(Map<String, Object?> json) {
    return BleDevice(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      rssi: (json['rssi'] as num?)?.toInt() ?? 0,
    );
  }
}

enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

class BleConnectionEvent {
  final BleConnectionState state;
  final String deviceId;
  final String? error;

  const BleConnectionEvent({
    required this.state,
    required this.deviceId,
    this.error,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'state': switch (state) {
          BleConnectionState.disconnected => 'disconnected',
          BleConnectionState.connecting => 'connecting',
          BleConnectionState.connected => 'connected',
          BleConnectionState.disconnecting => 'disconnecting',
        },
        'deviceId': deviceId,
        'error': error,
      };

  factory BleConnectionEvent.fromJson(Map<String, Object?> json) {
    final stateValue = (json['state'] as String?) ?? 'disconnected';
    return BleConnectionEvent(
      state: switch (stateValue) {
        'connecting' => BleConnectionState.connecting,
        'connected' => BleConnectionState.connected,
        'disconnecting' => BleConnectionState.disconnecting,
        _ => BleConnectionState.disconnected,
      },
      deviceId: json['deviceId'] as String? ?? '',
      error: json['error'] as String?,
    );
  }
}

abstract class FlutterBluetoothPlatform extends PlatformInterface {
  FlutterBluetoothPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBluetoothPlatform _instance = MethodChannelFlutterBluetooth();

  static FlutterBluetoothPlatform get instance => _instance;

  static set instance(FlutterBluetoothPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isBleAvailable();
  Future<bool> isBleEnabled();

  Stream<List<BleDevice>> scanDevices({String? serviceUuid});

  Future<void> startScan({String? serviceUuid});
  Future<void> stopScan();

  Stream<BleConnectionEvent> connectionEvents();

  Future<void> connect(String deviceId, {bool autoConnect = false});
  Future<void> disconnect([String? deviceId]);

  Future<bool> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    bool withResponse = true,
  });

  Stream<List<int>> subscribeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  });

  Future<void> unsubscribeFromCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  });
}
