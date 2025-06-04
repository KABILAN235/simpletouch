import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:simpletouch/models/ac.dart';
import 'package:simpletouch/models/air_touch_device.dart';
import 'package:simpletouch/models/zone.dart';

class AirtouchComms {
  Socket? _socket; // Added to store the socket instance

  static const _header = [0x55, 0x55, 0x55, 0xAA];
  static const _controlType = 0xC0;
  // static const _extendedType = 0x1F;
  static const _addrControl = [0x80, 0xB0];
  // static const _addrExtended = [0x90, 0xB0];
  static const _tcpPort = 9005;

  /// Discovers AirTouch 5 devices on the local network.
  ///
  /// Broadcasts a discovery message to port 49005 and listens for responses.
  /// Returns a list of AirtouchDevice
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
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        airTouchPort,
      );
      socket.broadcastEnabled = true;

      // Send the discovery message.
      socket.send(discoveryMessageBytes, broadcastAddress, airTouchPort);
      debugPrint(
        "Sent AirTouch discovery broadcast to $broadcastAddress:$airTouchPort",
      );

      // Listen for responses with a timeout.
      await for (RawSocketEvent event in socket.timeout(
        timeout,
        onTimeout: (sink) {
          debugPrint(
            "Discovery timeout reached after ${timeout.inSeconds} seconds.",
          );
          sink.close(); // This closes the stream, effectively ending the await for loop.
        },
      )) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = socket.receive();
          if (datagram != null) {
            String responseMessage = utf8.decode(datagram.data);
            debugPrint(
              "Received from ${datagram.address.address}:${datagram.port}: $responseMessage",
            );

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
              if (!devices.any(
                (d) => d.ip == device.ip || d.airTouchId == device.airTouchId,
              )) {
                devices.add(device);
                debugPrint(
                  "Discovered AirTouch 5 device: ${device.deviceName} at ${device.ip}",
                );
              }
            } else {
              debugPrint(
                "Received non-AirTouch5 or malformed message: $responseMessage",
              );
            }
          }
        }
      }
    } on SocketException catch (e) {
      debugPrint("SocketException during discovery: $e");
      if (e.osError != null) {
        debugPrint(
          "OS Error: ${e.osError!.message} (Code: ${e.osError!.errorCode})",
        );
        // Common error codes:
        // 13 (EACCES): Permission denied (e.g. for broadcast)
        // 99 (EADDRNOTAVAIL): Address not available (port might be in use)
        // 101 (ENETUNREACH): Network is unreachable
      }
      rethrow;
    } catch (e, s) {
      debugPrint("An unexpected error occurred during discovery: $e");
      debugPrint("Stack trace: $s");
      rethrow;
    } finally {
      socket?.close();
      debugPrint(
        "Discovery process finished. Socket closed. Found ${devices.length} devices.",
      );
    }
    return devices;
  }

  /// Connects to the master console of the given device.
  Future<void> connectToConsole(AirTouchDevice device) async {
    if (_socket != null) {
      await _socket?.close(); // Close existing socket if any
      _socket = null;
      debugPrint("Closed existing AirTouch console connection.");
    }
    try {
      _socket = await Socket.connect(device.ip, _tcpPort);
      debugPrint("Connected to AirTouch console at ${device.ip}:$_tcpPort");
    } catch (e) {
      debugPrint("Failed to connect to AirTouch console: $e");
      _socket = null; // Ensure socket is null on failure
      rethrow; // Rethrow the exception to be handled by the caller
    }
  }

  /// Disconnects from the master console.
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    debugPrint("Disconnected from AirTouch console.");
  }

  /// Builds a packet according to Section 3 of the protocol.
  static Uint8List _buildPacket({
    required List<int> address,
    required int messageId,
    required int messageType,
    required Uint8List data,
  }) {
    final length = data.length;
    final lengthBytes = [(length >> 8) & 0xFF, length & 0xFF];
    final payload = BytesBuilder();
    payload.add(_header);
    payload.add(address);
    payload.addByte(messageId & 0xFF);
    payload.addByte(messageType & 0xFF);
    payload.add(lengthBytes);
    payload.add(data);
    // compute CRC16-MODBUS over everything except header, but including address → data
    final crcInput = Uint8List.fromList([
      ...address,
      messageId & 0xFF,
      messageType & 0xFF,
      ...lengthBytes,
      ...data,
    ]);
    final crc = _crc16Modbus(crcInput);
    payload.addByte((crc >> 8) & 0xFF); // high byte
    payload.addByte(crc & 0xFF); // low byte
    return payload.toBytes();
  }

  /// CRC16-MODBUS (poly 0x8005, init 0xFFFF)
  static int _crc16Modbus(Uint8List bytes) {
    int crc = 0xFFFF;
    for (var b in bytes) {
      crc ^= b;
      for (int i = 0; i < 8; i++) {
        final lsb = crc & 1;
        crc >>= 1;
        if (lsb != 0) crc ^= 0xA001;
      }
    }
    return crc & 0xFFFF;
  }

  /// Send a raw packet and await the next response as Uint8List.
  Future<Uint8List> _sendPacketAndReceive(
    Uint8List packet, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_socket == null) {
      throw StateError('Socket is not connected. Call connectToConsole first.');
    }
    _socket!.add(packet);
    await _socket!.flush();
    // read until header found
    final completer = Completer<Uint8List>();
    final buffer = BytesBuilder();
    late StreamSubscription<Uint8List> sub;
    sub = _socket!.listen(
      (data) {
        buffer.add(data);
        final bytes = buffer.toBytes();
        // look for 0x55 0x55 0x55 0xAA
        for (int i = 0; i + 4 <= bytes.length; i++) {
          if (bytes[i] == 0x55 &&
              bytes[i + 1] == 0x55 &&
              bytes[i + 2] == 0x55 &&
              bytes[i + 3] == 0xAA) {
            // assume rest is full packet → hand off
            if (!completer.isCompleted) {
              completer.complete(bytes.sublist(i));
            }
            sub.cancel();
            return;
          }
        }
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        sub.cancel();
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            StateError(
              'Socket closed unexpectedly while waiting for response.',
            ),
          );
        }
      },
      cancelOnError: true,
    );
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        sub.cancel();
        if (!completer.isCompleted) {
          // Ensure buffer is cleared or handled if needed
          buffer.clear();
          throw TimeoutException('No response within $timeout');
        }
        // if completer already completed (e.g. with an error), return that future
        return completer.future;
      },
    );
  }

  /// Request Zone Status (sub-type 0x21).
  Future<List<ZoneStatus>> getZoneStatus() async {
    if (_socket == null) {
      throw StateError('Socket is not connected. Call connectToConsole first.');
    }
    // data: subtype byte + padding (8 bytes total header for C0)
    final data = Uint8List.fromList([
      0x21,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
    ]);
    final packet = _buildPacket(
      address: _addrControl,
      messageId: 0x01,
      messageType: _controlType,
      data: data,
    );
    final response = await _sendPacketAndReceive(packet);
    // parse repeat count at byte offset 10 (after header[4]+addr2+id+type+len2+subtype etc)
    final repeatCount = response[4 + 2 + 1 + 1 + 2 + 7];
    final list = <ZoneStatus>[];
    int offset = 4 + 2 + 1 + 1 + 2 + 8;
    for (int i = 0; i < repeatCount; i++) {
      final b1 = response[offset++];
      final power = (b1 & 0xC0) >> 6;
      final index = b1 & 0x3F;
      final b2 = response[offset++];
      final isTemp = (b2 & 0x80) != 0;
      final openPct = b2 & 0x7F;
      final setPtRaw = response[offset++];
      final setPoint = setPtRaw == 0xFF ? null : (setPtRaw + 100) / 10;
      final hasSensor = (response[offset++] & 0x80) != 0;
      final tempRaw = (response[offset++] & 0x0F) << 8 | response[offset++];
      final temperature = hasSensor ? (tempRaw - 500) / 10 : null;
      final flags = response[offset++];
      final spill = (flags & 0x04) != 0;
      final lowBatt = (flags & 0x01) != 0;
      offset += 2; // skip unused
      list.add(
        ZoneStatus(
          index: index,
          power: power,
          controlMethodIsTemp: isTemp,
          openPercentage: openPct,
          setPoint: setPoint,
          temperature: temperature,
          spill: spill,
          lowBattery: lowBatt,
        ),
      );
    }
    return list;
  }

  /// Control a single zone (sub-type 0x20).
  /// [action] is one of: decrease, increase, setPct, setTemp, toggleOnOff, off, on, turbo.
  Future<void> controlZone({
    required int zoneIndex,
    int? percentage, // 0–100 if using percentage
    double? temperature, // in °C if using temperature
    ZoneAction action = ZoneAction.keep,
  }) async {
    if (_socket == null) {
      throw StateError('Socket is not connected. Call connectToConsole first.');
    }
    // build the 4-byte repeat block
    int byte1 = (zoneIndex & 0x0F);
    int byte2 = 0;
    int byte3 = 0;
    switch (action) {
      case ZoneAction.decrease:
        byte2 = 0x40;
        break; // 010xxxxx
      case ZoneAction.increase:
        byte2 = 0x60;
        break; // 011xxxxx
      case ZoneAction.setPct:
        byte2 = 0x90; // 100xxxxx
        byte3 = percentage!.clamp(0, 100);
        break;
      case ZoneAction.setTemp:
        byte2 = 0xB0; // 101xxxxx
        byte3 = ((temperature! * 10) - 100).toInt();
        break;
      case ZoneAction.off:
        byte2 = 0x02;
        break;
      case ZoneAction.on:
        byte2 = 0x03;
        break;
      case ZoneAction.turbo:
        byte2 = 0x05;
        break;
      case ZoneAction.toggle:
        byte2 = 0x01;
        break;
      case ZoneAction.keep:
        // no-op
        break;
    }
    final repeat = [byte1, byte2, byte3, 0x00];
    final data =
        BytesBuilder()
          ..add([0x20, 0x00, 0x00, 0x00, 0x00, repeat.length, 0x00, 0x01])
          ..add(repeat);
    final packet = _buildPacket(
      address: _addrControl,
      messageId: 0x02,
      messageType: _controlType,
      data: data.toBytes(),
    );
    await _sendPacketAndReceive(packet);
  }

  /// Request split-system (AC) status (sub-type 0x23).
  Future<List<ACStatus>> getACStatus() async {
    if (_socket == null) {
      throw StateError('Socket is not connected. Call connectToConsole first.');
    }
    // subtype 0x23 + 7 padding bytes
    final data = Uint8List.fromList([0x23, 0, 0, 0, 0, 0, 0, 0]);
    final packet = _buildPacket(
      address: _addrControl,
      messageId: 0x01,
      messageType: _controlType,
      data: data,
    );
    final resp = await _sendPacketAndReceive(
      packet,
      timeout: Duration(seconds: 15),
    );

    final list = ACStatus.parseACStatusMessage(resp);

    return list;
  }

  /// Control an AC unit (sub-type 0x22).
  Future<void> controlAC({
    required int acIndex,
    ACAction action = ACAction.setOff,
    double? temperature, // only for setPoint
    int? fanSpeed, // 0–7
    bool? swing, // true=on, false=off
  }) async {
    if (_socket == null) {
      throw StateError('Socket is not connected. Call connectToConsole first.');
    }
    final repeat = <int>[];

    // Byte0 = index
    repeat.add(acIndex & 0x3F);

    // Byte1 = action code
    switch (action) {
      case ACAction.setOff:
        repeat.add(0x00);
        break;
      case ACAction.setOn:
        repeat.add(0x01);
        break;
      case ACAction.setCool:
        repeat.add(0x10);
        break;
      case ACAction.setHeat:
        repeat.add(0x11);
        break;
      case ACAction.setDry:
        repeat.add(0x12);
        break;
      case ACAction.setFan:
        repeat.add(0x13);
        break;
      case ACAction.setTemp:
        repeat.add(0x90);
        break;
      case ACAction.fanSpeed:
        repeat.add(0xA0);
        break;
      case ACAction.swing:
        repeat.add(0xB0);
        break;
    }

    // Byte2 = value
    int val = 0;
    if (action == ACAction.setTemp && temperature != null) {
      val = ((temperature * 10) - 100).toInt() & 0xFF;
    } else if (action == ACAction.fanSpeed && fanSpeed != null) {
      val = fanSpeed & 0x07;
    } else if (action == ACAction.swing && swing != null) {
      val = swing ? 1 : 0;
    }
    repeat.add(val);

    // Byte3 = reserved
    repeat.add(0x00);

    // Build data: subtype, pad×3, repeat count, pad, repeats…
    final data =
        BytesBuilder()
          ..add([0x22, 0x00, 0x00, 0x00])
          ..addByte(repeat.length) // count = 4
          ..addByte(0x00) // padding
          ..add(repeat);

    final packet = _buildPacket(
      address: _addrControl,
      messageId: 0x12,
      messageType: _controlType,
      data: data.toBytes(),
    );

    await _sendPacketAndReceive(packet);
  }
}
