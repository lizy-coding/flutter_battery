import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_assistant/flutter_assistant.dart';
import 'package:flutter_assistant/flutter_assistant_platform_interface.dart';
import 'package:flutter_assistant/flutter_assistant_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAssistantPlatform
    with MockPlatformInterfaceMixin
    implements FlutterAssistantPlatform {

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
}

void main() {
  final FlutterAssistantPlatform initialPlatform = FlutterAssistantPlatform.instance;

  test('$MethodChannelFlutterAssistant is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAssistant>());
  });

  test('getPlatformVersion', () async {
    FlutterAssistant flutterAssistantPlugin = FlutterAssistant();
    MockFlutterAssistantPlatform fakePlatform = MockFlutterAssistantPlatform();
    FlutterAssistantPlatform.instance = fakePlatform;

    expect(await flutterAssistantPlugin.getPlatformVersion(), '42');
  });
}
