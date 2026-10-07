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
import 'platform/example_platform_adapter.dart';
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

class FlutterBatteryExampleApp extends StatefulWidget {
  const FlutterBatteryExampleApp({super.key});

  @override
  State<FlutterBatteryExampleApp> createState() =>
      _FlutterBatteryExampleAppState();
}

class _FlutterBatteryExampleAppState extends State<FlutterBatteryExampleApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ExamplePlatformAdapter _platform = ExamplePlatformAdapter.current();
  final FlutterBattery _plugin = FlutterBattery();
  final ValueNotifier<int?> _levelListenable = ValueNotifier<int?>(null);
  final ValueNotifier<BatteryInfo?> _infoListenable =
      ValueNotifier<BatteryInfo?>(null);
  final ValueNotifier<BatteryHealth?> _healthListenable =
      ValueNotifier<BatteryHealth?>(null);
  final ValueNotifier<List<String>> _iotEventsListenable =
      ValueNotifier<List<String>>(<String>[]);

  int? _batteryLevel;
  BatteryInfo? _batteryInfo;
  BatteryHealth? _batteryHealth;

  StreamSubscription? _iotSub;
  List<String> _iotEvents = <String>[];

  BatteryPlatformCapabilities get _capabilities => _platform.capabilities;

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

  void _listenToIotEvents() {
    _iotSub = _platform.iotEvents.listen((dynamic e) {
      _recordIotEvent('event', e);
    }, onError: (Object err) {
      _recordIotEvent('error', err);
    });
  }

  void _recordIotEvent(String kind, Object? payload) {
    if (!mounted) return;
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

  Future<void> _startScan() => _invokeIotMethod('scanDevices');
  Future<void> _stopScan() => _invokeIotMethod('stopScan');
  Future<void> _connect() =>
      _invokeIotMethod('connect', {'deviceId': 'demo-001'});
  Future<void> _disconnect() => _invokeIotMethod('disconnect');
  Future<void> _startSync() => _invokeIotMethod('startSync');
  Future<void> _stopSync() => _invokeIotMethod('stopSync');

  Future<void> _invokeIotMethod(String method, [Object? arguments]) async {
    if (!_capabilities.isSupported(BatteryFeature.iotExampleBridge)) {
      _showUnsupportedFeatureMessage(BatteryFeature.iotExampleBridge);
      return;
    }
    try {
      await _platform.invokeIotMethod(method, arguments);
    } on MissingPluginException catch (err) {
      _recordIotEvent('error', err);
      _showUnsupportedFeatureMessage(BatteryFeature.iotExampleBridge);
    } on UnsupportedBatteryFeatureException catch (err) {
      _recordIotEvent('error', err);
      _showUnsupportedFeatureMessage(BatteryFeature.iotExampleBridge);
    } on PlatformException catch (err) {
      _recordIotEvent('error', err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
          builder: (_) => _capabilities.isSupported(BatteryFeature.blePeerSync)
              ? const RoleSelectionPage()
              : const _UnsupportedFeaturePage(
                  title: '蓝牙电量同步',
                  feature: BatteryFeature.blePeerSync,
                ),
        );
      case AppRoutes.iotControls:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              _capabilities.isSupported(BatteryFeature.iotExampleBridge)
                  ? IotControlsPage(
                      startScan: _startScan,
                      stopScan: _stopScan,
                      connect: _connect,
                      disconnect: _disconnect,
                      startSync: _startSync,
                      stopSync: _stopSync,
                    )
                  : const _UnsupportedFeaturePage(
                      title: 'IoT native controls',
                      feature: BatteryFeature.iotExampleBridge,
                    ),
        );
      case AppRoutes.eventLog:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              EventStreamPage(eventsListenable: _iotEventsListenable),
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
            capabilities: _capabilities,
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
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final feature = _featureForRoute(route);
    if (feature != null && !_capabilities.isSupported(feature)) {
      _showUnsupportedFeatureMessage(feature);
      return;
    }

    navigator.pushNamed(route);
  }

  BatteryFeature? _featureForRoute(String route) {
    switch (route) {
      case AppRoutes.peerSelection:
        return BatteryFeature.blePeerSync;
      case AppRoutes.iotControls:
        return BatteryFeature.iotExampleBridge;
      default:
        return null;
    }
  }

  void _showUnsupportedFeatureMessage(BatteryFeature feature) {
    final scaffoldMessenger = _navigatorKey.currentContext == null
        ? null
        : ScaffoldMessenger.maybeOf(_navigatorKey.currentContext!);
    scaffoldMessenger?.showSnackBar(
      SnackBar(content: Text('$feature is not supported on this platform.')),
    );
  }
}

class _UnsupportedFeaturePage extends StatelessWidget {
  const _UnsupportedFeaturePage({
    required this.title,
    required this.feature,
  });

  final String title;
  final BatteryFeature feature;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$feature is not supported on this platform.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
