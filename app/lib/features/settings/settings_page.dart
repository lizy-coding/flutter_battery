import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.batteryLevel,
    required this.onStartScan,
  });

  final int? batteryLevel;
  final Future<void> Function() onStartScan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('电池状态'),
          subtitle: Text(
            batteryLevel != null ? '当前电量 $batteryLevel%' : '尚未获取电量',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onStartScan,
          ),
        ),
        const Divider(),
        SwitchListTile.adaptive(
          value: true,
          onChanged: null,
          title: const Text('Telemetry 前台 Service'),
          subtitle: const Text('保持 IoT 设备持续同步'),
        ),
        SwitchListTile.adaptive(
          value: true,
          onChanged: null,
          title: const Text('Bluetooth 扫描'),
          subtitle: const Text('启用 BLE 扫描以发现新的 IoT 设备'),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('系统信息'),
          subtitle: const Text('Flutter + Kotlin 混生工程骨架'),
        ),
      ],
    );
  }
}
