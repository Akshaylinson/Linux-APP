class SystemInfo {
  const SystemInfo({
    required this.osPrettyName,
    required this.kernelVersion,
    required this.architecture,
    required this.hostname,
    required this.desktopEnvironment,
    required this.uptime,
    required this.uptimeSeconds,
  });

  final String osPrettyName;
  final String kernelVersion;
  final String architecture;
  final String hostname;
  final String desktopEnvironment;
  final String uptime;
  final int uptimeSeconds;
}
