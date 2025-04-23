import 'dart:io';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'analyzer.dart';

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

  static Future<void> importFromFile() async {
    final xfile = await openFiles(acceptedTypeGroups: [
      const XTypeGroup(label: 'JSON', extensions: ['json']),
    ]);

    final filesToImport = <File>[];
    if (xfile.isEmpty) return;

    filesToImport.addAll(xfile.map((f) => File(f.path)));
    for (final file in filesToImport) {
      await Analyzer().loadFromFile(file);
    }
  }
}
