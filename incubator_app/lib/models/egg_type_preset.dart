/// Recommended temp, humidity, and turn interval for each egg type.
class EggTypePreset {
  final double targetTemp;
  final double targetHumidity;
  final int turnIntervalHours;

  const EggTypePreset({
    required this.targetTemp,
    required this.targetHumidity,
    required this.turnIntervalHours,
  });

  static const _presets = <String, EggTypePreset>{
    'chicken': EggTypePreset(
      targetTemp: 37.5,
      targetHumidity: 55.0,
      turnIntervalHours: 4,
    ),
    'duck': EggTypePreset(
      targetTemp: 37.5,
      targetHumidity: 55.0,
      turnIntervalHours: 4,
    ),
    'reptile': EggTypePreset(
      targetTemp: 30.0,
      targetHumidity: 85.0,
      turnIntervalHours: 6,
    ),
    'exotic_bird': EggTypePreset(
      targetTemp: 37.5,
      targetHumidity: 55.0,
      turnIntervalHours: 4,
    ),
  };

  static EggTypePreset forType(String eggType) {
    return _presets[eggType] ?? _presets['chicken']!;
  }
}
