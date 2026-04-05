import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/consent_screen.dart';
import 'services/fcm_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthFlexx Coach',
      theme: healthFlexTheme(),
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            return const _ConsentGate();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

/// Checks if the user has accepted the disclaimer. Shows consent screen if not.
class _ConsentGate extends StatefulWidget {
  const _ConsentGate();

  @override
  State<_ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends State<_ConsentGate> {
  bool _loading = true;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        // Register FCM token now that user is authenticated
        FcmService().init();

        final result = await Supabase.instance.client
            .from('bot_profiles')
            .select('disclaimer_accepted_at')
            .eq('person_id', userId)
            .maybeSingle();

        if (result != null && result['disclaimer_accepted_at'] != null) {
          setState(() {
            _accepted = true;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {
      // If check fails, show consent screen to be safe
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_accepted) {
      return const ChatScreen();
    }

    return ConsentScreen(
      onAccepted: () => setState(() => _accepted = true),
    );
  }
}
