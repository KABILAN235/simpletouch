class AirTouchDevice {
  final String ip;
  final String consoleId;
  final String airTouchId;
  final String deviceName;

  AirTouchDevice({
    required this.ip,
    required this.consoleId,
    required this.airTouchId,
    required this.deviceName,
  });

  @override
  String toString() {
    return 'AirTouchDevice(ip: $ip, consoleId: $consoleId, airTouchId: $airTouchId, deviceName: $deviceName)';
  }

  factory AirTouchDevice.fromString(String str) {
    final regex = RegExp(
      r'AirTouchDevice\(ip: (.*?), consoleId: (.*?), airTouchId: (.*?), deviceName: (.*?)\)',
    );
    final match = regex.firstMatch(str);
    if (match == null) {
      throw FormatException('Invalid string format for AirTouchDevice');
    }
    return AirTouchDevice(
      ip: match.group(1)!,
      consoleId: match.group(2)!,
      airTouchId: match.group(3)!,
      deviceName: match.group(4)!,
    );
  }
}
