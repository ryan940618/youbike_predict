import 'dart:convert';
import 'dart:io';

class StationLog {
  final DateTime timestamp;
  final int availableSpaces;

  StationLog({required this.timestamp, required this.availableSpaces});
}

class Analyzer {
  final Map<String, List<StationLog>> _logsByStation = {};

  Future<void> loadFromFile(File file) async {
    _logsByStation.clear();
    final lines = await file.readAsLines();

    for (var line in lines) {
      try {
        final data = jsonDecode(line);
        final timestamp = DateTime.parse(data['timestamp']);
        final stations = List<Map<String, dynamic>>.from(data['stations']);

        for (var station in stations) {
          final stationNo = station['station_no'];
          final available = station['available_spaces'];

          _logsByStation.putIfAbsent(stationNo, () => []);
          _logsByStation[stationNo]!.add(
            StationLog(timestamp: timestamp, availableSpaces: available),
          );
        }
      } catch (e) {
        print("解析失敗：$e");
      }
    }
  }

  List<StationLog>? getLogs(String stationNo) {
    final logs = _logsByStation[stationNo];
    if (logs == null) return null;

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs;
  }

  List<StationLog> extractRangedLogs(String stationNo, DateTime center, Duration range) {
    final logs = getLogs(stationNo);
    if (logs == null) return [];

    return logs.where((log) {
      return log.timestamp.isAfter(center.subtract(range)) &&
             log.timestamp.isBefore(center.add(range));
    }).toList();
  }

  double calculateAverage(List<StationLog> logs) {
    if (logs.isEmpty) return 0;
    return logs.map((e) => e.availableSpaces).reduce((a, b) => a + b) / logs.length;
  }

  List<double> calculateChangeRates(List<StationLog> logs, Duration step) {
    final result = <double>[];

    for (int i = 1; i < logs.length; i++) {
      final diffMinutes = logs[i].timestamp.difference(logs[i - 1].timestamp).inMinutes;
      if (diffMinutes == step.inMinutes) {
        final delta = logs[i].availableSpaces - logs[i - 1].availableSpaces;
        result.add(delta / step.inMinutes);
      }
    }

    return result;
  }

  StationLog? findBestTime(String stationNo) {
    final logs = getLogs(stationNo);
    if (logs == null || logs.isEmpty) return null;

    return logs.reduce((a, b) => a.availableSpaces > b.availableSpaces ? a : b);
  }
}
