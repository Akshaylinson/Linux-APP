import '../../models/docker_info.dart';
import 'linux_command_runner.dart';
import 'parsers/docker_parser.dart';

class LinuxDockerProvider {
  LinuxDockerProvider(this._runner);

  final LinuxCommandRunner _runner;
  final DockerParser _parser = DockerParser();

  Future<DockerInfo> readDockerSnapshot() async {
    try {
      final info = await _runner.run('docker', const ['info'], timeout: const Duration(seconds: 5));
      if (!info.success) {
        final stderr = info.stderr.toLowerCase();
        if (stderr.contains('permission denied')) {
          return const DockerInfo(
            state: 'Docker Permission Denied',
            containersTotal: 0,
            containersRunning: 0,
            imagesTotal: 0,
            volumesTotal: 0,
            diskUsageBytes: 0,
            containers: [],
            permissionDenied: true,
            installed: true,
          );
        }
        return const DockerInfo(
          state: 'Docker Not Installed',
          containersTotal: 0,
          containersRunning: 0,
          imagesTotal: 0,
          volumesTotal: 0,
          diskUsageBytes: 0,
          containers: [],
          installed: false,
        );
      }

      final ps = await _runner.run(
        'docker',
        const ['ps', '--format', '{{.Names}}\t{{.Image}}\t{{.Status}}\t0%\t0B\t{{.Ports}}'],
        timeout: const Duration(seconds: 4),
      );
      final images = await _runner.run(
        'docker',
        const ['images', '--format', '{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}'],
        timeout: const Duration(seconds: 4),
      );
      final volumes = await _runner.run(
        'docker',
        const ['volume', 'ls', '--format', '{{.Name}}'],
        timeout: const Duration(seconds: 4),
      );
      final stats = await _runner.run(
        'docker',
        const ['stats', '--no-stream', '--format', '{{.Name}}\t{{.Image}}\t{{.Status}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.Ports}}'],
        timeout: const Duration(seconds: 5),
      );
      final systemDf = await _runner.run(
        'docker',
        const ['system', 'df'],
        timeout: const Duration(seconds: 5),
      );

      return _parser.parseSnapshot(
        infoOutput: info.stdout,
        psOutput: ps.stdout,
        imagesOutput: images.stdout,
        volumesOutput: volumes.stdout,
        systemDfOutput: systemDf.stdout,
        statsOutput: stats.stdout,
      );
    } catch (_) {
      return const DockerInfo(
        state: 'Docker Not Installed',
        containersTotal: 0,
        containersRunning: 0,
        imagesTotal: 0,
        volumesTotal: 0,
        diskUsageBytes: 0,
        containers: [],
        installed: false,
      );
    }
  }
}
