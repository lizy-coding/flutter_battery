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
    return Future.value(true);
  }
  
  @override
  Future<bool?> showNotification({required String title, required String message}) {
    return Future.value(true);
  }

  @override
  Future<int?> getBatteryLevel() {
    return Future.value(75);
  }

  @override
  Future<bool?> setBatteryLevelThreshold({required int threshold, required String title, required String message, int intervalMinutes = 15, bool useFlutterRendering = false}) {
    return Future.value(true);
  }

  @override
  void setLowBatteryCallback(Function(int batteryLevel) callback) {
    // no-op for testing
  }

  @override
  Future<bool?> stopBatteryMonitoring() {
    return Future.value(true);
  }
}

void main() {
  final FlutterBatteryPlatform initialPlatform = FlutterBatteryPlatform.instance;

  test('Default platform is FlutterBatteryPlatform', () {
    expect(initialPlatform, isInstanceOf<FlutterBatteryPlatform>());
  });

  test('getPlatformVersion returns from mock', () async {
    final fakePlatform = MockFlutterBatteryPlatform();
    FlutterBatteryPlatform.instance = fakePlatform;
    expect(await FlutterBatteryPlatform.instance.getPlatformVersion(), '42');
  });

  test('getBatteryLevel returns from mock', () async {
    expect(await FlutterBatteryPlatform.instance.getBatteryLevel(), 75);
  });

  test('scheduleNotification returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.scheduleNotification(
        title: 'test', message: 'hello', delayMinutes: 5
      ),
      true
    );
  });

  test('showNotification returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.showNotification(
        title: 'test', message: 'world'
      ),
      true
    );
  });

  test('setBatteryLevelThreshold returns true', () async {
    expect(
      await FlutterBatteryPlatform.instance.setBatteryLevelThreshold(
        threshold: 30, title: 'low', message: 'charging soon'
      ),
      true
    );
  });

  test('stopBatteryMonitoring returns true', () async {
    expect(await FlutterBatteryPlatform.instance.stopBatteryMonitoring(), true);
  });
}
