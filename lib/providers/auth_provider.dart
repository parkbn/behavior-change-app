import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Manages auth state — login, signup, logout, session recovery.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<AuthState>? _authSub;

  bool isLoggedIn = false;
  bool isLoading = false;
  String? errorMessage;

  AuthProvider(this._authService) {
    // Check for existing session on startup
    isLoggedIn = _authService.isLoggedIn;

    // Listen for auth changes (token refresh, sign out, etc.)
    _authSub = _authService.authStateChanges.listen((authState) {
      final wasLoggedIn = isLoggedIn;
      isLoggedIn = authState.session != null;
      if (wasLoggedIn != isLoggedIn) {
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      isLoggedIn = true;
      _syncTimezone();
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signUp(email, password);
      if (response.session != null) {
        isLoggedIn = true;
      } else {
        // Email confirmation required
        errorMessage = 'Check your email to confirm your account, then sign in.';
      }
    } on AuthException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Send the device timezone to bot_profiles so nudges fire at the right local time.
  void _syncTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final iana = _offsetToIana(offset.inHours);
      debugPrint('Syncing timezone: $iana (offset ${offset.inHours}h)');

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      Supabase.instance.client
          .from('bot_profiles')
          .update({'timezone': iana})
          .eq('person_id', userId)
          .then((_) => debugPrint('Timezone synced: $iana'))
          .catchError((e) => debugPrint('Timezone sync failed: $e'));
    } catch (e) {
      debugPrint('Timezone sync error: $e');
    }
  }

  /// Map UTC offset (hours) to an IANA timezone. Covers US zones + common offsets.
  static String _offsetToIana(int offsetHours) {
    return switch (offsetHours) {
      -10 => 'Pacific/Honolulu',
      -9  => 'America/Anchorage',
      -8  => 'America/Los_Angeles',
      -7  => 'America/Denver',
      -6  => 'America/Chicago',
      -5  => 'America/New_York',
      -4  => 'America/Puerto_Rico',
      _   => 'America/New_York', // default fallback
    };
  }

  Future<void> logout() async {
    await _authService.signOut();
    isLoggedIn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
