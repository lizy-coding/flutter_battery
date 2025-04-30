import 'flutter_battery_platform_interface.dart';

class FlutterBattery {
  Future<String?> getPlatformVersion() {
    return FlutterBatteryPlatform.instance.getPlatformVersion();
  }
  
  /// 获取电池电量百分比
  Future<int?> getBatteryLevel() {
    return FlutterBatteryPlatform.instance.getBatteryLevel();
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
