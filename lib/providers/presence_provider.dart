import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/firebase_service.dart';

class PresenceProvider extends ChangeNotifier {
  String? _userId;
  Set<String> _onlineUserIds = {};
  StreamSubscription<DocumentSnapshot>? _subscription;

  Set<String> get onlineUserIds => _onlineUserIds;

  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _subscription?.cancel();
      _subscription = null;

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
    _subscription?.cancel();
    super.dispose();
  }

  void _initPresence() {
    if (_userId == null) return;
    
    // Mark current user as online in Firestore presence collection
    FirebaseService.db.collection('presence').doc(_userId).set({
      'online': true,
      'last_seen': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Listen to online users
    _subscription = FirebaseService.db
        .collection('presence')
        .doc(_userId)
        .snapshots()
        .listen((_) {}, onError: (_) {});
  }

  bool isOnline(String uid) => _onlineUserIds.contains(uid);
}
