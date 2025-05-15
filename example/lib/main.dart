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
  bool _monitoringActive = false;
  bool _batteryListeningActive = false;
  final _flutterBatteryPlugin = FlutterBattery();
  
  // 创建一个全局的ScaffoldMessengerKey
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  
  final TextEditingController _titleController = TextEditingController(text: '测试通知');
  final TextEditingController _messageController = TextEditingController(text: '这是一条测试通知消息');
  final TextEditingController _delayController = TextEditingController(text: '1');
  
  // 电池监控相关控制器
  final TextEditingController _thresholdController = TextEditingController(text: '30');
  final TextEditingController _batteryTitleController = TextEditingController(text: '电量不足提醒');
  final TextEditingController _batteryMessageController = TextEditingController(text: '您的电池电量已经低于阈值，请及时充电');
  final TextEditingController _intervalController = TextEditingController(text: '1');
  bool _useFlutterRendering = true;
  
  // 电池电量历史记录
  final List<BatteryRecord> _batteryHistory = [];

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
    _thresholdController.dispose();
    _batteryTitleController.dispose();
    _batteryMessageController.dispose();
    _intervalController.dispose();
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
  
  // 开始电池电量变化监听
  Future<void> _startBatteryLevelListening() async {
    try {
      // 设置电池电量变化回调
      _flutterBatteryPlugin.setBatteryLevelChangeListener((batteryLevel) {
        if (!mounted) return;
        
        setState(() {
          _batteryLevel = batteryLevel;
          _batteryHistory.add(BatteryRecord(
            level: batteryLevel,
            timestamp: DateTime.now(),
          ));
          
          // 只保留最近的10条记录
          if (_batteryHistory.length > 10) {
            _batteryHistory.removeAt(0);
          }
        });
        
        _showMessage('电池电量变化: $batteryLevel%');
      });
      
      // 开始监听
      await _flutterBatteryPlugin.startBatteryLevelListening();
      
      setState(() {
        _batteryListeningActive = true;
      });
      
      _showMessage('已开启电池电量变化监听');
    } catch (e) {
      _showMessage('开启电池电量变化监听失败: $e');
    }
  }
  
  // 停止电池电量变化监听
  Future<void> _stopBatteryLevelListening() async {
    try {
      await _flutterBatteryPlugin.stopBatteryLevelListening();
      
      setState(() {
        _batteryListeningActive = false;
      });
      
      _showMessage('已停止电池电量变化监听');
    } catch (e) {
      _showMessage('停止电池电量变化监听失败: $e');
    }
  }
  
  // 开始电池监控
  Future<void> _startBatteryMonitoring() async {
    try {
      // 获取输入数据
      final int threshold = int.tryParse(_thresholdController.text) ?? 20;
      final String title = _batteryTitleController.text;
      final String message = _batteryMessageController.text;
      final int interval = int.tryParse(_intervalController.text) ?? 1;
      
      await _flutterBatteryPlugin.setBatteryLevelThreshold(
        threshold: threshold,
        title: title,
        message: message,
        intervalMinutes: interval,
        useFlutterRendering: _useFlutterRendering,
        onLowBattery: _useFlutterRendering ? (int batteryLevel) {
          // 自定义显示低电量UI
          if (!mounted) return;
          
          // 显示新的低电量警告对话框
          showDialog(
            context: _scaffoldMessengerKey.currentState!.context,
            builder: (context) => LowBatteryDialog(
              batteryLevel: batteryLevel,
              onDismiss: () {
                _showMessage('用户已关闭低电量警告');
              },
            ),
          );
        } : null,
      );
      
      setState(() {
        _monitoringActive = true;
      });
      
      _showMessage('已开启电池监控，阈值: $threshold%');
    } catch (e) {
      _showMessage('设置电池监控失败: $e');
    }
  }
  
  // 停止电池监控
  Future<void> _stopBatteryMonitoring() async {
    try {
      await _flutterBatteryPlugin.stopBatteryMonitoring();
      
      setState(() {
        _monitoringActive = false;
      });
      
      _showMessage('已停止电池监控');
    } catch (e) {
      _showMessage('停止电池监控失败: $e');
    }
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
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 平台信息和电池电量
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('运行平台: $_platformVersion'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('当前电量: $_batteryLevel%'),
                            const SizedBox(width: 8),
                            BatteryAnimation(
                              batteryLevel: _batteryLevel,
                              width: 50,
                              height: 25,
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: initPlatformState,
                              child: const Text('刷新'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 电池电量变化监听
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('电池电量变化监听', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _batteryListeningActive ? null : _startBatteryLevelListening,
                                child: const Text('开始监听'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _batteryListeningActive ? _stopBatteryLevelListening : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red.shade700,
                                ),
                                child: const Text('停止监听'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_batteryHistory.isNotEmpty) ...[
                          const Text('电量历史记录:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: _batteryHistory.length,
                              itemBuilder: (context, index) {
                                final record = _batteryHistory[_batteryHistory.length - 1 - index];
                                return ListTile(
                                  dense: true,
                                  title: Text('电量: ${record.level}%'),
                                  subtitle: Text('时间: ${_formatDateTime(record.timestamp)}'),
                                  leading: Icon(
                                    Icons.battery_std,
                                    color: _getBatteryColor(record.level),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 电池监控设置
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('电池监控', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _thresholdController,
                          decoration: const InputDecoration(
                            labelText: '电量阈值 (%)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _batteryTitleController,
                          decoration: const InputDecoration(
                            labelText: '通知标题',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_useFlutterRendering,
                        ),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _batteryMessageController,
                          decoration: const InputDecoration(
                            labelText: '通知内容',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_useFlutterRendering,
                        ),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _intervalController,
                          decoration: const InputDecoration(
                            labelText: '检查间隔(分钟)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        
                        SwitchListTile(
                          title: const Text('使用Flutter自定义渲染'),
                          subtitle: const Text('开启后将使用Flutter UI显示低电量提醒'),
                          value: _useFlutterRendering,
                          onChanged: (value) {
                            setState(() {
                              _useFlutterRendering = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _monitoringActive ? null : _startBatteryMonitoring,
                                child: const Text('开始监控'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _monitoringActive ? _stopBatteryMonitoring : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _monitoringActive ? Colors.red[100] : null,
                                ),
                                child: const Text('停止监控'),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_monitoringActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('监控已激活 - 阈值: ${_thresholdController.text}%'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                
                // 通知部分
                Text('推送通知', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                
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
      ),
    );
  }
  
  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
  
  // 根据电量获取颜色
  Color _getBatteryColor(int level) {
    if (level <= 20) {
      return Colors.red;
    } else if (level <= 50) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

// 电池记录数据类
class BatteryRecord {
  final int level;
  final DateTime timestamp;
  
  BatteryRecord({required this.level, required this.timestamp});
}

// 低电量警告对话框
class LowBatteryDialog extends StatelessWidget {
  final int batteryLevel;
  final VoidCallback onDismiss;
  
  const LowBatteryDialog({
    super.key,
    required this.batteryLevel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('电池电量低'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BatteryAnimation(
            batteryLevel: batteryLevel,
            width: 100,
            height: 50,
            showPercentage: true,
            warningLevel: batteryLevel + 5, // 确保显示为低电量状态
          ),
          const SizedBox(height: 16),
          Text('您的电池电量已经降至 $batteryLevel%，请及时充电！'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss();
          },
          child: const Text('我知道了'),
        ),
      ],
    );
  }
}
