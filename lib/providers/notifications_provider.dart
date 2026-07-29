import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../models/notification.dart';

class NotificationsProvider extends ChangeNotifier {
  String? _userId;
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  RealtimeChannel? _subscription;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (_subscription != null) {
        SupabaseService.client.removeChannel(_subscription!);
        _subscription = null;
      }
      if (userId != null) {
        loadNotifications();
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
    if (_subscription != null) {
      SupabaseService.client.removeChannel(_subscription!);
    }
    super.dispose();
  }

  Future<void> loadNotifications() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final notifs = await SupabaseService.fetchNotifications(_userId!);
      final unread = await SupabaseService.fetchUnreadNotificationCount(_userId!);
      _notifications = notifs;
      _unreadCount = unread;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    if (_userId == null) return;
    _subscription = SupabaseService.client
        .channel('notifications-$_userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId!,
          ),
          callback: (payload) {
            final newNotif = AppNotification.fromJson(payload.newRecord);
            _notifications = [newNotif, ..._notifications];
            _unreadCount++;
            notifyListeners();
          },
        )
        .subscribe();
  }

  Future<void> markRead(String notificationId) async {
    await SupabaseService.markNotificationRead(notificationId);
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
    await SupabaseService.markAllNotificationsRead(_userId!);
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
