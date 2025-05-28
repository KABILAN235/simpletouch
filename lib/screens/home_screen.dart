import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpletouch/airtouch_comms/airtouch_comms.dart';
import 'package:simpletouch/models/air_touch_device.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AirtouchComms comms = AirtouchComms();

  Future<void> getAndInitializeDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsString = prefs.getString('device');
    if (prefsString != null && prefsString.isNotEmpty) {
      try {
        final device = AirTouchDevice.fromString(prefsString);
        await comms.connectToConsole(device);
        final status = await comms.getACStatus();
        debugPrint('AC Status: $status');
        return;
      } catch (e) {
        debugPrint(e.toString());
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/get_started');
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/get_started');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getAndInitializeDevice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome to Home Screen!')),
    );
  }
}
