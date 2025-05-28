enum ZoneAction {
  decrease,
  increase,
  setPct,
  setTemp,
  off,
  on,
  toggle,
  turbo,
  keep,
}

class ZoneStatus {
  final int index;
  final int power; // 0=off,1=on,3=turbo
  final bool controlMethodIsTemp;
  final int openPercentage;
  final double? setPoint;
  final double? temperature;
  final bool spill;
  final bool lowBattery;
  ZoneStatus({
    required this.index,
    required this.power,
    required this.controlMethodIsTemp,
    required this.openPercentage,
    this.setPoint,
    this.temperature,
    required this.spill,
    required this.lowBattery,
  });
  @override
  String toString() =>
      'Zone#$index: power=$power, mode=${controlMethodIsTemp ? "°C" : "%"}, '
      'open=$openPercentage%, set=${setPoint ?? "-"}, temp=${temperature ?? "-"}';
}
