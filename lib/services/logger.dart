import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'analyzer.dart';

class LoggerService {
  static String? directoryPath;
  static int lineCount = 0;
  static int fileIndex = 1;
  static IOSink? _currentSink;

  static Future<bool> initLogFile() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) return false;

    final parts = directory.split(Platform.pathSeparator);
  if (parts.length >= 2 && parts[parts.length - 1] == parts[parts.length - 2]) {
    parts.removeLast();
  }

    directoryPath = parts.join(Platform.pathSeparator);
    lineCount = 0;
    fileIndex = 1;

    await _createNewLogFile();
    return true;
  }

  static Future<void> _createNewLogFile() async {
    if (directoryPath == null) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(":", "-");
    final filename = 'ubikeData_${timestamp}_$fileIndex.json';
    final path = '$directoryPath/$filename';

    _currentSink?.close();
    _currentSink = File(path).openWrite(mode: FileMode.write);
  }

  static Future<void> closeLog() async {
    await _currentSink?.flush();
    await _currentSink?.close();
    _currentSink = null;
  }

  static Future<void> writeLog(List<Map<String, dynamic>> data) async {
    if (_currentSink == null) return;

    for (var entry in data) {
      _currentSink!.writeln(jsonEncode(entry));
      lineCount++;

      if (lineCount >= 100) {
        lineCount = 0;
        fileIndex++;
        await _createNewLogFile();
      }
    }
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
