import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scanForDevicesLocally();
  }

  Future<void> _scanForDevicesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final device = prefs.getString('device');

    if (device != null && device.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _loading
              ? CircularProgressIndicator()
              : const Center(child: FlutterLogo(size: 150)),
      bottomNavigationBar:
          _loading
              ? Container()
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/device_scan');
                    },
                    child: const Text('Get Started'),
                  ),
                ),
              ),
    );
  }
}
