import 'flutter_battery_platform_interface.dart';
export 'battery_animation.dart';

/// 电池状态枚举
enum BatteryState {
  NORMAL,    // 正常状态
  LOW,       // 低电量状态
  CRITICAL,  // 极低电量状态
  CHARGING,  // 充电状态
  FULL       // 已充满状态
}

/// 监听配置类，用于配置电池监控选项
class BatteryMonitorConfig {
  /// 是否监控电池电量
  final bool monitorBatteryLevel;
  
  /// 是否监控电池完整信息
  final bool monitorBatteryInfo;
  
  /// 推送间隔（毫秒）
  final int intervalMs;
  
  /// 电池信息推送间隔（毫秒）
  final int batteryInfoIntervalMs;
  
  /// 是否监控电池健康状态
  final bool monitorBatteryHealth;
  
  /// 电池健康推送间隔
  final int batteryHealthIntervalMs;
  
  /// 是否启用防抖动（仅在电量变化时推送）
  final bool enableDebounce;
  
  /// 创建监控配置
  BatteryMonitorConfig({
    this.monitorBatteryLevel = true,
    this.monitorBatteryInfo = false,
    this.intervalMs = 1000,
    this.batteryInfoIntervalMs = 5000,
    this.monitorBatteryHealth = false,
    this.batteryHealthIntervalMs = 10000,
    this.enableDebounce = true,
  });
}

/// 电池监控配置类，用于配置低电量监控
class BatteryLevelMonitorConfig {
  /// 是否启用监控
  final bool enable;
  
  /// 电池电量阈值（百分比）
  final int threshold;
  
  /// 通知标题
  final String title;
  
  /// 通知内容
  final String message;
  
  /// 检查间隔（分钟）
  final int intervalMinutes;
  
  /// 是否使用Flutter渲染通知
  final bool useFlutterRendering;
  
  /// 低电量回调
  final Function(int)? onLowBattery;
  
  /// 创建低电量监控配置
  BatteryLevelMonitorConfig({
    required this.enable,
    this.threshold = 20,
    this.title = "电池电量低",
    this.message = "您的电池电量已经低于阈值，请及时充电",
    this.intervalMinutes = 15,
    this.useFlutterRendering = false,
    this.onLowBattery,
  });
}

