import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/incubator_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _prediction;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    final service = context.read<IncubatorService>();
    final incubatorId = service.currentIncubatorId;
    if (incubatorId != null) {
      final prediction = await service.getHatchPrediction(incubatorId);
      setState(() {
        _prediction = prediction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IncubatorService>();
    final incubatorId = service.currentIncubatorId;

    if (incubatorId == null) {
      return const Scaffold(
        body: Center(child: Text('No incubator selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrediction,
          ),
        ],
      ),
      body: _prediction == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hatch Success Prediction
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hatch Success Prediction',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CircularProgressIndicator(
                            value: _prediction!['predicted_success_rate'] as double,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              (_prediction!['predicted_success_rate'] as double) > 0.7
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              '${((_prediction!['predicted_success_rate'] as double) * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_prediction!['days_remaining'] != null)
                            Center(
                              child: Text(
                                '${_prediction!['days_remaining']} days until hatch',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Performance Metrics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _MetricRow(
                            label: 'Temperature Stability',
                            value: _prediction!['temp_stability_score'] as int,
                            maxValue: 100,
                          ),
                          _MetricRow(
                            label: 'Humidity Score',
                            value: _prediction!['humidity_score'] as int,
                            maxValue: 100,
                          ),
                          _MetricRow(
                            label: 'Turn Compliance',
                            value: _prediction!['turn_compliance'] as int,
                            maxValue: 100,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recommendations
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommendations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...((_prediction!['recommendations'] as List)
                              .map((rec) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(rec as String),
                                        ),
                                      ],
                                    ),
                                  ))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = value / maxValue;
    Color color;
    if (percentage >= 0.8) {
      color = Colors.green;
    } else if (percentage >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '$value/$maxValue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}

