class Station {
  final String id;
  final String name;
  final double lat;
  final double lon;
  int total = -1;
  var availability = [-1, -1];
  int available = -1;
  int empty = -1;
  int forbidden = -1;
  int level = -1;

  Station({required this.id, required this.name, required this.lat, required this.lon});

  factory Station.listJson(Map<String, dynamic> json) {
    return Station(
      id: json['sno'],
      name: json['sna'],
      lat: double.parse(json['lat']),
      lon: double.parse(json['lng']),
    );
  }
}