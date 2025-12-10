import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';

/// Landing screen showing battery overview and entry points to feature demos.
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.batteryLevel,
    required this.batteryInfo,
    required this.batteryHealth,
    required this.eventCount,
    required this.onRefresh,
    required this.onOpenBatteryDetails,
    required this.onOpenLowBatteryAlerts,
    required this.onOpenPeerBatterySync,
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
  final VoidCallback onOpenLowBatteryAlerts;
  final VoidCallback onOpenPeerBatterySync;
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
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('低电量系统通知'),
                  subtitle: const Text('配置阈值订阅，触发原生通知或 Flutter 回调'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenLowBatteryAlerts,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.hub_outlined),
                  title: const Text('蓝牙电量同步'),
                  subtitle: const Text('选择主/从机后进行电量互通'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onOpenPeerBatterySync,
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

class BatteryGaugeCard extends StatefulWidget {
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
  State<BatteryGaugeCard> createState() => _BatteryGaugeCardState();
}

class _BatteryGaugeCardState extends State<BatteryGaugeCard> {
  double _previousLevel = 0;

  @override
  void initState() {
    super.initState();
    _previousLevel = widget.batteryLevel.toDouble();
  }

  @override
  void didUpdateWidget(covariant BatteryGaugeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batteryLevel != widget.batteryLevel) {
      _previousLevel = oldWidget.batteryLevel.toDouble();
    } else {
      _previousLevel = widget.batteryLevel.toDouble();
    }
  }

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
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(
              begin: _previousLevel,
              end: widget.batteryLevel.toDouble(),
            ),
            builder: (context, animatedLevel, _) {
              return CustomPaint(
                painter: _BatteryGaugePainter(
                  level: animatedLevel,
                  info: widget.batteryInfo,
                  health: widget.batteryHealth,
                  colorScheme: theme.colorScheme,
                ),
              );
            },
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

  final double level;
  final BatteryInfo? info;
  final BatteryHealth? health;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.max(56.0, (math.min(size.width, size.height) / 2 - 12));
    final middleRadius = math.max(40.0, baseRadius - 30);
    final innerRadius = math.max(32.0, baseRadius - 60);
    final levelRatio = _clamp01(level / 100);
    _drawRing(
      canvas,
      center,
      baseRadius,
      16,
      levelRatio,
      colorScheme.primary,
      label: 'Level',
      value: '${level.toStringAsFixed(0)}%',
    );

    final tempValue = info?.temperature;
    final tempRatio = _clamp01(tempValue != null ? tempValue / 60 : 0);
    _drawRing(
      canvas,
      center,
      middleRadius,
      12,
      tempRatio,
      Colors.orangeAccent,
      label: 'Temp',
      value: tempValue != null ? '${tempValue.toStringAsFixed(1)}°C' : '--',
    );

    final voltage = info?.voltage;
    final voltageRatio = _clamp01(voltage != null ? (voltage - 3.0) / 1.4 : 0);
    _drawRing(
      canvas,
      center,
      innerRadius,
      10,
      voltageRatio,
      Colors.blueAccent,
      label: 'Volt',
      value: info != null ? '${voltage?.toStringAsFixed(2)}V' : '--',
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
      ..color = color.withValues(alpha: 0.12)
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

  double _clamp01(num value) {
    final v = value.toDouble();
    if (v.isNaN || !v.isFinite) return 0;
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }

  void _drawCenterLabels(Canvas canvas, Offset center) {
    final state = info?.state.name ?? 'unknown';
    final charging = info?.isCharging == true ? 'Charging' : 'Idle';
    final healthLabel = health?.statusLabel ?? 'Health n/a';
    final healthColor = _healthColor(health?.riskLevel ?? '');

    final levelPainter = TextPainter(
      text: TextSpan(
        text: '${level.toStringAsFixed(0)}%',
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
