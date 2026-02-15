class Schedule {
  final int id;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int deviceType; // 0=Fan, 1=Heater, 2=Humidifier
  final bool activeState;
  final int daysMask; // Bitmask: 1=Sun, 2=Mon, 4=Tue...
  final bool enabled;

  Schedule({
    this.id = 0,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.deviceType,
    this.activeState = true,
    this.daysMask = 127, // Default all days
    this.enabled = true,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as int? ?? 0,
      startHour: json['startHour'] as int,
      startMinute: json['startMinute'] as int,
      endHour: json['endHour'] as int,
      endMinute: json['endMinute'] as int,
      deviceType: json['deviceType'] as int,
      activeState: json['activeState'] as bool? ?? true,
      daysMask: json['daysMask'] as int? ?? 127,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'deviceType': deviceType,
      'activeState': activeState,
      'daysMask': daysMask,
      'enabled': enabled,
    };
  }

  String get deviceName {
    switch (deviceType) {
      case 0:
        return 'Fan';
      case 1:
        return 'Heater';
      case 2:
        return 'Humidifier';
      case 3:
        return 'Turner';
      default:
        return 'Unknown';
    }
  }

  String _formatTime(int h, int m) {
    // Simple HH:MM format
    String hour = h.toString().padLeft(2, '0');
    String minute = m.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get timeRange =>
      '${_formatTime(startHour, startMinute)} - ${_formatTime(endHour, endMinute)}';
}
