import 'package:flutter/material.dart';

import 'core/native_bridge.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/devices/devices_page.dart';
import 'features/settings/settings_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IotShellApp());
}

class IotShellApp extends StatefulWidget {
  const IotShellApp({super.key});

  @override
  State<IotShellApp> createState() => _IotShellAppState();
}

class _IotShellAppState extends State<IotShellApp> {
  late final NativeBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridge = NativeBridge();
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(seedColor: Colors.blueGrey);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'IoT Device Shell',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => DevicesPage(bridge: _bridge),
        '/dashboard': (context) => DashboardPage(bridge: _bridge),
        '/settings': (context) => SettingsPage(bridge: _bridge),
      },
    );
  }
}
