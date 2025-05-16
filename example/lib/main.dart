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

  int _batteryPushInterval = 1;
  bool _enablePushDebounce = true;

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
      
      // 如果电池历史记录为空或最后一条记录与当前电量不同，添加一条记录
      if (_batteryHistory.isEmpty || _batteryHistory.last.level != batteryLevel) {
        setState(() {
          _batteryHistory.add(BatteryRecord(
            level: batteryLevel,
            timestamp: DateTime.now(),
          ));
          
          // 只保留最近的20条记录
          if (_batteryHistory.length > 20) {
            _batteryHistory.removeAt(0);
          }
        });
      }
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
      // 设置推送间隔
      await _flutterBatteryPlugin.setPushInterval(
        intervalMs: _batteryPushInterval * 1000, // 转换为毫秒
        enableDebounce: _enablePushDebounce,
      );
      
      // 设置电池电量变化回调
      _flutterBatteryPlugin.setBatteryLevelChangeListener((batteryLevel) {
        if (!mounted) return;
        
        setState(() {
          _batteryLevel = batteryLevel;
          final now = DateTime.now();
          
          // 如果最后一条记录的电量与新电量相同且时间间隔小于1秒，则不添加新记录
          if (_batteryHistory.isNotEmpty) {
            final lastRecord = _batteryHistory.last;
            final timeDiff = now.difference(lastRecord.timestamp).inSeconds;
            if (lastRecord.level == batteryLevel && timeDiff < 1) {
              return;
            }
          }
          
          _batteryHistory.add(BatteryRecord(
            level: batteryLevel,
            timestamp: now,
          ));
          
          // 只保留最近的20条记录
          if (_batteryHistory.length > 20) {
            _batteryHistory.removeAt(0);
          }
        });
        
        // 避免过多提示，只在启用防抖动时显示消息
        if (_enablePushDebounce) {
          _showMessage('电池电量变化: $batteryLevel%');
        }
      });
      
      // 开始监听
      await _flutterBatteryPlugin.startBatteryLevelListening();
      
      setState(() {
        _batteryListeningActive = true;
      });
      
      _showMessage('已开启电池电量变化监听，间隔: $_batteryPushInterval 秒');
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
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_android, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '运行平台: $_platformVersion',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '当前电量',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '$_batteryLevel%',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: _getBatteryColor(_batteryLevel),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      BatteryAnimation(
                                        batteryLevel: _batteryLevel,
                                        width: 40,
                                        height: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                initPlatformState();
                                _showMessage('电量数据已刷新');
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('刷新'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
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
                        // 添加推送间隔设置
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: _batteryListeningActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: Column(
                            children: [
                              Row(
                                children: [
                                  const Text('推送间隔: '),
                                  Expanded(
                                    child: Slider(
                                      value: _batteryPushInterval.toDouble(),
                                      min: 1.0,
                                      max: 10.0,
                                      divisions: 9,
                                      label: '${_batteryPushInterval}秒',
                                      onChanged: (value) {
                                        setState(() {
                                          _batteryPushInterval = value.round();
                                        });
                                      },
                                    ),
                                  ),
                                  Text('${_batteryPushInterval}秒'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 添加防抖动选项
                              SwitchListTile(
                                title: const Text('仅在电量变化时推送'),
                                subtitle: const Text('减少相同电量的重复推送'),
                                value: _enablePushDebounce,
                                onChanged: (value) {
                                  setState(() {
                                    _enablePushDebounce = value;
                                  });
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          secondChild: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monitor_heart, color: Colors.green),
                                const SizedBox(width: 8),
                                Text('电池监听已启用 - 推送间隔: $_batteryPushInterval秒${_enablePushDebounce ? " (仅在电量变化时)" : ""}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _batteryListeningActive ? _stopBatteryLevelListening : _startBatteryLevelListening,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _batteryListeningActive ? Colors.red.shade100 : null,
                                  foregroundColor: _batteryListeningActive ? Colors.red.shade700 : null,
                                ),
                                child: Text(_batteryListeningActive ? '停止监听' : '开始监听'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_batteryHistory.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('电量历史记录:', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _batteryHistory.clear();
                                  });
                                  _showMessage('历史记录已清空');
                                },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('清空'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _batteryHistory.isEmpty
                                ? const Center(child: Text('暂无数据'))
                                : ListView.builder(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('电池监控', style: Theme.of(context).textTheme.titleLarge),
                            if (_monitoringActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('监控中', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        AnimatedOpacity(
                          opacity: _monitoringActive ? 0.6 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            children: [
                              TextField(
                                controller: _thresholdController,
                                decoration: InputDecoration(
                                  labelText: '电量阈值 (%)',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.battery_alert),
                                  helperText: '电量低于此值时会触发提醒',
                                  enabled: !_monitoringActive,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              
                              TextField(
                                controller: _intervalController,
                                decoration: InputDecoration(
                                  labelText: '检查间隔(分钟)',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.timer),
                                  helperText: '电池监控检查的时间间隔',
                                  enabled: !_monitoringActive,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              
                              SwitchListTile(
                                title: const Text('使用Flutter自定义渲染'),
                                subtitle: const Text('开启后将使用Flutter UI显示低电量提醒'),
                                value: _useFlutterRendering,
                                onChanged: _monitoringActive ? null : (value) {
                                  setState(() {
                                    _useFlutterRendering = value;
                                  });
                                },
                                secondary: Icon(
                                  _useFlutterRendering ? Icons.phone_android : Icons.notifications,
                                  color: _useFlutterRendering ? Colors.blue : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                crossFadeState: _useFlutterRendering ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                firstChild: Column(
                                  children: [
                                    TextField(
                                      controller: _batteryTitleController,
                                      decoration: InputDecoration(
                                        labelText: '通知标题',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.title),
                                        enabled: !_monitoringActive && !_useFlutterRendering,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    TextField(
                                      controller: _batteryMessageController,
                                      decoration: InputDecoration(
                                        labelText: '通知内容',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.message),
                                        enabled: !_monitoringActive && !_useFlutterRendering,
                                      ),
                                    ),
                                  ],
                                ),
                                secondChild: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '使用Flutter渲染模式',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '将在电量低于阈值时使用Flutter UI显示自定义对话框，而不是系统通知。',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '阈值触发后会显示低电量对话框',
                                        style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _monitoringActive ? null : _startBatteryMonitoring,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('开始监控'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[50],
                          foregroundColor: Colors.green[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _monitoringActive ? _stopBatteryMonitoring : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('停止监控'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _monitoringActive ? Colors.red[100] : null,
                          foregroundColor: _monitoringActive ? Colors.red[700] : null,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_monitoringActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '电池监控已激活 - 电量低于${_thresholdController.text}%时将${_useFlutterRendering ? "显示对话框" : "发送通知"}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // 通知部分
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text('推送通知', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: '通知标题',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            labelText: '通知内容',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.message),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _delayController,
                          decoration: const InputDecoration(
                            labelText: '延迟分钟数',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                            helperText: '仅用于延迟通知',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showNotification,
                                icon: const Icon(Icons.send),
                                label: const Text('立即发送通知'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.blue[50],
                                  foregroundColor: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _scheduleNotification,
                                icon: const Icon(Icons.schedule),
                                label: const Text('调度延迟通知'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.purple[50],
                                  foregroundColor: Colors.purple[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 添加电池流监控卡片
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.battery_charging_full, color: Colors.teal[600]),
                            const SizedBox(width: 8),
                            Text('电池信息流', style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '实时监控电池电量变化并控制推送频率，可视化展示电池数据和充电状态变化。',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => const BatteryStreamPage())
                              );
                            },
                            icon: const Icon(Icons.show_chart),
                            label: const Text('打开电池流监控'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              backgroundColor: Colors.teal[50],
                              foregroundColor: Colors.teal[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[700], size: 28),
                const SizedBox(width: 10),
                const Text(
                  '电池电量低',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: BatteryAnimation(
                    batteryLevel: batteryLevel,
                    width: 70,
                    height: 130,
                    showPercentage: true,
                    warningLevel: batteryLevel + 5, // 确保显示为低电量状态
                    animationDuration: const Duration(milliseconds: 1500),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    '您的电池电量已降至 $batteryLevel%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请尽快给设备充电，避免设备自动关机导致数据丢失',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('我知道了'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BatteryStreamPage extends StatefulWidget {
  const BatteryStreamPage({Key? key}) : super(key: key);

  @override
  State<BatteryStreamPage> createState() => _BatteryStreamPageState();
}

class _BatteryStreamPageState extends State<BatteryStreamPage> {
  final _flutterBatteryPlugin = FlutterBattery();
  double _sliderValue = 1.0; // 默认推送间隔为1秒
  bool _enableDebounce = true; // 默认启用防抖动
  bool _isStreaming = false; // 是否正在监听流
  final List<Map<String, dynamic>> _batteryEvents = [];
  StreamSubscription? _streamSubscription;
  bool _isSetupCollapsed = false; // 控制设置区域是否折叠

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  // 开始或停止监听电池流
  void _toggleStreaming() {
    setState(() {
      if (_isStreaming) {
        _streamSubscription?.cancel();
        _streamSubscription = null;
        _isSetupCollapsed = false; // 停止监听时展开设置
      } else {
        // 设置推送间隔（毫秒）
        int intervalMs = (_sliderValue * 1000).round();
        _flutterBatteryPlugin.setPushInterval(
          intervalMs: intervalMs,
          enableDebounce: _enableDebounce,
        );

        // 订阅电池流
        _streamSubscription = _flutterBatteryPlugin.batteryStream.listen((event) {
          setState(() {
            // 限制事件列表长度，防止过长
            if (_batteryEvents.length > 50) {
              _batteryEvents.removeAt(0);
            }
            _batteryEvents.add(event);
          });
        });
        
        _isSetupCollapsed = true; // 开始监听时折叠设置
      }
      _isStreaming = !_isStreaming;
    });
  }
  
  // 清空事件列表
  void _clearEvents() {
    setState(() {
      _batteryEvents.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('事件列表已清空')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('电池信息流示例'),
        actions: [
          if (_batteryEvents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '清空数据',
              onPressed: _clearEvents,
            ),
          IconButton(
            icon: Icon(_isSetupCollapsed ? Icons.expand_more : Icons.expand_less),
            tooltip: _isSetupCollapsed ? '显示设置' : '隐藏设置',
            onPressed: () {
              setState(() {
                _isSetupCollapsed = !_isSetupCollapsed;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '推送间隔设置',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('间隔: '),
                          Expanded(
                            child: Slider(
                              value: _sliderValue,
                              min: 0.1,
                              max: 10.0,
                              divisions: 99,
                              onChanged: _isStreaming ? null : (value) {
                                setState(() {
                                  _sliderValue = value;
                                });
                              },
                            ),
                          ),
                          Container(
                            width: 60,
                            alignment: Alignment.center,
                            child: Text('${_sliderValue.toStringAsFixed(1)}秒'),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text('防抖动'),
                        subtitle: const Text('仅在电量变化时推送'),
                        value: _enableDebounce,
                        onChanged: _isStreaming ? null : (value) {
                          setState(() {
                            _enableDebounce = value;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              secondChild: _isStreaming ? Card(
                color: Colors.green[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.graphic_eq, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '电池流监听中',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '推送间隔: ${_sliderValue.toStringAsFixed(1)}秒 ${_enableDebounce ? "(防抖动已启用)" : ""}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ) : const SizedBox(height: 8),
              crossFadeState: _isSetupCollapsed && _isStreaming ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleStreaming,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStreaming ? Colors.red[100] : Colors.blue[100],
                foregroundColor: _isStreaming ? Colors.red[700] : Colors.blue[700],
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(_isStreaming ? '停止监听' : '开始监听'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '接收到的电池事件:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_batteryEvents.isNotEmpty && _isStreaming)
                  Text(
                    '已接收: ${_batteryEvents.length}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: _batteryEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.battery_unknown, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              '暂无数据',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '点击"开始监听"接收电池事件',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _batteryEvents.length,
                        itemBuilder: (context, index) {
                          final event = _batteryEvents[_batteryEvents.length - index - 1];
                          final timestamp = DateTime.fromMillisecondsSinceEpoch(
                              event['timestamp'] as int);
                          
                          final batteryLevel = event['batteryLevel'] as int;
                          Color batteryColor = Colors.green;
                          if (batteryLevel <= 20) {
                            batteryColor = Colors.red;
                          } else if (batteryLevel <= 50) {
                            batteryColor = Colors.orange;
                          }
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text('电量: $batteryLevel%'),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 30,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: batteryColor.withOpacity(0.2),
                                      border: Border.all(color: batteryColor),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      widthFactor: batteryLevel / 100,
                                      alignment: Alignment.centerLeft,
                                      child: Container(color: batteryColor),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '时间: ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${(timestamp.millisecond ~/10).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.battery_full,
                                    color: batteryColor,
                                    size: 32,
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    child: Text(
                                      '$batteryLevel',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: batteryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '#${_batteryEvents.length - index}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
