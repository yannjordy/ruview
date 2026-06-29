enum SensorType {
  presence,
  breathing,
  heartrate,
  pose,
  fall,
  sleep,
}

enum DeviceStatus { online, offline, calibrating, error }

class Room {
  final String id;
  final String name;
  final DeviceStatus status;
  final int occupantCount;
  final double? breathingRate;
  final int? heartRate;
  final DateTime lastUpdated;

  Room({
    required this.id,
    required this.name,
    this.status = DeviceStatus.offline,
    this.occupantCount = 0,
    this.breathingRate,
    this.heartRate,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}

class CsiFrame {
  final int timestamp;
  final List<List<double>> amplitudes;
  final List<List<double>> phases;

  CsiFrame({
    required this.timestamp,
    required this.amplitudes,
    required this.phases,
  });

  factory CsiFrame.fromJson(Map<String, dynamic> json) => CsiFrame(
        timestamp: json['timestamp'] as int,
        amplitudes: (json['amplitude'] as List)
            .map((s) => (s as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
        phases: (json['phase'] as List)
            .map((s) => (s as List).map((v) => (v as num).toDouble()).toList())
            .toList(),
      );
}

class VitalsReading {
  final double? breathingRate;
  final int? heartRate;
  final double? hrConfidence;
  final double? brConfidence;
  final DateTime timestamp;

  VitalsReading({
    this.breathingRate,
    this.heartRate,
    this.hrConfidence,
    this.brConfidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory VitalsReading.fromJson(Map<String, dynamic> json) => VitalsReading(
        breathingRate: (json['breathing_rate'] as num?)?.toDouble(),
        heartRate: json['heart_rate'] as int?,
        hrConfidence: (json['hr_confidence'] as num?)?.toDouble(),
        brConfidence: (json['br_confidence'] as num?)?.toDouble(),
      );
}

class PoseKeypoint {
  final String name;
  final double x;
  final double y;
  final double confidence;

  PoseKeypoint({
    required this.name,
    required this.x,
    required this.y,
    this.confidence = 0.0,
  });
}

class CalibrationStatus {
  final int progressPercent;
  final String phase;
  final bool completed;

  CalibrationStatus({
    this.progressPercent = 0,
    this.phase = 'idle',
    this.completed = false,
  });
}
