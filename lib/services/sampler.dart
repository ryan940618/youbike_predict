import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../services/api.dart';
import '../services/logger.dart';

class Sampler {
  static Timer? _timer;
  bool _isLogging = false;

  double _minLat = 22.465504, _maxLat = 23.099788;
  double _minLon = 120.172277, _maxLon = 120.613318;
  double _interval = 16000;
  Duration period = const Duration(minutes: 1);

  bool getLoggingStat() {
    return _isLogging;
  }

  Map<String, dynamic> getConfig() {
    return {
      "minLat": _minLat,
      "maxLat": _maxLat,
      "minLon": _minLon,
      "maxLon": _maxLon,
      "interval": _interval,
    };
  }

  void setConfig(Map<String, dynamic> config) {
    _minLat = config["minLat"];
    _maxLat = config["maxLat"];
    _minLon = config["minLon"];
    _maxLon = config["maxLon"];
    _interval = config["interval"];
  }

  void startJob({
    required void Function(String log) onLog,
    required void Function(List<Map<String, dynamic>>) onStationsUpdated,
  }) {
    _performLogging(_minLat, _maxLat, _minLon, _maxLon, _interval, onLog,
        onStationsUpdated);

    _timer = Timer.periodic(period, (timer) {
      _performLogging(_minLat, _maxLat, _minLon, _maxLon, _interval, onLog,
          onStationsUpdated);
    });
  }

  Future<bool> startLogging() async {
    final success = await LoggerService.initLogFile();
    if (!success) return false;

    _isLogging = true;
    return true;
  }

  void _performLogging(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
    double interval,
    void Function(String log) onLog,
    void Function(List<Map<String, dynamic>>) onStationsUpdated,
  ) async {
    final points = generatePoints(minLat, maxLat, minLon, maxLon, interval);
    final stationSet = <String>{};
    final results = <Map<String, dynamic>>[];

    for (final point in points) {
      try {
        final data =
            await fetchStationInfo(point.latitude, point.longitude, 10000);
        final list = data['retVal'];
        for (var item in list) {
          if (stationSet.add(item['station_no'])) {
            results.add(item);
          }
        }
      } catch (e) {
        print("座標 ${point.latitude},${point.longitude} 處取得資料失敗: $e");
      }
    }

    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'stations': results,
    };
    onStationsUpdated(results);

    if (_isLogging) {
      await LoggerService.writeLog([logEntry]);
    }
    onLog("Logged 站點數量：${results.length} @ ${DateTime.now()}");
  }

  Future<void> stopLogging() async {
    await LoggerService.closeLog();
    _isLogging = false;
  }

  List<LatLng> generatePoints(double minLat, double maxLat, double minLon,
      double maxLon, double intervalMeter) {
    // 把 interval (meter) 轉成經緯度位移，然後產生網格點
    // 約略換算：1 度緯度 ≈ 111000 公尺
    final delta = intervalMeter / 111000;
    final points = <LatLng>[];

    for (double lat = minLat; lat <= maxLat; lat += delta) {
      for (double lon = minLon; lon <= maxLon; lon += delta) {
        points.add(LatLng(lat, lon));
      }
    }
    return points;
  }
}
