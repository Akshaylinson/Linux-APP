import 'battery_info.dart';
import 'cpu_info.dart';
import 'docker_info.dart';
import 'filesystem_info.dart';
import 'gpu_info.dart';
import 'memory_info.dart';
import 'network_info.dart';
import 'system_info.dart';
import 'temperature_info.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.cpu,
    required this.memory,
    required this.filesystems,
    required this.system,
    required this.network,
    required this.docker,
    required this.temperatures,
    required this.battery,
    required this.gpu,
    required this.cpuHistory,
    required this.memoryHistory,
    required this.storageHistory,
    required this.networkHistory,
    required this.temperatureHistory,
  });

  final CpuInfo cpu;
  final MemoryInfo memory;
  final List<FilesystemInfo> filesystems;
  final SystemInfo system;
  final List<NetworkInfo> network;
  final DockerInfo docker;
  final List<TemperatureInfo> temperatures;
  final BatteryInfo battery;
  final GpuInfo gpu;
  final List<double> cpuHistory;
  final List<double> memoryHistory;
  final List<double> storageHistory;
  final List<double> networkHistory;
  final List<double> temperatureHistory;
}
