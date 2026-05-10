import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ExampleFeature {
  peerBatterySync,
  iotNativeControls,
}

class FeatureAvailability {
  const FeatureAvailability.supported()
      : isSupported = true,
        disabledLabel = '',
        details = '';

  const FeatureAvailability.unsupported({
    required this.disabledLabel,
    required this.details,
  }) : isSupported = false;

  final bool isSupported;
  final String disabledLabel;
  final String details;
}

class UnsupportedPlatformFeatureException implements Exception {
  UnsupportedPlatformFeatureException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class ExamplePlatformAdapter {
  const ExamplePlatformAdapter();

  String get platformName;

  FeatureAvailability availabilityFor(ExampleFeature feature);

  Stream<Object?> get iotEvents;

  Future<void> invokeIotMethod(String method, [Object? arguments]);

  static ExamplePlatformAdapter current() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidExamplePlatformAdapter();
    }
    return UnsupportedExamplePlatformAdapter(
        platformName: defaultTargetPlatform.name);
  }
}

class AndroidExamplePlatformAdapter extends ExamplePlatformAdapter {
  const AndroidExamplePlatformAdapter();

  static const MethodChannel _iotMethod = MethodChannel('iot/native');
  static const EventChannel _iotEvent = EventChannel('iot/stream');

  @override
  String get platformName => 'android';

  @override
  FeatureAvailability availabilityFor(ExampleFeature feature) {
    return const FeatureAvailability.supported();
  }

  @override
  Stream<Object?> get iotEvents => _iotEvent.receiveBroadcastStream();

  @override
  Future<void> invokeIotMethod(String method, [Object? arguments]) {
    return _iotMethod.invokeMethod<void>(method, arguments);
  }
}

class UnsupportedExamplePlatformAdapter extends ExamplePlatformAdapter {
  const UnsupportedExamplePlatformAdapter({required this.platformName});

  @override
  final String platformName;

  @override
  FeatureAvailability availabilityFor(ExampleFeature feature) {
    return FeatureAvailability.unsupported(
      disabledLabel: '当前平台不可用',
      details: '${_featureName(feature)} 仅支持 Android 原生桥接，当前平台为 $platformName。',
    );
  }

  @override
  Stream<Object?> get iotEvents {
    return Stream<Object?>.value(
      'IoT native controls are Android-only. Current platform: $platformName.',
    );
  }

  @override
  Future<void> invokeIotMethod(String method, [Object? arguments]) {
    throw UnsupportedPlatformFeatureException(
      availabilityFor(ExampleFeature.iotNativeControls).details,
    );
  }

  String _featureName(ExampleFeature feature) {
    switch (feature) {
      case ExampleFeature.peerBatterySync:
        return '蓝牙电量同步';
      case ExampleFeature.iotNativeControls:
        return 'IoT native controls';
    }
  }
}
