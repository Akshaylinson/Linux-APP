import '../models/network_info.dart';
import 'system_service.dart';

class NetworkService {
  NetworkService(this._systemService);

  final SystemService _systemService;

  Future<List<NetworkInfo>> loadNetworkInfo() => _systemService.loadNetworkInfo();
}
