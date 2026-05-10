import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_battery/flutter_battery_method_channel.dart';
import 'package:flutter_battery/src/battery_channel_contract.dart';
import 'package:flutter_battery/src/platform_capabilities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelFlutterBattery platform;
  const MethodChannel channel =
      MethodChannel(BatteryChannelNames.methodChannel);

  setUp(() {
    platform = MethodChannelFlutterBattery();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('getPlatformCapabilities returns empty on MissingPluginException',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        throw MissingPluginException('not found');
      },
    );
    final caps = await platform.getPlatformCapabilities();
    expect(caps.supportedFeatures, isEmpty);
  });

  test(
      'method_channel_maps_missing_plugin_to_unsupported_for_peer_optional_feature',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        throw MissingPluginException('not found');
      },
    );
    final caps = await platform.getPlatformCapabilities();
    expect(caps.isSupported(BatteryFeature.blePeerSync), false);
  });
}
