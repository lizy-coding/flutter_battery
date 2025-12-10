import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';

/// Detail view with live level/temperature/voltage/health readings.
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
