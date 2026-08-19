import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/errors/app_exception.dart';

class LinuxCommandResult {
  LinuxCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get success => exitCode == 0;
}

class LinuxCommandRunner {
  Future<LinuxCommandResult> run(
    String executable,
    List<String> arguments, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final process = await Process.start(
        executable,
        arguments,
        runInShell: false,
      );

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      final exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          throw TimeoutException('$executable timed out');
        },
      );

      return LinuxCommandResult(
        exitCode: exitCode,
        stdout: await stdoutFuture,
        stderr: await stderrFuture,
      );
    } on TimeoutException catch (error) {
      throw AppException('Command timed out', details: error.message);
    } on ProcessException catch (error) {
      throw AppException('Command failed', details: error.message);
    }
  }
}
