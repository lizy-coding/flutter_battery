import 'package:flutter_battery/flutter_battery_platform_interface.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/widgets.dart';

class MockFlutterBatteryPlatform
    with MockPlatformInterfaceMixin
    implements FlutterBatteryPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) {
    return Future.value(true);
  }

  @override
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) {
    return Future.value(true);
  }

  @override
  Future<int?> getBatteryLevel() {
    return Future.value(75);
  }

  @override
  Future<bool?> setBatteryLevelThreshold({
    required int threshold,
    required String title,
    required String message,
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    dynamic Function(int)? onLowBattery,
  }) {
    return Future.value(true);
  }

  @override
  void setLowBatteryCallback(Function(int batteryLevel) callback) {
    // no-op for testing
  }

  @override
  Future<bool?> stopBatteryMonitoring() {
    return Future.value(true);
  }
  
  @override
  void setBatteryLevelChangeCallback(Function(int batteryLevel) callback) {
    // no-op for testing
  }
  
  @override
  Future<bool?> startBatteryLevelListening() {
    return Future.value(true);
  }
  
  @override
  Future<bool?> stopBatteryLevelListening() {
    return Future.value(true);
  }
  
  @override
  Stream<Map<String, dynamic>> get batteryStream {
    return Stream.fromIterable([
      {'batteryLevel': 75, 'timestamp': DateTime.now().millisecondsSinceEpoch},
      {
        'type': 'BATTERY_HEALTH',
        'state': 'GOOD',
        'statusLabel': '电池状态良好',
        'isGood': true,
        'temperature': 30.0,
        'voltage': 4.1,
        'level': 80,
        'isCharging': false,
        'riskLevel': 'LOW',
        'recommendations': ['测试建议'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ]);
  }
  
  @override
  Future<bool?> setPushInterval({required int intervalMs, bool enableDebounce = true}) {
    return Future.value(true);
  }
  
  @override
  Future<Map<String, dynamic>> getBatteryInfo() {
    return Future.value({
      'level': 75,
      'isCharging': false,
      'temperature': 30.5,
      'voltage': 4.2,
      'state': 'NORMAL',
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }

  @override
  Future<Map<String, dynamic>> getBatteryHealth() {
    return Future.value({
      'state': 'GOOD',
      'statusLabel': '电池状态良好',
      'isGood': true,
      'temperature': 30.0,
      'voltage': 4.1,
      'level': 80,
      'isCharging': false,
      'riskLevel': 'LOW',
      'recommendations': ['保持良好的充电习惯'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  @override
  Future<List<String>> getBatteryOptimizationTips() {
    return Future.value(['关闭后台应用', '降低屏幕亮度', '启用电池优化模式']);
  }
  
  @override
  void setBatteryInfoChangeCallback(Function(Map<String, dynamic> batteryInfo) callback) {
    // no-op for testing
  }

  @override
  void setBatteryHealthChangeCallback(Function(Map<String, dynamic> batteryHealth) callback) {
    // no-op for testing
  }
  
  @override
  Future<bool?> startBatteryInfoListening({int intervalMs = 5000}) {
    return Future.value(true);
  }
  
  @override
  Future<bool?> stopBatteryInfoListening() {
    return Future.value(true);
  }

  @override
  Future<bool?> startBatteryHealthListening({int intervalMs = 10000}) {
    return Future.value(true);
  }

  @override
  Future<bool?> stopBatteryHealthListening() {
    return Future.value(true);
  }
  
  @override
  Future<bool?> sendNotification({
    required String title,
    required String message,
    int delay = 0,
  }) {
    return Future.value(true);
  }
  
  @override
  Future<Map<String, bool>> configureBatteryMonitor({
    bool monitorBatteryLevel = false,
    bool monitorBatteryInfo = false,
    bool monitorBatteryHealth = false,
    int intervalMs = 1000,
    int batteryInfoIntervalMs = 5000,
    int batteryHealthIntervalMs = 10000,
    bool enableDebounce = true,
  }) {
    return Future.value({
      'setPushInterval': true,
      'batteryLevelMonitor': true,
      'batteryInfoMonitor': true,
      'batteryHealthMonitor': monitorBatteryHealth,
    });
  }
  
  @override
  void configureBatteryCallbacks({
    Function(int batteryLevel)? onLowBattery,
    Function(int batteryLevel)? onBatteryLevelChange,
    Function(Map<String, dynamic> batteryInfo)? onBatteryInfoChange,
    Function(Map<String, dynamic> batteryHealth)? onBatteryHealthChange,
  }) {
    // no-op for testing
  }
  
  @override
  Future<bool?> configureBatteryMonitoring({
    required bool enable,
    int threshold = 20,
    String title = "电池电量低",
    String message = "您的电池电量已经低于阈值，请及时充电",
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    Function(int)? onLowBattery,
  }) {
    return Future.value(true);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final FlutterBatteryPlatform initialPlatform =
      FlutterBatteryPlatform.instance;

  setUp(() {
    final fakePlatform = MockFlutterBatteryPlatform();
    FlutterBatteryPlatform.instance = fakePlatform;
  });

  test('Default platform is FlutterBatteryPlatform', () {
    expect(initialPlatform, isInstanceOf<FlutterBatteryPlatform>());
  });

  test('getPlatformVersion returns from mock', () async {
    expect(await FlutterBatteryPlatform.instance.getPlatformVersion(), '42');
  });

  test('getBatteryLevel returns from mock', () async {
    expect(await FlutterBatteryPlatform.instance.getBatteryLevel(), 75);
  });

  test('scheduleNotification returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.scheduleNotification(
        title: 'test',
        message: 'hello',
        delayMinutes: 5,
      ),
      true,
    );
  });

  test('showNotification returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.showNotification(
        title: 'test',
        message: 'world',
      ),
      true,
    );
  });

  test('setBatteryLevelThreshold returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.setBatteryLevelThreshold(
        threshold: 30,
        title: 'low',
        message: 'charging soon',
      ),
      true,
    );
  });

  test('stopBatteryMonitoring returns true', () async {
    expect(await FlutterBatteryPlatform.instance.stopBatteryMonitoring(), true);
  });
  
  test('sendNotification returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.sendNotification(
        title: 'test',
        message: 'notification',
        delay: 2,
      ),
      true,
    );
  });
  
  test('configureBatteryMonitor returns expected map', () async {
    final result = await FlutterBatteryPlatform.instance.configureBatteryMonitor(
      monitorBatteryLevel: true,
      monitorBatteryInfo: true,
      intervalMs: 2000,
      batteryInfoIntervalMs: 10000,
      enableDebounce: true,
    );
    
    expect(result, isA<Map<String, bool>>());
    expect(result['setPushInterval'], true);
    expect(result['batteryLevelMonitor'], true);
    expect(result['batteryInfoMonitor'], true);
  });
  
  test('configureBatteryMonitoring returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.configureBatteryMonitoring(
        enable: true,
        threshold: 15,
        title: '低电量提醒',
        message: '电池电量低于15%',
        intervalMinutes: 30,
      ),
      true,
    );
  });
  
  test('getBatteryInfo returns valid map', () async {
    final batteryInfo = await FlutterBatteryPlatform.instance.getBatteryInfo();
    
    expect(batteryInfo, isA<Map<String, dynamic>>());
    expect(batteryInfo['level'], 75);
    expect(batteryInfo['isCharging'], false);
    expect(batteryInfo['temperature'], 30.5);
    expect(batteryInfo['voltage'], 4.2);
    expect(batteryInfo['state'], 'NORMAL');
    expect(batteryInfo['timestamp'], isA<int>());
  });
  
  test('getBatteryHealth returns valid map', () async {
    final health = await FlutterBatteryPlatform.instance.getBatteryHealth();
    expect(health['state'], 'GOOD');
    expect(health['statusLabel'], isA<String>());
    expect(health['recommendations'], isA<List<String>>());
  });
  
  test('getBatteryOptimizationTips returns non-empty list', () async {
    final tips = await FlutterBatteryPlatform.instance.getBatteryOptimizationTips();
    
    expect(tips, isA<List<String>>());
    expect(tips, isNotEmpty);
    expect(tips.length, 3);
  });
  
  test('batteryStream emits valid data', () async {
    final batteryEvent = await FlutterBatteryPlatform.instance.batteryStream.first;
    
    expect(batteryEvent, isA<Map<String, dynamic>>());
    expect(batteryEvent['batteryLevel'], 75);
    expect(batteryEvent['timestamp'], isA<int>());
  });

  test('batteryHealthStream emits BatteryHealth', () async {
    final plugin = FlutterBattery();
    final health = await plugin.batteryHealthStream.first;
    expect(health.state, BatteryHealthState.good);
    expect(health.recommendations, isNotEmpty);
  });

  test('configureBattery aggregates results', () async {
    final plugin = FlutterBattery();
    final result = await plugin.configureBattery(
      BatteryConfiguration(
        monitorConfig: BatteryMonitorConfig(
          monitorBatteryLevel: true,
          monitorBatteryInfo: true,
          monitorBatteryHealth: true,
        ),
        lowBatteryConfig: BatteryLevelMonitorConfig(enable: true),
        onBatteryLevelChange: (level) {},
        onBatteryInfoChange: (info) {},
        onBatteryHealthChange: (health) {},
        onLowBattery: (level) {},
      ),
    );
    expect(result['callbacksConfigured'], true);
    expect(result['monitoringResults'], isA<Map<String, bool>>());
    expect(result['lowBatteryMonitoring'], true);
  });
}
