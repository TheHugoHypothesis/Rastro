class ActivityRecord {
  final String id;
  final DateTime timestamp;
  final double distanceMeters;
  final double durationSeconds;
  final double calories;

  ActivityRecord({
    required this.id,
    required this.timestamp,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.calories,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'calories': calories,
    };
  }

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
    );
  }
}
