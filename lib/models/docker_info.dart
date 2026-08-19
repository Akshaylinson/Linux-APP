class DockerContainerInfo {
  const DockerContainerInfo({
    required this.name,
    required this.image,
    required this.status,
    required this.cpuPercent,
    required this.memoryUsage,
    required this.ports,
  });

  final String name;
  final String image;
  final String status;
  final double cpuPercent;
  final String memoryUsage;
  final String ports;
}

class DockerInfo {
  const DockerInfo({
    required this.state,
    required this.containersTotal,
    required this.containersRunning,
    required this.imagesTotal,
    required this.volumesTotal,
    required this.diskUsageBytes,
    required this.containers,
    this.buildCacheBytes,
    this.permissionDenied = false,
    this.installed = true,
  });

  final String state;
  final int containersTotal;
  final int containersRunning;
  final int imagesTotal;
  final int volumesTotal;
  final int diskUsageBytes;
  final int? buildCacheBytes;
  final List<DockerContainerInfo> containers;
  final bool permissionDenied;
  final bool installed;
}
