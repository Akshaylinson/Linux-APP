class BatteryInfo {
  const BatteryInfo({
    required this.present,
    this.percentage,
    this.status,
    this.health,
    this.powerNowW,
    this.timeToEmpty,
    this.timeToFull,
  });

  final bool present;
  final double? percentage;
  final String? status;
  final String? health;
  final double? powerNowW;
  final Duration? timeToEmpty;
  final Duration? timeToFull;
}
