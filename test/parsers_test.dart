import 'package:flutter_test/flutter_test.dart';

import 'package:systemlens/platform/linux/parsers/cpu_stat_parser.dart';
import 'package:systemlens/platform/linux/parsers/docker_parser.dart';
import 'package:systemlens/platform/linux/parsers/lsblk_parser.dart';
import 'package:systemlens/platform/linux/parsers/meminfo_parser.dart';

void main() {
  group('MeminfoParser', () {
    test('parses memory values', () {
      const input = '''
MemTotal:       16384000 kB
MemAvailable:    8192000 kB
Buffers:          100000 kB
Cached:           500000 kB
SwapTotal:        2000000 kB
SwapFree:         1500000 kB
''';
      final info = MeminfoParser().parse(input);

      expect(info.totalBytes, 16384000 * 1024);
      expect(info.availableBytes, 8192000 * 1024);
      expect(info.cachedBytes, 600000 * 1024);
      expect(info.swapUsedBytes, 500000 * 1024);
    });
  });

  group('CpuStatParser', () {
    test('parses cpu model and usage data', () {
      const cpuInfo = '''
processor   : 0
model name  : Test CPU 123
cpu MHz     : 2500.000

processor   : 1
model name  : Test CPU 123
cpu MHz     : 2500.000
''';
      const procStat = '''
cpu  100 0 100 900 0 0 0 0 0 0
cpu0 50 0 50 450 0 0 0 0 0 0
cpu1 50 0 50 450 0 0 0 0 0 0
''';
      final info = CpuStatParser().parse(
        cpuInfo: cpuInfo,
        procStat: procStat,
        usagePercent: 42.5,
        perCoreUsage: const [40.0, 45.0],
        loadAverage: const [1.0, 0.5, 0.2],
      );

      expect(info.model, 'Test CPU 123');
      expect(info.coreCount, 2);
      expect(info.threadCount, 2);
      expect(info.frequencyMhz, 2500.0);
      expect(info.usagePercent, 42.5);
      expect(info.perCoreUsage, hasLength(2));
    });
  });

  group('LsblkParser', () {
    test('parses disks and filesystems', () {
      const lsblkJson = '''
{
  "blockdevices": [
    {
      "name": "nvme0n1",
      "path": "/dev/nvme0n1",
      "model": "Samsung SSD 980",
      "size": "1T",
      "type": "disk",
      "tran": "nvme",
      "children": [
        {
          "name": "nvme0n1p1",
          "path": "/dev/nvme0n1p1",
          "size": "512M",
          "type": "part",
          "fstype": "vfat",
          "mountpoint": "/boot/efi",
          "label": "EFI"
        }
      ]
    }
  ]
}
''';
      const dfOutput = '''
Filesystem 1B-blocks Used Available Use% Mounted on
/dev/nvme0n1p1 536870912 268435456 268435456 50% /boot/efi
''';

      final snapshot = LsblkParser().parse(lsblkJson: lsblkJson, dfOutput: dfOutput);

      expect(snapshot.disks, hasLength(1));
      expect(snapshot.partitions, hasLength(1));
      expect(snapshot.filesystems, hasLength(1));
      expect(snapshot.disks.first.model, 'Samsung SSD 980');
      expect(snapshot.partitions.first.mountPoint, '/boot/efi');
    });
  });

  group('DockerParser', () {
    test('parses container stats', () {
      const statsOutput = '''
codevoice-api\tapi:latest\tUp 1 hour\t12.5%\t300MiB / 2GiB\t0.0.0.0:3000->3000/tcp
postgres\tpostgres:16\tUp 3 hours\t2.0%\t500MiB / 4GiB\t5432/tcp
''';
      const psOutput = '''
codevoice-api
postgres
''';
      const imagesOutput = '''
api latest sha256:123 1.2GB
postgres 16 sha256:456 900MB
''';
      const volumesOutput = '''
db-data
cache
''';
      const systemDfOutput = 'Local Volumes space usage: 24.6GB';

      final info = DockerParser().parseSnapshot(
        infoOutput: '{}',
        psOutput: psOutput,
        imagesOutput: imagesOutput,
        volumesOutput: volumesOutput,
        systemDfOutput: systemDfOutput,
        statsOutput: statsOutput,
      );

      expect(info.containersRunning, 2);
      expect(info.imagesTotal, 2);
      expect(info.volumesTotal, 2);
      expect(info.containers, hasLength(2));
      expect(info.containers.first.name, 'codevoice-api');
    });
  });
}
