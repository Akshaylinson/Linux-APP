import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/battery_info.dart';
import '../models/dashboard_snapshot.dart';
import '../models/docker_info.dart';
import '../models/network_info.dart';
import '../models/system_snapshot.dart';
import '../models/storage_snapshot.dart';
import '../providers/core_providers.dart';
import '../providers/settings_provider.dart';

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<DashboardSnapshot>>(
        (ref) {
  return DashboardController(ref);
});

class DashboardController extends StateNotifier<AsyncValue<DashboardSnapshot>> {
  DashboardController(this._ref) : super(const AsyncLoading()) {
    _load();
    _schedule();
    _ref.listen<AppSettings>(settingsControllerProvider, (_, __) => _schedule());
  }

  final Ref _ref;
  Timer? _timer;
  final List<double> _cpuHistory = [];
  final List<double> _memoryHistory = [];
  final List<double> _storageHistory = [];
  final List<double> _networkHistory = [];
  final List<double> _temperatureHistory = [];

  void _schedule() {
    _timer?.cancel();
    final interval = _ref.read(settingsControllerProvider).refreshInterval.seconds;
    if (interval == null) return;
    _timer = Timer.periodic(Duration(seconds: interval), (_) => _load());
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      state = const AsyncLoading();
      final system = await _ref.read(systemServiceProvider).loadSystemInfo();
      final cpu = await _ref.read(cpuServiceProvider).loadCpuInfo();
      final memory = await _ref.read(memoryServiceProvider).loadMemoryInfo();
      final filesystems = (await _ref.read(storageServiceProvider).loadSnapshot()).filesystems;
      final network = await _ref.read(networkServiceProvider).loadNetworkInfo();
      final docker = await _ref.read(dockerServiceProvider).loadDockerInfo();
      final temperatures = await _ref.read(temperatureServiceProvider).loadTemperatures();
      final battery = await _ref.read(batteryServiceProvider).loadBatteryInfo();
      final gpu = await _ref.read(gpuServiceProvider).loadGpuInfo();
      _cpuHistory.add(cpu.usagePercent);
      _memoryHistory.add(memory.usagePercent);
      _storageHistory.add(filesystems.isEmpty ? 0 : filesystems.first.usagePercent);
      _networkHistory.add(
        network.isEmpty
            ? 0
            : (network.first.rxBytesPerSecond + network.first.txBytesPerSecond)
                .clamp(0, double.infinity)
                .toDouble(),
      );
      _temperatureHistory.add(
        temperatures.isEmpty || temperatures.first.temperatureC == null
            ? 0
            : temperatures.first.temperatureC!,
      );
      _trimHistory(_cpuHistory);
      _trimHistory(_memoryHistory);
      _trimHistory(_storageHistory);
      _trimHistory(_networkHistory);
      _trimHistory(_temperatureHistory);
      state = AsyncData(
        DashboardSnapshot(
          cpu: cpu,
          memory: memory,
          filesystems: filesystems,
          system: system,
          network: network,
          docker: docker,
          temperatures: temperatures,
          battery: battery,
          gpu: gpu,
          cpuHistory: List<double>.unmodifiable(_cpuHistory),
          memoryHistory: List<double>.unmodifiable(_memoryHistory),
          storageHistory: List<double>.unmodifiable(_storageHistory),
          networkHistory: List<double>.unmodifiable(_networkHistory),
          temperatureHistory: List<double>.unmodifiable(_temperatureHistory),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _trimHistory(List<double> values, {int limit = 60}) {
    while (values.length > limit) {
      values.removeAt(0);
    }
  }
}

final systemSnapshotProvider =
    StateNotifierProvider<SystemController, AsyncValue<SystemSnapshot>>((ref) {
  return SystemController(ref);
});

class SystemController extends StateNotifier<AsyncValue<SystemSnapshot>> {
  SystemController(this._ref) : super(const AsyncLoading()) {
    _load();
    _schedule();
  }

  final Ref _ref;
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    final interval = _ref.read(settingsControllerProvider).refreshInterval.seconds;
    if (interval == null) {
      _timer = null;
      return;
    }
    _timer = Timer.periodic(
      Duration(seconds: interval.clamp(10, 30).toInt()),
      (_) => _load(),
    );
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final system = await _ref.read(systemServiceProvider).loadSystemInfo();
      final cpu = await _ref.read(cpuServiceProvider).loadCpuInfo();
      final memory = await _ref.read(memoryServiceProvider).loadMemoryInfo();
      final temperatures = await _ref.read(temperatureServiceProvider).loadTemperatures();
      final battery = await _ref.read(batteryServiceProvider).loadBatteryInfo();
      final gpu = await _ref.read(gpuServiceProvider).loadGpuInfo();
      final processes = await _ref.read(systemServiceProvider).loadProcesses();
      state = AsyncData(
        SystemSnapshot(
          system: system,
          cpu: cpu,
          memory: memory,
          temperatures: temperatures,
          battery: battery,
          gpu: gpu,
          processes: processes,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final storageSnapshotProvider =
    StateNotifierProvider<StorageController, AsyncValue<StorageSnapshot>>((ref) {
  return StorageController(ref);
});

class StorageController extends StateNotifier<AsyncValue<StorageSnapshot>> {
  StorageController(this._ref) : super(const AsyncLoading()) {
    _load();
    _schedule();
  }

  final Ref _ref;
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(AppConstants.storageRefresh, (_) => _load());
  }

  Future<void> refresh() => _load();

  Future<void> scanFolders(String rootPath) async {
    final snapshot = state.valueOrNull;
    if (snapshot == null) return;
    state = const AsyncLoading();
    final usage = await _ref.read(storageServiceProvider).scanFolderUsage(rootPath);
    state = AsyncData(
      StorageSnapshot(
        disks: snapshot.disks,
        partitions: snapshot.partitions,
        filesystems: snapshot.filesystems,
        folderUsage: {...snapshot.folderUsage, rootPath: usage},
      ),
    );
  }

  Future<void> _load() async {
    try {
      state = AsyncData(await _ref.read(storageServiceProvider).loadSnapshot());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final dockerSnapshotProvider =
    StateNotifierProvider<DockerController, AsyncValue<DockerInfo>>((ref) {
  return DockerController(ref);
});

class DockerController extends StateNotifier<AsyncValue<DockerInfo>> {
  DockerController(this._ref) : super(const AsyncLoading()) {
    _load();
    _schedule();
    _ref.listen<AppSettings>(settingsControllerProvider, (_, __) => _schedule());
  }

  final Ref _ref;
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    final settings = _ref.read(settingsControllerProvider);
    if (!settings.dockerMonitoringEnabled) return;
    _timer = Timer.periodic(AppConstants.dockerRefresh, (_) => _load());
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      state = AsyncData(await _ref.read(dockerServiceProvider).loadDockerInfo());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final networkSnapshotProvider =
    StateNotifierProvider<NetworkController, AsyncValue<List<NetworkInfo>>>((ref) {
  return NetworkController(ref);
});

class NetworkController
    extends StateNotifier<AsyncValue<List<NetworkInfo>>> {
  NetworkController(this._ref) : super(const AsyncLoading()) {
    _load();
    _schedule();
  }

  final Ref _ref;
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    final interval = _ref.read(settingsControllerProvider).refreshInterval.seconds;
    if (interval == null) {
      _timer = null;
      return;
    }
    _timer = Timer.periodic(Duration(seconds: interval), (_) => _load());
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      state = AsyncData(await _ref.read(networkServiceProvider).loadNetworkInfo());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final monitoringProvider = Provider<AsyncValue<DashboardSnapshot>>((ref) {
  return ref.watch(dashboardControllerProvider);
});
