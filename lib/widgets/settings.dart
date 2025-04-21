import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class SettingsDialog extends StatefulWidget {
  final void Function(Map<String, dynamic>) onConfigChanged;
  final VoidCallback onStartLogging;
  final VoidCallback onStopLogging;
  final void Function(File importFile) onImport;

  const SettingsDialog({
    super.key,
    required this.onConfigChanged,
    required this.onStartLogging,
    required this.onStopLogging,
    required this.onImport,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  double minLat = 22.465504, maxLat = 23.099788;
  double minLon = 120.172277, maxLon = 120.613318;
  double interval = 10000;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("設定log參數"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDoubleField("Min Latitude", minLat, (v) => minLat = v),
              _buildDoubleField("Max Latitude", maxLat, (v) => maxLat = v),
              _buildDoubleField("Min Longitude", minLon, (v) => minLon = v),
              _buildDoubleField("Max Longitude", maxLon, (v) => maxLon = v),
              _buildDoubleField("間距密度(m)", interval, (v) => interval = v),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("開始"),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onConfigChanged({
                          "minLat": minLat,
                          "maxLat": maxLat,
                          "minLon": minLon,
                          "maxLon": maxLon,
                          "interval": interval.toInt(),
                        });
                        widget.onStartLogging();
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text("停止"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: widget.onStopLogging,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("匯入"),
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    File file = File(result.files.single.path!);
                    widget.onImport(file);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text("關閉"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildDoubleField(
      String label, double initial, void Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        initialValue: initial.toString(),
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (value) {
          final v = double.tryParse(value ?? "");
          if (v == null) return '請輸入數值';
          return null;
        },
        onChanged: (value) {
          final v = double.tryParse(value);
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
