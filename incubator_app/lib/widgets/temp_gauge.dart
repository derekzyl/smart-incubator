import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class TempGauge extends StatelessWidget {
  final double temperature;
  final double targetTemp;

  const TempGauge({
    super.key,
    required this.temperature,
    required this.targetTemp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Temperature',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 30,
                    maximum: 45,
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 30,
                        endValue: targetTemp - 1,
                        color: Colors.blue,
                      ),
                      GaugeRange(
                        startValue: targetTemp - 1,
                        endValue: targetTemp + 1,
                        color: Colors.green,
                      ),
                      GaugeRange(
                        startValue: targetTemp + 1,
                        endValue: 45,
                        color: Colors.red,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: temperature,
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
                              '${temperature.toStringAsFixed(1)}°C',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Target: ${targetTemp.toStringAsFixed(1)}°C',
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

