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

Future<Map<String, dynamic>> fetchStationInfo(double lat, double lon) async {
  final url = Uri.parse("https://apis.youbike.com.tw/tw2/parkingInfo");
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'lat': lat,
      'lng': lon,
      'maxDistance': 1,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('獲取站點資訊失敗');
  }
}

Future<List<Map<String, dynamic>>> fetchStationDetail(String stationNo) async {
  final url = Uri.parse("https://apis.youbike.com.tw/api/front/bike/lists?station_no=$stationNo");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    return List<Map<String, dynamic>>.from(jsonData['retVal']);
  } else {
    throw Exception('獲取站點詳細資訊失敗');
  }
}