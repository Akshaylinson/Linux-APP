import 'dart:io';

class LinuxSysReader {
  Future<List<FileSystemEntity>> listEntities(String path) async {
    try {
      return await Directory(path).list(followLinks: false).toList();
    } catch (_) {
      return const [];
    }
  }

  String? readSync(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return file.readAsStringSync();
    } catch (_) {
      return null;
    }
  }
}
