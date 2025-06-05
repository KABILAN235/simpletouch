import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpletouch/airtouch_comms/airtouch_comms.dart';
import 'package:simpletouch/models/ac.dart';
import 'package:simpletouch/models/air_touch_device.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AirtouchComms comms = AirtouchComms();
  AirTouchDevice? device;

  bool _connectedToConsole = false;

  Future<void> getAndInitializeDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsString = prefs.getString('device');
    if (prefsString != null && prefsString.isNotEmpty) {
      try {
        final airTouchDevice = AirTouchDevice.fromString(prefsString);
        setState(() {
          device = airTouchDevice;
        });
        await comms.connectToConsole(airTouchDevice);
        setState(() {
          _connectedToConsole = true;
        });

        return;
      } catch (e) {
        debugPrint(e.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Failed to connect to device. Make sure you're connected to the same network as the AirTouch 5 console",
              ),
            ),
          );
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
      appBar: AppBar(
        elevation: 1,
        centerTitle: false,
        primary: true,
        actionsPadding: EdgeInsets.all(8.0),
        title: Text(device?.deviceName ?? "AirTouch 5"),
        actions: [
          FilledButton.tonalIcon(
            onPressed: () {},
            label: Icon(Icons.power_settings_new_outlined),
          ),
        ],
      ),
      body:
          _connectedToConsole
              ? Center(
                child: FutureBuilder(
                  future: comms.getACStatus(),
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (asyncSnapshot.hasError) {
                      return Text('Error: ${asyncSnapshot.error}');
                    }
                    if (!asyncSnapshot.hasData) {
                      return const Text('No data');
                    }
                    final acStatus = asyncSnapshot.data;
                    final currentAC = acStatus![0];

                    final off = currentAC.powerState == ACPowerState.off;

                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 10,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: SleekCircularSlider(
                                appearance: CircularSliderAppearance(
                                  size: MediaQuery.of(context).size.width * 0.7,
                                  customWidths: CustomSliderWidths(
                                    trackWidth: 24,
                                    progressBarWidth: 24,
                                    handlerSize: 12,
                                  ),
                                  customColors: CustomSliderColors(
                                    hideShadow: true,
                                    trackColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                    progressBarColor:
                                        Theme.of(context).colorScheme.primary,
                                    dotColor:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                min: 18,
                                max: 30,
                                initialValue: currentAC.setPoint ?? 18,
                                onChange: (value) {},
                                innerWidget:
                                    (val) => Center(
                                      child: Text(
                                        '${val.toInt()}°C',
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          Row(
                            spacing: 8.0,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: FilledButton.icon(
                                    onPressed: () {},
                                    label: Icon(Icons.ac_unit),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () {},
                                    label: Icon(Icons.sunny),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () {},
                                    label: Icon(Icons.air),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () {},
                                    label: Icon(Icons.dry),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
              : const Center(child: Text('Welcome to Home Screen!')),
    );
  }
}
