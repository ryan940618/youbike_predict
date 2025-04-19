import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../services/api.dart';
import '../services/logger.dart';

class SamplerService {
  Timer? _timer;
  bool _isLogging = false;

  void startLogging({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required double interval,
    required Duration period,
    required void Function(String log) onLog,
  }) {
    if (_isLogging) return;
    _isLogging = true;

    _timer = Timer.periodic(period, (timer) async {
      final points = generatePoints(minLat, maxLat, minLon, maxLon, interval);
      final stationSet = <String>{};
      final results = <Map<String, dynamic>>[];

      for (final point in points) {
        try {
          print("現在處理 ${point.latitude},${point.longitude}");
          final data = await fetchStationInfo(point.latitude, point.longitude);
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

      await LoggerService.writeLog(results);
      onLog("Logged 站點數量： ${results.length} @ ${DateTime.now()}");
    });
  }

  void stopLogging() {
    _timer?.cancel();
    _isLogging = false;
  }

  List<LatLng> generatePoints(double minLat, double maxLat, double minLon, double maxLon, double intervalMeter) {
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
