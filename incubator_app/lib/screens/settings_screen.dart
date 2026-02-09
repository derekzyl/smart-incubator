import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/incubator_config.dart';
import '../services/direct_incubator_service.dart';
import '../services/incubator_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipController; // New IP Controller
  late TextEditingController _targetTempController;
  late TextEditingController _targetHumidityController;
  late TextEditingController _turnIntervalController;
  String _selectedEggType = 'chicken';
  DateTime? _selectedHatchDate;

  @override
  void initState() {
    super.initState();
    final service = context.read<IncubatorService>();
    final config = service.config;

    _nameController = TextEditingController(
      text: config?.name ?? 'My Incubator',
    );

    String currentIp = '';
    if (service is DirectIncubatorService) {
      currentIp = service.baseUrl.replaceAll('http://', '');
    }

    _ipController = TextEditingController(text: currentIp);

    _targetTempController = TextEditingController(
      text: (config?.targetTemp ?? 37.5).toString(),
    );
    _targetHumidityController = TextEditingController(
      text: (config?.targetHumidity ?? 55.0).toString(),
    );
    _turnIntervalController = TextEditingController(
      text: (config?.turnIntervalHours ?? 4).toString(),
    );
    _selectedEggType = config?.eggType ?? 'chicken';
    _selectedHatchDate = config?.hatchDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _targetTempController.dispose();
    _targetHumidityController.dispose();
    _turnIntervalController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final service = context.read<IncubatorService>();
    final incubatorId = service.currentIncubatorId;

    if (incubatorId == null || _selectedHatchDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hatch date')),
      );
      return;
    }

    final config = IncubatorConfig(
      id: incubatorId ?? 'esp32_device',
      userId: service.config?.userId ?? 'default_user',
      name: _nameController.text,
      eggType: _selectedEggType,
      hatchDate: _selectedHatchDate,
      targetTemp: double.parse(_targetTempController.text),
      targetHumidity: double.parse(_targetHumidityController.text),
      turnIntervalHours: int.parse(_turnIntervalController.text),
      createdAt: service.config?.createdAt ?? DateTime.now(),
    );

    // Save IP Address
    if (service is DirectIncubatorService) {
      await service.setIpAddress(_ipController.text);
    }

    // await service.updateConfig(incubatorId, config); // Backend update skipped for now

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  Future<void> _selectHatchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedHatchDate ?? DateTime.now().add(const Duration(days: 21)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedHatchDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Incubator Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Only show IP config if using Direct Service
            if (context.read<IncubatorService>() is DirectIncubatorService) ...[
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'ESP32 IP Address',
                  hintText: 'e.g., 192.168.4.1',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the IP shown on Telegram/Serial',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter IP address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedEggType,
              decoration: const InputDecoration(
                labelText: 'Egg Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'chicken', child: Text('Chicken')),
                DropdownMenuItem(value: 'duck', child: Text('Duck')),
                DropdownMenuItem(value: 'reptile', child: Text('Reptile')),
                DropdownMenuItem(
                  value: 'exotic_bird',
                  child: Text('Exotic Bird'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedEggType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _selectHatchDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expected Hatch Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedHatchDate != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedHatchDate!)
                      : 'Select date',
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _targetTempController,
              decoration: const InputDecoration(
                labelText: 'Target Temperature (°C)',
                border: OutlineInputBorder(),
                helperText: 'Recommended: 37.5°C for chicken eggs',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target temperature';
                }
                final temp = double.tryParse(value);
                if (temp == null || temp < 30 || temp > 45) {
                  return 'Temperature must be between 30 and 45°C';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _targetHumidityController,
              decoration: const InputDecoration(
                labelText: 'Target Humidity (%)',
                border: OutlineInputBorder(),
                helperText: 'Recommended: 50-65% for chicken eggs',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target humidity';
                }
                final humidity = double.tryParse(value);
                if (humidity == null || humidity < 0 || humidity > 100) {
                  return 'Humidity must be between 0 and 100%';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _turnIntervalController,
              decoration: const InputDecoration(
                labelText: 'Turn Interval (hours)',
                border: OutlineInputBorder(),
                helperText: 'Recommended: 4 hours for chicken eggs',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter turn interval';
                }
                final interval = int.tryParse(value);
                if (interval == null || interval < 1 || interval > 24) {
                  return 'Interval must be between 1 and 24 hours';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
