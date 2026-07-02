import 'dart:math';
import 'dart:async';
import '../core/models.dart';
import '../core/api_types.dart';

class ApiService {
  Timer? _dataTimer;
  Timer? _calibTimer;
  int _calibProgress = 0;
  bool _calibrating = false;

  final _rng = Random(42);
  final _rooms = <String, _SimRoom>{};
  double _globalPhase = 0;

  final StreamController<CsiFrame> _csiController =
      StreamController<CsiFrame>.broadcast();
  final StreamController<VitalsReading> _vitalsController =
      StreamController<VitalsReading>.broadcast();
  final StreamController<ApiError> _errorController =
      StreamController<ApiError>.broadcast();

  Stream<CsiFrame> get csiStream => _csiController.stream;
  Stream<VitalsReading> get vitalsStream => _vitalsController.stream;
  Stream<ApiError> get errorStream => _errorController.stream;

  ApiService() {
    _rooms['salon'] = _SimRoom(name: 'Salon', occCount: 2);
    _rooms['chambre'] = _SimRoom(name: 'Chambre', occCount: 1);
    _rooms['bureau'] = _SimRoom(name: 'Bureau', occCount: 0);
    _rooms['cuisine'] = _SimRoom(name: 'Cuisine', occCount: 1);
    _rooms['garage'] = _SimRoom(name: 'Garage', occCount: 0);
    _startDataGeneration();
  }

  void _startDataGeneration() {
    _dataTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _globalPhase += 0.15;
      _generateVitals();
      _generateCsi();
    });
  }

  void _generateVitals() {
    for (final entry in _rooms.entries) {
      final room = entry.value;
      final baseBr = room.baseBreathingRate;
      final baseHr = room.baseHeartRate;
      final variation = sin(_globalPhase * room.phaseOffset);

      room.currentVitals = VitalsReading(
        breathingRate: baseBr + variation * 1.5 + _rng.nextDouble() * 0.3,
        heartRate: (baseHr + variation * 4 + _rng.nextDouble() * 2).round(),
        brConfidence: (0.8 + sin(_globalPhase * 0.5 + room.phaseOffset) * 0.1)
            .clamp(0.4, 0.95),
        hrConfidence: (0.75 + cos(_globalPhase * 0.3 + room.phaseOffset) * 0.1)
            .clamp(0.4, 0.95),
      );

      _vitalsController.add(room.currentVitals!);
    }
  }

  void _generateCsi() {
    final subcarriers = List.generate(3, (_) =>
        List.generate(64, (i) =>
            50 + sin(_globalPhase + i * 0.1) * 20 +
            _rng.nextDouble() * 5));
    _csiController.add(CsiFrame(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      amplitudes: subcarriers,
      phases: subcarriers.map((s) =>
          s.map((v) => sin(v * 0.1) * pi).toList()).toList(),
    ));
  }

  Future<ApiResult<List<RoomUpdate>>> getRooms() async {
    final list = _rooms.entries.map((e) {
      final r = e.value;
      final hasOcc = r.occCount > 0;
      return RoomUpdate(
        id: e.key,
        name: r.name,
        status: hasOcc ? DeviceStatus.online : DeviceStatus.offline,
        occupantCount: r.currentVitals != null
            ? (r.occCount + sin(_globalPhase * 0.2 + r.phaseOffset) * 0.3).round().clamp(0, 5)
            : 0,
        breathingRate: r.currentVitals?.breathingRate,
        heartRate: r.currentVitals?.heartRate,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      );
    }).toList();
    return ApiResult.success(list);
  }

  Future<ApiResult<VitalsReading>> getRoomVitals(String roomId) async {
    final room = _rooms[roomId];
    if (room?.currentVitals != null) {
      return ApiResult.success(room!.currentVitals!);
    }
    if (_rooms.isNotEmpty) {
      final first = _rooms.values.first;
      return ApiResult.success(
        VitalsReading(
          breathingRate: first.baseBreathingRate,
          heartRate: first.baseHeartRate.round(),
          brConfidence: 0.7,
          hrConfidence: 0.7,
        ),
      );
    }
    return ApiResult.failure(ApiError.notFound, message: 'Aucune pièce');
  }

  Future<ApiResult<bool>> startCalibration(String roomId) async {
    if (_calibrating) {
      return ApiResult.failure(ApiError.serverError,
          message: 'Calibration déjà en cours');
    }
    _calibrating = true;
    _calibProgress = 0;
    _calibTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      _calibProgress = (_calibProgress + 5).clamp(0, 100);
      if (_calibProgress >= 100) {
        t.cancel();
        _calibrating = false;
      }
    });
    await Future.delayed(const Duration(seconds: 6));
    return ApiResult.success(true);
  }

  int getCalibrationProgress() => _calibProgress;
  bool get isCalibrating => _calibrating;

  Future<ApiResult<bool>> setConfig(String key, dynamic value) async {
    return ApiResult.success(true);
  }

  Future<ApiResult<Map<String, dynamic>>> getConfig() async {
    return ApiResult.success({'mode': 'local', 'sensitivity': 0.7});
  }

  void connectWebSocket() {}

  void dispose() {
    _dataTimer?.cancel();
    _calibTimer?.cancel();
    _csiController.close();
    _vitalsController.close();
    _errorController.close();
  }
}

class _SimRoom {
  final String name;
  final int occCount;
  final double phaseOffset;
  final double baseBreathingRate;
  final double baseHeartRate;
  VitalsReading? currentVitals;

  _SimRoom({
    required this.name,
    this.occCount = 0,
    this.baseBreathingRate = 16,
    this.baseHeartRate = 72,
  }) : phaseOffset = Random().nextDouble() * 6.28;
}
