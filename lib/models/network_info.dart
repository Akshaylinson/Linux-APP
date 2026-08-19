class NetworkInfo {
  const NetworkInfo({
    required this.interfaceName,
    required this.state,
    required this.rxBytesPerSecond,
    required this.txBytesPerSecond,
    required this.rxTotalBytes,
    required this.txTotalBytes,
    this.ipAddress,
    this.ssid,
  });

  final String interfaceName;
  final String state;
  final double rxBytesPerSecond;
  final double txBytesPerSecond;
  final int rxTotalBytes;
  final int txTotalBytes;
  final String? ipAddress;
  final String? ssid;
}
