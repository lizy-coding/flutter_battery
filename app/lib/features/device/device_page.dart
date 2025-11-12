import 'package:flutter/material.dart';

import '../../core/models/native_event.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({
    super.key,
    required this.events,
    required this.onScan,
    required this.onConnect,
    required this.onTelemetryToggle,
  });

  final List<NativeEvent> events;
  final Future<void> Function() onScan;
  final Future<void> Function(String deviceId) onConnect;
  final Future<void> Function(String deviceId, bool enable) onTelemetryToggle;

  List<NativeEvent> get _devices {
    final list = events
        .where((event) => event.type == NativeEventType.discovery)
        .toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final deviceEvents = _devices.toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('扫描设备'),
              ),
              const SizedBox(width: 12),
              Text('已发现 ${deviceEvents.length} 台设备'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: deviceEvents.isEmpty
                ? const Center(child: Text('尚未发现 BLE 设备'))
                : ListView.builder(
                    itemCount: deviceEvents.length,
                    itemBuilder: (context, index) {
                      final event = deviceEvents[index];
                      final deviceMeta = event.data;
                      final deviceId = event.deviceId ?? deviceMeta['id']?.toString() ?? 'unknown';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(deviceMeta['name']?.toString() ?? '未命名设备',
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text('ID: $deviceId • RSSI: ${deviceMeta['rssi'] ?? '--'} dBm'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                children: [
                                  FilledButton(
                                    onPressed: () => onConnect(deviceId),
                                    child: const Text('连接'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => onTelemetryToggle(deviceId, true),
                                    child: const Text('开启 Telemetry'),
                                  ),
                                  TextButton(
                                    onPressed: () => onTelemetryToggle(deviceId, false),
                                    child: const Text('停止 Telemetry'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
