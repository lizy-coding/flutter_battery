import 'package:flutter/material.dart';
import 'package:flutter_battery_example/pages/dashboard_page.dart';
import 'package:flutter_battery_example/platform/example_platform_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard disables unavailable Android native demos',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DashboardPage(
          batteryLevel: 50,
          batteryInfo: null,
          batteryHealth: null,
          eventCount: 0,
          onRefresh: () async {},
          onBootstrap: () {},
          peerBatterySyncAvailability: const FeatureAvailability.unsupported(
            disabledLabel: '当前平台不可用',
            details: '蓝牙电量同步 仅支持 Android 原生桥接，当前平台为 macOS。',
          ),
          iotNativeControlsAvailability: const FeatureAvailability.unsupported(
            disabledLabel: '当前平台不可用',
            details: 'IoT native controls 仅支持 Android 原生桥接，当前平台为 macOS。',
          ),
          onOpenBatteryDetails: () {},
          onOpenLowBatteryAlerts: () {},
          onOpenPeerBatterySync: () {},
          onOpenIotControls: () {},
          onOpenEventLog: () {},
        ),
      ),
    );

    expect(find.text('flutter_battery overview'), findsOneWidget);
    expect(find.text('当前平台不可用'), findsNWidgets(2));
  });
}
