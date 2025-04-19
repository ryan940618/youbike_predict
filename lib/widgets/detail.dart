import 'package:flutter/material.dart';

class StationDetail extends StatelessWidget {
  final Map<String, dynamic> stationData;
  final List<Map<String, dynamic>> bikeDetails;
  final String stationName;

  const StationDetail({
    super.key,
    required this.stationData,
    required this.bikeDetails,
    required this.stationName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("站點名稱: ${stationName}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("編號: ${stationData['station_no']}"),
          Text("停車格總數: ${stationData['parking_spaces']}"),
          Text("可借車數: ${stationData['available_spaces']}（YouBike 2.0: ${stationData['available_spaces_detail']['yb2']}, YouBike 2.0E電輔車: ${stationData['available_spaces_detail']['eyb']}）"),
          Text("空位數: ${stationData['empty_spaces']}"),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}
