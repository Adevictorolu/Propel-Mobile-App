import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';
import '../models/notification.dart';

class NotificationsProvider extends ChangeNotifier {
  String? _userId;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _subscription?.cancel();
      _subscription = null;

      if (userId != null) {
        _subscribeRealtime();
      } else {
        _notifications = [];
        _unreadCount = 0;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeRealtime() {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseService.db
        .collection('notifications')
        .where('user_id', isEqualTo: _userId!)
        .orderBy('created_at', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      final list = <AppNotification>[];
      int unread = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isRead = data['is_read'] as bool? ?? false;
        if (!isRead) unread++;

        list.add(AppNotification.fromJson({
          ...data,
          'id': doc.id,
        }));
      }

      _notifications = list;
      _unreadCount = unread;
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> markRead(String notificationId) async {
    await FirebaseService.db
        .collection('notifications')
        .doc(notificationId)
        .update({'is_read': true});

    _notifications = _notifications.map((n) {
      if (n.id == notificationId) {
        return AppNotification(
          id: n.id,
          userId: n.userId,
          type: n.type,
          title: n.title,
          body: n.body,
          link: n.link,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    _unreadCount = (_unreadCount - 1).clamp(0, 99999);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (_userId == null) return;
    final batch = FirebaseService.db.batch();
    final docs = await FirebaseService.db
        .collection('notifications')
        .where('user_id', isEqualTo: _userId!)
        .where('is_read', isEqualTo: false)
        .get();

    for (final doc in docs.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();

    _notifications = _notifications.map((n) => AppNotification(
      id: n.id,
      userId: n.userId,
      type: n.type,
      title: n.title,
      body: n.body,
      link: n.link,
      isRead: true,
      createdAt: n.createdAt,
    )).toList();
    _unreadCount = 0;
    notifyListeners();
  }
}
