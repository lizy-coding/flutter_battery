import 'package:flutter/material.dart';

import '../../core/models/native_event.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.events,
    required this.batteryLevel,
  });

  final List<NativeEvent> events;
  final int? batteryLevel;

  @override
  Widget build(BuildContext context) {
    final telemetryCount = events.where((e) => e.type == NativeEventType.telemetry).length;
    final connectionCount = events.where((e) => e.type == NativeEventType.connection).length;
    final lastTelemetry = events.lastWhere(
      (e) => e.type == NativeEventType.telemetry,
      orElse: () => const NativeEvent(type: NativeEventType.unknown, timestamp: DateTime.fromMillisecondsSinceEpoch(0)),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(title: '当前电量', value: batteryLevel != null ? '$batteryLevel%' : '--'),
              _StatCard(title: 'Telemetry 事件', value: telemetryCount.toString()),
              _StatCard(title: '连接事件', value: connectionCount.toString()),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最新 Telemetry', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (lastTelemetry.type == NativeEventType.unknown)
                      const Text('暂无 Telemetry 数据')
                    else
                      Expanded(
                        child: ListView(
                          children: lastTelemetry.data.entries
                              .map((entry) => ListTile(
                                    dense: true,
                                    title: Text(entry.key),
                                    trailing: Text(entry.value.toString()),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}
