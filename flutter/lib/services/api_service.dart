import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../core/models.dart';
import '../core/api_types.dart';

class ApiService {
  final http.Client _client = http.Client();
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  final StreamController<CsiFrame> _csiController =
      StreamController<CsiFrame>.broadcast();
  final StreamController<VitalsReading> _vitalsController =
      StreamController<VitalsReading>.broadcast();
  final StreamController<ApiError> _errorController =
      StreamController<ApiError>.broadcast();

  Stream<CsiFrame> get csiStream => _csiController.stream;
  Stream<VitalsReading> get vitalsStream => _vitalsController.stream;
  Stream<ApiError> get errorStream => _errorController.stream;

  Future<ApiResult<List<RoomUpdate>>> getRooms() async {
    try {
      final res = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/rooms'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return ApiResult.success(
            data.map((r) => RoomUpdate.fromJson(r)).toList());
      }
      return ApiResult.failure(
        res.statusCode == 404 ? ApiError.notFound : ApiError.serverError,
        message: 'HTTP ${res.statusCode}',
      );
    } on TimeoutException {
      _errorController.add(ApiError.timeout);
      return ApiResult.failure(ApiError.timeout,
          message: 'Connexion au serveur trop lente');
    } catch (e) {
      _errorController.add(ApiError.network);
      return ApiResult.failure(ApiError.network,
          message: 'Impossible de joindre le serveur ($e)');
    }
  }

  Future<ApiResult<VitalsReading>> getRoomVitals(String roomId) async {
    try {
      final res = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/rooms/$roomId/vitals'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return ApiResult.success(
            VitalsReading.fromJson(jsonDecode(res.body)));
      }
      return ApiResult.failure(
        res.statusCode == 503 ? ApiError.offline : ApiError.serverError,
        message: 'Pièce non disponible',
      );
    } on TimeoutException {
      return ApiResult.failure(ApiError.timeout);
    } catch (e) {
      return ApiResult.failure(ApiError.network, message: '$e');
    }
  }

  Future<ApiResult<bool>> startCalibration(String roomId) async {
    try {
      final res = await _client
          .post(Uri.parse('${AppConstants.apiBaseUrl}/rooms/$roomId/calibrate'))
          .timeout(const Duration(seconds: 35));
      if (res.statusCode == 200) {
        return ApiResult.success(true);
      }
      return ApiResult.failure(ApiError.serverError);
    } on TimeoutException {
      return ApiResult.failure(ApiError.timeout,
          message: 'La calibration prend plus de temps que prévu');
    } catch (e) {
      return ApiResult.failure(ApiError.network, message: '$e');
    }
  }

  Future<ApiResult<bool>> setConfig(String key, dynamic value) async {
    try {
      final res = await _client
          .put(
            Uri.parse('${AppConstants.apiBaseUrl}/config'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({key: value}),
          )
          .timeout(const Duration(seconds: 5));
      return ApiResult.success(res.statusCode == 200);
    } catch (e) {
      return ApiResult.failure(ApiError.network, message: '$e');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getConfig() async {
    try {
      final res = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/config'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return ApiResult.success(jsonDecode(res.body) as Map<String, dynamic>);
      }
      return ApiResult.failure(ApiError.serverError);
    } catch (e) {
      return ApiResult.failure(ApiError.network, message: '$e');
    }
  }

  void connectWebSocket() {
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(AppConstants.wsUrl));
      _reconnectAttempts = 0;
      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);
            if (json['type'] == 'csi') {
              _csiController.add(CsiFrame.fromJson(json['data']));
            } else if (json['type'] == 'vitals') {
              _vitalsController.add(VitalsReading.fromJson(json['data']));
            }
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _errorController.add(ApiError.network);
    _reconnectAttempts++;
    final delay = Duration(
      seconds: (_reconnectAttempts * 2).clamp(1, 30),
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts = 0;
      connectWebSocket();
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _csiController.close();
    _vitalsController.close();
    _errorController.close();
    _client.close();
  }
}
