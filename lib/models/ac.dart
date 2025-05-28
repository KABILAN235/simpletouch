enum ACMode { cool, heat, dry, fan }

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
  final int power; // 0=off,1=on,3=turbo
  final ACMode mode;
  final int fanSpeed; // 0=auto,1–7
  final bool swing;
  final double? setPoint;
  final double? temperature;
  final int errorFlags;

  ACStatus({
    required this.index,
    required this.power,
    required this.mode,
    required this.fanSpeed,
    required this.swing,
    this.setPoint,
    this.temperature,
    required this.errorFlags,
  });

  @override
  String toString() =>
      'AC#$index: power=$power, mode=$mode, fan=$fanSpeed, '
      'swing=${swing ? "on" : "off"}, set=${setPoint ?? "-"}°C, '
      'temp=${temperature ?? "-"}°C, errors=0x${errorFlags.toRadixString(16)}';
}
