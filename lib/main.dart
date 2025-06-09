import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simpletouch/airtouch_comms/airtouch_comms.dart';
import 'package:simpletouch/screens/device_scan.dart';
import 'package:simpletouch/screens/get_started.dart';
import 'package:simpletouch/screens/home_screen/home_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => AirtouchComms(),
    child: const MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AirtouchComms>(
      builder:
          (ctx, comms, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SimpleTouch',
            theme: comms.lightTheme,
            darkTheme: comms.darkTheme,
            themeMode: ThemeMode.system,
            routes: {
              "/get_started": (ctx) => GetStartedScreen(),
              "/device_scan": (ctx) => DeviceScanScreen(),
              "/home": (ctx) => HomeScreen(),
            },
            initialRoute: "/get_started",
          ),
    );
  }
}
