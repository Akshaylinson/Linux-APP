import 'network_info.dart';

class NetworkSnapshot {
  const NetworkSnapshot({required this.interfaces});

  final List<NetworkInfo> interfaces;
}
