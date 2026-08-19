class DiskInfo {
  const DiskInfo({
    required this.device,
    required this.model,
    required this.sizeBytes,
    required this.type,
    required this.interfaceType,
    this.temperatureC,
    this.mountPoints = const [],
    this.state,
  });

  final String device;
  final String model;
  final int sizeBytes;
  final String type;
  final String interfaceType;
  final double? temperatureC;
  final List<String> mountPoints;
  final String? state;
}
