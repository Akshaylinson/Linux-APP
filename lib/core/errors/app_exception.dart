class AppException implements Exception {
  AppException(this.message, {this.details});

  final String message;
  final Object? details;

  @override
  String toString() => 'AppException: $message${details == null ? '' : ' ($details)'}';
}

class CommandNotAvailableException extends AppException {
  CommandNotAvailableException(String command)
      : super('Command not available', details: command);
}
