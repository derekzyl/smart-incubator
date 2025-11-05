import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HumidityGauge extends StatelessWidget {
  final double humidity;
  final double targetHumidity;

  const HumidityGauge({
    super.key,
    required this.humidity,
    required this.targetHumidity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Humidity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: targetHumidity - 10,
                        color: Colors.orange,
                      ),
                      GaugeRange(
                        startValue: targetHumidity - 10,
                        endValue: targetHumidity + 10,
                        color: Colors.green,
                      ),
                      GaugeRange(
                        startValue: targetHumidity + 10,
                        endValue: 100,
                        color: Colors.blue,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: humidity,
                        needleColor: Colors.black,
                        needleStartWidth: 1,
                        needleEndWidth: 3,
                        needleLength: 0.8,
                        knobStyle: const KnobStyle(
                          knobRadius: 0.08,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${humidity.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Target: ${targetHumidity.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

