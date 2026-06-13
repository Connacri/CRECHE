import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class FCMService extends AdminSupabaseService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal() : super();

  Future<void> initialize() async {
    if (!kIsWeb && ![Platform.isAndroid, Platform.isIOS].any((b) => b)) {
      debugPrint('FCMService: Skipping initialization on unsupported platform');
      return;
    }
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message: ${message.notification?.title}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked!');
      });

      _fcm.onTokenRefresh.listen((token) async {
        debugPrint('FCM Token refreshed');
      });
    } catch (e) {
      debugPrint('FCMService: initialize error (non-bloquant): $e');
    }
  }

  Future<String?> getToken() async {
    if (!kIsWeb && ![Platform.isAndroid, Platform.isIOS].any((b) => b)) {
      return null;
    }
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('FCMService: Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> updateUserToken(String userId, String token) async {
    try {
      await adminClient.from('users').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      debugPrint('FCM Token updated in Supabase for user $userId');
    } catch (e) {
      debugPrint('Error updating FCM token in Supabase: $e');
    }
  }
}
