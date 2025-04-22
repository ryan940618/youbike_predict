import 'package:flutter/material.dart';

class HourlyHistogram extends StatelessWidget {
  final Map<int, double> data;
  final String title;
  final Color color;

  const HourlyHistogram({
    super.key,
    required this.data,
    this.title = "每小時統計",
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(24, (i) => i);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hours.length,
            itemBuilder: (context, index) {
              final hour = hours[index];
              final value = data[hour] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10)),
                    Container(
                      width: 20,
                      height: value,
                      color: color,
                    ),
                    const SizedBox(height: 4),
                    Text(hour.toString()),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
