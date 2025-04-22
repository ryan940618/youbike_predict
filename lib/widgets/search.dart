import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final List<Map<String, dynamic>> stationList;
  final Function(double lat, double lng) onStationSelected;

  const SearchBarWidget({
    super.key,
    required this.stationList,
    required this.onStationSelected,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _filteredStations = [];

  void _filterStations(String query) {
    setState(() {
      _filteredStations = widget.stationList
          .where((station) =>
              station['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          onChanged: _filterStations,
          decoration: InputDecoration(
            hintText: "搜尋站點...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        if (_filteredStations.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredStations.length,
              itemBuilder: (context, index) {
                final station = _filteredStations[index];
                return ListTile(
                  title: Text(station['name']),
                  onTap: () {
                    _controller.clear();
                    setState(() => _filteredStations.clear());
                    widget.onStationSelected(station['lat'], station['lon']);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
