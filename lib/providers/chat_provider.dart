import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  String? _type; // 'dm' | 'group'
  String? _channelId;
  String? _userId;

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  RealtimeChannel? _realtimeChannel;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;

  void initChannel({required String type, required String channelId, required String? userId}) {
    if (_type != type || _channelId != channelId || _userId != userId) {
      _type = type;
      _channelId = channelId;
      _userId = userId;

      if (_realtimeChannel != null) {
        SupabaseService.client.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      }

      if (channelId.isNotEmpty) {
        loadMessages();
        _subscribeRealtime();
      }
    }
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      SupabaseService.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> loadMessages() async {
    if (_type == null || _channelId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final msgs = await SupabaseService.fetchMessages(_type!, _channelId!);
      _messages = msgs;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    if (_type == null || _channelId == null) return;
    final column = _type == 'dm' ? 'connection_id' : 'group_id';
    _realtimeChannel = SupabaseService.client
        .channel('chat-$_type-$_channelId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: column,
            value: _channelId!,
          ),
          callback: (payload) async {
            final newRow = payload.newRecord;
            final senderId = newRow['sender_id'] as String;
            final senderProfile = await SupabaseService.fetchProfile(senderId);

            final incomingMsg = Message.fromJson({
              ...newRow,
              'sender': senderProfile?.toJson(),
            });

            final filtered = _messages.where((m) => !(m.isOptimistic && m.senderId == senderId && m.content == incomingMsg.content)).toList();
            if (!filtered.any((m) => m.id == incomingMsg.id)) {
              _messages = [...filtered, incomingMsg];
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  Future<void> sendMessage(String content) async {
    if (_userId == null || _type == null || _channelId == null || content.trim().isEmpty) return;

    final tempId = 'optimistic-${DateTime.now().millisecondsSinceEpoch}';
    final userProfile = await SupabaseService.fetchProfile(_userId!);

    final optimisticMsg = Message(
      id: tempId,
      senderId: _userId!,
      connectionId: _type == 'dm' ? _channelId : null,
      groupId: _type == 'group' ? _channelId : null,
      content: content.trim(),
      type: _type!,
      createdAt: DateTime.now().toIso8601String(),
      sender: userProfile,
      isOptimistic: true,
    );

    _messages = [..._messages, optimisticMsg];
    _isSending = true;
    notifyListeners();

    try {
      final sent = await SupabaseService.sendMessage(
        senderId: _userId!,
        type: _type!,
        channelId: _channelId!,
        content: content.trim(),
      );

      _messages = _messages.map((m) => m.id == tempId ? sent : m).toList();
      _isSending = false;
      notifyListeners();
    } catch (e) {
      _messages = _messages.where((m) => m.id != tempId).toList();
      _isSending = false;
      notifyListeners();
      rethrow;
    }
  }
}
