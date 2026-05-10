import 'package:flutter/material.dart';
import 'package:flutter_battery/flutter_battery.dart';
import 'package:flutter_battery_example/pages/dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const unsupportedCaps = BatteryPlatformCapabilities(features: {
    BatteryFeature.batteryLevel: true,
    BatteryFeature.batteryInfo: true,
    BatteryFeature.batteryHealth: true,
    BatteryFeature.batteryLevelStream: true,
    BatteryFeature.batteryInfoStream: true,
    BatteryFeature.batteryHealthStream: true,
    BatteryFeature.lowBatteryMonitoring: true,
    BatteryFeature.nativeNotifications: false,
    BatteryFeature.scheduledNotifications: false,
    BatteryFeature.blePeerSync: false,
    BatteryFeature.iotExampleBridge: false,
  });

  testWidgets('dashboard_disables_features_from_capability_object',
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
          capabilities: unsupportedCaps,
          onOpenBatteryDetails: () {},
          onOpenLowBatteryAlerts: () {},
          onOpenPeerBatterySync: () {},
          onOpenIotControls: () {},
          onOpenEventLog: () {},
        ),
      ),
    );

    expect(find.text('flutter_battery overview'), findsOneWidget);
    expect(find.text('当前平台不支持'), findsNWidgets(2));
  });
}
