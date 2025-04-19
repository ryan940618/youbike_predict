import 'dart:io';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';

class LoggerService {
  static File? filePath;

  static Future<bool> initLogFile() async {
    final saveLocation = await getSaveLocation(
      suggestedName: 'log.json',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );

    if (saveLocation == null) return false;

    filePath = File(saveLocation.path);
    return true;
  }

  static Future<void> writeLog(List<Map<String, dynamic>> data) async {
    if (filePath == null) return;

    final sink = filePath!.openWrite(mode: FileMode.append);

    for (var entry in data) {
      sink.writeln(jsonEncode(entry));
    }

    await sink.flush();
    await sink.close();
  }

  static Future<List<Map<String, dynamic>>> readLog() async {
    if (filePath == null) return [];

    final lines = await filePath!.readAsLines();
    return lines
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> importFromFile() async {
    final file = await openFile(acceptedTypeGroups: [
      const XTypeGroup(label: 'JSON', extensions: ['json'])
    ]);

    if (file == null) return;

    final content = await file.readAsString();
    final data = List<Map<String, dynamic>>.from(jsonDecode(content));

    if (filePath == null) return;

    final sink = filePath!.openWrite(mode: FileMode.append);
    for (var entry in data) {
      sink.writeln(jsonEncode(entry));
    }
    await sink.flush();
    await sink.close();
  }

  static Future<void> exportToFile() async {
    final data = await readLog();

    final location = await getSaveLocation(
      suggestedName: 'exported_log.json',
      acceptedTypeGroups: [const XTypeGroup(label: 'JSON', extensions: ['json'])],
    );

    if (location == null) return;

    final file = File(location.path);
    await file.writeAsString(jsonEncode(data));
  }
}