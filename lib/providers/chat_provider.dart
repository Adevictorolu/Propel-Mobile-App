import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  String? _type; // 'dm' | 'group'
  String? _channelId;
  String? _userId;

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;

  void initChannel({required String type, required String channelId, required String? userId}) {
    if (_type != type || _channelId != channelId || _userId != userId) {
      _type = type;
      _channelId = channelId;
      _userId = userId;

      _subscription?.cancel();
      _subscription = null;

      if (channelId.isNotEmpty) {
        _subscribeRealtime();
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeRealtime() {
    if (_type == null || _channelId == null) return;
    _isLoading = true;
    notifyListeners();

    final field = _type == 'dm' ? 'connection_id' : 'group_id';
    _subscription = FirebaseService.db
        .collection('messages')
        .where(field, isEqualTo: _channelId!)
        .orderBy('created_at', descending: false)
        .snapshots()
        .listen((snapshot) async {
      final list = <Message>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['sender_id'] as String?;
        Map<String, dynamic>? senderData;
        if (senderId != null) {
          final sDoc = await FirebaseService.db.collection('profiles').doc(senderId).get();
          senderData = sDoc.data();
        }

        list.add(Message.fromJson({
          ...data,
          'id': doc.id,
          'sender': senderData,
        }));
      }

      _messages = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> sendMessage(String content) async {
    if (_userId == null || _type == null || _channelId == null || content.trim().isEmpty) return;

    final tempId = 'optimistic-${DateTime.now().millisecondsSinceEpoch}';
    final userProfile = await FirebaseService.fetchProfile(_userId!);

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
      final payload = <String, dynamic>{
        'sender_id': _userId!,
        'content': content.trim(),
        'type': _type!,
        'created_at': DateTime.now().toIso8601String(),
      };
      if (_type == 'dm') {
        payload['connection_id'] = _channelId;
      } else {
        payload['group_id'] = _channelId;
      }

      await FirebaseService.db.collection('messages').add(payload);
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
