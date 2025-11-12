import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';

import '../../core/native_bridge.dart';
import '../../shared/widgets/gauge.dart';
import '../../shared/widgets/line_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.bridge});

  final NativeBridge bridge;
  static final FlutterBattery _battery = FlutterBattery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GaugePlaceholder(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<BatteryInfo>(
                  stream: _battery.batteryInfoStream,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final level = info?.level ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Battery', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Center(
                          child: BatteryAnimation(
                            batteryLevel: level.clamp(0, 100),
                            width: 120,
                            height: 200,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Telemetry', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<Map<String, dynamic>>(
                          stream: bridge.telemetryStream,
                          builder: (context, snapshot) {
                            final telemetry = snapshot.data;
                            if (telemetry == null || telemetry.isEmpty) {
                              return const Center(child: Text('Waiting for telemetry...'));
                            }
                            return ListView(
                              children: telemetry.entries
                                  .map(
                                    (entry) => ListTile(
                                      dense: true,
                                      title: Text(entry.key),
                                      trailing: Text(entry.value.toString()),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Expanded(
                        child: LineChartPlaceholder(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: bridge.startSync,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Sync'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: bridge.stopSync,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stop Sync'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
