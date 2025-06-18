import 'package:flutter/material.dart';
import 'package:youbike_predict/services/sampler.dart';
import '../services/analyzer.dart';

class SettingsDialog extends StatefulWidget {
  final Sampler sampler;
  final Future<bool> Function() onStartLogging;
  final Future<void> Function() onStopLogging;

  const SettingsDialog({
    super.key,
    required this.sampler,
    required this.onStartLogging,
    required this.onStopLogging,
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

  final _urlController = TextEditingController();
  late double minLat, maxLat, minLon, maxLon, interval;
  late String baseurl;
  late bool allowUpload;
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
    baseurl = Analyzer.getBaseUrl();
    allowUpload = Analyzer.getUploadcfg();

    _minLatController.text = minLat.toString();
    _maxLatController.text = maxLat.toString();
    _minLonController.text = minLon.toString();
    _maxLonController.text = maxLon.toString();
    _intervalController.text = interval.toString();
    _urlController.text = baseurl;

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
              ElevatedButton.icon(
                icon: const Icon(Icons.mark_chat_read_rounded),
                label: const Text("套用設定"),
                onPressed: _applyNewConfig,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("啟用"),
                    onPressed: !isLogging
                        ? () async {
                            final ok = await widget.onStartLogging();
                            if (ok) {
                              setState(() {
                                isLogging = widget.sampler.getLoggingStat();
                              });
                            }
                          }
                        : null,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text("停用"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: isLogging
                        ? () async {
                            await widget.onStopLogging();
                            setState(() {
                              isLogging = widget.sampler.getLoggingStat();
                            });
                          }
                        : null,
                  ),
                ],
              ),
              CheckboxListTile(
                title: const Text('自動上傳至API'),
                value: allowUpload,
                onChanged: isLogging
                    ? (bool? value) {
                        if (value != null) {
                          setState(() {
                            allowUpload = value;
                          });
                          Analyzer.setUploadcfg(value);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: "資料庫API位置",
                ),
                onChanged: (value) {
                  Analyzer.setBaseUrl(value);
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
