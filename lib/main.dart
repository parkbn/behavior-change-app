import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  // Initialize Supabase — the anon key is safe to expose (RLS protects data)
  await Supabase.initialize(
    url: 'https://ibqoqmzzdjbweucoydtd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlicW9xbXp6ZGpid2V1Y295ZHRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcwMzc2MTAsImV4cCI6MjA1MjYxMzYxMH0.PeXbhu5eWsbAAejhfweSD6MemmzMulQ5q15YtPHoCeE',
  );

  // Initialize local notifications
  await NotificationService().init();

  // Register background polling as fallback (reduced frequency since FCM is primary)
  await initBackgroundService();

  final authService = AuthService();
  final chatService = ChatService(authService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ChatProvider(chatService)),
      ],
      child: const App(),
    ),
  );
}
