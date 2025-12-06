import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _bootstrapBattery();
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

  void _openBatteryDetails(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BatteryDetailsPage(
        levelListenable: _levelListenable,
        infoListenable: _infoListenable,
        healthListenable: _healthListenable,
        onRefresh: _refresh,
      ),
    ));
  }

  void _openIotControls(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => IotControlsPage(
        startScan: _startScan,
        stopScan: _stopScan,
        connect: _connect,
        disconnect: _disconnect,
        startSync: _startSync,
        stopSync: _stopSync,
      ),
    ));
  }

  void _openEventLog(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EventStreamPage(eventsListenable: _iotEventsListenable),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final level = _batteryLevel ?? _batteryInfo?.level ?? 0;
    return MaterialApp(
      home: DashboardPage(
        batteryLevel: level,
        batteryInfo: _batteryInfo,
        batteryHealth: _batteryHealth,
        eventCount: _iotEvents.length,
        onRefresh: _refresh,
        onOpenBatteryDetails: () => _openBatteryDetails(context),
        onOpenIotControls: () => _openIotControls(context),
        onOpenEventLog: () => _openEventLog(context),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.batteryLevel,
    required this.batteryInfo,
    required this.batteryHealth,
    required this.eventCount,
    required this.onRefresh,
    required this.onOpenBatteryDetails,
    required this.onOpenIotControls,
    required this.onOpenEventLog,
    super.key,
  });

  final int batteryLevel;
  final BatteryInfo? batteryInfo;
  final BatteryHealth? batteryHealth;
  final int eventCount;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenBatteryDetails;
  final VoidCallback onOpenIotControls;
  final VoidCallback onOpenEventLog;

  @override
  Widget build(BuildContext context) {
    final isCharging = batteryInfo?.isCharging ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_battery overview'),
        actions: [
          IconButton(
            onPressed: onRefresh,
            tooltip: 'Refresh battery info',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BatteryGaugeCard(
                    batteryLevel: batteryLevel,
                    batteryInfo: batteryInfo,
                    batteryHealth: batteryHealth,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        icon: isCharging ? Icons.bolt : Icons.bolt_outlined,
                        label: isCharging ? 'Charging' : 'Idle',
                      ),
                      _MetricChip(
                        icon: Icons.thermostat_auto_outlined,
                        label: batteryInfo != null
                            ? '${batteryInfo!.temperature.toStringAsFixed(1)}°C'
                            : '-- °C',
                      ),
                      _MetricChip(
                        icon: Icons.speed_outlined,
                        label: batteryInfo != null
                            ? '${batteryInfo!.voltage.toStringAsFixed(2)}V'
                            : '-- V',
                      ),
                      _MetricChip(
                        icon: Icons.shield_outlined,
                        label: batteryHealth?.riskLevel ?? 'Health unknown',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.battery_std_outlined),
                  title: const Text('Battery details'),
                  subtitle: const Text('Level, state, health, temperature, and manual refresh'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenBatteryDetails,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.memory_outlined),
                  title: const Text('IoT native controls'),
                  subtitle: const Text('Scan, connect, and sync via MethodChannel'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenIotControls,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_note_outlined),
                  title: const Text('Event stream log'),
                  subtitle: Text('$eventCount recent entries from iot/stream'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenEventLog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BatteryGaugeCard extends StatelessWidget {
  const BatteryGaugeCard({
    required this.batteryLevel,
    required this.batteryInfo,
    required this.batteryHealth,
    super.key,
  });

  final int batteryLevel;
  final BatteryInfo? batteryInfo;
  final BatteryHealth? batteryHealth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Battery overview',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: CustomPaint(
            painter: _BatteryGaugePainter(
              level: batteryLevel,
              info: batteryInfo,
              health: batteryHealth,
              colorScheme: theme.colorScheme,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }
}

class _BatteryGaugePainter extends CustomPainter {
  _BatteryGaugePainter({
    required this.level,
    required this.info,
    required this.health,
    required this.colorScheme,
  });

  final int level;
  final BatteryInfo? info;
  final BatteryHealth? health;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 12;
    _drawRing(
      canvas,
      center,
      baseRadius,
      16,
      level.clamp(0, 100) / 100,
      colorScheme.primary,
      label: 'Level',
      value: '$level%',
    );

    final tempValue = info?.temperature ?? 0;
    final tempRatio = (tempValue / 60).clamp(0.0, 1.0);
    _drawRing(
      canvas,
      center,
      baseRadius - 30,
      12,
      tempRatio,
      Colors.orangeAccent,
      label: 'Temp',
      value: info != null ? '${tempValue.toStringAsFixed(1)}°C' : '--',
    );

    final voltage = info?.voltage ?? 0;
    final voltageRatio = ((voltage - 3.0) / 1.4).clamp(0.0, 1.0);
    _drawRing(
      canvas,
      center,
      baseRadius - 60,
      10,
      voltageRatio,
      Colors.blueAccent,
      label: 'Volt',
      value: info != null ? '${voltage.toStringAsFixed(2)}V' : '--',
    );

    _drawCenterLabels(canvas, center);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double thickness,
    double ratio,
    Color color, {
    required String label,
    required String value,
  }) {
    final basePaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi * 3 / 4;
    const sweep = math.pi * 3 / 2;
    canvas.drawArc(rect, startAngle, sweep, false, basePaint);
    canvas.drawArc(rect, startAngle, sweep * ratio, false, arcPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 1.5);
    final valuePainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 1.5);
    final offsetY = center.dy + radius - thickness / 2 - 10;
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, offsetY - textPainter.height - 2),
    );
    valuePainter.paint(
      canvas,
      Offset(center.dx - valuePainter.width / 2, offsetY),
    );
  }

  void _drawCenterLabels(Canvas canvas, Offset center) {
    final state = info?.state.name ?? 'unknown';
    final charging = info?.isCharging == true ? 'Charging' : 'Idle';
    final healthLabel = health?.statusLabel ?? 'Health n/a';
    final healthColor = _healthColor(health?.riskLevel ?? '');

    final levelPainter = TextPainter(
      text: TextSpan(
        text: '$level%',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 200);

    final statePainter = TextPainter(
      text: TextSpan(
        text: '$state • $charging',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 240);

    final healthPainter = TextPainter(
      text: TextSpan(
        text: healthLabel,
        style: TextStyle(color: healthColor, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 240);

    final startY = center.dy - (levelPainter.height + statePainter.height + healthPainter.height + 8) / 2;
    levelPainter.paint(canvas, Offset(center.dx - levelPainter.width / 2, startY));
    statePainter.paint(
      canvas,
      Offset(center.dx - statePainter.width / 2, startY + levelPainter.height + 4),
    );
    healthPainter.paint(
      canvas,
      Offset(center.dx - healthPainter.width / 2, startY + levelPainter.height + statePainter.height + 8),
    );
  }

  Color _healthColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'LOW':
        return Colors.green;
      case 'MEDIUM':
        return Colors.orange;
      case 'HIGH':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  bool shouldRepaint(covariant _BatteryGaugePainter oldDelegate) {
    return level != oldDelegate.level ||
        info != oldDelegate.info ||
        health != oldDelegate.health ||
        colorScheme != oldDelegate.colorScheme;
  }
}

class BatteryDetailsPage extends StatelessWidget {
  const BatteryDetailsPage({
    required this.levelListenable,
    required this.infoListenable,
    required this.healthListenable,
    required this.onRefresh,
    super.key,
  });

  final ValueListenable<int?> levelListenable;
  final ValueListenable<BatteryInfo?> infoListenable;
  final ValueListenable<BatteryHealth?> healthListenable;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery details'),
        actions: [
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([levelListenable, infoListenable, healthListenable]),
        builder: (context, _) {
          final level = levelListenable.value ?? infoListenable.value?.level ?? 0;
          final info = infoListenable.value;
          final health = healthListenable.value;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: BatteryAnimation(
                  batteryLevel: level,
                  width: 140,
                  height: 240,
                  isCharging: info?.isCharging ?? false,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.bolt_outlined),
                      title: const Text('Level'),
                      subtitle: Text('$level%'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.thermostat_auto_outlined),
                      title: const Text('Temperature'),
                      subtitle: Text(info != null ? '${info.temperature.toStringAsFixed(1)}°C' : '--'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.speed_outlined),
                      title: const Text('Voltage'),
                      subtitle: Text(info != null ? '${info.voltage.toStringAsFixed(2)}V' : '--'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.electric_bike_outlined),
                      title: const Text('State'),
                      subtitle: Text(info?.state.name ?? 'unknown'),
                      trailing: Text(info?.isCharging == true ? 'Charging' : 'Idle'),
                    ),
                  ],
                ),
              ),
              if (health != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.health_and_safety_outlined),
                        title: Text('Health ${health.riskLevel}'),
                        subtitle: Text(health.statusLabel),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recommendations',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            ...health.recommendations
                                .map((tip) => Text('• $tip', style: Theme.of(context).textTheme.bodySmall))
                                .toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class IotControlsPage extends StatelessWidget {
  const IotControlsPage({
    required this.startScan,
    required this.stopScan,
    required this.connect,
    required this.disconnect,
    required this.startSync,
    required this.stopSync,
    super.key,
  });

  final Future<void> Function() startScan;
  final Future<void> Function() stopScan;
  final Future<void> Function() connect;
  final Future<void> Function() disconnect;
  final Future<void> Function() startSync;
  final Future<void> Function() stopSync;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IoT native controls')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MethodChannel: iot/native',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(onPressed: startScan, icon: const Icon(Icons.search), label: const Text('Scan')),
                ElevatedButton.icon(onPressed: stopScan, icon: const Icon(Icons.close), label: const Text('Stop Scan')),
                ElevatedButton.icon(onPressed: connect, icon: const Icon(Icons.usb), label: const Text('Connect')),
                ElevatedButton.icon(onPressed: disconnect, icon: const Icon(Icons.link_off), label: const Text('Disconnect')),
                ElevatedButton.icon(onPressed: startSync, icon: const Icon(Icons.cloud_upload_outlined), label: const Text('Start Sync')),
                ElevatedButton.icon(onPressed: stopSync, icon: const Icon(Icons.cloud_off_outlined), label: const Text('Stop Sync')),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Use these controls to validate native bridge calls. Check the Event Stream log for results.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class EventStreamPage extends StatelessWidget {
  const EventStreamPage({required this.eventsListenable, super.key});

  final ValueListenable<List<String>> eventsListenable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event stream log')),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: eventsListenable,
        builder: (context, events, _) {
          if (events.isEmpty) {
            return const Center(child: Text('No events yet. Trigger IoT actions to populate the stream.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.bubble_chart_outlined),
              title: Text(events[index]),
            ),
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemCount: events.length,
          );
        },
      ),
    );
  }
}
