import 'battery_info.dart';
import 'cpu_info.dart';
import 'gpu_info.dart';
import 'memory_info.dart';
import 'process_info.dart';
import 'system_info.dart';
import 'temperature_info.dart';

class SystemSnapshot {
  const SystemSnapshot({
    required this.system,
    required this.cpu,
    required this.memory,
    required this.temperatures,
    required this.battery,
    required this.gpu,
    required this.processes,
  });

  final SystemInfo system;
  final CpuInfo cpu;
  final MemoryInfo memory;
  final List<TemperatureInfo> temperatures;
  final BatteryInfo battery;
  final GpuInfo gpu;
  final List<ProcessInfo> processes;
}
