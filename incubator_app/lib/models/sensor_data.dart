class SensorData {
  final String incubatorId;
  final double temp1;
  final double temp2;
  final double tempSht31;
  final double humiditySht31;
  final bool heaterState;
  final bool humidifierState;
  final int fanSpeed;
  final DateTime timestamp;

  SensorData({
    required this.incubatorId,
    required this.temp1,
    required this.temp2,
    required this.tempSht31,
    required this.humiditySht31,
    required this.heaterState,
    required this.humidifierState,
    required this.fanSpeed,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      incubatorId: json['incubator_id'] as String,
      temp1: (json['temp_1'] as num).toDouble(),
      temp2: (json['temp_2'] as num).toDouble(),
      tempSht31: (json['temp_sht31'] as num).toDouble(),
      humiditySht31: (json['humidity_sht31'] as num).toDouble(),
      heaterState: json['heater_state'] as bool,
      humidifierState: json['humidifier_state'] as bool,
      fanSpeed: json['fan_speed'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  double get averageTemp => (temp1 + temp2 + tempSht31) / 3.0;
}

