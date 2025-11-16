import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';

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

  @override
  void initState() {
    super.initState();
    _refresh();
    _plugin.configureBatteryCallbacks(
      onBatteryLevelChange: (level) => setState(() => _batteryLevel = level),
      onBatteryInfoChange: (info) => setState(() => _batteryInfo = info),
    );
    _plugin.configureBatteryMonitor(
      BatteryMonitorConfig(monitorBatteryLevel: true, monitorBatteryInfo: true),
    );
  }

  Future<void> _refresh() async {
    final level = await _plugin.getBatteryLevel();
    final info = await _plugin.getBatteryInfo();
    if (!mounted) return;
    setState(() {
      _batteryLevel = level;
      _batteryInfo = info;
    });
  }

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
          ]),
        ),
      ),
    );
  }
}

