import 'dart:convert';
import 'dart:io';
import 'dart:math';

class StationLog {
  final DateTime timestamp;
  final int availableSpaces;

  StationLog({required this.timestamp, required this.availableSpaces});
}

class Analyzer {
  final Map<String, List<StationLog>> _importedData = {};
  bool get isDataLoaded => _importedData.isNotEmpty;

  Future<void> loadFromFile(File file) async {
    _importedData.clear();
    final lines = await file.readAsLines();

    for (var line in lines) {
      try {
        final data = jsonDecode(line);
        final timestamp = DateTime.parse(data['timestamp']);
        final stations = List<Map<String, dynamic>>.from(data['stations']);

        for (var station in stations) {
          final stationNo = station['station_no'];
          final available = station['available_spaces'];

          _importedData.putIfAbsent(stationNo, () => []);
          _importedData[stationNo]!.add(
            StationLog(timestamp: timestamp, availableSpaces: available),
          );
        }
      } catch (e) {
        print("解析失敗：$e");
      }
    }
  }

  static Map<int, double> getHourlyAvg(
    String stationNo,
    Map<String, List<StationLog>> importedData,
  ) {
    final logs = importedData[stationNo];
    if (logs == null || logs.isEmpty) return {};

    final Map<int, List<int>> hourlyValues = {};

    for (var log in logs) {
      final hour = log.timestamp.hour;
      hourlyValues.putIfAbsent(hour, () => []).add(log.availableSpaces);
    }

    return hourlyValues.map((hour, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(hour, avg);
    });
  }

  static Map<int, double> getHourlyAvgDelta(
    String stationNo,
    Map<String, List<StationLog>> importedData,
  ) {
    final logs = importedData[stationNo];
    if (logs == null || logs.length < 2) return {};

    // 時間排序
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final Map<int, List<int>> hourlyChanges = {};

    for (int i = 1; i < logs.length; i++) {
      final prev = logs[i - 1];
      final curr = logs[i];

      // 必須是同一小時才算變化值
      if (curr.timestamp.hour != prev.timestamp.hour) continue;

      final hour = curr.timestamp.hour;
      final diff = (curr.availableSpaces - prev.availableSpaces).abs();
      hourlyChanges.putIfAbsent(hour, () => []).add(diff);
    }

    return hourlyChanges.map((hour, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      return MapEntry(hour, avg);
    });
  }

  static int? predictFutureLikely(
      String stationNo, Map<String, List<StationLog>> importedData) {
    final hourlyAvg = getHourlyAvg(stationNo, importedData);
    final sorted = hourlyAvg.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.isNotEmpty ? sorted.first.key : null;
  }

  static List<Map<String, dynamic>> findNearby({
    required double lat,
    required double lon,
    required List<Map<String, dynamic>> realTimeStations,
    double maxDistanceMeters = 400,
    int maxResults = 5,
  }) {
    double distance(double lat1, double lon1, double lat2, double lon2) {
      const r = 6371000;
      final dLat = (lat2 - lat1) * 3.1415926 / 180;
      final dLon = (lon2 - lon1) * 3.1415926 / 180;
      final a = (sin(dLat / 2) * sin(dLat / 2)) +
          cos(lat1 * 3.1415926 / 180) *
              cos(lat2 * 3.1415926 / 180) *
              sin(dLon / 2) *
              sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return r * c;
    }

    return realTimeStations
        .where((s) => s['available_spaces'] > 0)
        .map((s) => {
              'station_no': s['station_no'],
              'name': s['name'],
              'available_spaces': s['available_spaces'],
              'distance': distance(lat, lon, s['lat'], s['lon']),
            })
        .where((s) => s['distance'] < maxDistanceMeters)
        .toList()
      ..sort((a, b) => a['distance'].compareTo(b['distance']))
      ..take(maxResults);
  }
}
