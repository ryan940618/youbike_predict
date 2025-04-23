import 'package:flutter/material.dart';
import '../services/analyzer.dart';
import 'histogram.dart';

class StationDetail extends StatelessWidget {
  final Map<String, dynamic> stationData;
  final List<Map<String, dynamic>> bikeDetails;
  final String stationName;
  final List<Map<String, dynamic>> stations;
  final double lat;
  final double lon;
  final List<Map<String, dynamic>> stationStaticInfo;
  const StationDetail({
    super.key,
    required this.stationData,
    required this.bikeDetails,
    required this.stationName,
    required this.stations,
    required this.lat,
    required this.lon,
    required this.stationStaticInfo,
  });

  @override
  Widget build(BuildContext context) {
    final likelyTimes = Analyzer.predictFutureLikely(stationData['station_no']);
    final nearbyStations = Analyzer.formattedFindNearby(
      lat: lat,
      lon: lon,
      realTimeStations: stations,
      stationStaticInfo: stationStaticInfo,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("站點名稱: $stationName",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("編號: ${stationData['station_no']}"),
          Text("停車格總數: ${stationData['parking_spaces']}"),
          Text(
              "可借車數: ${stationData['available_spaces']}（YouBike 2.0: ${stationData['available_spaces_detail']['yb2']}, YouBike 2.0E電輔車: ${stationData['available_spaces_detail']['eyb']}）"),
          Text("空位數: ${stationData['empty_spaces']}"),
          const Divider(),
          bikeDetails.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("電輔車資訊：",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...bikeDetails.map((bike) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                              "${bike['bike_no']} | 電量：${bike['battery_power']}%"),
                        )),
                  ],
                )
              : const SizedBox.shrink(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //const Text("未來可能有車時段："),
              //...likelyTimes.map((t) => Text("• $t")),
              const SizedBox(height: 12),
              const Text("附近有車站點："),
              ...nearbyStations.map((s) => Text("• $s")),
            ],
          ),
          const SizedBox(height: 12),
          HourlyHistogram(
            data: Analyzer.getHourlyAvg(stationData['station_no']),
            title: "每小時平均可借車數",
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          HourlyHistogram(
            data: Analyzer.getHourlyAvgDelta(stationData['station_no']),
            title: "每小時車輛流動量",
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}
