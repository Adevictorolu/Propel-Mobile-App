import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/firebase_service.dart';
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
    FirebaseService.auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        await loadUserData(firebaseUser.uid);
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

    final initialUser = FirebaseService.currentUser;
    if (initialUser != null) {
      loadUserData(initialUser.uid);
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
      final prof = await FirebaseService.fetchProfile(userId);
      MentorProfile? mProf;
      MenteeProfile? meProf;

      if (prof != null) {
        if (prof.role == 'mentor') {
          mProf = await FirebaseService.fetchMentorProfile(userId);
        } else {
          meProf = await FirebaseService.fetchMenteeProfile(userId);
        }
      }

      _user = FirebaseService.currentUser;
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
      final res = await FirebaseService.signIn(email: email, password: password);
      if (res.user != null) {
        await loadUserData(res.user!.uid);
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await FirebaseService.signInWithGoogle();
      if (res?.user != null) {
        await loadUserData(res!.user!.uid);
      } else {
        _isLoading = false;
        notifyListeners();
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
      final res = await FirebaseService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );
      if (res.user != null) {
        await loadUserData(res.user!.uid);
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException e) verificationFailed,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await FirebaseService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final res = await FirebaseService.auth.signInWithCredential(credential);
          if (res.user != null) {
            await loadUserData(res.user!.uid);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          _error = e.message;
          notifyListeners();
          verificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          _isLoading = false;
          notifyListeners();
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loginWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await FirebaseService.signInWithPhoneCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      if (res.user != null) {
        await loadUserData(res.user!.uid);
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await FirebaseService.signOut();
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
      await loadUserData(_user!.uid);
    }
  }
}
