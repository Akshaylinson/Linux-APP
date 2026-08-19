import 'dart:async';
import 'dart:io';

import '../../core/utils/file_utils.dart';
import '../../core/utils/formatters.dart';
import '../../models/battery_info.dart';
import '../../models/cpu_info.dart';
import '../../models/gpu_info.dart';
import '../../models/memory_info.dart';
import '../../models/network_info.dart';
import '../../models/process_info.dart';
import '../../models/system_info.dart';
import '../../models/temperature_info.dart';
import 'linux_command_runner.dart';
import 'linux_proc_reader.dart';
import 'parsers/cpu_stat_parser.dart';
import 'parsers/meminfo_parser.dart';

class LinuxSystemProvider {
  LinuxSystemProvider(this._runner, this._procReader);

  final LinuxCommandRunner _runner;
  final LinuxProcReader _procReader;
  final MeminfoParser _meminfoParser = MeminfoParser();
  final CpuStatParser _cpuParser = CpuStatParser();

  List<int>? _previousCpuTotals;
  List<int>? _previousCpuIdle;
  DateTime? _previousCpuSample;

  Map<String, _NetCounters>? _previousNetCounters;
  DateTime? _previousNetSample;

  Future<SystemInfo> readSystemInfo() async {
    final osRelease = await readTextFile('/etc/os-release');
    final parsed = _parseKeyValueFile(osRelease ?? '');
    final prettyName = parsed['PRETTY_NAME'] ??
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    final kernel = await _safeUname('-r');
    final architecture = await _safeUname('-m');
    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'] ??
        Platform.environment['DESKTOP_SESSION'] ??
        'Desktop';
    final uptime = await _readUptime();

    return SystemInfo(
      osPrettyName: prettyName,
      kernelVersion: kernel,
      architecture: architecture,
      hostname: Platform.localHostname,
      desktopEnvironment: desktop,
      uptime: formatDuration(uptime),
      uptimeSeconds: uptime.inSeconds,
    );
  }

  Future<CpuInfo> readCpuInfo() async {
    final cpuInfoText = await _procReader.readFile('/proc/cpuinfo') ?? '';
    final statText = await _procReader.readFile('/proc/stat') ?? '';
    final sample1 = _parseCpuSample(statText);

    if (_previousCpuTotals == null || _previousCpuIdle == null) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final later = await _procReader.readFile('/proc/stat') ?? '';
      final sample2 = _parseCpuSample(later);
      _previousCpuTotals = sample2.totals;
      _previousCpuIdle = sample2.idles;
      _previousCpuSample = DateTime.now();
      return _cpuParser.parse(
        cpuInfo: cpuInfoText,
        procStat: later,
        usagePercent: sample2.overallUsage,
        perCoreUsage: sample2.perCoreUsage,
        loadAverage: await _readLoadAverage(),
      );
    }

    final usage = _usageBetweenSamples(
      previousTotals: _previousCpuTotals!,
      previousIdle: _previousCpuIdle!,
      currentTotals: sample1.totals,
      currentIdle: sample1.idles,
    );
    _previousCpuTotals = sample1.totals;
    _previousCpuIdle = sample1.idles;
    _previousCpuSample = DateTime.now();

