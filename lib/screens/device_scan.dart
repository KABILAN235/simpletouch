import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simpletouch/airtouch_comms/airtouch_comms.dart';
import 'package:simpletouch/models/air_touch_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  bool _searching = false;
  bool _successful = false;
  String? _errorMessage;
  List<AirTouchDevice>? _availableDevices;

  Future<void> _onSearch() async {
    setState(() {
      _searching = true;
      _errorMessage = null;
      _successful = false;
      _availableDevices = null;
    });
    try {
      final devices = await AirtouchComms.discoverAirTouchDevices(
        timeout: Duration(seconds: 10),
      );

      setState(() {
        _availableDevices = devices;
        _searching = false;
        _successful = true;
      });
    } catch (e) {
      setState(() {
        _successful = false;
        _availableDevices = [];
        _searching = false;
        _errorMessage = "Failed to find devices. Please try again.";
      });
    }
  }

  Future<void> onSelect(AirTouchDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device', device.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Device')),
      body:
          _successful &&
                  _availableDevices != null &&
                  _availableDevices!.isNotEmpty
              ? ListView.builder(
                shrinkWrap: true,
                itemCount: _availableDevices!.length,
                itemBuilder: (context, index) {
                  final device = _availableDevices![index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.devices),
                      title: Text(device.deviceName),
                      subtitle: Text("Address : ${device.ip}"),
                      onTap: () async {
                        await onSelect(device);
                        if (mounted) {
                          Navigator.of(context).pushReplacementNamed('/home');
                        }
                      },
                    ),
                  );
                },
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _searching
                        ? Icon(Icons.wifi, size: 64, color: Colors.grey)
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .fadeOut(duration: Duration(milliseconds: 1000))
                            .fadeIn(duration: Duration(milliseconds: 1000))
                        : Icon(Icons.wifi, size: 64, color: Colors.grey),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(
                        child: Text(
                          _searching
                              ? "Searching for AirTouch 5 Consoles on your network. Hold Tight!"
                              : "Make sure you're on the same network as the AirTouch 5 console when searching",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _onSearch();
        },
        label: const Text("Search for Devices"),
        icon: const Icon(Icons.search),
      ),
    );
  }
}
