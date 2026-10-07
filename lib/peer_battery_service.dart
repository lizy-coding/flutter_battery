import 'dart:async';

import 'package:flutter/services.dart';

import 'src/battery_channel_contract.dart';
import 'src/platform_capabilities.dart';

enum PeerRole { master, slave }

class PeerBatteryState {
  final PeerRole role;
  final int localBattery;
  final int? remoteBattery;
  final bool isConnected;

  const PeerBatteryState({
    required this.role,
    required this.localBattery,
    required this.remoteBattery,
    required this.isConnected,
  });

  factory PeerBatteryState.fromMap(Map<dynamic, dynamic> map) {
    final roleStr = map['role'] as String? ?? 'master';
    final role = roleStr == 'slave' ? PeerRole.slave : PeerRole.master;
    return PeerBatteryState(
      role: role,
      localBattery: (map['localBattery'] as num?)?.toInt() ?? -1,
      remoteBattery: (map['remoteBattery'] as num?)?.toInt(),
      isConnected: map['connected'] == true,
    );
  }
}

class PeerBatteryService {
  static const MethodChannel _methodChannel =
      MethodChannel(BatteryChannelNames.peerMethods);
  static const EventChannel _eventChannel =
      EventChannel(BatteryChannelNames.peerEvents);

  Stream<PeerBatteryState>? _stream;

  Stream<PeerBatteryState> get peerBatteryStream {
    _stream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => PeerBatteryState.fromMap(event as Map))
        .asBroadcastStream();
    return _stream!;
  }

  Future<void> startAsMaster() async {
    try {
      await _methodChannel.invokeMethod(BatteryMethodNames.startMasterMode);
    } on MissingPluginException {
      throw UnsupportedBatteryFeatureException(
        BatteryFeature.blePeerSync,
        'BLE peer sync is not supported on this platform.',
      );
    } on PlatformException catch (e) {
      if (e.code != 'PERMISSION_REQUIRED') rethrow;
    }
  }

  Future<void> startAsSlave() async {
    try {
      await _methodChannel.invokeMethod(BatteryMethodNames.startSlaveMode);
    } on MissingPluginException {
      throw UnsupportedBatteryFeatureException(
        BatteryFeature.blePeerSync,
        'BLE peer sync is not supported on this platform.',
      );
    } on PlatformException catch (e) {
      if (e.code != 'PERMISSION_REQUIRED') rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod(BatteryMethodNames.stopAllPeerModes);
    } on MissingPluginException {
      throw UnsupportedBatteryFeatureException(
        BatteryFeature.blePeerSync,
        'BLE peer sync is not supported on this platform.',
      );
    }
  }

  Future<void> masterConnectToDevice(String deviceId) async {
    try {
      await _methodChannel
          .invokeMethod(BatteryMethodNames.masterConnectToDevice, {
        'deviceId': deviceId,
      });
    } on MissingPluginException {
      throw UnsupportedBatteryFeatureException(
        BatteryFeature.blePeerSync,
        'BLE peer sync is not supported on this platform.',
      );
    } on PlatformException catch (e) {
      if (e.code != 'PERMISSION_REQUIRED') rethrow;
    }
  }
}
