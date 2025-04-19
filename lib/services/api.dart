import '../models/station.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<Station>> fetchStations() async {
  final res = await http.get(Uri.parse("YOUR_API_URL"));
  final data = json.decode(res.body);
  List<Station> stations = [];

  for (var item in data['data']['retVal']) {
    stations.add(Station.fromJson(item));
  }
  return stations;
}