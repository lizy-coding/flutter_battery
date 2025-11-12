import 'package:flutter/material.dart';

import '../../core/native_bridge.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.bridge});

  final NativeBridge bridge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notification Preferences'),
            subtitle: const Text('Configure alerts and telemetry notifications'),
            onTap: () {},
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.battery_saver_outlined),
            title: const Text('Battery Threshold'),
            subtitle: const Text('Set warning levels for low battery'),
            onTap: () {},
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.sync_alt_outlined),
            title: const Text('Sync Settings'),
            subtitle: const Text('Manage background sync behaviour'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync settings coming soon.')),
              );
            },
          ),
          const Divider(height: 0),
          SwitchListTile.adaptive(
            value: true,
            onChanged: (_) {},
            title: const Text('Foreground service pin'),
            subtitle: const Text('Keep telemetry active in the foreground'),
          ),
          SwitchListTile.adaptive(
            value: false,
            onChanged: (_) {},
            title: const Text('Diagnostics logging'),
            subtitle: const Text('Capture additional BLE traces when debugging'),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
