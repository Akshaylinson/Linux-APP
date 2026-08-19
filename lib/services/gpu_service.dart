import '../models/gpu_info.dart';
import 'system_service.dart';

class GpuService {
  GpuService(this._systemService);

  final SystemService _systemService;

  Future<GpuInfo> loadGpuInfo() => _systemService.loadGpuInfo();
}
