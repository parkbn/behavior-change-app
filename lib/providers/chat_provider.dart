import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Manages the chat state — messages, typing indicator, conversation ID,
/// and Realtime subscription for bot-initiated messages.
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  List<ChatMessage> messages = [];
  bool isTyping = false;
  bool isLoadingHistory = false;
  String? conversationId;
  String? errorMessage;

  RealtimeChannel? _realtimeChannel;

  ChatProvider(this._chatService);

  /// Load the current conversation and its history from the backend.
  /// Called after login when the auth token is available.
  Future<void> loadConversation() async {
    isLoadingHistory = true;
    notifyListeners();

    try {
      final data = await _chatService.getConversation();
      conversationId = data['conversation_id'] as String;
      final history = data['messages'] as List<ChatMessage>;

      if (history.isNotEmpty) {
        messages = history;
      } else {
        messages = [ChatMessage.system('Connected! Send a message to start coaching.')];
      }

      // Cache conversation ID
      try {
        await _storage.write(key: 'conversation_id', value: conversationId);
      } catch (_) {}

      // Mark any pending messages as delivered (app received them)
      _chatService.markMessagesDelivered(conversationId!);

      // Start listening for bot messages via Realtime
      _subscribeToRealtime();
    } catch (e) {
      debugPrint('Failed to load conversation: $e');
      messages = [ChatMessage.system('Connected! Send a message to start coaching.')];
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Subscribe to Realtime inserts on chat_messages for the current conversation.
  void _subscribeToRealtime() {
    _unsubscribeRealtime();

    if (conversationId == null) return;

    _realtimeChannel = Supabase.instance.client
        .channel('chat:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId!,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            final senderType = row['sender_type'] as String? ?? '';

            // Only handle bot messages — user messages are added optimistically
            if (senderType != 'bot') return;

            final id = row['id'] as String? ?? '';

            // Deduplicate — message may already exist from sendMessage response
            if (messages.any((m) => m.id == id)) return;

            final message = ChatMessage(
              id: id,
              content: row['content'] as String? ?? '',
              senderType: 'bot',
              createdAt: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
            );

            messages.add(message);
            notifyListeners();
            // Don't mark as read here — the chat screen handles that
            // when it's actively visible. This allows background notifications
            // to fire for messages received while the app is backgrounded.
          },
        )
        .subscribe();

    debugPrint('Realtime subscribed for conversation $conversationId');
  }

  void _unsubscribeRealtime() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  /// Add a notification's content as a bot message in the chat so the user can read it.
  /// Deduplicates against existing messages with the same content.
  void addNotificationMessage(String content) {
    // Avoid duplicating if the message is already visible
    final recent = messages.where((m) => m.isBot && m.content == content);
    if (recent.isNotEmpty) return;

    messages.add(ChatMessage(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      senderType: 'bot',
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Refresh conversation from backend (e.g., after notification tap or app resume).
  Future<void> refresh() async {
    if (conversationId == null) return;

    try {
      final data = await _chatService.getConversation();
      final history = data['messages'] as List<ChatMessage>;
      if (history.isNotEmpty) {
        messages = history;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh conversation: $e');
    }
  }

  /// Mark bot messages as read.
  Future<void> markAsRead() async {
    if (conversationId == null) return;
    await _chatService.markMessagesRead(conversationId!);
  }

  /// Send a message and get the bot's response.
  Future<void> sendMessage(String text) async {
    // 1. Show user message immediately (optimistic)
    messages.add(ChatMessage.user(text));
    isTyping = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 2. Call the backend
      final data = await _chatService.sendMessage(text);

      // 3. Store conversation ID
      conversationId = data['conversation_id'];
      try {
        await _storage.write(key: 'conversation_id', value: conversationId);
      } catch (_) {}

      // 4. Add bot response (deduplicate if Realtime already delivered it)
      final messageId = data['message_id'];
      if (!messages.any((m) => m.id == messageId)) {
        messages.add(ChatMessage(
          id: messageId,
          content: data['response'],
          senderType: 'bot',
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      errorMessage = e.toString();
      messages.add(ChatMessage.system('Error: Could not reach the coach. Try again.'));
    } finally {
      isTyping = false;
      notifyListeners();
      // Mark all bot messages as read since user is actively viewing chat
      markAsRead();
    }
  }

  /// Clear state on logout.
  void clear() {
    _unsubscribeRealtime();
    messages = [];
    conversationId = null;
    isTyping = false;
    isLoadingHistory = false;
    errorMessage = null;
    try {
      _storage.delete(key: 'conversation_id');
    } catch (_) {}
    notifyListeners();
  }
}
