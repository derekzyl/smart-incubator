import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/egg_type_preset.dart';
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
    _nameController = TextEditingController(text: 'My Incubator');
    _ipController = TextEditingController();
    _targetTempController = TextEditingController(
      text: EggTypePreset.forType('chicken').targetTemp.toString(),
    );
    _targetHumidityController = TextEditingController(
      text: EggTypePreset.forType('chicken').targetHumidity.toString(),
    );
    _turnIntervalController = TextEditingController(
      text: EggTypePreset.forType('chicken').turnIntervalHours.toString(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialConfig());
  }

  Future<void> _loadInitialConfig() async {
    final service = context.read<IncubatorService>();
    if (service is DirectIncubatorService) {
      await service.loadConfig(service.baseUrl.replaceAll('http://', ''));
      if (!mounted) return;
      final config = service.config;
      setState(() {
        _nameController.text = config?.name ?? 'My Incubator';
        _ipController.text = service.baseUrl.replaceAll('http://', '');
        _targetTempController.text =
            (config?.targetTemp ?? EggTypePreset.forType(_selectedEggType).targetTemp)
                .toString();
        _targetHumidityController.text =
            (config?.targetHumidity ?? EggTypePreset.forType(_selectedEggType).targetHumidity)
                .toString();
        _turnIntervalController.text =
            (config?.turnIntervalHours ?? EggTypePreset.forType(_selectedEggType).turnIntervalHours)
                .toString();
        _selectedEggType = config?.eggType ?? 'chicken';
        _selectedHatchDate = config?.hatchDate;
      });
    } else {
      final config = service.config;
      if (config != null) {
        setState(() {
          _nameController.text = config.name;
          _targetTempController.text = config.targetTemp.toString();
          _targetHumidityController.text = config.targetHumidity.toString();
          _turnIntervalController.text = config.turnIntervalHours.toString();
          _selectedEggType = config.eggType;
          _selectedHatchDate = config.hatchDate;
        });
      }
    }
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
    final incubatorId = service.currentIncubatorId ?? 'esp32_device';

    final config = IncubatorConfig(
      id: incubatorId,
      userId: service.config?.userId ?? 'default_user',
      name: _nameController.text,
      eggType: _selectedEggType,
      hatchDate: _selectedHatchDate,
      targetTemp: double.parse(_targetTempController.text),
      targetHumidity: double.parse(_targetHumidityController.text),
      turnIntervalHours: int.parse(_turnIntervalController.text),
      createdAt: service.config?.createdAt ?? DateTime.now(),
    );

    if (service is DirectIncubatorService) {
      await service.setIpAddress(_ipController.text);
      try {
        await service.updateConfig(
          service.baseUrl.replaceAll('http://', ''),
          config,
        );
        await service.setSystemMode(0); // Switch to Auto mode with new settings
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sync with device: $e')),
          );
        }
        return;
      }
    } else {
      await service.updateConfig(incubatorId, config);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved and synced to device')),
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
              value: _selectedEggType,
              decoration: const InputDecoration(
                labelText: 'Egg Type',
                border: OutlineInputBorder(),
                helperText: 'Select to apply recommended presets',
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
                    final preset = EggTypePreset.forType(value);
                    _targetTempController.text = preset.targetTemp.toString();
                    _targetHumidityController.text =
                        preset.targetHumidity.toString();
                    _turnIntervalController.text =
                        preset.turnIntervalHours.toString();
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
