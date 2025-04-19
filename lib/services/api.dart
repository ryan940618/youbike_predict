import '../models/station.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<Station>> fetchStations() async {
  final res = await http.get(Uri.parse("https://api.kcg.gov.tw/api/service/Get/b4dd9c40-9027-4125-8666-06bef1756092"));
  final data = json.decode(res.body);
  List<Station> stations = [];

  for (var item in data['data']['data']['retVal']) {
    stations.add(Station.fromJson(item));
  }
  return stations;
}