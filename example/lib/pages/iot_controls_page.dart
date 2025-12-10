import 'package:flutter/material.dart';

/// Basic MethodChannel controls used to smoke-test non-battery native bridge calls.
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