/// 电池信息类
class BatteryInfo {
  final int level;
  final bool isCharging;
  final double temperature;
  final double voltage;
  final BatteryState state;
  final int timestamp;
  
  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.temperature,
    required this.voltage,
    required this.state,
    required this.timestamp,
  });
  
  /// 从Map创建电池信息对象
  factory BatteryInfo.fromMap(Map<String, dynamic> map) {
    return BatteryInfo(
      level: map['level'] as int? ?? 0,
      isCharging: map['isCharging'] as bool? ?? false,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      voltage: (map['voltage'] as num?)?.toDouble() ?? 0.0,
      state: _parseState(map['state'] as String?),
      timestamp: map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// 解析电池状态字符串
  static BatteryState _parseState(String? stateStr) {
    if (stateStr == null) return BatteryState.NORMAL;
    
    try {
      return BatteryState.values.firstWhere(
        (e) => e.toString() == 'BatteryState.$stateStr',
        orElse: () => BatteryState.NORMAL,
      );
    } catch (_) {
      return BatteryState.NORMAL;
    }
  }
  
  @override
  String toString() => 'BatteryInfo(level: $level%, isCharging: $isCharging, '
                      'temperature: ${temperature.toStringAsFixed(1)}°C, '
                      'voltage: ${voltage.toStringAsFixed(2)}V, state: $state)';
}

enum BatteryHealthState {
  good,
  overheat,
  dead,
  overVoltage,
  failure,
  cold,
  unknown,
}

class BatteryHealth {
  final BatteryHealthState state;
  final String statusLabel;
  final bool isGood;
  final double temperature;
  final double voltage;
  final int level;
  final bool isCharging;
  final String riskLevel;
  final List<String> recommendations;
  final int timestamp;

  BatteryHealth({
    required this.state,
    required this.statusLabel,
    required this.isGood,
    required this.temperature,
    required this.voltage,
    required this.level,
    required this.isCharging,
    required this.riskLevel,
    required this.recommendations,
    required this.timestamp,
  });

  factory BatteryHealth.fromMap(Map<String, dynamic> map) {
    return BatteryHealth(
      state: _parseHealthState(map['state'] as String?),
      statusLabel: map['statusLabel'] as String? ?? '未知',
      isGood: map['isGood'] as bool? ?? false,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      voltage: (map['voltage'] as num?)?.toDouble() ?? 0.0,
      level: map['level'] as int? ?? 0,
      isCharging: map['isCharging'] as bool? ?? false,
      riskLevel: map['riskLevel'] as String? ?? 'LOW',
      recommendations: (map['recommendations'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const <String>[],
      timestamp:
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  static BatteryHealthState _parseHealthState(String? value) {
    switch (value) {
      case 'GOOD':
        return BatteryHealthState.good;
      case 'OVERHEAT':
        return BatteryHealthState.overheat;
      case 'DEAD':
        return BatteryHealthState.dead;
      case 'OVER_VOLTAGE':
        return BatteryHealthState.overVoltage;
      case 'FAILURE':
        return BatteryHealthState.failure;
      case 'COLD':
        return BatteryHealthState.cold;
      default:
        return BatteryHealthState.unknown;
    }
  }

  @override
  String toString() =>
      'BatteryHealth(state: $state, risk: $riskLevel, temp: ${temperature.toStringAsFixed(1)}°C)';
}

/// 高级电池配置类，整合所有电池相关设置
class BatteryConfiguration {
  /// 基本监听配置
  final BatteryMonitorConfig? monitorConfig;
  
  /// 低电量监控配置
  final BatteryLevelMonitorConfig? lowBatteryConfig;
  
  /// 电池电量变化回调
  final Function(int batteryLevel)? onBatteryLevelChange;
  
  /// 电池信息变化回调
  final Function(BatteryInfo info)? onBatteryInfoChange;

  /// 电池健康变化回调
  final Function(BatteryHealth health)? onBatteryHealthChange;
  
  /// 低电量回调
  final Function(int batteryLevel)? onLowBattery;
  
  /// 创建高级电池配置
  BatteryConfiguration({
    this.monitorConfig,
    this.lowBatteryConfig,
    this.onBatteryLevelChange,
    this.onBatteryInfoChange,
    this.onBatteryHealthChange,
    this.onLowBattery,
  });
}

class FlutterBattery {
  /// 获取平台版本
  Future<String?> getPlatformVersion() {
    return FlutterBatteryPlatform.instance.getPlatformVersion();
  }
  
  /// 获取电池电量百分比
  Future<int?> getBatteryLevel() {
    return FlutterBatteryPlatform.instance.getBatteryLevel();
  }
  
  /// 获取电池完整信息
  Future<BatteryInfo> getBatteryInfo() async {
    final infoMap = await FlutterBatteryPlatform.instance.getBatteryInfo();
    return BatteryInfo.fromMap(infoMap);
  }
  
  /// 获取电池优化建议
  Future<List<String>> getBatteryOptimizationTips() {
    return FlutterBatteryPlatform.instance.getBatteryOptimizationTips();
  }
  
  /// 获取电池信息流（原始数据）
  Stream<Map<String, dynamic>> get batteryStream {
    return FlutterBatteryPlatform.instance.batteryStream;
  }
  
  /// 获取格式化的电池信息流
  Stream<BatteryInfo> get batteryInfoStream {
    return batteryStream.map((event) {
      // 检查是否包含完整的电池信息
      if (event.containsKey('type') && event['type'] == 'BATTERY_INFO') {
        return BatteryInfo.fromMap(event);
      }
      
      // 兼容简单电池电量信息
      final int level = event['batteryLevel'] as int? ?? 0;
      final int timestamp = event['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
      
      return BatteryInfo(
        level: level,
        isCharging: false,
        temperature: 0.0,
        voltage: 0.0,
        state: level <= 20 ? BatteryState.LOW : BatteryState.NORMAL,
        timestamp: timestamp,
      );
    });
  }
  
  /// 配置所有电池相关回调
  /// 
  /// 一次性设置所有回调，减少多次调用接口
  /// [onLowBattery] 低电量回调
  /// [onBatteryLevelChange] 电池电量变化回调
  /// [onBatteryInfoChange] 电池信息变化回调
  void configureBatteryCallbacks({
    Function(int batteryLevel)? onLowBattery,
    Function(int batteryLevel)? onBatteryLevelChange,
    Function(BatteryInfo info)? onBatteryInfoChange,
  }) {
    // 设置低电量回调
    if (onLowBattery != null) {
      FlutterBatteryPlatform.instance.setLowBatteryCallback(onLowBattery);
    }
    
    // 设置电池电量变化回调
    if (onBatteryLevelChange != null) {
      FlutterBatteryPlatform.instance.setBatteryLevelChangeCallback(onBatteryLevelChange);
    }
    
    // 设置电池信息变化回调
    if (onBatteryInfoChange != null) {
      FlutterBatteryPlatform.instance.setBatteryInfoChangeCallback((Map<String, dynamic> infoMap) {
        final info = BatteryInfo.fromMap(infoMap);
        onBatteryInfoChange(info);
      });
    }
  }
  
  /// 设置电池电量推送间隔和防抖动
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> setPushInterval({
    required int intervalMs,
    bool enableDebounce = true,
  }) {
    return FlutterBatteryPlatform.instance.setPushInterval(
      intervalMs: intervalMs,
      enableDebounce: enableDebounce,
    );
  }
  
  /// 设置电池电量变化监听
  @Deprecated('请使用configureBatteryCallbacks方法代替')
  void setBatteryLevelChangeListener(Function(int batteryLevel) onBatteryLevelChanged) {
    FlutterBatteryPlatform.instance.setBatteryLevelChangeCallback(onBatteryLevelChanged);
  }
  
  /// 设置电池信息变化监听
  @Deprecated('请使用configureBatteryCallbacks方法代替')
  void setBatteryInfoChangeListener(Function(BatteryInfo info) onBatteryInfoChanged) {
    FlutterBatteryPlatform.instance.setBatteryInfoChangeCallback((Map<String, dynamic> infoMap) {
      final info = BatteryInfo.fromMap(infoMap);
      onBatteryInfoChanged(info);
    });
  }
  
  /// 配置电池监听
  /// 
  /// 一次性配置电池监听选项，减少多次调用接口
  /// [config] 监听配置，包含监听类型、间隔等
  /// 返回一个包含各项配置是否成功的Map
  Future<Map<String, bool>> configureBatteryMonitor(BatteryMonitorConfig config) async {
    return FlutterBatteryPlatform.instance.configureBatteryMonitor(
      monitorBatteryLevel: config.monitorBatteryLevel,
      monitorBatteryInfo: config.monitorBatteryInfo,
      intervalMs: config.intervalMs,
      batteryInfoIntervalMs: config.batteryInfoIntervalMs,
      enableDebounce: config.enableDebounce,
    );
  }
  
  /// 开始监听电池电量变化（建议使用configureBatteryMonitor替代）
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> startBatteryLevelListening() {
    return FlutterBatteryPlatform.instance.startBatteryLevelListening();
  }
  
  /// 停止监听电池电量变化（建议使用configureBatteryMonitor替代）
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> stopBatteryLevelListening() {
    return FlutterBatteryPlatform.instance.stopBatteryLevelListening();
  }
  
  /// 开始监听电池信息变化（建议使用configureBatteryMonitor替代）
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> startBatteryInfoListening({int intervalMs = 5000}) {
    return FlutterBatteryPlatform.instance.startBatteryInfoListening(
      intervalMs: intervalMs,
    );
  }
  
  /// 停止监听电池信息变化（建议使用configureBatteryMonitor替代）
  @Deprecated('请使用configureBatteryMonitor方法代替')
  Future<bool?> stopBatteryInfoListening() {
    return FlutterBatteryPlatform.instance.stopBatteryInfoListening();
  }
  
  /// 配置电池低电量监控
  /// 
  /// 一次性配置低电量监控，可启用或停用
  /// [config] 低电量监控配置
  /// 返回配置是否成功
  Future<bool?> configureBatteryMonitoring(BatteryLevelMonitorConfig config) {
    return FlutterBatteryPlatform.instance.configureBatteryMonitoring(
      enable: config.enable,
      threshold: config.threshold,
      title: config.title,
      message: config.message,
      intervalMinutes: config.intervalMinutes,
      useFlutterRendering: config.useFlutterRendering,
      onLowBattery: config.onLowBattery,
    );
  }
  
  /// 设置电池低电量阈值监控（建议使用configureBatteryMonitoring替代）
  @Deprecated('请使用configureBatteryMonitoring方法代替')
  Future<bool?> setBatteryLevelThreshold({
    required int threshold,
    required String title,
    required String message,
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    Function(int batteryLevel)? onLowBattery,
  }) {
    if (useFlutterRendering && onLowBattery != null) {
      FlutterBatteryPlatform.instance.setLowBatteryCallback(onLowBattery);
    }
    
    return FlutterBatteryPlatform.instance.setBatteryLevelThreshold(
      threshold: threshold,
      title: title,
      message: message,
      intervalMinutes: intervalMinutes,
      useFlutterRendering: useFlutterRendering,
      onLowBattery: onLowBattery,
    );
  }
  
  /// 停止电池电量监控（建议使用configureBatteryMonitoring替代）
  @Deprecated('请使用configureBatteryMonitoring方法代替')
  Future<bool?> stopBatteryMonitoring() {
    return FlutterBatteryPlatform.instance.stopBatteryMonitoring();
  }
  
  /// 发送通知
  /// 
  /// 统一的通知发送方法，支持即时或延迟发送
  /// [title] 通知标题
  /// [message] 通知内容
  /// [delay] 延迟分钟数，0表示立即发送
  Future<bool?> sendNotification({
    required String title,
    required String message,
    int delay = 0,
  }) {
    return FlutterBatteryPlatform.instance.sendNotification(
      title: title,
      message: message,
      delay: delay,
    );
  }
  
  /// 调度一个延迟通知（建议使用sendNotification替代）
  @Deprecated('请使用sendNotification方法代替')
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) {
    return FlutterBatteryPlatform.instance.scheduleNotification(
      title: title,
      message: message,
      delayMinutes: delayMinutes,
    );
  }
  
  /// 立即显示一个通知（建议使用sendNotification替代）
  @Deprecated('请使用sendNotification方法代替')
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) {
    return FlutterBatteryPlatform.instance.showNotification(
      title: title,
      message: message,
    );
  }
  
  /// 一次性配置所有电池相关设置
  /// 
  /// 高级API，整合了监控、回调和低电量设置
  /// [config] 完整的电池配置
  /// 返回配置结果，包含各项配置是否成功的信息
  Future<Map<String, dynamic>> configureBattery(BatteryConfiguration config) async {
    final result = <String, dynamic>{};
    
    // 1. 设置回调
    if (config.onBatteryLevelChange != null || 
        config.onBatteryInfoChange != null || 
        config.onLowBattery != null) {
      
      configureBatteryCallbacks(
        onBatteryLevelChange: config.onBatteryLevelChange,
        onBatteryInfoChange: config.onBatteryInfoChange,
        onLowBattery: config.onLowBattery,
      );
      
      result['callbacksConfigured'] = true;
    }
    
    // 2. 配置电池监听
    if (config.monitorConfig != null) {
      result['monitoringResults'] = await configureBatteryMonitor(config.monitorConfig!);
    }
    
    // 3. 配置低电量监控
    if (config.lowBatteryConfig != null) {
      result['lowBatteryMonitoring'] = await configureBatteryMonitoring(config.lowBatteryConfig!);
    }
    
    return result;
  }
}
