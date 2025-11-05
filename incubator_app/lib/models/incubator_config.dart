class IncubatorConfig {
  final String id;
  final String userId;
  final String? deviceId;
  final String name;
  final String eggType;
  final DateTime? hatchDate;
  final double targetTemp;
  final double targetHumidity;
  final int turnIntervalHours;
  final DateTime createdAt;

  IncubatorConfig({
    required this.id,
    required this.userId,
    this.deviceId,
    required this.name,
    required this.eggType,
    this.hatchDate,
    required this.targetTemp,
    required this.targetHumidity,
    required this.turnIntervalHours,
    required this.createdAt,
  });

  factory IncubatorConfig.fromJson(Map<String, dynamic> json) {
    return IncubatorConfig(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String?,
      name: json['name'] as String,
      eggType: json['egg_type'] as String,
      hatchDate: json['hatch_date'] != null
          ? DateTime.parse(json['hatch_date'] as String)
          : null,
      targetTemp: (json['target_temp'] as num).toDouble(),
      targetHumidity: (json['target_humidity'] as num).toDouble(),
      turnIntervalHours: json['turn_interval_hours'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'egg_type': eggType,
      'hatch_date': hatchDate?.toIso8601String(),
      'target_temp': targetTemp,
      'target_humidity': targetHumidity,
      'turn_interval_hours': turnIntervalHours,
    };
  }

  int? get daysToHatch {
    if (hatchDate == null) return null;
    final now = DateTime.now();
    final difference = hatchDate!.difference(now);
    return difference.inDays;
  }
}

