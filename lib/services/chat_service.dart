import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import 'auth_service.dart';

/// HTTP client for the FastAPI backend.
class ChatService {
  final AuthService _authService;

  ChatService(this._authService);

  /// Resolved backend URL. On first API call, we probe to find which works.
  String? _baseUrl;

  /// Get the backend base URL. Probes local server in debug mode, falls back to production.
  Future<String> get baseUrl async {
    if (_baseUrl != null) return _baseUrl!;

    const productionUrl = 'https://behavior-change.onrender.com';

    // Always use production unless a local override is set.
    // To test locally, change this to 'http://10.0.2.2:8000' (emulator)
    // or 'http://localhost:8000' (adb reverse).
    _baseUrl = productionUrl;
    debugPrint('Using backend: $_baseUrl');
    return _baseUrl!;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_authService.accessToken}',
      };

  /// Send a message to the bot and get a response.
  Future<Map<String, dynamic>> sendMessage(String message) async {
    final url = await baseUrl;
    final res = await http.post(
      Uri.parse('$url/api/v1/chat'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    ).timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['detail'] ?? 'Request failed (${res.statusCode})');
    }

    return jsonDecode(res.body);
  }

  /// Get the user's current conversation and message history in one call.
  /// Returns a map with: conversation_id, messages.
  Future<Map<String, dynamic>> getConversation({int limit = 50}) async {
    final url = await baseUrl;
    final res = await http.get(
      Uri.parse('$url/api/v1/conversation?limit=$limit'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Failed to load conversation');
    }

    final data = jsonDecode(res.body);
    final messages = (data['messages'] as List)
        .map((m) => ChatMessage.fromJson(m))
        .toList();

    return {
      'conversation_id': data['conversation_id'] as String,
      'messages': messages,
    };
  }

  /// Get chat history for a conversation.
  Future<List<ChatMessage>> getHistory(String conversationId,
      {int limit = 50}) async {
    final url = await baseUrl;
    final res = await http.get(
      Uri.parse('$url/api/v1/messages/$conversationId?limit=$limit'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Failed to load messages');
    }

    final data = jsonDecode(res.body);
    final messages = data['messages'] as List;
    return messages.map((m) => ChatMessage.fromJson(m)).toList();
  }

  /// Get unread message count for the current user.
  Future<int> getUnreadCount() async {
    final url = await baseUrl;
    final res = await http.get(
      Uri.parse('$url/api/v1/unread-count'),
      headers: _headers,
    ).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) return 0;

    final data = jsonDecode(res.body);
    return data['unread_count'] as int? ?? 0;
  }

  /// Mark bot messages as delivered (app received them).
  Future<void> markMessagesDelivered(String conversationId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await Supabase.instance.client
          .from('chat_messages')
          .update({'status': 'delivered', 'delivered_at': now})
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'bot')
          .eq('status', 'sent');
    } catch (e) {
      debugPrint('Failed to mark messages delivered: $e');
    }
  }

  /// Mark all bot messages in a conversation as read via Supabase directly.
  Future<void> markMessagesRead(String conversationId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await Supabase.instance.client
          .from('chat_messages')
          .update({'status': 'read', 'read_at': now, 'delivered_at': now})
          .eq('conversation_id', conversationId)
          .eq('sender_type', 'bot')
          .inFilter('status', ['sent', 'delivered']);
    } catch (e) {
      debugPrint('Failed to mark messages read: $e');
    }
  }

  /// Health check — no auth required.
  Future<bool> healthCheck() async {
    try {
      final url = await baseUrl;
      final res = await http.get(Uri.parse('$url/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
