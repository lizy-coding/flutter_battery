import 'dart:async';

import 'package:flutter/services.dart';

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
  static const MethodChannel _methodChannel = MethodChannel('flutter_battery/peer_methods');
  static const EventChannel _eventChannel = EventChannel('flutter_battery/peer_events');

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
      await _methodChannel.invokeMethod('startMasterMode');
    } on PlatformException catch (e) {
      if (e.code != 'PERMISSION_REQUIRED') rethrow;
    }
  }

  Future<void> startAsSlave() async {
    try {
      await _methodChannel.invokeMethod('startSlaveMode');
    } on PlatformException catch (e) {
      if (e.code != 'PERMISSION_REQUIRED') rethrow;
    }
  }

  Future<void> stop() async {
    await _methodChannel.invokeMethod('stopAllPeerModes');
  }

  Future<void> masterConnectToDevice(String deviceId) async {
    try {
      await _methodChannel.invokeMethod('masterConnectToDevice', {
        'deviceId': deviceId,
      });
    } on PlatformException catch (e) {
      if (e.code != 'PERMISSION_REQUIRED') rethrow;
    }
  }
}
