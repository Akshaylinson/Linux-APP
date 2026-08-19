import '../models/battery_info.dart';
import 'system_service.dart';

class BatteryService {
  BatteryService(this._systemService);

  final SystemService _systemService;

  Future<BatteryInfo> loadBatteryInfo() => _systemService.loadBatteryInfo();
}
