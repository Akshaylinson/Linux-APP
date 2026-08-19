import 'dart:io';

Future<String?> readTextFile(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsString();
  } catch (_) {
    return null;
  }
}

String? readTextFileSync(String path) {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  } catch (_) {
    return null;
  }
}
