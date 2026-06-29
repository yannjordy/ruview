import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  FirebaseMessaging? _fcm;
  FlutterLocalNotificationsPlugin? _localNotif;
  bool _initialized = false;
  String? _deviceToken;

  bool get isInitialized => _initialized;
  String? get deviceToken => _deviceToken;

  Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;
      _localNotif = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _localNotif!.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      _deviceToken = await _fcm!.getToken();
      if (_deviceToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _deviceToken!);
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService: init failed ($e) — Firebase config may be missing');
    }
  }

  Future<void> requestPermission() async {
    if (_fcm == null) return;
    final settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || _localNotif == null) return;

    _localNotif!.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'aetheris_alerts',
          'Aetheris Alertes',
          channelDescription: 'Alertes de détection Aetheris',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tap: ${message.data}');
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (_localNotif == null) return;
    await _localNotif!.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'aetheris_alerts',
          'Aetheris Alertes',
          channelDescription: 'Alertes de détection Aetheris',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    if (_fcm == null) return;
    await _fcm!.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (_fcm == null) return;
    await _fcm!.unsubscribeFromTopic(topic);
  }
}
