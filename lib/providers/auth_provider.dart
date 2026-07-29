import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../models/profile.dart';
import '../models/mentor_profile.dart';
import '../models/mentee_profile.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  Profile? _profile;
  MentorProfile? _mentorProfile;
  MenteeProfile? _menteeProfile;
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _error;

  User? get user => _user;
  Profile? get profile => _profile;
  MentorProfile? get mentorProfile => _mentorProfile;
  MenteeProfile? get menteeProfile => _menteeProfile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  bool get isAuthenticated => _user != null;
  bool get isOnboarded => _profile?.onboardingComplete ?? false;
  UserRole get role => _profile?.role ?? 'mentee';

  AuthProvider() {
    _init();
  }

  void _init() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session?.user != null) {
        await loadUserData(session!.user.id);
      } else {
        _user = null;
        _profile = null;
        _mentorProfile = null;
        _menteeProfile = null;
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
    });

    final initialUser = SupabaseService.currentUser;
    if (initialUser != null) {
      loadUserData(initialUser.id);
    } else {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> loadUserData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prof = await SupabaseService.fetchProfile(userId);
      MentorProfile? mProf;
      MenteeProfile? meProf;

      if (prof != null) {
        if (prof.role == 'mentor') {
          mProf = await SupabaseService.fetchMentorProfile(userId);
        } else {
          meProf = await SupabaseService.fetchMenteeProfile(userId);
        }
      }

      _user = SupabaseService.currentUser;
      _profile = prof;
      _mentorProfile = mProf;
      _menteeProfile = meProf;
      _isLoading = false;
      _isInitialized = true;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isInitialized = true;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await SupabaseService.signIn(email: email, password: password);
      if (res.user != null) {
        await loadUserData(res.user!.id);
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await SupabaseService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      if (res.user != null) {
        await loadUserData(res.user!.id);
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
    _user = null;
    _profile = null;
    _mentorProfile = null;
    _menteeProfile = null;
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      await loadUserData(_user!.id);
    }
  }
}
