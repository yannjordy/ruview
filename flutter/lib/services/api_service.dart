import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../core/models.dart';

class ApiService {
  final http.Client _client = http.Client();
  WebSocketChannel? _channel;
  final StreamController<CsiFrame> _csiController =
      StreamController<CsiFrame>.broadcast();
  final StreamController<VitalsReading> _vitalsController =
      StreamController<VitalsReading>.broadcast();

  Stream<CsiFrame> get csiStream => _csiController.stream;
  Stream<VitalsReading> get vitalsStream => _vitalsController.stream;

  Future<List<Room>> getRooms() async {
    try {
      final res = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/rooms'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.map((r) => Room.fromJson(r)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<VitalsReading?> getRoomVitals(String roomId) async {
    try {
      final res = await _client
          .get(Uri.parse('${AppConstants.apiBaseUrl}/rooms/$roomId/vitals'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return VitalsReading.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  Future<CalibrationStatus> startCalibration(String roomId) async {
    try {
      final res = await _client
          .post(Uri.parse('${AppConstants.apiBaseUrl}/rooms/$roomId/calibrate'))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        return CalibrationStatus(completed: true);
      }
    } catch (_) {}
    return CalibrationStatus();
  }

  Future<bool> setConfig(String key, dynamic value) async {
    try {
      final res = await _client
          .put(
            Uri.parse('${AppConstants.apiBaseUrl}/config'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({key: value}),
          )
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void connectWebSocket() {
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(AppConstants.wsUrl));
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
        onDone: () => Future.delayed(AppConstants.reconnectionDelay, connectWebSocket),
        onError: (_) => Future.delayed(AppConstants.reconnectionDelay, connectWebSocket),
      );
    } catch (_) {}
  }

  void dispose() {
    _channel?.sink.close();
    _csiController.close();
    _vitalsController.close();
    _client.close();
  }
}
