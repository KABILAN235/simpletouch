
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
}