import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

/// Manages Firebase Cloud Messaging — token registration and push handling.
class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  final _messaging = FirebaseMessaging.instance;

  /// Initialize FCM: request permission, get token, set up listeners.
  Future<void> init() async {
    // Request permission (Android 13+ requires this)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save the FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    debugPrint('FCM initialized');
  }

  /// Save FCM token to bot_profiles in Supabase.
  Future<void> _saveToken(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('bot_profiles')
          .update({'fcm_token': token})
          .eq('person_id', userId);

      debugPrint('FCM token saved');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Handle messages received while app is in foreground.
  /// Show a local notification since FCM doesn't auto-display in foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'HealthFlexx Coach';
    final body = message.notification?.body ?? '';

    if (body.isNotEmpty) {
      NotificationService().show(title: title, body: body, payload: body);
    }
  }
}

/// Top-level background message handler — must be a top-level function.
/// Called when a push arrives while the app is backgrounded or terminated.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase handles showing the notification automatically when app is backgrounded.
  // This handler is for any custom processing needed.
  debugPrint('Background FCM message: ${message.messageId}');
}
