import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/profile.dart';
import '../../models/mentor_profile.dart';
import '../../models/mentee_profile.dart';

/// Extension to support .id getter on Firebase User
extension FirebaseUserExt on User {
  String get id => uid;
}

/// Comprehensive Firebase Backend Service for Propel
/// Manages Firebase Auth (Email/Password & Google Sign-In) and Firestore collections
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get db => _db;
  static User? get currentUser => _auth.currentUser;

  // ==========================================
  // AUTHENTICATION & GOOGLE SIGN-IN
  // ==========================================

  /// Sign Up with Email & Password using Firebase Auth
  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName('$firstName $lastName');
      final newProfile = Profile(
        id: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        fullName: '$firstName $lastName',
        role: role,
        onboardingComplete: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      await saveProfile(newProfile);
    }

    return cred;
  }

  /// Send Password Reset Email
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Sign In with Email & Password using Firebase Auth
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign In / Sign Up with Google using Firebase Auth & GoogleSignIn
  static Future<UserCredential?> signInWithGoogle({String defaultRole = 'mentee'}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled flow

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user profile already exists in Firestore
        final doc = await _db.collection('profiles').doc(user.uid).get();
        if (!doc.exists) {
          final nameParts = (user.displayName ?? 'Propel User').split(' ');
          final fName = nameParts.isNotEmpty ? nameParts.first : 'Propel';
          final lName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';

          final newProfile = Profile(
            id: user.uid,
            email: user.email ?? '',
            firstName: fName,
            lastName: lName,
            fullName: user.displayName ?? '$fName $lName',
            avatarUrl: user.photoURL,
            role: defaultRole,
            onboardingComplete: false,
            createdAt: DateTime.now().toIso8601String(),
          );

          await saveProfile(newProfile);
        }
      }

      return userCredential;
    } catch (e) {
      print('[FirebaseService] Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign Out from Firebase and Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ==========================================
  // FIRESTORE PROFILES & USERS
  // ==========================================

  static Future<Profile?> fetchProfile(String userId) async {
    final doc = await _db.collection('profiles').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Profile.fromJson({...doc.data()!, 'id': userId});
  }

  static Future<void> saveProfile(Profile profile) async {
    await _db.collection('profiles').doc(profile.id).set(
          profile.toJson(),
          SetOptions(merge: true),
        );
  }

  static Future<MentorProfile?> fetchMentorProfile(String userId) async {
    final doc = await _db.collection('mentor_profiles').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MentorProfile.fromJson({...doc.data()!, 'user_id': userId});
  }

  static Future<void> saveMentorProfile(MentorProfile mentorProfile) async {
    await _db.collection('mentor_profiles').doc(mentorProfile.userId).set(
          mentorProfile.toJson(),
          SetOptions(merge: true),
        );
  }

  static Future<MenteeProfile?> fetchMenteeProfile(String userId) async {
    final doc = await _db.collection('mentee_profiles').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MenteeProfile.fromJson({...doc.data()!, 'user_id': userId});
  }

  static Future<void> saveMenteeProfile(MenteeProfile menteeProfile) async {
    await _db.collection('mentee_profiles').doc(menteeProfile.userId).set(
          menteeProfile.toJson(),
          SetOptions(merge: true),
        );
  }
}
