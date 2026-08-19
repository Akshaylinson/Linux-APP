import '../../../models/docker_info.dart';

class DockerParser {
  List<DockerContainerInfo> parseContainers(String output) {
    final containers = <DockerContainerInfo>[];
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('\t');
      if (parts.length < 5) continue;
      containers.add(
        DockerContainerInfo(
          name: parts[0],
          image: parts[1],
          status: parts[2],
          cpuPercent: double.tryParse(parts[3].replaceAll('%', '')) ?? 0,
          memoryUsage: parts[4],
          ports: parts.length > 5 ? parts.sublist(5).join('\t') : '',
        ),
      );
    }
    return containers;
  }

  DockerInfo parseSnapshot({
    required String infoOutput,
    required String psOutput,
    required String imagesOutput,
    required String volumesOutput,
    required String systemDfOutput,
    required String statsOutput,
    bool installed = true,
    bool permissionDenied = false,
  }) {
    final containers = parseContainers(statsOutput);
    final running = psOutput
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
    final images = imagesOutput
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
    final volumes = volumesOutput
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;

    return DockerInfo(
      state: permissionDenied
          ? 'Docker Permission Denied'
          : installed
              ? 'Docker Detected'
              : 'Docker Not Installed',
      containersTotal: psOutput.split('\n').where((line) => line.trim().isNotEmpty).length,
      containersRunning: running,
      imagesTotal: images,
      volumesTotal: volumes,
      diskUsageBytes: _parseBytes(systemDfOutput),
      containers: containers,
      buildCacheBytes: null,
      permissionDenied: permissionDenied,
      installed: installed,
    );
  }

  int _parseBytes(String input) {
    final match = RegExp(r'([\d.]+)\s*([KMGTP])?B', caseSensitive: false)
        .firstMatch(input);
    if (match == null) return 0;
    final amount = double.parse(match.group(1)!);
    final unit = (match.group(2) ?? '').toUpperCase();
    const factors = {
      '': 1,
      'K': 1024,
      'M': 1024 * 1024,
      'G': 1024 * 1024 * 1024,
      'T': 1024 * 1024 * 1024 * 1024,
    };
    return (amount * (factors[unit] ?? 1)).round();
  }
}
