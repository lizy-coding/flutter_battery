import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_bluetooth.dart';
import 'package:flutter_battery/peer_battery_service.dart';

const String _peerServiceUuid = '0000ABCD-0000-1000-8000-00805F9B34FB';

class MasterPage extends StatefulWidget {
  const MasterPage({required this.service, super.key});

  final PeerBatteryService service;

  @override
  State<MasterPage> createState() => _MasterPageState();
}

class _MasterPageState extends State<MasterPage> {
  final FlutterBluetooth _bluetooth = FlutterBluetooth.instance;
  StreamSubscription<PeerBatteryState>? _peerSub;
  StreamSubscription<List<BleDevice>>? _scanSub;
  PeerBatteryState? _state;
  List<BleDevice> _devices = const [];

  @override
  void initState() {
    super.initState();
    _startMasterFlow();
  }

  Future<void> _startMasterFlow() async {
    await widget.service.startAsMaster();
    _peerSub = widget.service.peerBatteryStream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
    _scanSub = _bluetooth.scanDevices(serviceUuid: _peerServiceUuid).listen((devices) {
      if (!mounted) return;
      final merged = <String, BleDevice>{for (final d in _devices) d.id: d};
      for (final device in devices) {
        merged[device.id] = device;
      }
      setState(() => _devices = merged.values.toList());
    });
  }

  Future<void> _connectTo(BleDevice device) async {
    await widget.service.masterConnectToDevice(device.id);
  }

  Future<void> _refreshScan() async {
    await _bluetooth.stopScan();
    await _bluetooth.startScan(serviceUuid: _peerServiceUuid);
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    _scanSub?.cancel();
    _bluetooth.stopScan();
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
      appBar: AppBar(
        title: const Text('Master：读取从机电量'),
        actions: [
          IconButton(
            onPressed: _refreshScan,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新扫描',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.battery_std_outlined),
              title: Text('本机电量（Master）：${localBattery >= 0 ? '$localBattery%' : '--'}'),
              subtitle: Text(
                '对方电量（Slave）：${remoteBattery != null ? '$remoteBattery%' : '--'}',
              ),
              trailing: connected
                  ? const Chip(
                      label: Text('已连接'),
                      avatar: Icon(Icons.check, size: 16),
                    )
                  : const Chip(
                      label: Text('未连接'),
                      avatar: Icon(Icons.link_off, size: 16),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '扫描到的从机列表（包含 Service UUID $_peerServiceUuid）：',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (_devices.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.search_off),
                title: const Text('暂无从机'),
                subtitle: const Text('请确保对端处于广播状态'),
                trailing: IconButton(
                  onPressed: _refreshScan,
                  icon: const Icon(Icons.refresh),
                  tooltip: '重新扫描',
                ),
              ),
            )
          else
            ..._devices.map(
              (device) => Card(
                child: ListTile(
                  leading: const Icon(Icons.bluetooth_searching),
                  title: Text(device.name.isNotEmpty ? device.name : '未知设备'),
                  subtitle: Text('${device.id} • RSSI ${device.rssi}'),
                  trailing: ElevatedButton(
                    onPressed: () => _connectTo(device),
                    child: const Text('连接'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
