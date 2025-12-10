import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_battery/peer_battery_service.dart';

class SlavePage extends StatefulWidget {
  const SlavePage({required this.service, super.key});

  final PeerBatteryService service;

  @override
  State<SlavePage> createState() => _SlavePageState();
}

class _SlavePageState extends State<SlavePage> {
  StreamSubscription<PeerBatteryState>? _peerSub;
  PeerBatteryState? _state;

  @override
  void initState() {
    super.initState();
    _startSlave();
  }

  Future<void> _startSlave() async {
    await widget.service.startAsSlave();
    _peerSub = widget.service.peerBatteryStream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    widget.service.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final localBattery = state?.localBattery ?? -1;
    final remoteBattery = state?.remoteBattery;
    final connected = state?.isConnected ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Slave：广播本机电量')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.sensors),
                title: Text('本机电量（Slave）：${localBattery >= 0 ? '$localBattery%' : '--'}'),
                subtitle: Text('主机电量（对方）：${remoteBattery != null ? '$remoteBattery%' : '--'}'),
                trailing: connected
                    ? const Chip(
                        label: Text('主机已连接'),
                        avatar: Icon(Icons.check_circle, size: 16),
                      )
                    : const Chip(
                        label: Text('等待连接'),
                        avatar: Icon(Icons.watch_later_outlined, size: 16),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '保持此页面打开，设备会以 GATT Server 方式广播包含电量特征值的 Service，'
              '主机连接后会看到更新。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
