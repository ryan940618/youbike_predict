class Station {
  final String id;
  final String name;
  final double lat;
  final double lon;

  Station({required this.id, required this.name, required this.lat, required this.lon});

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['sno'],
      name: json['sna'],
      lat: double.parse(json['lat']),
      lon: double.parse(json['lng']),
    );
  }
}