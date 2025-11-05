class Alert {
  final String id;
  final String incubatorId;
  final String alertType;
  final String severity;
  final String message;
  final bool resolved;
  final DateTime createdAt;

  Alert({
    required this.id,
    required this.incubatorId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.resolved,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      incubatorId: json['incubator_id'] as String,
      alertType: json['alert_type'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
      resolved: json['resolved'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isCritical => severity == 'critical';
  bool get isWarning => severity == 'warning';
}

