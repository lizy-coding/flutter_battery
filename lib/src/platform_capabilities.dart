enum BatteryFeature {
  batteryLevel,
  batteryInfo,
  batteryHealth,
  batteryLevelStream,
  batteryInfoStream,
  batteryHealthStream,
  lowBatteryMonitoring,
  nativeNotifications,
  scheduledNotifications,
  blePeerSync,
  iotExampleBridge,
}

class BatteryPlatformCapabilities {
  final Map<BatteryFeature, bool> features;

  const BatteryPlatformCapabilities({required this.features});

  bool isSupported(BatteryFeature feature) => features[feature] ?? false;

  List<BatteryFeature> get supportedFeatures =>
      features.entries.where((e) => e.value).map((e) => e.key).toList();

  List<BatteryFeature> get unsupportedFeatures =>
      features.entries.where((e) => !e.value).map((e) => e.key).toList();

  factory BatteryPlatformCapabilities.fromMap(Map<String, dynamic> map) {
    final features = <BatteryFeature, bool>{};
    for (final entry in map.entries) {
      final feature = _featureFromString(entry.key);
      if (feature != null && entry.value is bool) {
        features[feature] = entry.value as bool;
      }
    }
    return BatteryPlatformCapabilities(features: features);
  }

  Map<String, dynamic> toMap() {
    return {for (final e in features.entries) _featureToString(e.key): e.value};
  }

  static BatteryFeature? _featureFromString(String name) {
    switch (name) {
      case 'batteryLevel':
        return BatteryFeature.batteryLevel;
      case 'batteryInfo':
        return BatteryFeature.batteryInfo;
      case 'batteryHealth':
        return BatteryFeature.batteryHealth;
      case 'batteryLevelStream':
        return BatteryFeature.batteryLevelStream;
      case 'batteryInfoStream':
        return BatteryFeature.batteryInfoStream;
      case 'batteryHealthStream':
        return BatteryFeature.batteryHealthStream;
      case 'lowBatteryMonitoring':
        return BatteryFeature.lowBatteryMonitoring;
      case 'nativeNotifications':
        return BatteryFeature.nativeNotifications;
      case 'scheduledNotifications':
        return BatteryFeature.scheduledNotifications;
      case 'blePeerSync':
        return BatteryFeature.blePeerSync;
      case 'iotExampleBridge':
        return BatteryFeature.iotExampleBridge;
      default:
        return null;
    }
  }

  static String _featureToString(BatteryFeature feature) {
    switch (feature) {
      case BatteryFeature.batteryLevel:
        return 'batteryLevel';
      case BatteryFeature.batteryInfo:
        return 'batteryInfo';
      case BatteryFeature.batteryHealth:
        return 'batteryHealth';
      case BatteryFeature.batteryLevelStream:
        return 'batteryLevelStream';
      case BatteryFeature.batteryInfoStream:
        return 'batteryInfoStream';
      case BatteryFeature.batteryHealthStream:
        return 'batteryHealthStream';
      case BatteryFeature.lowBatteryMonitoring:
        return 'lowBatteryMonitoring';
      case BatteryFeature.nativeNotifications:
        return 'nativeNotifications';
      case BatteryFeature.scheduledNotifications:
        return 'scheduledNotifications';
      case BatteryFeature.blePeerSync:
        return 'blePeerSync';
      case BatteryFeature.iotExampleBridge:
        return 'iotExampleBridge';
    }
  }
}

class UnsupportedBatteryFeatureException implements Exception {
  final BatteryFeature feature;
  final String message;

  UnsupportedBatteryFeatureException(this.feature, [this.message = '']);

  @override
  String toString() => message.isNotEmpty
      ? 'UnsupportedBatteryFeatureException($feature): $message'
      : 'UnsupportedBatteryFeatureException($feature)';
}
