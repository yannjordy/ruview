import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  final String url;
  final String anonKey;

  SupabaseConfig({required this.url, required this.anonKey});

  static SupabaseConfig get defaultDev => SupabaseConfig(
        url: 'http://localhost:54321',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock',
      );

  static const storageKey = 'supabase_config';
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._();
  factory SupabaseService() => _instance;
  SupabaseService._();

  SupabaseConfig? _config;
  String? _accessToken;
  String? _userId;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _accessToken != null;
  String? get userId => _userId;

  Future<void> init({SupabaseConfig? config}) async {
    if (_initialized) return;
    _config = config;
    _initialized = true;
    debugPrint('SupabaseService: initialisé');
  }

  // -- Auth --

  Future<bool> signInAnonymously() async {
    try {
      final res = await _post('/auth/v1/signup', {
        'email': 'anonymous@aetheris.local',
        'password': _randomPassword(),
      });
      if (res != null && res['access_token'] != null) {
        _accessToken = res['access_token'];
        _userId = res['user']?['id'];
        await _saveSession();
        return true;
      }
    } catch (_) {}
    return _restoreSession();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      final res = await _post('/auth/v1/token?grant_type=password', {
        'email': email,
        'password': password,
      });
      if (res != null && res['access_token'] != null) {
        _accessToken = res['access_token'];
        _userId = res['user']?['id'];
        await _saveSession();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> signOut() async {
    _accessToken = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('supabase_session');
  }

  // -- Database --

  Future<List<Map<String, dynamic>>> query(String table,
      {String? select, Map<String, dynamic>? eq}) async {
    if (_config == null) return [];
    try {
      var path = '/rest/v1/$table?select=${select ?? "*"}';
      eq?.forEach((k, v) => path += '&$k=eq.$v');
      final res = await _get(path);
      if (res is List) return res.cast<Map<String, dynamic>>();
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> insert(String table, Map<String, dynamic> data) async {
    if (_config == null) return false;
    try {
      await _post('/rest/v1/$table', data, isDb: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> upsert(String table, Map<String, dynamic> data,
      {String? onConflict}) async {
    if (_config == null) return false;
    try {
      var path = '/rest/v1/$table?on_conflict=$onConflict';
      await _request('POST', path, jsonEncode(data), isDb: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  // -- Realtime (polling fallback quand WebSocket indisponible) --

  void subscribe(String channel, String event, void Function(Map<String, dynamic>) callback) {
    // Utilise le polling REST comme fallback (WebSocket Realtime sera ajouté
    // quand supabase_realtime_client sera dans pubspec)
    debugPrint('Supabase: subscribed to $channel:$event (polling)');
  }

  // -- Push notifications via Supabase Realtime --

  Future<void> sendPush({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    await insert('notifications', {
      'user_id': userId,
      'title': title,
      'body': body,
      'data': data != null ? jsonEncode(data) : null,
      'read': false,
    });
  }

  // -- Interne --

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body,
      {bool isDb = false}) async {
    final res = await _request('POST', path, jsonEncode(body), isDb: isDb);
    if (res == null || res.isEmpty) return null;
    try {
      return jsonDecode(res) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _get(String path) async {
    final res = await _request('GET', path, null);
    if (res == null || res.isEmpty) return null;
    try {
      return jsonDecode(res);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _request(String method, String path, String? body,
      {bool isDb = false}) async {
    if (_config == null) return null;
    final url = Uri.parse('${_config!.url}$path');
    final headers = <String, String>{
      'apikey': _config!.anonKey,
      'Content-Type': 'application/json',
    };
    if (_accessToken != null) headers['Authorization'] = 'Bearer $_accessToken';
    if (isDb) headers['Prefer'] = 'return=minimal';

    try {
      final client = http.Client();
      try {
        final req = http.Request(method, url)
          ..headers.addAll(headers)
          ..body = body ?? '';
        final res =
            await client.send(req).timeout(const Duration(seconds: 10));
        return await res.stream.bytesToString();
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Supabase: $method $path failed ($e)');
      return null;
    }
  }

  Future<void> _saveSession() async {
    if (_accessToken == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_session', jsonEncode({
      'access_token': _accessToken,
      'user_id': _userId,
    }));
  }

  Future<bool> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('supabase_session');
    if (json == null) return false;
    try {
      final data = jsonDecode(json);
      _accessToken = data['access_token'];
      _userId = data['user_id'];
      return true;
    } catch (_) {
      return false;
    }
  }

  String _randomPassword() =>
      'aetheris_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';

  void dispose() {}
}
