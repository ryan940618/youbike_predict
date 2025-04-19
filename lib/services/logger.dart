import 'dart:io';
import 'dart:convert';

class LoggerService {
  static const String _logFilePath = '/log.json';

  static Future<void> writeLog(List<Map<String, dynamic>> data) async {
    final file = File(_logFilePath);
    final sink = file.openWrite(mode: FileMode.append);

    for (var entry in data) {
      sink.writeln(jsonEncode(entry));
    }
    await sink.flush();
    await sink.close();
  }

  static Future<List<Map<String, dynamic>>> readLog() async {
    final file = File(_logFilePath);
    final lines = await file.readAsLines();
    return lines.map((line) => jsonDecode(line) as Map<String, dynamic>).toList();
  }

  static Future<void> exportToFile(String exportPath) async {
    final data = await readLog();
    final file = File(exportPath);
    await file.writeAsString(jsonEncode(data));
  }

  static Future<void> importFromFile(String importPath) async {
    final file = File(importPath);
    final content = await file.readAsString();
    final data = List<Map<String, dynamic>>.from(jsonDecode(content));
    final sink = File(_logFilePath).openWrite(mode: FileMode.append);
    for (var entry in data) {
      sink.writeln(jsonEncode(entry));
    }
    await sink.flush();
    await sink.close();
  }
}
