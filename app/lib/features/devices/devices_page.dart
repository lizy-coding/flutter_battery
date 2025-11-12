import 'package:flutter/material.dart';

import '../../core/native_bridge.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key, required this.bridge});

  final NativeBridge bridge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: bridge.startScan,
                  icon: const Icon(Icons.radar),
                  label: const Text('Scan'),
                ),
                OutlinedButton.icon(
                  onPressed: bridge.stopScan,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Scan'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: bridge.devicesStream,
                initialData: const <Map<String, dynamic>>[],
                builder: (context, snapshot) {
                  final devices = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (devices.isEmpty) {
                    return const Center(child: Text('No devices discovered yet.'));
                  }
                  return ListView.separated(
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final id = device['id']?.toString() ?? 'unknown';
                      final name = device['name']?.toString() ?? 'Unnamed device';
                      final rssi = device['rssi']?.toString() ?? '--';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(name),
                          subtitle: Text('ID: $id • RSSI: $rssi'),
                          onTap: () async {
                            await bridge.connect(id);
                            if (!context.mounted) return;
                            Navigator.of(context).pushNamed('/dashboard');
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
