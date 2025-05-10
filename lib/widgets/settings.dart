import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:youbike_predict/services/sampler.dart';

class SettingsDialog extends StatefulWidget {
  final Sampler sampler;
  final VoidCallback onStartLogging;
  final VoidCallback onStopLogging;
  final void Function() onImport;

  const SettingsDialog({
    super.key,
    required this.sampler,
    required this.onStartLogging,
    required this.onStopLogging,
    required this.onImport,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  final _minLatController = TextEditingController();
  final _maxLatController = TextEditingController();
  final _minLonController = TextEditingController();
  final _maxLonController = TextEditingController();
  final _intervalController = TextEditingController();

  late double minLat, maxLat, minLon, maxLon, interval;
  bool isLogging = false;

  @override
  void initState() {
    super.initState();

    final config = widget.sampler.getConfig();
    minLat = config['minLat'];
    maxLat = config['maxLat'];
    minLon = config['minLon'];
    maxLon = config['maxLon'];
    interval = config['interval'].toDouble();

    _minLatController.text = minLat.toString();
    _maxLatController.text = maxLat.toString();
    _minLonController.text = minLon.toString();
    _maxLonController.text = maxLon.toString();
    _intervalController.text = interval.toString();

    isLogging = widget.sampler.getLoggingStat();
  }

  void _applyNewConfig() {
    widget.sampler.setConfig({
      "minLat": double.parse(_minLatController.text),
      "maxLat": double.parse(_maxLatController.text),
      "minLon": double.parse(_minLonController.text),
      "maxLon": double.parse(_maxLonController.text),
      "interval": double.parse(_intervalController.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("設定log參數"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDoubleField("Min Latitude", _minLatController),
              _buildDoubleField("Max Latitude", _maxLatController),
              _buildDoubleField("Min Longitude", _minLonController),
              _buildDoubleField("Max Longitude", _maxLonController),
              _buildDoubleField("間距密度(m)", _intervalController),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.mark_chat_read_rounded),
                    label: const Text("套用設定"),
                    onPressed: _applyNewConfig,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("啟用"),
                    onPressed: !isLogging
                        ? () {
                            widget.onStartLogging();
                          }
                        : null,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text("停用"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: isLogging ? widget.onStopLogging : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: const Text("匯入"),
                onPressed: () async {
                  widget.onImport();
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

  Widget _buildDoubleField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (value) {
          final v = double.tryParse(value ?? "");
          if (v == null) return '請輸入數值';
          return null;
        },
      ),
    );
  }
}
