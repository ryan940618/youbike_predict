import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'analyzer.dart';

class LoggerService {
  static String? directoryPath;
  static int lineCount = 0;
  static int fileIndex = 1;
  static IOSink? _currentSink;
  static File? _currentLogFile;

  static Future<bool> initLogFile() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return false;

      directoryPath = dir.path;
    } else {
      final pickedPath = await FilePicker.platform.getDirectoryPath();
      if (pickedPath == null) return false;

      directoryPath = pickedPath;
    }
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

    _currentLogFile = File(path);
    _currentSink = _currentLogFile!.openWrite(mode: FileMode.write);
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
        await _currentSink?.flush();
        await _currentSink?.close();

        if (_currentLogFile != null) {
          await Analyzer.uploadLogFile(_currentLogFile!);
        }

        lineCount = 0;
        fileIndex++;
        await _createNewLogFile();
      }
    }
    await _currentSink?.flush();
  }
}
