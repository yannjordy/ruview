import '../core/models.dart';

enum ApiError { network, timeout, notFound, serverError, offline, unknown }

class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final String? message;
  bool get isSuccess => data != null && error == null;
  bool get isError => error != null;

  ApiResult.success(this.data) : error = null, message = null;
  ApiResult.failure(this.error, {this.message}) : data = null;
}

class RoomUpdate {
  final String id;
  final String name;
  final DeviceStatus status;
  final int occupantCount;
  final double? breathingRate;
  final int? heartRate;
  final int lastUpdated;

  RoomUpdate({
    required this.id,
    required this.name,
    required this.status,
    this.occupantCount = 0,
    this.breathingRate,
    this.heartRate,
    required this.lastUpdated,
  });

  factory RoomUpdate.fromJson(Map<String, dynamic> json) {
    return RoomUpdate(
      id: json['id'] as String,
      name: json['name'] as String,
      status: _parseStatus(json['status'] as String? ?? 'offline'),
      occupantCount: (json['occupant_count'] as num?)?.toInt() ?? 0,
      breathingRate: (json['breathing_rate'] as num?)?.toDouble(),
      heartRate: (json['heart_rate'] as num?)?.toInt(),
      lastUpdated: (json['last_updated'] as num?)?.toInt() ?? 0,
    );
  }

  static DeviceStatus _parseStatus(String s) => switch (s) {
        'online' => DeviceStatus.online,
        'calibrating' => DeviceStatus.calibrating,
        'error' => DeviceStatus.error,
        _ => DeviceStatus.offline,
      };

  Room toRoom() => Room(
        id: id,
        name: name,
        status: status,
        occupantCount: occupantCount,
        breathingRate: breathingRate,
        heartRate: heartRate,
      );
}
