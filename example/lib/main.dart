import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_battery/flutter_battery.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  int _batteryLevel = -1;
  final _flutterBatteryPlugin = FlutterBattery();
  
  // 创建一个全局的ScaffoldMessengerKey
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  final TextEditingController _titleController = TextEditingController(text: '测试通知');
  final TextEditingController _messageController = TextEditingController(text: '这是一条测试通知消息');
  final TextEditingController _delayController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    int batteryLevel = -1;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _flutterBatteryPlugin.getPlatformVersion() ?? 'Unknown platform version';
      batteryLevel = await _flutterBatteryPlugin.getBatteryLevel() ?? -1;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _batteryLevel = batteryLevel;
    });
  }
  
  // 显示消息的辅助方法
  void _showMessage(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  // 显示立即通知
  Future<void> _showNotification() async {
    try {
      await _flutterBatteryPlugin.showNotification(
        title: _titleController.text,
        message: _messageController.text,
      );
      
      // 显示成功反馈
      if (!mounted) return;
      _showMessage('通知已发送');
    } catch (e) {
      // 显示错误信息
      if (!mounted) return;
      _showMessage('通知发送失败: $e');
    }
  }
  
  // 调度延迟通知
  Future<void> _scheduleNotification() async {
    try {
      int delay = int.tryParse(_delayController.text) ?? 1;
      
      await _flutterBatteryPlugin.scheduleNotification(
        title: _titleController.text,
        message: _messageController.text,
        delayMinutes: delay,
      );
      
      // 显示成功反馈
      if (!mounted) return;
      _showMessage('通知已调度，将在 $delay 分钟后发送');
    } catch (e) {
      // 显示错误信息
      if (!mounted) return;
      _showMessage('通知调度失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey, // 设置ScaffoldMessenger的Key
      title: 'Flutter Battery Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Battery Plugin'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('运行平台: $_platformVersion\n'),
              Text('电池电量: $_batteryLevel%\n'),
              const SizedBox(height: 20),
              
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '通知标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: '通知内容',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: _delayController,
                decoration: const InputDecoration(
                  labelText: '延迟分钟数',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () async {
                  try {
                    final batteryLevel = await _flutterBatteryPlugin.getBatteryLevel() ?? -1;
                    setState(() {
                      _batteryLevel = batteryLevel;
                    });
                    if (!mounted) return;
                    _showMessage('电池电量已更新');
                  } catch (e) {
                    if (!mounted) return;
                    _showMessage('获取电池电量失败: $e');
                  }
                },
                child: const Text('刷新电池电量'),
              ),
              const SizedBox(height: 12),
              
              ElevatedButton(
                onPressed: _showNotification,
                child: const Text('立即发送通知'),
              ),
              const SizedBox(height: 12),
              
              ElevatedButton(
                onPressed: _scheduleNotification,
                child: const Text('调度延迟通知'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
