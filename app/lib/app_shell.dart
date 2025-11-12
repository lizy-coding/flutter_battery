import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';

import 'core/battery/battery_subsystem_repository.dart';
import 'core/models/native_event.dart';
import 'core/native_bridge.dart';
import 'features/battery_curve/battery_curve_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/device/device_page.dart';
import 'features/settings/settings_page.dart';

class IotShellApp extends StatefulWidget {
  const IotShellApp({super.key});

  @override
  State<IotShellApp> createState() => _IotShellAppState();
}

class _IotShellAppState extends State<IotShellApp> {
  final NativeBridge _bridge = NativeBridge.instance;
  late final BatterySubsystemRepository _batteryRepository;
  StreamSubscription<NativeEvent>? _eventSubscription;
  final List<NativeEvent> _eventBuffer = <NativeEvent>[];
  int? _batteryLevel;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _batteryRepository = BatterySubsystemRepository(FlutterBattery());
    _eventSubscription = _bridge.events.listen(_handleNativeEvent);
    _refreshBattery();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshBattery() async {
    final level = await _batteryRepository.fetchBatteryLevel();
    if (!mounted) return;
    setState(() => _batteryLevel = level);
  }

  void _handleNativeEvent(NativeEvent event) {
    setState(() {
      _eventBuffer.add(event);
      if (_eventBuffer.length > 128) {
        _eventBuffer.removeAt(0);
      }
      if (event.type == NativeEventType.battery) {
        _batteryLevel = event.data['level'] as int? ?? _batteryLevel;
      }
    });
  }

  Future<void> _startScan() => _bridge.startScan();

  Future<void> _connect(String deviceId) => _bridge.connect(deviceId: deviceId);

  Future<void> _startTelemetry(String deviceId) => _bridge.startTelemetry(deviceId: deviceId);

  Future<void> _stopTelemetry() => _bridge.stopTelemetry();

  Future<void> _requestBatterySnapshot({String? deviceId}) => _bridge.requestBatterySnapshot(deviceId: deviceId);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Shell',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey)),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('IoT Device Shell'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshBattery,
              tooltip: 'Refresh Battery',
            ),
          ],
        ),
        body: Column(
          children: [
            NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.devices_other_outlined), label: '设备'),
                NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), label: '仪表盘'),
                NavigationDestination(icon: Icon(Icons.show_chart), label: '电量曲线'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), label: '设置'),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  DevicePage(
                    events: _eventBuffer,
                    onScan: _startScan,
                    onConnect: _connect,
                    onTelemetryToggle: (deviceId, enable) =>
                        enable ? _startTelemetry(deviceId) : _stopTelemetry(),
                  ),
                  DashboardPage(
                    events: _eventBuffer,
                    batteryLevel: _batteryLevel,
                  ),
                  BatteryCurvePage(
                    events: _eventBuffer,
                    batteryLevel: _batteryLevel,
                    onRequestSnapshot: _requestBatterySnapshot,
                  ),
                  SettingsPage(
                    batteryLevel: _batteryLevel,
                    onStartScan: _startScan,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
