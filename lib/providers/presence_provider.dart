import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';

class PresenceProvider extends ChangeNotifier {
  String? _userId;
  Set<String> _onlineUserIds = {};
  RealtimeChannel? _channel;

  Set<String> get onlineUserIds => _onlineUserIds;

  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      if (_channel != null) {
        SupabaseService.client.removeChannel(_channel!);
        _channel = null;
      }
      if (userId != null) {
        _initPresence();
      } else {
        _onlineUserIds = {};
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      SupabaseService.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  void _initPresence() {
    if (_userId == null) return;
    _channel = SupabaseService.client.channel('propel-presence');

    _channel!.onPresenceSync((_) {
      final presenceState = _channel!.presenceState();
      final userIds = <String>{};
      for (final presences in presenceState.values) {
        for (final p in presences) {
          final uId = p.payload['user_id'] as String?;
          if (uId != null) userIds.add(uId);
        }
      }
      _onlineUserIds = userIds;
      notifyListeners();
    }).subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _channel!.track({
          'user_id': _userId,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  bool isOnline(String uid) => _onlineUserIds.contains(uid);
}