    return _cpuParser.parse(
      cpuInfo: cpuInfoText,
      procStat: statText,
      usagePercent: usage.overallUsage,
      perCoreUsage: usage.perCoreUsage,
      loadAverage: await _readLoadAverage(),
    );
  }

  Future<MemoryInfo> readMemoryInfo() async {
    final text = await _procReader.readFile('/proc/meminfo') ?? '';
    return _meminfoParser.parse(text);
  }

  Future<List<TemperatureInfo>> readTemperatures() async {
    final zones = <TemperatureInfo>[];
    final dir = Directory('/sys/class/thermal');
    if (!await dir.exists()) {
      return zones;
    }
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! Directory ||
          !RegExp(r'thermal_zone\d+').hasMatch(_name(entity.path))) {
        continue;
      }
      final type = await readTextFile('${entity.path}/type');
      final temp = await readTextFile('${entity.path}/temp');
      final high = await readTextFile('${entity.path}/trip_point_1_temp');
      final critical = await readTextFile('${entity.path}/trip_point_2_temp');
      final tempValue = double.tryParse(temp?.trim() ?? '');
      final highValue = double.tryParse(high?.trim() ?? '');
      final criticalValue = double.tryParse(critical?.trim() ?? '');
      zones.add(
        TemperatureInfo(
          label: type?.trim().isEmpty == true ? _name(entity.path) : type!.trim(),
          temperatureC: tempValue == null ? null : tempValue / 1000,
          highC: highValue == null ? null : highValue / 1000,
          criticalC: criticalValue == null ? null : criticalValue / 1000,
          source: 'sysfs',
        ),
      );
    }
    return zones;
  }

  Future<BatteryInfo> readBatteryInfo() async {
    final base = Directory('/sys/class/power_supply');
    if (!await base.exists()) {
      return const BatteryInfo(present: false);
    }
    await for (final entity in base.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = _name(entity.path).toUpperCase();
      if (!name.startsWith('BAT')) continue;
      final capacity = await readTextFile('${entity.path}/capacity');
      final status = await readTextFile('${entity.path}/status');
      final health = await readTextFile('${entity.path}/health');
      final energyNow = await readTextFile('${entity.path}/energy_now') ??
          await readTextFile('${entity.path}/charge_now');
      final powerNow = await readTextFile('${entity.path}/power_now');
      final powerNowValue = double.tryParse(powerNow?.trim() ?? '');
      return BatteryInfo(
        present: true,
        percentage: capacity == null ? null : double.tryParse(capacity.trim()),
        status: status?.trim(),
        health: health?.trim(),
        powerNowW: powerNowValue == null ? null : powerNowValue / 1000000,
        timeToEmpty: _estimateBatteryDuration(energyNow, powerNow, charging: false),
        timeToFull: _estimateBatteryDuration(energyNow, powerNow, charging: true),
      );
    }
    return const BatteryInfo(present: false);
  }

  Future<GpuInfo> readGpuInfo() async {
    final drm = Directory('/sys/class/drm');
    if (!await drm.exists()) {
      return const GpuInfo(vendor: 'Unknown', model: 'GPU information unavailable', status: 'Unavailable');
    }

    String? vendor;
    String? model;
    await for (final entity in drm.list(followLinks: false)) {
      if (entity is! Directory || !_name(entity.path).startsWith('card')) {
        continue;
      }
      final deviceVendor = await readTextFile('${entity.path}/device/vendor');
      final deviceName = await readTextFile('${entity.path}/device/device');
      vendor = _vendorFromId(deviceVendor?.trim());
      model = deviceName?.trim();
      break;
    }

    return GpuInfo(
      vendor: vendor ?? 'Unknown',
      model: model ?? 'GPU detected through PCI/system information',
      status: vendor == null ? 'Unavailable' : 'Detected',
    );
  }

  Future<List<NetworkInfo>> readNetworkInfo() async {
    final proc = await _procReader.readFile('/proc/net/dev') ?? '';
    final now = DateTime.now();
    final counters = <String, _NetCounters>{};
    final result = <NetworkInfo>[];

    for (final line in proc.split('\n').skip(2)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.contains(':')) continue;
      final parts = trimmed.split(':');
      final iface = parts.first.trim();
      if (iface == 'lo') continue;
      final values = parts[1].trim().split(RegExp(r'\s+'));
      if (values.length < 16) continue;
      final rxBytes = int.tryParse(values[0]) ?? 0;
      final txBytes = int.tryParse(values[8]) ?? 0;
      counters[iface] = _NetCounters(rxBytes, txBytes);

      final previous = _previousNetCounters?[iface];
      final elapsed = _previousNetSample == null
          ? null
          : now.difference(_previousNetSample!).inMicroseconds / 1000000.0;
      final rxPerSecond = previous == null || elapsed == null || elapsed <= 0
          ? 0
          : (rxBytes - previous.rxBytes) / elapsed;
      final txPerSecond = previous == null || elapsed == null || elapsed <= 0
          ? 0
          : (txBytes - previous.txBytes) / elapsed;

      result.add(
        NetworkInfo(
          interfaceName: iface,
          state: await _interfaceState(iface),
          rxBytesPerSecond: rxPerSecond.toDouble(),
          txBytesPerSecond: txPerSecond.toDouble(),
          rxTotalBytes: rxBytes,
          txTotalBytes: txBytes,
          ipAddress: null,
          ssid: null,
        ),
      );
    }

    _previousNetCounters = counters;
    _previousNetSample = now;
    result.sort((a, b) => b.rxBytesPerSecond.compareTo(a.rxBytesPerSecond));
    return result;
  }

  Future<List<ProcessInfo>> readTopProcesses() async {
    try {
      final result = await _runner.run(
        'ps',
        const ['-eo', 'pid,comm,%cpu,rss', '--sort=-%cpu', '--no-headers'],
        timeout: const Duration(seconds: 4),
      );
      if (!result.success) return const [];
      final processes = <ProcessInfo>[];
      for (final line in result.stdout.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length < 4) continue;
        processes.add(
          ProcessInfo(
            pid: int.tryParse(parts[0]) ?? 0,
            name: parts[1],
            cpuPercent: double.tryParse(parts[2]) ?? 0,
            memoryBytes: (int.tryParse(parts[3]) ?? 0) * 1024,
          ),
        );
      }
      return processes.take(8).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<double>> _readLoadAverage() async {
    final text = await _procReader.readFile('/proc/loadavg');
    if (text == null) return const [];
    final values = text.split(RegExp(r'\s+')).take(3).map((e) => double.tryParse(e) ?? 0).toList();
    return values;
  }

  Future<String> _interfaceState(String iface) async {
    final state = await readTextFile('/sys/class/net/$iface/operstate');
    if (state != null && state.trim().isNotEmpty) {
      return state.trim();
    }
    return 'unknown';
  }

  Future<Duration> _readUptime() async {
    final text = await _procReader.readFile('/proc/uptime');
    if (text == null) return Duration.zero;
    final seconds = double.tryParse(text.split(' ').first) ?? 0;
    return Duration(seconds: seconds.round());
  }

  Future<String> _safeUname(String arg) async {
    try {
      final result = await _runner.run('uname', [arg], timeout: const Duration(seconds: 2));
      final text = result.stdout.trim();
      if (text.isNotEmpty) return text;
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  Map<String, String> _parseKeyValueFile(String input) {
    final result = <String, String>{};
    for (final line in input.split('\n')) {
      if (!line.contains('=')) continue;
      final index = line.indexOf('=');
      final key = line.substring(0, index);
      final value = line.substring(index + 1).replaceAll('"', '');
      result[key] = value;
    }
    return result;
  }

  _CpuSample _parseCpuSample(String statText) {
    final lines = statText.split('\n').where((line) => line.startsWith('cpu'));
    final totals = <int>[];
    final idles = <int>[];
    for (final line in lines) {
      final parts = line.split(RegExp(r'\s+')).sublist(1).map((e) => int.tryParse(e) ?? 0).toList();
      if (parts.isEmpty) continue;
      final idle = (parts.length > 3 ? parts[3] : 0) + (parts.length > 4 ? parts[4] : 0);
      final total = parts.fold<int>(0, (sum, value) => sum + value);
      totals.add(total);
      idles.add(idle);
    }
    return _CpuSample(
      totals: totals,
      idles: idles,
      overallUsage: _usageBetweenSamples(
        previousTotals: _previousCpuTotals ?? totals,
        previousIdle: _previousCpuIdle ?? idles,
        currentTotals: totals,
        currentIdle: idles,
      ).overallUsage,
      perCoreUsage: _usageBetweenSamples(
        previousTotals: _previousCpuTotals ?? totals,
        previousIdle: _previousCpuIdle ?? idles,
        currentTotals: totals,
        currentIdle: idles,
      ).perCoreUsage,
    );
  }

  _CpuUsage _usageBetweenSamples({
    required List<int> previousTotals,
    required List<int> previousIdle,
    required List<int> currentTotals,
    required List<int> currentIdle,
  }) {
    final coreCount = currentTotals.length;
    if (coreCount == 0) {
      return const _CpuUsage(0, []);
    }

    final perCore = <double>[];
    for (var i = 0; i < coreCount; i++) {
      final totalDelta = currentTotals[i] - (i < previousTotals.length ? previousTotals[i] : currentTotals[i]);
      final idleDelta = currentIdle[i] - (i < previousIdle.length ? previousIdle[i] : currentIdle[i]);
      final usage = totalDelta <= 0 ? 0 : (1 - (idleDelta / totalDelta)) * 100;
      perCore.add(usage.clamp(0, 100).toDouble());
    }
    return _CpuUsage(perCore.reduce((a, b) => a + b) / perCore.length, perCore);
  }

  Duration? _estimateBatteryDuration(String? energyNow, String? powerNow, {required bool charging}) {
    final energy = double.tryParse(energyNow ?? '');
    final power = double.tryParse(powerNow ?? '');
    if (energy == null || power == null || power <= 0) return null;
    final hours = energy / power;
    return Duration(minutes: (hours * 60).round());
  }

  String _vendorFromId(String? id) {
    switch (id) {
      case '0x10de':
        return 'NVIDIA';
      case '0x1002':
        return 'AMD';
      case '0x8086':
        return 'Intel';
      default:
        return id ?? 'Unknown';
    }
  }

  String _name(String path) => path.split(Platform.pathSeparator).last;
}

class _CpuSample {
  const _CpuSample({
    required this.totals,
    required this.idles,
    required this.overallUsage,
    required this.perCoreUsage,
  });

  final List<int> totals;
  final List<int> idles;
  final double overallUsage;
  final List<double> perCoreUsage;
}

class _CpuUsage {
  const _CpuUsage(this.overallUsage, this.perCoreUsage);

  final double overallUsage;
  final List<double> perCoreUsage;
}

class _NetCounters {
  const _NetCounters(this.rxBytes, this.txBytes);

  final int rxBytes;
  final int txBytes;
}
