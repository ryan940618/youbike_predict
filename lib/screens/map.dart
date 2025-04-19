import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/station_marker.dart';
import '../services/logger.dart';
import '../services/sampler.dart';
import '../widgets/settings.dart';
import 'dart:io';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});
  final String title;
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final SamplerService samplerService;
  Map<String, dynamic> currentConfig = {};

  @override
  void initState() {
    super.initState();
    samplerService = SamplerService();
  }

  @override
  void dispose() {
    samplerService.stopLogging();
    super.dispose();
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        onConfigChanged: (config) {
          currentConfig = config;
        },
        onStartLogging: () async {
          final ok = await LoggerService.initLogFile();
          if (!ok) return;
      
          samplerService.startLogging(
          minLat: currentConfig["minLat"],
          maxLat: currentConfig["maxLat"],
          minLon: currentConfig["minLon"],
          maxLon: currentConfig["maxLon"],
          interval: currentConfig["interval"],
          period: const Duration(minutes: 1),
          onLog: (msg) => print("[Log]$msg"),
          );
        },
        onStopLogging: () {
          samplerService.stopLogging();
        },
        onImport: (File file) async {
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
                MarkerWidget(),
              ],
            ),
          ),
          const Positioned(
            left: 10,
            bottom: 10,
            child: Column(
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
                  "timestamp",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
