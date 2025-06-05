import 'package:flutter/material.dart';
import 'package:simpletouch/screens/device_scan.dart';
import 'package:simpletouch/screens/get_started.dart';
import 'package:simpletouch/screens/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SimpleTouch',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orangeAccent,
          brightness: Brightness.light,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orangeAccent,
          brightness: Brightness.dark,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      routes: {
        "/get_started": (ctx) => GetStartedScreen(),
        "/device_scan": (ctx) => DeviceScanScreen(),
        "/home": (ctx) => HomeScreen(),
      },
      initialRoute: "/get_started",
    );
  }
}
