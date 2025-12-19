import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_battery/flutter_battery.dart';

import 'pages/battery_details_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/event_stream_page.dart';
import 'pages/iot_controls_page.dart';
import 'pages/low_battery_notification_page.dart';
import 'perflab/perflab_channel.dart';
import 'role_selection_page.dart';
import 'routes.dart';
import 'startup_trace.dart';

void main() {
  StartupTrace.start();
  WidgetsFlutterBinding.ensureInitialized();
  PerfLabChannel.logMarker('flutter_main_t0');
  StartupTrace.markRunApp();
  PerfLabChannel.logMarker('flutter_runApp');
  runApp(const FlutterBatteryExampleApp());
}

// Entry point for the demo app: wires battery monitoring, IoT stubs, and sample pages.
class FlutterBatteryExampleApp extends StatefulWidget {
  const FlutterBatteryExampleApp({super.key});

  @override
  State<FlutterBatteryExampleApp> createState() => _FlutterBatteryExampleAppState();
}

class _FlutterBatteryExampleAppState extends State<FlutterBatteryExampleApp> {
  final FlutterBattery _plugin = FlutterBattery();
  final ValueNotifier<int?> _levelListenable = ValueNotifier<int?>(null);
  final ValueNotifier<BatteryInfo?> _infoListenable = ValueNotifier<BatteryInfo?>(null);
  final ValueNotifier<BatteryHealth?> _healthListenable = ValueNotifier<BatteryHealth?>(null);
  final ValueNotifier<List<String>> _iotEventsListenable = ValueNotifier<List<String>>(<String>[]);

  int? _batteryLevel;
  BatteryInfo? _batteryInfo;
  BatteryHealth? _batteryHealth;

  static const MethodChannel _iotMethod = MethodChannel('iot/native');
  static const EventChannel _iotEvent = EventChannel('iot/stream');
  StreamSubscription? _iotSub;
  List<String> _iotEvents = <String>[];

  @override
  void initState() {
    super.initState();
    _listenToIotEvents();
  }

  @override
  void dispose() {
    _iotSub?.cancel();
    _levelListenable.dispose();
    _infoListenable.dispose();
    _healthListenable.dispose();
    _iotEventsListenable.dispose();
    super.dispose();
  }

  // Configure the plugin callbacks and start native-side monitoring streams.
  void _bootstrapBattery() {
    _refresh();
    _plugin.configureBatteryCallbacks(
      onBatteryLevelChange: (level) {
        setState(() => _batteryLevel = level);
        _levelListenable.value = level;
      },
      onBatteryInfoChange: (info) {
        setState(() => _batteryInfo = info);
        _infoListenable.value = info;
      },
      onBatteryHealthChange: (health) {
        setState(() => _batteryHealth = health);
        _healthListenable.value = health;
      },
    );
    _plugin.configureBatteryMonitor(
      BatteryMonitorConfig(
        monitorBatteryLevel: true,
        monitorBatteryInfo: true,
        monitorBatteryHealth: true,
      ),
    );
  }

  // IoT section: demo EventChannel/MethodChannel usage unrelated to battery.
  void _listenToIotEvents() {
    _iotSub = _iotEvent.receiveBroadcastStream().listen((dynamic e) {
      _recordIotEvent('event', e);
    }, onError: (Object err) {
      _recordIotEvent('error', err);
    });
  }

  void _recordIotEvent(String kind, Object? payload) {
    final stamp = DateTime.now().toIso8601String().substring(11, 19);
    final entry = '$stamp $kind: $payload';
    setState(() {
      _iotEvents = <String>[entry, ..._iotEvents].take(50).toList();
      _iotEventsListenable.value = List<String>.from(_iotEvents);
    });
  }

  Future<void> _refresh() async {
    try {
      final level = await _plugin.getBatteryLevel();
      final info = await _plugin.getBatteryInfo();
      final health = await _plugin.getBatteryHealth();
      if (!mounted) return;
      setState(() {
        _batteryLevel = level;
        _batteryInfo = info;
        _batteryHealth = health;
      });
      _levelListenable.value = level;
      _infoListenable.value = info;
      _healthListenable.value = health;
    } catch (err) {
      debugPrint('Refresh failed: $err');
    }
  }

  Future<void> _startScan() => _iotMethod.invokeMethod<void>('scanDevices');
  Future<void> _stopScan() => _iotMethod.invokeMethod<void>('stopScan');
  Future<void> _connect() => _iotMethod.invokeMethod<void>('connect', {'deviceId': 'demo-001'});
  Future<void> _disconnect() => _iotMethod.invokeMethod<void>('disconnect');
  Future<void> _startSync() => _iotMethod.invokeMethod<void>('startSync');
  Future<void> _stopSync() => _iotMethod.invokeMethod<void>('stopSync');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: AppRoutes.dashboard,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.batteryDetails:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BatteryDetailsPage(
            levelListenable: _levelListenable,
            infoListenable: _infoListenable,
            healthListenable: _healthListenable,
            onRefresh: _refresh,
          ),
        );
      case AppRoutes.lowBattery:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LowBatteryNotificationPage(plugin: _plugin),
        );
      case AppRoutes.peerSelection:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RoleSelectionPage(),
        );
      case AppRoutes.iotControls:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IotControlsPage(
            startScan: _startScan,
            stopScan: _stopScan,
            connect: _connect,
            disconnect: _disconnect,
            startSync: _startSync,
            stopSync: _stopSync,
          ),
        );
      case AppRoutes.eventLog:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EventStreamPage(eventsListenable: _iotEventsListenable),
        );
      case AppRoutes.dashboard:
      default:
        final level = _batteryLevel ?? _batteryInfo?.level ?? 0;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DashboardPage(
            batteryLevel: level,
            batteryInfo: _batteryInfo,
            batteryHealth: _batteryHealth,
            eventCount: _iotEvents.length,
            onRefresh: _refresh,
            onBootstrap: _bootstrapBattery,
            onOpenBatteryDetails: () => _pushNamed(AppRoutes.batteryDetails),
            onOpenLowBatteryAlerts: () => _pushNamed(AppRoutes.lowBattery),
            onOpenPeerBatterySync: () => _pushNamed(AppRoutes.peerSelection),
            onOpenIotControls: () => _pushNamed(AppRoutes.iotControls),
            onOpenEventLog: () => _pushNamed(AppRoutes.eventLog),
          ),
        );
    }
  }

  void _pushNamed(String route) {
    Navigator.of(context).pushNamed(route);
  }
}
