class BatteryChannelNames {
  static const String methodChannel = 'flutter_battery';
  static const String eventChannel = 'flutter_battery/battery_stream';
  static const String bleMethods = 'flutter_battery/ble_methods';
  static const String bleScanEvents = 'flutter_battery/ble_scan_events';
  static const String bleConnectionEvents =
      'flutter_battery/ble_connection_events';
  static const String peerMethods = 'flutter_battery/peer_methods';
  static const String peerEvents = 'flutter_battery/peer_events';
}

class BatteryMethodNames {
  static const String getPlatformVersion = 'getPlatformVersion';
  static const String getPlatformCapabilities = 'getPlatformCapabilities';
  static const String getBatteryLevel = 'getBatteryLevel';
  static const String getBatteryInfo = 'getBatteryInfo';
  static const String getBatteryHealth = 'getBatteryHealth';
  static const String getBatteryOptimizationTips = 'getBatteryOptimizationTips';
  static const String startBatteryLevelListening = 'startBatteryLevelListening';
  static const String stopBatteryLevelListening = 'stopBatteryLevelListening';
  static const String startBatteryInfoListening = 'startBatteryInfoListening';
  static const String stopBatteryInfoListening = 'stopBatteryInfoListening';
  static const String startBatteryHealthListening =
      'startBatteryHealthListening';
  static const String stopBatteryHealthListening = 'stopBatteryHealthListening';
  static const String setPushInterval = 'setPushInterval';
  static const String setBatteryLevelThreshold = 'setBatteryLevelThreshold';
  static const String stopBatteryMonitoring = 'stopBatteryMonitoring';
  static const String scheduleNotification = 'scheduleNotification';
  static const String showNotification = 'showNotification';
  static const String sendNotification = 'sendNotification';
  static const String onLowBattery = 'onLowBattery';
  static const String onBatteryLevelChanged = 'onBatteryLevelChanged';
  static const String onBatteryInfoChanged = 'onBatteryInfoChanged';
  static const String onBatteryHealthChanged = 'onBatteryHealthChanged';

  static const String isBleAvailable = 'isBleAvailable';
  static const String isBleEnabled = 'isBleEnabled';
  static const String startScan = 'startScan';
  static const String stopScan = 'stopScan';
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String writeCharacteristic = 'writeCharacteristic';

  static const String startMasterMode = 'startMasterMode';
  static const String startSlaveMode = 'startSlaveMode';
  static const String stopAllPeerModes = 'stopAllPeerModes';
  static const String masterConnectToDevice = 'masterConnectToDevice';
}

class BatteryEventTypes {
  static const String batteryLevel = 'BATTERY_LEVEL';
  static const String batteryInfo = 'BATTERY_INFO';
  static const String batteryHealth = 'BATTERY_HEALTH';
  static const String batteryUnavailable = 'BATTERY_UNAVAILABLE';
  static const String batteryError = 'BATTERY_ERROR';
}

class BatteryPayloadKeys {
  static const String type = 'type';
  static const String timestamp = 'timestamp';
  static const String batteryLevel = 'batteryLevel';
  static const String level = 'level';
  static const String isCharging = 'isCharging';
  static const String isCharged = 'isCharged';
  static const String state = 'state';
  static const String temperature = 'temperature';
  static const String voltage = 'voltage';
  static const String timeToFull = 'timeToFull';
  static const String timeToEmpty = 'timeToEmpty';
  static const String statusLabel = 'statusLabel';
  static const String isGood = 'isGood';
  static const String riskLevel = 'riskLevel';
  static const String recommendations = 'recommendations';
  static const String healthPercentage = 'healthPercentage';
  static const String maxCapacity = 'maxCapacity';
  static const String currentCapacity = 'currentCapacity';
  static const String designCapacity = 'designCapacity';
  static const String cycleCount = 'cycleCount';
  static const String serialNumber = 'serialNumber';
  static const String manufacturer = 'manufacturer';
  static const String deviceName = 'deviceName';
  static const String unavailableReason = 'unavailableReason';
  static const String error = 'error';

  static const String intervalMs = 'intervalMs';
  static const String enableDebounce = 'enableDebounce';
  static const String threshold = 'threshold';
  static const String title = 'title';
  static const String message = 'message';
  static const String intervalMinutes = 'intervalMinutes';
  static const String useFlutterRendering = 'useFlutterRendering';
  static const String delay = 'delay';
  static const String delayMinutes = 'delayMinutes';
}
