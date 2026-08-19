import '../models/temperature_info.dart';
import 'system_service.dart';

class TemperatureService {
  TemperatureService(this._systemService);

  final SystemService _systemService;

  Future<List<TemperatureInfo>> loadTemperatures() =>
      _systemService.loadTemperatures();
}
