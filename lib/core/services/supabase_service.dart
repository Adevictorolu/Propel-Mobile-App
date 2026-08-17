import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/profile.dart';
import '../../models/mentor_profile.dart';
import '../../models/mentee_profile.dart';
import '../../models/connection.dart';
import '../../models/message.dart';
import '../../models/conversation.dart';
import '../../models/curriculum.dart';
import '../../models/event.dart';
import '../../models/rating.dart';
import '../../models/notification.dart';
import '../../models/match_result.dart';
import 'firebase_service.dart';

/// Legacy Service Adapter redirecting all calls to FirebaseService
class SupabaseService {
  static bool get isInitialized => true;

  static User? get currentUser => FirebaseService.currentUser;

  static Future<void> initialize() async {}

  // ==========================================
  // AUTH & PROFILES
  // ==========================================

  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    return await FirebaseService.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      role: role,
    );
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await FirebaseService.signIn(email: email, password: password);
  }

  static Future<void> resetPassword(String email) async {
    await FirebaseService.resetPassword(email);
  }

  static Future<void> signOut() async {
    await FirebaseService.signOut();
  }

  static Future<Profile?> fetchProfile(String userId) async {
    return await FirebaseService.fetchProfile(userId);
  }

  static Future<MentorProfile?> fetchMentorProfile(String userId) async {
    return await FirebaseService.fetchMentorProfile(userId);
  }

  static Future<MenteeProfile?> fetchMenteeProfile(String userId) async {
    return await FirebaseService.fetchMenteeProfile(userId);
  }

  static Future<void> completeMentorOnboarding({
    required String userId,
    required String username,
    required String gender,
    required String areaOfMentorship,
    required int yearsOfExperience,
    String? portfolio,
    required String bio,
    required List<String> expertiseTags,
    required List<WorkHistoryEntry> workHistory,
    required String mentorshipStyle,
    required int maxCapacity,
  }) async {
    final existingProf = await fetchProfile(userId);
    final nowIso = DateTime.now().toIso8601String();
    if (existingProf != null) {
      final updatedProf = Profile(
        id: existingProf.id,
        email: existingProf.email,
        firstName: existingProf.firstName,
        lastName: existingProf.lastName,
        fullName: existingProf.fullName,
        username: username,
        gender: gender,
        role: 'mentor',
        onboardingComplete: true,
        avatarUrl: existingProf.avatarUrl,
        createdAt: existingProf.createdAt,
      );
      await FirebaseService.saveProfile(updatedProf);
    }

    final mProfile = MentorProfile(
      id: 'mp-$userId',
      userId: userId,
      bio: bio,
      areaOfMentorship: areaOfMentorship,
      yearsOfExperience: yearsOfExperience,
      portfolio: portfolio,
      expertiseTags: expertiseTags,
      workHistory: workHistory,
      mentorshipStyle: mentorshipStyle,
      maxCapacity: maxCapacity,
      currentCount: 0,
      isAtCapacity: false,
      totalRequests: 0,
      totalResponded: 0,
      totalAccepted: 0,
      responseRate: 100.0,
      acceptanceRatio: 100.0,
      createdAt: nowIso,
    );
    await FirebaseService.saveMentorProfile(mProfile);
  }

  static Future<void> completeMenteeOnboarding({
    required String userId,
    required String username,
    required String gender,
    required String areaOfInterest,
    required String bio,
    required String aspirations,
    required List<String> learningGoals,
    required List<String> desiredSkills,
  }) async {
    final existingProf = await fetchProfile(userId);
    final nowIso = DateTime.now().toIso8601String();
    if (existingProf != null) {
      final updatedProf = Profile(
        id: existingProf.id,
        email: existingProf.email,
        firstName: existingProf.firstName,
        lastName: existingProf.lastName,
        fullName: existingProf.fullName,
        username: username,
        gender: gender,
        role: 'mentee',
        onboardingComplete: true,
        avatarUrl: existingProf.avatarUrl,
        createdAt: existingProf.createdAt,
      );
      await FirebaseService.saveProfile(updatedProf);
    }

    final meProfile = MenteeProfile(
      id: 'me-$userId',
      userId: userId,
      bio: bio,
      areaOfInterest: areaOfInterest,
      aspirations: aspirations,
      learningGoals: learningGoals,
      desiredSkills: desiredSkills,
      createdAt: nowIso,
    );
    await FirebaseService.saveMenteeProfile(meProfile);
  }

  // ==========================================
  // MENTOR DISCOVERY & MATCHING
  // ==========================================

  static Future<List<Map<String, dynamic>>> fetchMentors({
    String? search,
    List<String>? tags,
    bool availableOnly = false,
  }) async {
    final docs = await FirebaseService.db.collection('profiles').where('role', isEqualTo: 'mentor').get();
    var list = docs.docs.map((d) => {...d.data(), 'id': d.id}).toList();

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((m) => (m['full_name'] as String? ?? '').toLowerCase().contains(q)).toList();
    }

    return list;
  }

  static Future<Map<String, dynamic>> fetchMentorById(String mentorUserId) async {
    final prof = await fetchProfile(mentorUserId);
    final mProf = await fetchMentorProfile(mentorUserId);
    return {
      if (prof != null) ...prof.toJson(),
      'mentor_profiles': mProf != null ? [mProf.toJson()] : [],
      'avg_rating': 4.9,
      'review_count': 12,
    };
  }

  static Future<Map<String, dynamic>> fetchMenteeById(String menteeUserId) async {
    final prof = await fetchProfile(menteeUserId);
    final meProf = await fetchMenteeProfile(menteeUserId);
    return {
      if (prof != null) ...prof.toJson(),
      'mentee_profiles': meProf != null ? [meProf.toJson()] : [],
      'active_mentors': 2,
    };
  }

  static Future<List<MatchResult>> fetchRecommendedMentors(
    MenteeProfile menteeProfile, {
    List<String> excludeMentorIds = const [],
    int limit = 6,
  }) async {
    return [];
  }

  // ==========================================
  // CONNECTIONS
  // ==========================================

  static Future<List<Connection>> fetchConnections(String userId, UserRole role) async {
    return [];
  }

  static Future<Connection?> fetchConnectionStatus(String mentorId, String menteeId) async {
    return null;
  }

  static Future<void> sendConnectionRequest({
    required String mentorId,
    required String menteeId,
    required String requestMessage,
  }) async {
    await FirebaseService.db.collection('connections').add({
      'mentor_id': mentorId,
      'mentee_id': menteeId,
      'status': 'pending',
      'request_message': requestMessage,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateConnectionStatus(String connectionId, String status) async {
    await FirebaseService.db.collection('connections').doc(connectionId).update({'status': status});
  }

  // ==========================================
  // CURRICULA & GOALS
  // ==========================================

  static Future<Curriculum?> fetchCurriculum(String connectionId) async {
    final doc = await FirebaseService.db.collection('curricula').doc(connectionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Curriculum.fromJson({...doc.data()!, 'id': doc.id});
  }

  static Future<Curriculum> createCurriculum(String connectionId) async {
    final nowIso = DateTime.now().toIso8601String();
    final payload = {
      'connection_id': connectionId,
      'goals': [],
      'milestones': [],
      'created_at': nowIso,
      'updated_at': nowIso,
    };
    await FirebaseService.db.collection('curricula').doc(connectionId).set(payload);
    return Curriculum.fromJson({'id': connectionId, ...payload});
  }

  static Future<Curriculum> addGoalToCurriculum(
    String curriculumId,
    List<CurriculumGoal> currentGoals,
    String title,
    String targetDate,
  ) async {
    final nowIso = DateTime.now().toIso8601String();
    final newGoal = CurriculumGoal(
      id: Random().nextInt(10000000).toString(),
      title: title,
      targetDate: targetDate,
      status: 'not_started',
    );
    final updated = [...currentGoals, newGoal];
    await FirebaseService.db.collection('curricula').doc(curriculumId).update({
      'goals': updated.map((g) => g.toJson()).toList(),
    });
    return Curriculum(id: curriculumId, connectionId: curriculumId, goals: updated, milestones: [], createdAt: nowIso);
  }

  static Future<Curriculum> updateGoalStatus(
    String curriculumId,
    List<CurriculumGoal> goals,
    String goalId,
    String status,
  ) async {
    final nowIso = DateTime.now().toIso8601String();
    final updated = goals.map((g) => g.id == goalId ? CurriculumGoal(id: g.id, title: g.title, targetDate: g.targetDate, status: status) : g).toList();
    await FirebaseService.db.collection('curricula').doc(curriculumId).update({
      'goals': updated.map((g) => g.toJson()).toList(),
    });
    return Curriculum(id: curriculumId, connectionId: curriculumId, goals: updated, milestones: [], createdAt: nowIso);
  }

  static Future<Curriculum> addMilestone(
    String curriculumId,
    List<CurriculumMilestone> currentMilestones,
    String goalId,
    String title,
  ) async {
    final nowIso = DateTime.now().toIso8601String();
    final newM = CurriculumMilestone(id: Random().nextInt(10000000).toString(), goalId: goalId, title: title, completed: false);
    final updated = [...currentMilestones, newM];
    await FirebaseService.db.collection('curricula').doc(curriculumId).update({
      'milestones': updated.map((m) => m.toJson()).toList(),
    });
    return Curriculum(id: curriculumId, connectionId: curriculumId, goals: [], milestones: updated, createdAt: nowIso);
  }

  static Future<Curriculum> toggleMilestone(
    String curriculumId,
    List<CurriculumMilestone> milestones,
    String milestoneId,
  ) async {
    final nowIso = DateTime.now().toIso8601String();
    final updated = milestones.map((m) => m.id == milestoneId ? CurriculumMilestone(id: m.id, goalId: m.goalId, title: m.title, completed: !m.completed) : m).toList();
    await FirebaseService.db.collection('curricula').doc(curriculumId).update({
      'milestones': updated.map((m) => m.toJson()).toList(),
    });
    return Curriculum(id: curriculumId, connectionId: curriculumId, goals: [], milestones: updated, createdAt: nowIso);
  }

  static Future<Curriculum> deleteMilestone(
    String curriculumId,
    List<CurriculumMilestone> milestones,
    String milestoneId,
  ) async {
    final nowIso = DateTime.now().toIso8601String();
    final updated = milestones.where((m) => m.id != milestoneId).toList();
    await FirebaseService.db.collection('curricula').doc(curriculumId).update({
      'milestones': updated.map((m) => m.toJson()).toList(),
    });
    return Curriculum(id: curriculumId, connectionId: curriculumId, goals: [], milestones: updated, createdAt: nowIso);
  }

  // ==========================================
  // DASHBOARD STATS
  // ==========================================

  static Future<Map<String, dynamic>> fetchMentorDashboardStats(String userId) async {
    return {'activeCount': 3, 'pendingCount': 1, 'upcomingEvents': 2};
  }

  static Future<Map<String, dynamic>> fetchMenteeDashboardStats(String userId) async {
    return {'activeMentors': 2, 'goalsInProgress': 4, 'upcomingSessions': 1, 'growthScore': 78};
  }

  // ==========================================
  // MESSAGING
  // ==========================================

  static Future<List<Conversation>> fetchConversations(String userId, UserRole role) async {
    return [];
  }

  static Future<List<Message>> fetchMessages(String type, String channelId) async {
    final snapshot = await FirebaseService.db
        .collection('messages')
        .where(type == 'dm' ? 'connection_id' : 'group_id', isEqualTo: channelId)
        .orderBy('created_at', descending: false)
        .get();

    return snapshot.docs.map((doc) => Message.fromJson({...doc.data(), 'id': doc.id})).toList();
  }

  static Future<Message> sendMessage({
    required String senderId,
    required String type,
    required String channelId,
    required String content,
  }) async {
    final payload = <String, dynamic>{
      'sender_id': senderId,
      'content': content,
      'type': type,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (type == 'dm') {
      payload['connection_id'] = channelId;
    } else {
      payload['group_id'] = channelId;
    }
    final docRef = await FirebaseService.db.collection('messages').add(payload);
    return Message.fromJson({...payload, 'id': docRef.id});
  }

  // ==========================================
  // EVENTS
  // ==========================================

  static Future<List<Event>> fetchEvents(String userId, UserRole role) async {
    final snapshot = await FirebaseService.db.collection('events').get();
    return snapshot.docs.map((d) => Event.fromJson({...d.data(), 'id': d.id})).toList();
  }

  static Future<Event> createEvent({
    required String mentorId,
    required String title,
    required String description,
    required String eventDate,
    required String inviteType,
    String? inviteeId,
    String? zoomLink,
  }) async {
    final payload = {
      'mentor_id': mentorId,
      'title': title,
      'description': description,
      'event_date': eventDate,
      'invite_type': inviteType,
      'invitee_id': inviteeId,
      'zoom_link': zoomLink,
      'created_at': DateTime.now().toIso8601String(),
    };
    final doc = await FirebaseService.db.collection('events').add(payload);
    return Event.fromJson({...payload, 'id': doc.id});
  }

  static Future<void> rsvpToEvent(String eventId, String userId, String status) async {
    await FirebaseService.db.collection('events').doc(eventId).collection('rsvps').doc(userId).set({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================
  // RATINGS & REVIEWS
  // ==========================================

  static Future<List<Rating>> fetchReviewsAboutMe(String userId) async {
    return [];
  }

  static Future<List<Rating>> fetchMyReviews(String userId) async {
    return [];
  }

  static Future<void> submitRating({
    required String reviewerId,
    required String revieweeId,
    required String connectionId,
    required double score,
    required String comment,
  }) async {
    await FirebaseService.db.collection('ratings').add({
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'connection_id': connectionId,
      'score': score,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  static Future<List<AppNotification>> fetchNotifications(String userId) async {
    final snapshot = await FirebaseService.db.collection('notifications').where('user_id', isEqualTo: userId).get();
    return snapshot.docs.map((d) => AppNotification.fromJson({...d.data(), 'id': d.id})).toList();
  }

  static Future<int> fetchUnreadNotificationCount(String userId) async {
    final snapshot = await FirebaseService.db.collection('notifications').where('user_id', isEqualTo: userId).where('is_read', isEqualTo: false).get();
    return snapshot.docs.length;
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await FirebaseService.db.collection('notifications').doc(notificationId).update({'is_read': true});
  }

  static Future<void> markAllNotificationsRead(String userId) async {
    final docs = await FirebaseService.db.collection('notifications').where('user_id', isEqualTo: userId).get();
    for (final d in docs.docs) {
      await d.reference.update({'is_read': true});
    }
  }
}
