import '../models/cpu_info.dart';
import 'system_service.dart';

class CpuService {
  CpuService(this._systemService);

  final SystemService _systemService;

  Future<CpuInfo> loadCpuInfo() => _systemService.loadCpuInfo();
}
