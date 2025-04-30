import 'flutter_battery_platform_interface.dart';

class FlutterBattery {
  Future<String?> getPlatformVersion() {
    return FlutterBatteryPlatform.instance.getPlatformVersion();
  }
  
  /// 获取电池电量百分比
  Future<int?> getBatteryLevel() {
    return FlutterBatteryPlatform.instance.getBatteryLevel();
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
