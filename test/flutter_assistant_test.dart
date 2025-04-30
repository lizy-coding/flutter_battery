import 'package:flutter_battery/flutter_battery_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterBatteryPlatform
    with MockPlatformInterfaceMixin
    implements FlutterBatteryPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
  
  @override
  Future<bool?> scheduleNotification({required String title, required String message, int delayMinutes = 1}) {
    // TODO: implement scheduleNotification
    throw UnimplementedError();
  }
  
  @override
  Future<bool?> showNotification({required String title, required String message}) {
    // TODO: implement showNotification
    throw UnimplementedError();
  }

  @override
  Future<int?> getBatteryLevel() {
    // TODO: implement getBatteryLevel
    throw UnimplementedError();
  }
}

void main() {
  final FlutterBatteryPlatform initialPlatform = FlutterBatteryPlatform.instance;

  test('$MockFlutterBatteryPlatform is the default instance', () {
    expect(initialPlatform, isInstanceOf<FlutterBatteryPlatform>());
  });

  test('getPlatformVersion', () async {
    MockFlutterBatteryPlatform fakePlatform = MockFlutterBatteryPlatform();
    FlutterBatteryPlatform.instance = fakePlatform;

  });
}
