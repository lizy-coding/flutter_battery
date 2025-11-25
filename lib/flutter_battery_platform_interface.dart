import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_battery_method_channel.dart';

abstract class FlutterBatteryPlatform extends PlatformInterface {
  /// Constructs a FlutterBatteryPlatform.
  FlutterBatteryPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBatteryPlatform _instance = MethodChannelFlutterBattery();

  /// The default instance of [FlutterBatteryPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBattery].
  static FlutterBatteryPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBatteryPlatform] when
  /// they register themselves.
  static set instance(FlutterBatteryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  
  /// 获取电池电量百分比
  Future<int?> getBatteryLevel() {
    throw UnimplementedError('getBatteryLevel() has not been implemented.');
  }
  
  /// 获取电池完整信息
  /// 
  /// 返回一个包含电池详细信息的Map，包括电量、充电状态、温度、电压等
  Future<Map<String, dynamic>> getBatteryInfo() {
    throw UnimplementedError('getBatteryInfo() has not been implemented.');
  }
  
  /// 获取电池健康信息
  Future<Map<String, dynamic>> getBatteryHealth() {
    throw UnimplementedError('getBatteryHealth() has not been implemented.');
  }
  
  /// 获取电池优化建议
  /// 
  /// 返回基于当前电池状态的优化建议列表
  Future<List<String>> getBatteryOptimizationTips() {
    throw UnimplementedError('getBatteryOptimizationTips() has not been implemented.');
  }
  
  /// 配置电池监听和回调
  /// 
  /// 此方法整合了多个回调设置，允许同时设置多种不同的电池事件回调
  /// [onLowBattery] 低电量回调
  /// [onBatteryLevelChange] 电池电量变化回调
  /// [onBatteryInfoChange] 电池信息变化回调
  void configureBatteryCallbacks({
    Function(int batteryLevel)? onLowBattery,
    Function(int batteryLevel)? onBatteryLevelChange,
    Function(Map<String, dynamic> batteryInfo)? onBatteryInfoChange,
    Function(Map<String, dynamic> batteryHealth)? onBatteryHealthChange,
  }) {
    if (onLowBattery != null) {
      setLowBatteryCallback(onLowBattery);
    }
    
    if (onBatteryLevelChange != null) {
      setBatteryLevelChangeCallback(onBatteryLevelChange);
    }
    
    if (onBatteryInfoChange != null) {
      setBatteryInfoChangeCallback(onBatteryInfoChange);
    }

    if (onBatteryHealthChange != null) {
      setBatteryHealthChangeCallback(onBatteryHealthChange);
    }
  }
  
  /// 设置低电量回调函数
  void setLowBatteryCallback(Function(int batteryLevel) callback) {
    throw UnimplementedError('setLowBatteryCallback() has not been implemented.');
  }
  
  /// 设置电池电量变化回调函数
  void setBatteryLevelChangeCallback(Function(int batteryLevel) callback) {
    throw UnimplementedError('setBatteryLevelChangeCallback() has not been implemented.');
  }
  
  /// 设置电池信息变化回调函数
  void setBatteryInfoChangeCallback(Function(Map<String, dynamic> batteryInfo) callback) {
    throw UnimplementedError('setBatteryInfoChangeCallback() has not been implemented.');
  }

  /// 设置电池健康变化回调函数
  void setBatteryHealthChangeCallback(Function(Map<String, dynamic> batteryHealth) callback) {
    throw UnimplementedError('setBatteryHealthChangeCallback() has not been implemented.');
  }
  
  /// 配置电池监听选项
  /// 
  /// 此方法整合了多个电池监听功能，可以同时配置电池电量监听和电池信息监听
  /// [monitorBatteryLevel] 是否监控电池电量
  /// [monitorBatteryInfo] 是否监控电池完整信息
  /// [intervalMs] 推送间隔（毫秒）
  /// [batteryInfoIntervalMs] 电池信息推送间隔（毫秒）
  /// [enableDebounce] 是否启用防抖动（仅在电量变化时推送）
  /// 返回配置结果，包含各项配置是否成功的布尔值
  Future<Map<String, bool>> configureBatteryMonitor({
    bool monitorBatteryLevel = false,
    bool monitorBatteryInfo = false,
    bool monitorBatteryHealth = false,
    int intervalMs = 1000, 
    int batteryInfoIntervalMs = 5000,
    int batteryHealthIntervalMs = 10000,
    bool enableDebounce = true,
  }) async {
    final result = <String, bool>{};
    
    // 设置推送间隔
    if (monitorBatteryLevel || monitorBatteryInfo) {
      result['setPushInterval'] = await setPushInterval(
        intervalMs: intervalMs,
        enableDebounce: enableDebounce,
      ) ?? false;
    }
    
    // 启动或停止电池电量监听
    if (monitorBatteryLevel) {
      result['batteryLevelMonitor'] = await startBatteryLevelListening() ?? false;
    } else {
      result['batteryLevelMonitor'] = await stopBatteryLevelListening() ?? false;
    }
    
    // 启动或停止电池信息监听
    if (monitorBatteryInfo) {
      result['batteryInfoMonitor'] = await startBatteryInfoListening(
        intervalMs: batteryInfoIntervalMs,
      ) ?? false;
    } else {
      result['batteryInfoMonitor'] = await stopBatteryInfoListening() ?? false;
    }

    if (monitorBatteryHealth) {
      result['batteryHealthMonitor'] = await startBatteryHealthListening(
        intervalMs: batteryHealthIntervalMs,
      ) ?? false;
    } else {
      result['batteryHealthMonitor'] = await stopBatteryHealthListening() ?? false;
    }
    
    return result;
  }
  
  /// 开始监听电池电量变化
  Future<bool?> startBatteryLevelListening() {
    throw UnimplementedError('startBatteryLevelListening() has not been implemented.');
  }
  
  /// 停止监听电池电量变化
  Future<bool?> stopBatteryLevelListening() {
    throw UnimplementedError('stopBatteryLevelListening() has not been implemented.');
  }
  
  /// 开始监听完整电池信息变化
  Future<bool?> startBatteryInfoListening({
    int intervalMs = 5000,
  }) {
    throw UnimplementedError('startBatteryInfoListening() has not been implemented.');
  }
  
  /// 停止监听完整电池信息变化
  Future<bool?> stopBatteryInfoListening() {
    throw UnimplementedError('stopBatteryInfoListening() has not been implemented.');
  }

  /// 开始监听电池健康状态
  Future<bool?> startBatteryHealthListening({
    int intervalMs = 10000,
  }) {
    throw UnimplementedError('startBatteryHealthListening() has not been implemented.');
  }

  /// 停止监听电池健康状态
  Future<bool?> stopBatteryHealthListening() {
    throw UnimplementedError('stopBatteryHealthListening() has not been implemented.');
  }
  
  /// 获取电池电量信息流
  Stream<Map<String, dynamic>> get batteryStream {
    throw UnimplementedError('batteryStream has not been implemented.');
  }
  
  /// 设置电池信息推送间隔
  Future<bool?> setPushInterval({
    required int intervalMs,
    bool enableDebounce = true,
  }) {
    throw UnimplementedError('setPushInterval() has not been implemented.');
  }
  
  /// 配置电池监控
  /// 
  /// 此方法整合了低电量监控的设置和停止功能
  /// [enable] 是否启用监控
  /// [threshold] 电池电量阈值（百分比）
  /// [title] 通知标题
  /// [message] 通知内容
  /// [intervalMinutes] 检查间隔（分钟）
  /// [useFlutterRendering] 是否使用Flutter渲染通知
  /// [onLowBattery] 低电量回调
  Future<bool?> configureBatteryMonitoring({
    required bool enable,
    int threshold = 20,
    String title = "电池电量低",
    String message = "您的电池电量已经低于阈值，请及时充电",
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    Function(int)? onLowBattery,
  }) async {
    if (enable) {
      return setBatteryLevelThreshold(
        threshold: threshold,
        title: title,
        message: message,
        intervalMinutes: intervalMinutes,
        useFlutterRendering: useFlutterRendering,
        onLowBattery: onLowBattery,
      );
    } else {
      return stopBatteryMonitoring();
    }
  }
  
  /// 设置电池低电量阈值监控
  Future<bool?> setBatteryLevelThreshold({
    required int threshold,
    required String title,
    required String message,
    int intervalMinutes = 15,
    bool useFlutterRendering = false,
    Function(int)? onLowBattery,
  }) {
    throw UnimplementedError('setBatteryLevelThreshold() has not been implemented.');
  }
  
  /// 停止电池电量监控
  Future<bool?> stopBatteryMonitoring() {
    throw UnimplementedError('stopBatteryMonitoring() has not been implemented.');
  }
  
  /// 发送通知
  /// 
  /// 此方法整合了立即通知和延迟通知功能
  /// [title] 通知标题
  /// [message] 通知内容
  /// [delay] 延迟时间（分钟），如果为0则立即发送
  Future<bool?> sendNotification({
    required String title,
    required String message,
    int delay = 0,
  }) async {
    if (delay <= 0) {
      return showNotification(
        title: title,
        message: message,
      );
    } else {
      return scheduleNotification(
        title: title,
        message: message,
        delayMinutes: delay,
      );
    }
  }
  
  /// 调度一个延迟通知
  Future<bool?> scheduleNotification({
    required String title,
    required String message,
    int delayMinutes = 1,
  }) {
    throw UnimplementedError('scheduleNotification() has not been implemented.');
  }
  
  /// 立即显示一个通知
  Future<bool?> showNotification({
    required String title,
    required String message,
  }) {
    throw UnimplementedError('showNotification() has not been implemented.');
  }
}
