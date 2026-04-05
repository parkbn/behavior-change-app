import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages local notifications for bot-initiated messages.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  /// Fires when the user taps a notification.
  final _onTapController = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationTap => _onTapController.stream;

  /// Initialize the notification plugin and request permissions.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _onTapController.add(response.payload);
      },
    );

    // Request POST_NOTIFICATIONS permission on Android 13+
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    }
  }

  /// Show a local notification.
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'coach_nudges',
      'Coach Messages',
      channelDescription: 'Proactive coaching nudges and reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(0, title, body, details, payload: payload);
    debugPrint('Notification shown: $title');
  }

  void dispose() {
    _onTapController.close();
  }
}
