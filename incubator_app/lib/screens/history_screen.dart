import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/incubator_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedResolution = '5min';
  int _selectedDays = 7;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IncubatorService>();
    final incubatorId = service.currentIncubatorId;

    if (incubatorId == null) {
      return const Scaffold(
        body: Center(child: Text('No incubator selected')),
      );
    }

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: _selectedDays));

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: service.getHistory(incubatorId, startDate, endDate,
            resolution: _selectedResolution),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final data = snapshot.data!;

          return Column(
            children: [
              // Controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedResolution,
                        items: const [
                          DropdownMenuItem(value: '1min', child: Text('1 min')),
                          DropdownMenuItem(value: '5min', child: Text('5 min')),
                          DropdownMenuItem(value: '1hour', child: Text('1 hour')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedResolution = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedDays,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 day')),
                          DropdownMenuItem(value: 7, child: Text('7 days')),
                          DropdownMenuItem(value: 30, child: Text('30 days')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedDays = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Temperature Chart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Temperature History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final date = DateTime.fromMillisecondsSinceEpoch(
                                          value.toInt(),
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            DateFormat('MM/dd HH:mm').format(date),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: data
                                        .where((d) => d['avg_temp_1'] != null)
                                        .map((d) => FlSpot(
                                              DateTime.parse(d['time'] as String)
                                                  .millisecondsSinceEpoch
                                                  .toDouble(),
                                              (d['avg_temp_1'] as num).toDouble(),
                                            ))
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: data
                                        .where((d) => d['avg_temp_sht31'] != null)
                                        .map((d) => FlSpot(
                                              DateTime.parse(d['time'] as String)
                                                  .millisecondsSinceEpoch
                                                  .toDouble(),
                                              (d['avg_temp_sht31'] as num).toDouble(),
                                            ))
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.red,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                                minX: startDate.millisecondsSinceEpoch.toDouble(),
                                maxX: endDate.millisecondsSinceEpoch.toDouble(),
                                minY: 30,
                                maxY: 45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _LegendItem(color: Colors.blue, label: 'DS18B20 #1'),
                              const SizedBox(width: 16),
                              _LegendItem(color: Colors.red, label: 'SHT31'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Humidity Chart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Humidity History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: true),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      getTitlesWidget: (value, meta) {
                                        final date = DateTime.fromMillisecondsSinceEpoch(
                                          value.toInt(),
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            DateFormat('MM/dd HH:mm').format(date),
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: data
                                        .where((d) => d['avg_humidity'] != null)
                                        .map((d) => FlSpot(
                                              DateTime.parse(d['time'] as String)
                                                  .millisecondsSinceEpoch
                                                  .toDouble(),
                                              (d['avg_humidity'] as num).toDouble(),
                                            ))
                                        .toList(),
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                                minX: startDate.millisecondsSinceEpoch.toDouble(),
                                maxX: endDate.millisecondsSinceEpoch.toDouble(),
                                minY: 0,
                                maxY: 100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

