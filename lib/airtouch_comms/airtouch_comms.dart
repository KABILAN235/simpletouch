import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simpletouch/models/air_touch_device.dart';

class AirtouchComms {


  /// Discovers AirTouch 5 devices on the local network.
///
/// Broadcasts a discovery message to port 49005 and listens for responses.
/// Returns a list of [AirTouchDevice] objects.
///
/// [timeout] specifies how long to listen for responses.
static Future<List<AirTouchDevice>> discoverAirTouchDevices({
  Duration timeout = const Duration(seconds: 5),
}) async {
  final devices = <AirTouchDevice>[];
  final discoveryMessageString = "::REQUEST-POLYAIRE-AIRTOUCH-DEVICE-INFO:;";
  final discoveryMessageBytes = utf8.encode(discoveryMessageString);
  const airTouchPort = 49005;
  // Using 255.255.255.255 for IPv4 broadcast.
  // Ensure your network configuration and firewall allow UDP broadcast on this port.
  final broadcastAddress = InternetAddress("255.255.255.255");

  RawDatagramSocket? socket;

  try {
    // Bind the socket to listen for responses on the AirTouch port.
    // InternetAddress.anyIPv4 listens on all available IPv4 interfaces.
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, airTouchPort);
    socket.broadcastEnabled = true;

    // Send the discovery message.
    socket.send(discoveryMessageBytes, broadcastAddress, airTouchPort);
    debugPrint("Sent AirTouch discovery broadcast to $broadcastAddress:$airTouchPort");

    // Listen for responses with a timeout.
    await for (RawSocketEvent event in socket.timeout(timeout, onTimeout: (sink) {
      debugPrint("Discovery timeout reached after ${timeout.inSeconds} seconds.");
      sink.close(); // This closes the stream, effectively ending the await for loop.
    })) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = socket.receive();
        if (datagram != null) {
          String responseMessage = utf8.decode(datagram.data);
          debugPrint("Received from ${datagram.address.address}:${datagram.port}: $responseMessage");

          // Message format: [IP],[ConsoleID],AirTouch5,[AirTouch ID],[Device Name]
          List<String> parts = responseMessage.split(',');
          if (parts.length == 5 && parts[2] == "AirTouch5") {
            final device = AirTouchDevice(
              ip: parts[0], // IP as reported in the message
              consoleId: parts[1],
              airTouchId: parts[3],
              deviceName: parts[4],
            );

            // Add device if not already discovered (based on IP or AirTouch ID)
            if (!devices.any((d) => d.ip == device.ip || d.airTouchId == device.airTouchId)) {
              devices.add(device);
              debugPrint("Discovered AirTouch 5 device: ${device.deviceName} at ${device.ip}");
            }
          } else {
            debugPrint("Received non-AirTouch5 or malformed message: $responseMessage");
          }
        }
      }
    }
  } on SocketException catch (e) {
    debugPrint("SocketException during discovery: $e");
    if (e.osError != null) {
        debugPrint("OS Error: ${e.osError!.message} (Code: ${e.osError!.errorCode})");
        // Common error codes:
        // 13 (EACCES): Permission denied (e.g. for broadcast)
        // 99 (EADDRNOTAVAIL): Address not available (port might be in use)
        // 101 (ENETUNREACH): Network is unreachable
    }
  } catch (e, s) {
    debugPrint("An unexpected error occurred during discovery: $e");
    debugPrint("Stack trace: $s");
  } finally {
    socket?.close();
    debugPrint("Discovery process finished. Socket closed. Found ${devices.length} devices.");
  }
  return devices;
}

}