import 'flutter_battery_platform_interface.dart';
export 'battery_animation.dart';

class FlutterBattery {
  Future<String?> getPlatformVersion() {
    return FlutterBatteryPlatform.instance.getPlatformVersion();
  }
  
  /// 获取电池电量百分比
  Future<int?> getBatteryLevel() {
    return FlutterBatteryPlatform.instance.getBatteryLevel();
  }
  
  /// 获取电池信息流
  /// 
  /// 返回包含电池信息的事件流，每个事件包含：
  /// - batteryLevel: 电池电量百分比
  /// - timestamp: 时间戳（毫秒）
  Stream<Map<String, dynamic>> get batteryStream {
    return FlutterBatteryPlatform.instance.batteryStream;
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
  /// 返回一个监听句柄，可用于移除监听
  void setBatteryLevelChangeListener(Function(int batteryLevel) onBatteryLevelChanged) {
    FlutterBatteryPlatform.instance.setBatteryLevelChangeCallback(onBatteryLevelChanged);
  }
  
  /// 开始监听电池电量变化
  Future<bool?> startBatteryLevelListening() {
    return FlutterBatteryPlatform.instance.startBatteryLevelListening();
  }
  
  /// 停止监听电池电量变化
  Future<bool?> stopBatteryLevelListening() {
    return FlutterBatteryPlatform.instance.stopBatteryLevelListening();
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
