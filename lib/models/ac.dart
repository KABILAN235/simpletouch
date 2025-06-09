import 'dart:typed_data';

import 'package:flutter/material.dart';

enum ACMode { auto, heat, dry, fan, cool, autoHeat, autoCool }

final acModeToIconMap = {
  ACMode.auto: Icons.autorenew,
  ACMode.heat: Icons.wb_sunny,
  ACMode.dry: Icons.grain,
  ACMode.fan: Icons.air, // or Icons.air
  ACMode.cool: Icons.ac_unit,
  ACMode.autoHeat: Icons.thermostat_auto,
  ACMode.autoCool: Icons.snowing,
};

enum ACPowerState { off, on, awayOff, awayOn, sleep }

enum ACFanSpeed {
  auto,
  quiet,
  low,
  med,
  high,
  powerful,
  turbo,
  intelligentAuto,
}

enum ACAction {
  setOff,
  setOn,
  setCool,
  setHeat,
  setDry,
  setFan,
  setTemp,
  fanSpeed,
  swing,
}

class ACStatus {
  final int index;
  final ACPowerState powerState;
  final ACMode mode;
  final bool? turbo;
  final bool? bypass;
  final bool? spill;
  final bool? timerStatus;
  final ACFanSpeed fanSpeed;
  final double? setPoint;
  final double? temperature;
  final int errorFlags;

  ACStatus({
    required this.index,
    required this.powerState,
    required this.mode,
    required this.fanSpeed,
    this.turbo,
    this.bypass,
    this.spill,
    this.timerStatus,
    this.setPoint,
    this.temperature,
    required this.errorFlags,
  });

  static Future<List<ACStatus>?> parseACStatusMessage(
    Uint8List statusMessage,
  ) async {
    // Check if this is an ACStatus Message. Return null if it's not
    if (statusMessage[10] != 0x23) return null;
    // parse repeat count at offset = header(4)+addr2+id+type+len2+subtype(1)+padding(7) = byte 16
    final repeatCount = statusMessage[17];
    final list = <ACStatus>[];
    int offset = 18;

    for (int i = 0; i < repeatCount; i++) {
      final bytes = statusMessage.sublist(offset, offset + 8);
      offset += 8;
      // Byte 0: index (lower 6 bits), power (top 2): 0=off,1=on,3=turbo
      final b0 = bytes[0];
      final index = b0 & 0xF;
      final power = (b0 & 0xF0) >> 4;
      // Byte 1: mode: 0=cool,1=heat,2=dry,3=fan
      final mode = (bytes[1] & 0xF0) >> 4;
      // Byte 2: fan speed 0–7 (0=auto)
      final fanSpeed = bytes[1] & 0xF;

      // Byte 3: set-point raw: (value+100)/10
      final spRaw = bytes[2];
      final setPoint = (spRaw == 0xFF) ? null : (spRaw + 100) / 10.0;

      // Byte 4: swing active flag (bit7)
      final statusByte = bytes[3];
      final turbo = (statusByte & 0x8) >> 3;
      final bypass = (statusByte & 0x4) >> 2;
      final spill = (statusByte & 0x2) >> 1;
      final timerStatus = (statusByte & 0x1);

      // Byte 5: current temp raw/10 (0xFF=none)
      final tRaw = ((bytes[4] & 0x7) << 8) | bytes[5];

      final temperature =
          (tRaw == 0xFF) ? null : (tRaw - 500) / 10.0; // example bias
      // Byte 6: error flags
      final errors = (bytes[6] << 8) | bytes[7];
      // Byte 7: reserved
      list.add(
        ACStatus(
          index: index,
          powerState: ACPowerState.values[power],
          mode: ACMode.values[mode],
          fanSpeed: ACFanSpeed.values[fanSpeed],
          setPoint: setPoint,
          temperature: temperature,
          errorFlags: errors,
          turbo: turbo == 1,
          bypass: bypass == 1,
          spill: spill == 1,
          timerStatus: timerStatus == 1,
        ),
      );
    }

    return list;
  }

  @override
  String toString() =>
      'AC#$index: power=$powerState, mode=$mode, fan=$fanSpeed, turbo=${turbo ?? "-"}, bypass=${bypass ?? "-"}, spill=${spill ?? "-"}, timerStatus=${timerStatus ?? "-"}, set=${setPoint ?? "-"}°C, temp=${temperature ?? "-"}°C, errors=0x${errorFlags.toRadixString(16)}';
}
