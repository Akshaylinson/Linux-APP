import '../models/battery_info.dart';
import '../models/cpu_info.dart';
import '../models/gpu_info.dart';
import '../models/memory_info.dart';
import '../models/network_info.dart';
import '../models/process_info.dart';
import '../models/system_info.dart';
import '../models/temperature_info.dart';
import '../platform/linux/linux_system_provider.dart';

class SystemService {
  SystemService(this._provider);

  final LinuxSystemProvider _provider;

  Future<SystemInfo> loadSystemInfo() => _provider.readSystemInfo();
  Future<CpuInfo> loadCpuInfo() => _provider.readCpuInfo();
  Future<MemoryInfo> loadMemoryInfo() => _provider.readMemoryInfo();
  Future<List<TemperatureInfo>> loadTemperatures() => _provider.readTemperatures();
  Future<BatteryInfo> loadBatteryInfo() => _provider.readBatteryInfo();
  Future<GpuInfo> loadGpuInfo() => _provider.readGpuInfo();
  Future<List<NetworkInfo>> loadNetworkInfo() => _provider.readNetworkInfo();
  Future<List<ProcessInfo>> loadProcesses() => _provider.readTopProcesses();
}
