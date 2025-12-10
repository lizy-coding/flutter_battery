import 'package:flutter/material.dart';
import 'package:flutter_battery/peer_battery_service.dart';

import 'master_page.dart';
import 'slave_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  static final PeerBatteryService _peerService = PeerBatteryService();

  void _openMaster(BuildContext context, PeerBatteryService service) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MasterPage(service: service),
    ));
  }

  void _openSlave(BuildContext context, PeerBatteryService service) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SlavePage(service: service),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择蓝牙角色')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '进入蓝牙电量同步前请选择主机或从机角色，整个流程只支持两台 Android 设备互通。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openMaster(context, _peerService),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('我是主机（Master）'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openSlave(context, _peerService),
                      icon: const Icon(Icons.sensors),
                      label: const Text('我是从机（Slave）'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Master 会扫描含指定 Service 的设备并主动连接；'
              'Slave 会广播自身电量并接收对方写入的主机电量。',
            ),
          ],
        ),
      ),
    );
  }
}
