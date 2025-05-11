import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/logger.dart';
import '../services/sampler.dart';
import '../widgets/settings.dart';
import '../services/api.dart';
import '../widgets/detail.dart';
import '../widgets/search.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});
  final String title;
  static List<Map<String, dynamic>> stationStaticInfo = [];
  static void addStationData(Map<String, dynamic> stationData) {
    stationStaticInfo.add(stationData);
  }

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController mapController;
  String timestamp = "正在載入...";
  List<Map<String, dynamic>> get stationStaticInfo => MapPage.stationStaticInfo;
  late final Sampler sampler;
  Map<String, dynamic> currentConfig = {};

  @override
  void initState() {
    mapController = MapController();
    super.initState();
    sampler = Sampler();
    fetchStations().then((stations) {
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

    sampler.startJob(
      onLog: (msg) => print("[Log]$msg"),
      onStationsUpdated: onStationsUpdated,
    );
  }

  void focusMap(double lat, double lng) {
    mapController.move(LatLng(lat, lng), 20.0);
  }

  @override
  void dispose() {
    sampler.stopLogging();
    super.dispose();
  }

  List<Map<String, dynamic>> stations = [];
  List<Marker> markers = [];

  void updateMarkers() {
    int count = 0;
    markers = stations
        .map((station) {
          Map<String, dynamic>? staticData = stationStaticInfo.firstWhere(
            (info) => info['station_no'] == station['station_no'],
            orElse: () => <String, dynamic>{},
          );

          if (staticData.isEmpty) return null;
          count++;
          final lat = staticData['lat'];
          final lon = staticData['lon'];
          final name = staticData['name'];
          final color = getColorByAvailability(station['available_spaces']);
          return Marker(
              width: 25,
              point: LatLng(lat, lon),
              child: GestureDetector(
                onTap: () async {
                  try {
                    final stationName = name;
                    final infoJson = await fetchStationInfo(lat, lon);
                    final stationData = infoJson['retVal'][0];
                    final stationNo = stationData['station_no'];
                    final bikeDetails = await fetchStationDetail(stationNo);

                    showModalBottomSheet(
                      context: context,
                      builder: (context) => StationDetail(
                        stationData: stationData,
                        bikeDetails: bikeDetails,
                        stationName: stationName,
                        stations: stations,
                        lat: lat,
                        lon: lon,
                        stationStaticInfo: stationStaticInfo,
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
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ));
        })
        .whereType<Marker>()
        .toList();
    print("共更新站點 ${count} 站");
  }

  Color getColorByAvailability(int availableSpaces) {
    if (availableSpaces == 0) return Colors.red;
    if (availableSpaces < 5) return Colors.orange;
    return Colors.green;
  }

  void onStationsUpdated(List<Map<String, dynamic>> newStations) {
    setState(() {
      stations = newStations;
      updateMarkers();
      timestamp = DateTime.now().toString();
    });
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        sampler: sampler,
        onStartLogging: () async {
          sampler.startLogging();
        },
        onStopLogging: () {
          sampler.stopLogging();
        },
        onImport: () async {
          await LoggerService.importFromFile();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("匯入完成")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF292929),
        titleTextStyle: const TextStyle(
          color: Color(0xffa3a3a3),
          fontSize: 18,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: LatLng(23.761, 120.958),
                initialZoom: 7.5,
              ),
              children: [
                Container(
                  color: const Color(0xFF292929),
                ),
                TileLayer(
                  urlTemplate:
                      'https://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}&s=Ga',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SearchBarWidget(
              stationList: stationStaticInfo,
              onStationSelected: (lat, lng) => focusMap(lat, lng),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: kToolbarHeight,
              color: const Color(0xFF292929),
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '更新時間：',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
