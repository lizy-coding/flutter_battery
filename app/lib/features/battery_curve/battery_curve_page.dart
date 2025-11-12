import 'package:flutter/material.dart';

import '../../core/models/native_event.dart';

class BatteryCurvePage extends StatelessWidget {
  const BatteryCurvePage({
    super.key,
    required this.events,
    required this.batteryLevel,
    required this.onRequestSnapshot,
  });

  final List<NativeEvent> events;
  final int? batteryLevel;
  final Future<void> Function({String? deviceId}) onRequestSnapshot;

  @override
  Widget build(BuildContext context) {
    final batteryEvents = events
        .where((event) => event.type == NativeEventType.battery)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('当前电量: ${batteryLevel?.toString() ?? '--'}%'),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () => onRequestSnapshot(deviceId: batteryEvents.firstOrNull?.deviceId),
                child: const Text('请求快照'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: batteryEvents.isEmpty
                ? const Center(child: Text('等待电量曲线数据'))
                : ListView.builder(
                    itemCount: batteryEvents.length,
                    itemBuilder: (context, index) {
                      final event = batteryEvents[index];
                      return ListTile(
                        leading: Icon(Icons.battery_charging_full,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text('${event.data['level'] ?? '--'}%'),
                        subtitle: Text(event.timestamp.toIso8601String()),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
