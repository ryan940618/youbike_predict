import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:io';

class StationLog {
  final DateTime timestamp;
  final int availableSpaces;

  StationLog({required this.timestamp, required this.availableSpaces});
}

class Analyzer {
  static String _baseUrl = "http://localhost:5000";

  static String getBaseUrl() {
    return _baseUrl;
  }

  static setBaseUrl(String url) {
    _baseUrl = url;
  }

  static Future<Map<int, double>> getHourlyAvg(String stationNo) async {
    final response =
        await http.get(Uri.parse("$_baseUrl/api/hourly_avg/$stationNo"));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data
          .map((key, value) => MapEntry(int.parse(key), value.toDouble()));
    } else {
      throw Exception("Failed to load hourly average data");
    }
  }

  static Future<Map<int, double>> getHourlyAvgDelta(String stationNo) async {
    final response =
        await http.get(Uri.parse("$_baseUrl/api/hourly_delta/$stationNo"));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data
          .map((key, value) => MapEntry(int.parse(key), value.toDouble()));
    } else {
      throw Exception("Failed to load hourly delta data");
    }
  }

  static Future<List<String>> predictFutureLikely(String stationNo,
      {int maxItems = 5}) async {
    final hourlyAvg = await getHourlyAvg(stationNo);
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
            'parking_spaces': s['parking_spaces'],
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

      return "$name(${distance}m)\n車輛數:$available/$total (YouBike 2.0: $yb2 電輔車: $eyb)";
    }).toList();
  }

  static Future<void> uploadLogFile(File file) async {
    try {
      final url = Uri.parse('$_baseUrl/upload');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: await file.readAsString(),
      );

      if (response.statusCode == 200) {
        print("上傳成功: ${file.path}");
      } else {
        print("上傳失敗: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("上傳失敗: $e");
    }
  }
}
