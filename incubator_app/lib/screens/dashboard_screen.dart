import 'package:flutter/material.dart';
import 'package:incubator_app/services/direct_incubator_service.dart';
import 'package:incubator_app/widgets/temp_gauge.dart';
import 'package:provider/provider.dart';

import '../services/incubator_service.dart';
import '../widgets/humidity_gauge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // For demo purposes, use a default incubator ID
    // In production, this would come from user authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final incubatorId = 'demo-incubator-1';
      context.read<IncubatorService>().setIncubator(incubatorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incubator Dashboard'),
        actions: [
          Consumer<IncubatorService>(
            builder: (context, service, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  service.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: service.isConnected ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<IncubatorService>(
        builder: (context, service, child) {
          final sensorData = service.latestSensorData;
          final config = service.config;

          if (sensorData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Temperature and Humidity Gauges
                Row(
                  children: [
                    Expanded(
                      child: TempGauge(
                        temperature: sensorData.averageTemp,
                        targetTemp: config?.targetTemp ?? 37.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HumidityGauge(
                        humidity: sensorData.humiditySht31,
                        targetHumidity: config?.targetHumidity ?? 55.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // System Status
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'System Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (service is DirectIncubatorService)
                              DropdownButton<int>(
                                value: sensorData.systemMode,
                                items: const [
                                  DropdownMenuItem(
                                    value: 0,
                                    child: Text('Auto'),
                                  ),
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text('Manual'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    (service).setSystemMode(val);
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StatusRow(
                          label: 'Heater',
                          isOn: sensorData.heaterState,
                        ),
                        _StatusRow(
                          label: 'Humidifier',
                          isOn: sensorData.humidifierState,
                        ),
                        _StatusRow(label: 'Fan', isOn: sensorData.fanSpeed > 0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Manual Controls (Only if Manual Mode)
                if (sensorData.systemMode == 1 &&
                    service is DirectIncubatorService) ...[
                  Card(
                    color: Colors.blue[50], // Highlight manual controls
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manual Controls',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              FilterChip(
                                label: const Text('Fan'),
                                selected: sensorData.fanSpeed > 0,
                                onSelected: (val) => (service).toggleFan(val),
                              ),
                              FilterChip(
                                label: const Text('Heater'),
                                selected: sensorData.heaterState,
                                onSelected: (val) =>
                                    (service).toggleHeater(val),
                              ),
                              FilterChip(
                                label: const Text('Humidifier'),
                                selected: sensorData.humidifierState,
                                onSelected: (val) =>
                                    (service).toggleHumidifier(val),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.rotate_right),
                                label: const Text('Turn Eggs'),
                                onPressed: () {
                                  (service).turnEggs();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Turning eggs...'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Sensor Readings
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Temperature Sensors',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ReadingRow(
                          label: 'DS18B20 #1',
                          value: '${sensorData.temp1.toStringAsFixed(1)}°C',
                        ),
                        _ReadingRow(
                          label: 'DS18B20 #2',
                          value: '${sensorData.temp2.toStringAsFixed(1)}°C',
                        ),
                        _ReadingRow(
                          label: 'SHT31',
                          value: '${sensorData.tempSht31.toStringAsFixed(1)}°C',
                        ),
                        _ReadingRow(
                          label: 'Average',
                          value:
                              '${sensorData.averageTemp.toStringAsFixed(1)}°C',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hatch Countdown
                if (config?.hatchDate != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hatch Countdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatCountdown(config!.hatchDate!),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          if (config.daysToHatch != null)
                            Text(
                              '${config.daysToHatch} days remaining',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Alerts
                if (service.alerts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Active Alerts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...service.alerts
                              .take(3)
                              .map(
                                (alert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        alert.isCritical
                                            ? Icons.error
                                            : Icons.warning_amber,
                                        color: alert.isCritical
                                            ? Colors.red
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          alert.message,
                                          style: TextStyle(
                                            color: Colors.red[900],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatCountdown(DateTime hatchDate) {
    final now = DateTime.now();
    final difference = hatchDate.difference(now);

    if (difference.isNegative) {
      return 'Hatch time passed';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    return '${days}d ${hours}h ${minutes}m';
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool? isOn;
  final String? value;

  const _StatusRow({required this.label, this.isOn, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (isOn != null)
            Icon(
              isOn! ? Icons.check_circle : Icons.cancel,
              color: isOn! ? Colors.green : Colors.grey,
            )
          else if (value != null)
            Text(value!, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _ReadingRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
