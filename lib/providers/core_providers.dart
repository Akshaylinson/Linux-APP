import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/linux/linux_command_runner.dart';
import '../platform/linux/linux_docker_provider.dart';
import '../platform/linux/linux_proc_reader.dart';
import '../platform/linux/linux_storage_provider.dart';
import '../platform/linux/linux_sys_reader.dart';
import '../platform/linux/linux_system_provider.dart';
import '../services/battery_service.dart';
import '../services/cpu_service.dart';
import '../services/docker_service.dart';
import '../services/gpu_service.dart';
import '../services/memory_service.dart';
import '../services/network_service.dart';
import '../services/storage_service.dart';
import '../services/system_service.dart';
import '../services/temperature_service.dart';

final linuxCommandRunnerProvider = Provider<LinuxCommandRunner>((ref) {
  return LinuxCommandRunner();
});

final linuxProcReaderProvider = Provider<LinuxProcReader>((ref) {
  return LinuxProcReader();
});

final linuxSysReaderProvider = Provider<LinuxSysReader>((ref) {
  return LinuxSysReader();
});

final linuxStorageProvider = Provider<LinuxStorageProvider>((ref) {
  return LinuxStorageProvider(ref.watch(linuxCommandRunnerProvider));
});

final linuxSystemProvider = Provider<LinuxSystemProvider>((ref) {
  return LinuxSystemProvider(
    ref.watch(linuxCommandRunnerProvider),
    ref.watch(linuxProcReaderProvider),
  );
});

final linuxDockerProvider = Provider<LinuxDockerProvider>((ref) {
  return LinuxDockerProvider(ref.watch(linuxCommandRunnerProvider));
});

final systemServiceProvider = Provider<SystemService>((ref) {
  return SystemService(ref.watch(linuxSystemProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(linuxStorageProvider));
});

final cpuServiceProvider = Provider<CpuService>((ref) {
  return CpuService(ref.watch(systemServiceProvider));
});

final memoryServiceProvider = Provider<MemoryService>((ref) {
  return MemoryService(ref.watch(systemServiceProvider));
});

final gpuServiceProvider = Provider<GpuService>((ref) {
  return GpuService(ref.watch(systemServiceProvider));
});

final temperatureServiceProvider = Provider<TemperatureService>((ref) {
  return TemperatureService(ref.watch(systemServiceProvider));
});

final batteryServiceProvider = Provider<BatteryService>((ref) {
  return BatteryService(ref.watch(systemServiceProvider));
});

final networkServiceProvider = Provider<NetworkService>((ref) {
  return NetworkService(ref.watch(systemServiceProvider));
});

final dockerServiceProvider = Provider<DockerService>((ref) {
  return DockerService(ref.watch(linuxDockerProvider));
});
