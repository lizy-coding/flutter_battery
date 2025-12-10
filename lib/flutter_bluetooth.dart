library flutter_bluetooth;

import 'flutter_bluetooth_platform_interface.dart';

export 'flutter_bluetooth_platform_interface.dart'
    show BleDevice, BleConnectionEvent, BleConnectionState, FlutterBluetoothPlatform;

class FlutterBluetooth {
  FlutterBluetooth._();
  static final FlutterBluetooth instance = FlutterBluetooth._();

  FlutterBluetoothPlatform get _platform => FlutterBluetoothPlatform.instance;

  Future<bool> isBleAvailable() => _platform.isBleAvailable();
  Future<bool> isBleEnabled() => _platform.isBleEnabled();

  Stream<List<BleDevice>> scanDevices({String? serviceUuid}) =>
      _platform.scanDevices(serviceUuid: serviceUuid);

  Future<void> startScan({String? serviceUuid}) =>
      _platform.startScan(serviceUuid: serviceUuid);

  Future<void> stopScan() => _platform.stopScan();

  Stream<BleConnectionEvent> get connectionEvents => _platform.connectionEvents();

  Future<void> connect(String deviceId, {bool autoConnect = false}) =>
      _platform.connect(deviceId, autoConnect: autoConnect);

  Future<void> disconnect([String? deviceId]) => _platform.disconnect(deviceId);

  Future<bool> writeCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
    required List<int> value,
    bool withResponse = true,
  }) =>
      _platform.writeCharacteristic(
        deviceId: deviceId,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        value: value,
        withResponse: withResponse,
      );

  Stream<List<int>> subscribeToCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      _platform.subscribeToCharacteristic(
        deviceId: deviceId,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );

  Future<void> unsubscribeFromCharacteristic({
    required String deviceId,
    required String serviceUuid,
    required String characteristicUuid,
  }) =>
      _platform.unsubscribeFromCharacteristic(
        deviceId: deviceId,
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
      );
}
