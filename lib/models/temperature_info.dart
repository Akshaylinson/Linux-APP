class TemperatureInfo {
  const TemperatureInfo({
    required this.label,
    required this.temperatureC,
    this.highC,
    this.criticalC,
    this.source,
  });

  final String label;
  final double? temperatureC;
  final double? highC;
  final double? criticalC;
  final String? source;
}
