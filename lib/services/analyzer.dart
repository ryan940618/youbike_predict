import 'dart:convert';
import 'dart:io';
import 'dart:math';

class StationLog {
  final DateTime timestamp;
  final int availableSpaces;

  StationLog({required this.timestamp, required this.availableSpaces});
}

class Analyzer {
  static Map<String, List<StationLog>> _importedData = {};
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
  ) {
    final logs = _importedData[stationNo];
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
  ) {
    final logs = _importedData[stationNo];
    if (logs == null || logs.length < 2) return {};

    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final Map<int, List<int>> hourlyChanges = {};

    for (int i = 1; i < logs.length; i++) {
      final prev = logs[i - 1];
      final curr = logs[i];

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

  static List<String> predictFutureLikely(String stationNo,
      {int maxItems = 5}) {
    final hourlyAvg = getHourlyAvg(stationNo);
    final sorted = hourlyAvg.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return sorted.take(maxItems).map((entry) {
      final hour = entry.key;
      return "${hour.toString().padLeft(2, '0')}時15分";
    }).toList();
  }

  static List<Map<String, dynamic>> findNearby({
    required double lat,
    required double lon,
    required List<Map<String, dynamic>> realTimeStations,
    required List<Map<String, dynamic>> staticStationData,
    double maxDistanceMeters = 400,
    int maxResults = 5,
  }) {
    double distance(double lat1, double lon1, double lat2, double lon2) {
      const r = 6371000;
      final dLat = (lat2 - lat1) * 3.1415926 / 180;
      final dLon = (lon2 - lon1) * 3.1415926 / 180;
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(lat1 * 3.1415926 / 180) *
              cos(lat2 * 3.1415926 / 180) *
              sin(dLon / 2) *
              sin(dLon / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return r * c;
    }

    final result = realTimeStations
        .where((s) => s['available_spaces'] > 0)
        .map((s) {
          final staticInfo = staticStationData.firstWhere(
            (e) => e['station_no'] == s['station_no'],
            orElse: () => {},
          );

          if (staticInfo.isEmpty ||
              staticInfo['lat'] == null ||
              staticInfo['lon'] == null) {
            return <String, dynamic>{};
          }

          final stationLat = staticInfo['lat'];
          final stationLon = staticInfo['lon'];

          return {
            'station_no': s['station_no'],
            'name': staticInfo['name'],
            'available_spaces': s['available_spaces'],
            'yb2': s['available_spaces_detail']?['yb2'] ?? 0,
            'eyb': s['available_spaces_detail']?['eyb'] ?? 0,
            'distance': distance(lat, lon, stationLat, stationLon).round(),
          };
        })
        .whereType<Map<String, dynamic>>()
        .where((s) => s['distance'] != null && s['distance'] > 0)
        .toList();

    result.removeWhere((s) => s.isEmpty);

    result.sort((a, b) => a['distance'].compareTo(b['distance']));
    result.length = min(maxResults, result.length);

    return result;
  }

  static List<String> formattedFindNearby({
    required double lat,
    required double lon,
    required List<Map<String, dynamic>> realTimeStations,
    required List<Map<String, dynamic>> stationStaticInfo,
    int maxResults = 5,
  }) {
    final results = findNearby(
      lat: lat,
      lon: lon,
      realTimeStations: realTimeStations,
      maxResults: maxResults,
      staticStationData: stationStaticInfo,
    );

    return results.map((s) {
      final name = (s['name'] ?? '無站名').replaceAll('YouBike2.0_', '');
      final distance = s['distance']?.toStringAsFixed(0) ?? '?';
      final available = s['available_spaces'] ?? 0;
      final total = s['parking_spaces'] ?? 0;
      final yb2 = s['yb2'] ?? 0;
      final eyb = s['eyb'] ?? 0;

      return "$name(${distance}m)\n車輛數:$available/$total (YouBike 2.0:$yb2 電輔車:$eyb)";
    }).toList();
  }
}
