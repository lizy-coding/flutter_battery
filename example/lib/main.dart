import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterBatteryExampleApp());
}

class FlutterBatteryExampleApp extends StatefulWidget {
  const FlutterBatteryExampleApp({super.key});

  @override
  State<FlutterBatteryExampleApp> createState() => _FlutterBatteryExampleAppState();
}

class _FlutterBatteryExampleAppState extends State<FlutterBatteryExampleApp> {
  final FlutterBattery _plugin = FlutterBattery();
  int? _batteryLevel;
  BatteryInfo? _batteryInfo;
  BatteryHealth? _batteryHealth;
  // IoT native bridge
  static const MethodChannel _iotMethod = MethodChannel('iot/native');
  static const EventChannel _iotEvent = EventChannel('iot/stream');
  StreamSubscription? _iotSub;

  @override
  void initState() {
    super.initState();
    _refresh();
    _plugin.configureBatteryCallbacks(
      onBatteryLevelChange: (level) => setState(() => _batteryLevel = level),
      onBatteryInfoChange: (info) => setState(() => _batteryInfo = info),
      onBatteryHealthChange: (health) => setState(() => _batteryHealth = health),
    );
    _plugin.configureBatteryMonitor(
      BatteryMonitorConfig(
        monitorBatteryLevel: true,
        monitorBatteryInfo: true,
        monitorBatteryHealth: true,
      ),
    );
    _iotSub = _iotEvent.receiveBroadcastStream().listen((dynamic e) {
      debugPrint('IoT event: $e');
    }, onError: (Object err) {
      debugPrint('IoT event error: $err');
    });
  }

  Future<void> _refresh() async {
    final level = await _plugin.getBatteryLevel();
    final info = await _plugin.getBatteryInfo();
    final health = await _plugin.getBatteryHealth();
    if (!mounted) return;
    setState(() {
      _batteryLevel = level;
      _batteryInfo = info;
      _batteryHealth = health;
    });
  }

  Future<void> _startScan() => _iotMethod.invokeMethod<void>('scanDevices');
  Future<void> _stopScan() => _iotMethod.invokeMethod<void>('stopScan');
  Future<void> _connect() => _iotMethod.invokeMethod<void>('connect', {'deviceId': 'demo-001'});
  Future<void> _disconnect() => _iotMethod.invokeMethod<void>('disconnect');
  Future<void> _startSync() => _iotMethod.invokeMethod<void>('startSync');
  Future<void> _stopSync() => _iotMethod.invokeMethod<void>('stopSync');

  @override
  Widget build(BuildContext context) {
    final level = _batteryLevel ?? _batteryInfo?.level ?? 0;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_battery example'), actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ]),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            BatteryAnimation(
              batteryLevel: level,
              width: 120,
              height: 240,
              isCharging: _batteryInfo?.isCharging ?? false,
            ),
            const SizedBox(height: 16),
            Text('Battery: $level%'),
            if (_batteryInfo != null) ...[
              Text('State: ${_batteryInfo!.state}'),
              Text('Temp: ${_batteryInfo!.temperature.toStringAsFixed(1)}°C'),
              Text('Voltage: ${_batteryInfo!.voltage.toStringAsFixed(2)}V'),
            ],
            if (_batteryHealth != null) ...[
              const SizedBox(height: 12),
              Text(
                'Health: ${_batteryHealth!.state.name.toUpperCase()} (${_batteryHealth!.statusLabel})',
              ),
              Text('Risk: ${_batteryHealth!.riskLevel}'),
              ..._batteryHealth!.recommendations
                  .map((tip) => Text('• $tip'))
                  .toList(),
            ],
            const SizedBox(height: 24),
            const Text('IoT Native Controls'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton(onPressed: _startScan, child: const Text('Scan')),
              ElevatedButton(onPressed: _stopScan, child: const Text('Stop Scan')),
              ElevatedButton(onPressed: _connect, child: const Text('Connect')),
              ElevatedButton(onPressed: _disconnect, child: const Text('Disconnect')),
              ElevatedButton(onPressed: _startSync, child: const Text('Start Sync')),
              ElevatedButton(onPressed: _stopSync, child: const Text('Stop Sync')),
            ]),
          ]),
        ),
      ),
    );
  }
}
