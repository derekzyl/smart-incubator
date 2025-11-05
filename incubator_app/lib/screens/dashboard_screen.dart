import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../services/incubator_service.dart';
import '../services/websocket_service.dart';
import '../models/sensor_data.dart';
import '../widgets/temp_gauge.dart';
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
      context.read<WebSocketService>().connect(incubatorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incubator Dashboard'),
        actions: [
          Consumer<WebSocketService>(
            builder: (context, ws, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  ws.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: ws.isConnected ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<IncubatorService, WebSocketService>(
        builder: (context, service, ws, child) {
          // Use WebSocket data if available, otherwise fall back to service
          final sensorData = ws.latestSensorData ?? service.latestSensorData;
          final config = service.config;
          
          // Update service with WebSocket data
          if (ws.latestSensorData != null && ws.latestSensorData != service.latestSensorData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              service.updateSensorData(ws.latestSensorData!);
            });
          }
          
          // Handle alerts from WebSocket
          if (ws.latestAlert != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              service.addAlert(ws.latestAlert!);
            });
          }

          if (sensorData == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
                        const Text(
                          'System Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                        _StatusRow(
                          label: 'Fan Speed',
                          value: '${sensorData.fanSpeed}%',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                          value: '${sensorData.averageTemp.toStringAsFixed(1)}°C',
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
                          ...service.alerts.take(3).map((alert) => Padding(
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
                              )),
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

  const _StatusRow({
    required this.label,
    this.isOn,
    this.value,
  });

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
            Text(
              value!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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

