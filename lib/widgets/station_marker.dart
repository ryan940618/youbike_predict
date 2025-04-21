import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/api.dart';
import '../models/station.dart';
import '../widgets/detail.dart';
import '../screens/map.dart';

class MarkerWidget extends StatefulWidget {
  @override
  _MarkerWidget createState() => _MarkerWidget();
}

class _MarkerWidget extends State<MarkerWidget> {
  late Future<List<Station>> stationsFuture;

  @override
  void initState() {
    super.initState();
    stationsFuture = fetchStations().then((stations) {
      for (var station in stations) {
        MapPage.addStationData({
          'station_no': station.id,
          'name': station.name,
          'lat': station.lat,
          'lon': station.lon,
        });
      }
      return stations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Station>>(
      future: stationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('錯誤: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          List<Station> stations = snapshot.data!;

          List<Marker> stationMarkers = stations.map((station) {
            return Marker(
                width: 8,
                point: LatLng(station.lat, station.lon),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      final stationName = station.name;
                      final infoJson =
                          await fetchStationInfo(station.lat, station.lon);
                      final stationData = infoJson['retVal'][0];
                      final stationNo = stationData['station_no'];
                      final bikeDetails = await fetchStationDetail(stationNo);

                      showModalBottomSheet(
                        context: context,
                        builder: (context) => StationDetail(
                          stationData: stationData,
                          bikeDetails: bikeDetails,
                          stationName: stationName,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('資料讀取失敗：$e')),
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          const Color.fromARGB(255, 255, 0, 0).withOpacity(1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ));
          }).toList();

          return MarkerLayer(markers: stationMarkers);
        } else {
          return const Center(child: Text('載入站點失敗'));
        }
      },
    );
  }
}
