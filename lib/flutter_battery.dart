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

class FlutterBattery {
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
  
  /// 获取电池信息流
  /// 
  /// 返回包含电池信息的事件流，每个事件包含：
  /// - batteryLevel: 电池电量百分比
  /// - timestamp: 时间戳（毫秒）
  Stream<Map<String, dynamic>> get batteryStream {
    return FlutterBatteryPlatform.instance.batteryStream;
  }
  
  /// 获取格式化的电池信息流
  /// 
  /// 将原始的电池信息转换为格式化的 BatteryInfo 对象
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
  
  /// 设置电池信息推送间隔
  /// 
  /// [intervalMs] 推送间隔（毫秒）
  /// [enableDebounce] 是否启用防抖动（仅在电量变化时推送）
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
  /// 
  /// [onBatteryLevelChanged] 电池电量变化回调
  void setBatteryLevelChangeListener(Function(int batteryLevel) onBatteryLevelChanged) {
    FlutterBatteryPlatform.instance.setBatteryLevelChangeCallback(onBatteryLevelChanged);
  }
  
  /// 设置电池信息变化监听
  /// 
  /// [onBatteryInfoChanged] 电池信息变化回调
  void setBatteryInfoChangeListener(Function(BatteryInfo info) onBatteryInfoChanged) {
    FlutterBatteryPlatform.instance.setBatteryInfoChangeCallback((Map<String, dynamic> infoMap) {
      final info = BatteryInfo.fromMap(infoMap);
      onBatteryInfoChanged(info);
    });
  }
  
  /// 开始监听电池电量变化
  Future<bool?> startBatteryLevelListening() {
    return FlutterBatteryPlatform.instance.startBatteryLevelListening();
  }
  
  /// 停止监听电池电量变化
  Future<bool?> stopBatteryLevelListening() {
    return FlutterBatteryPlatform.instance.stopBatteryLevelListening();
  }
  
  /// 开始监听电池信息变化
  /// 
  /// [intervalMs] 推送间隔（毫秒）
  Future<bool?> startBatteryInfoListening({int intervalMs = 5000}) {
    return FlutterBatteryPlatform.instance.startBatteryInfoListening(
      intervalMs: intervalMs,
    );
  }
  
  /// 停止监听电池信息变化
  Future<bool?> stopBatteryInfoListening() {
    return FlutterBatteryPlatform.instance.stopBatteryInfoListening();
  }
  
  /// 设置电池低电量阈值监控
  /// 
  /// [threshold] 电池电量阈值（百分比），低于此值将触发通知
  /// [title] 通知标题
  /// [message] 通知内容
  /// [intervalMinutes] 检查间隔（分钟），默认15分钟
  /// [useFlutterRendering] 是否使用Flutter渲染通知，如果为true，将通过回调通知Flutter
  /// [onLowBattery] 当电池电量低于阈值且useFlutterRendering为true时的回调
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
  
  /// 停止电池电量监控
  Future<bool?> stopBatteryMonitoring() {
    return FlutterBatteryPlatform.instance.stopBatteryMonitoring();
  }
  
  /// 调度一个延迟通知
  /// 
  /// [title] 通知标题
  /// [message] 通知内容
  /// [delayMinutes] 延迟分钟数（默认1分钟）
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
  
  /// 立即显示一个通知
  /// 
  /// [title] 通知标题
  /// [message] 通知内容
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) {
    return FlutterBatteryPlatform.instance.showNotification(
      title: title,
      message: message,
    );
  }
}
