import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

const _taskName = 'check_unread_messages';
const _backendUrl = 'https://behavior-change.onrender.com';

/// Top-level callback for WorkManager — runs in a separate isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskName) return true;

    try {
      // Initialize Supabase in the background isolate
      await Supabase.initialize(
        url: 'https://ibqoqmzzdjbweucoydtd.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlicW9xbXp6ZGpid2V1Y295ZHRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwMzc2MTAsImV4cCI6MjA1MjYxMzYxMH0.PeXbhu5eWsbAAejhfweSD6MemmzMulQ5q15YtPHoCeE',
      );

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('Background: no active session, skipping');
        return true;
      }

      final token = session.accessToken;
      final res = await http.get(
        Uri.parse('$_backendUrl/api/v1/unread-count'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 401) {
        debugPrint('Background: token expired, skipping');
        return true;
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final unread = data['unread_count'] as int? ?? 0;

        if (unread > 0) {
          // Init without permission request — background isolate has no Activity
          final plugin = FlutterLocalNotificationsPlugin();
          const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
          await plugin.initialize(const InitializationSettings(android: androidSettings));

          const androidDetails = AndroidNotificationDetails(
            'coach_nudges',
            'Coach Messages',
            channelDescription: 'Proactive coaching nudges and reminders',
            importance: Importance.high,
            priority: Priority.high,
          );

          await plugin.show(
            0,
            'HealthFlexx Coach',
            unread == 1
                ? 'Your coach sent you a message'
                : 'Your coach sent you $unread messages',
            const NotificationDetails(android: androidDetails),
            payload: 'unread',
          );
        }
      }
    } catch (e) {
      debugPrint('Background check failed: $e');
    }

    return true;
  });
}

/// Register the periodic background task.
Future<void> initBackgroundService() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'unread-check',
    _taskName,
    frequency: const Duration(minutes: 60),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  debugPrint('Background service registered');
}
