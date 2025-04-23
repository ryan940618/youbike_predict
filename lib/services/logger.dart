import 'dart:io';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:file_picker/file_picker.dart';
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      final files = result.paths
          .where((path) => path != null && path.endsWith('.json'))
          .map((path) => File(path!))
          .toList();

      for (final file in files) {
        await Analyzer().loadFromFile(file);
      }
    } else {
      return;
    }
  }
}
