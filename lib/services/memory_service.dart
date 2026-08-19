import '../models/memory_info.dart';
import 'system_service.dart';

class MemoryService {
  MemoryService(this._systemService);

  final SystemService _systemService;

  Future<MemoryInfo> loadMemoryInfo() => _systemService.loadMemoryInfo();
}
