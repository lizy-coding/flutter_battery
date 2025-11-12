import 'package:flutter_battery/flutter_battery.dart';

class BatterySubsystemRepository {
  BatterySubsystemRepository(this._plugin);

  final FlutterBattery _plugin;

  Future<int?> fetchBatteryLevel() => _plugin.getBatteryLevel();

  Future<BatteryInfo> fetchBatteryInfo() => _plugin.getBatteryInfo();

  Future<Map<String, dynamic>> configureMonitoring({
    BatteryMonitorConfig? monitorConfig,
    BatteryLevelMonitorConfig? lowBatteryConfig,
  }) async {
    final configuration = BatteryConfiguration(
      monitorConfig: monitorConfig,
      lowBatteryConfig: lowBatteryConfig,
    );
    return _plugin.configureBattery(configuration);
  }
}
