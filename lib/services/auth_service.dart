import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth — handles sign in, sign up, sign out, and session.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Sign in with email and password. Returns the auth response.
  Future<AuthResponse> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Create a new account. Returns the auth response.
  /// If email confirmation is required, `response.session` will be null.
  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  /// Sign out and clear the local session.
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  /// The current session, or null if not logged in.
  /// Supabase Flutter auto-persists and refreshes this.
  Session? get currentSession => _client.auth.currentSession;

  /// The current JWT access token, or null.
  String? get accessToken => currentSession?.accessToken;

  /// Whether the user is currently authenticated.
  bool get isLoggedIn => currentSession != null;

  /// Stream of auth state changes (login, logout, token refresh).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
