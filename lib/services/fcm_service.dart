import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  late final SupabaseClient _adminClient;

  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal() {
    _adminClient = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.serviceRoleKey,
    );
  }

  Future<void> initialize() async {
    if (!kIsWeb && ![Platform.isAndroid, Platform.isIOS].any((b) => b)) {
      print('FCMService: Skipping initialization on unsupported platform');
      return;
    }
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Foreground message: ${message.notification?.title}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification clicked!');
      });

      _fcm.onTokenRefresh.listen((token) async {
        print('FCM Token refreshed');
      });
    } catch (e) {
      print('FCMService: initialize error (non-bloquant): $e');
    }
  }

  Future<String?> getToken() async {
    if (!kIsWeb && ![Platform.isAndroid, Platform.isIOS].any((b) => b)) {
      return null;
    }
    try {
      return await _fcm.getToken();
    } catch (e) {
      print('FCMService: Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> updateUserToken(String userId, String token) async {
    try {
      await _adminClient.from('users').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      print('FCM Token updated in Supabase for user $userId');
    } catch (e) {
      print('Error updating FCM token in Supabase: $e');
    }
  }
}
