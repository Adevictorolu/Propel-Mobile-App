import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
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

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  }

  // ==========================================
  // AUTH & PROFILES
  // ==========================================

  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserRole role,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': '$firstName $lastName'.trim(),
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      },
    );
    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email.trim());
  }

  static Future<Profile?> fetchProfile(String userId) async {
    try {
      final res = await client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (res == null) return null;
      return Profile.fromJson(res);
    } catch (e) {
      print('[SupabaseService] fetchProfile error: $e');
      return null;
    }
  }

  static Future<MentorProfile?> fetchMentorProfile(String userId) async {
    try {
      final res = await client
          .from('mentor_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return null;
      return MentorProfile.fromJson(res);
    } catch (e) {
      print('[SupabaseService] fetchMentorProfile error: $e');
      return null;
    }
  }

  static Future<MenteeProfile?> fetchMenteeProfile(String userId) async {
    try {
      final res = await client
          .from('mentee_profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return null;
      return MenteeProfile.fromJson(res);
    } catch (e) {
      print('[SupabaseService] fetchMenteeProfile error: $e');
      return null;
    }
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
    // 1. Update Profile base info
    await client.from('profiles').update({
      'username': username,
      'gender': gender,
      'onboarding_complete': true,
    }).eq('id', userId);

    // 2. Upsert Mentor Profile
    await client.from('mentor_profiles').upsert({
      'user_id': userId,
      'bio': bio,
      'area_of_mentorship': areaOfMentorship,
      'years_of_experience': yearsOfExperience,
      'portfolio': portfolio,
      'expertise_tags': expertiseTags,
      'work_history': workHistory.map((w) => w.toJson()).toList(),
      'mentorship_style': mentorshipStyle,
      'max_capacity': maxCapacity,
    }, onConflict: 'user_id');
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
    // 1. Update Profile base info
    await client.from('profiles').update({
      'username': username,
      'gender': gender,
      'onboarding_complete': true,
    }).eq('id', userId);

    // 2. Upsert Mentee Profile
    await client.from('mentee_profiles').upsert({
      'user_id': userId,
      'bio': bio,
      'area_of_interest': areaOfInterest,
      'aspirations': aspirations,
      'learning_goals': learningGoals,
      'desired_skills': desiredSkills,
    }, onConflict: 'user_id');
  }

  // ==========================================
  // MENTOR DISCOVERY & MATCHING
  // ==========================================

  static Future<List<Map<String, dynamic>>> fetchMentors({
    String? search,
    List<String>? tags,
    bool availableOnly = false,
  }) async {
    var query = client
        .from('profiles')
        .select('*, mentor_profiles!inner(*)')
        .eq('role', 'mentor')
        .eq('onboarding_complete', true);

    if (search != null && search.isNotEmpty) {
      query = query.or('full_name.ilike.%$search%,mentor_profiles.bio.ilike.%$search%');
    }

    if (availableOnly) {
      query = query.eq('mentor_profiles.is_at_capacity', false);
    }

    final data = await query.order('created_at', ascending: false);
    var list = (data as List<dynamic>).cast<Map<String, dynamic>>();

    if (tags != null && tags.isNotEmpty) {
      list = list.where((m) {
        final mProfiles = m['mentor_profiles'] as List<dynamic>? ?? [];
        if (mProfiles.isEmpty) return false;
        final mTags = (mProfiles.first['expertise_tags'] as List<dynamic>? ?? [])
            .map((e) => e.toString().toLowerCase())
            .toList();
        return tags.any((tag) => mTags.contains(tag.toLowerCase()));
      }).toList();
    }

    // Attach ratings
    final mentorIds = list.map((m) => m['id'] as String).toList();
    if (mentorIds.isNotEmpty) {
      final ratingsRes = await client
          .from('ratings')
          .select('reviewee_id, score')
          .filter('reviewee_id', 'in', mentorIds);

      final ratingMap = <String, List<num>>{};
      for (final r in ratingsRes) {
        final id = r['reviewee_id'] as String;
        ratingMap.putIfAbsent(id, () => []).add(r['score'] as num);
      }

      list = list.map((m) {
        final id = m['id'] as String;
        final scores = ratingMap[id] ?? [];
        final avg = scores.isEmpty ? 0.0 : (scores.reduce((a, b) => a + b) / scores.length).toDouble();
        return {
          ...m,
          'avg_rating': avg,
          'review_count': scores.length,
        };
      }).toList();
    }

    return list;
  }

  static Future<Map<String, dynamic>> fetchMentorById(String mentorUserId) async {
    final profileRes = await client
        .from('profiles')
        .select('*, mentor_profiles!inner(*)')
        .eq('id', mentorUserId)
        .single();

    final ratingsRes = await client
        .from('ratings')
        .select('*, reviewer:profiles!ratings_reviewer_id_fkey(id, full_name, avatar_url)')
        .eq('reviewee_id', mentorUserId)
        .order('created_at', ascending: false);

    final ratings = (ratingsRes as List<dynamic>).cast<Map<String, dynamic>>();
    final avg = ratings.isEmpty
        ? 0.0
        : (ratings.map((r) => r['score'] as num).reduce((a, b) => a + b) / ratings.length).toDouble();

    return {
      ...profileRes,
      'ratings': ratings,
      'avg_rating': avg,
      'review_count': ratings.length,
    };
  }

  static Future<Map<String, dynamic>> fetchMenteeById(String menteeUserId) async {
    final profileRes = await client
        .from('profiles')
        .select('*, mentee_profiles!inner(*)')
        .eq('id', menteeUserId)
        .single();

    final connectionsRes = await client
        .from('connections')
        .select('id')
        .eq('mentee_id', menteeUserId)
        .eq('status', 'active');

    return {
      ...profileRes,
      'active_mentors': (connectionsRes as List<dynamic>).length,
    };
  }

  static Future<List<MatchResult>> fetchRecommendedMentors(
    MenteeProfile menteeProfile, {
    List<String> excludeMentorIds = const [],
    int limit = 6,
  }) async {
    try {
      // Try edge function first
      final edgeRes = await client.functions.invoke('match-mentors', body: {
        'mentee_id': menteeProfile.userId,
        'limit': limit,
      });
      if (edgeRes.data != null && edgeRes.data['matches'] != null) {
        final rawMatches = edgeRes.data['matches'] as List<dynamic>;
        return rawMatches.map((m) => MatchResult.fromJson(m as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Fallback to client-side recommendation engine
    final allMentors = await fetchMentors(availableOnly: true);
    final candidates = allMentors.where((m) => !excludeMentorIds.contains(m['id'])).toList();

    if (candidates.isEmpty) return [];

    final menteeSkills = menteeProfile.desiredSkills.map((s) => s.toLowerCase()).toSet();
    final menteeGoals = menteeProfile.learningGoals.map((g) => g.toLowerCase()).toSet();
    final menteeInterests = {...menteeSkills, ...menteeGoals};
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;

    final scored = candidates.map((m) {
      final mpRaw = (m['mentor_profiles'] as List<dynamic>).first as Map<String, dynamic>;
      final mp = MentorProfile.fromJson(mpRaw);
      final mTags = mp.expertiseTags.map((t) => t.toLowerCase()).toSet();

      final intersection = menteeInterests.where((s) => mTags.contains(s)).length;
      final tagOverlap = menteeInterests.isNotEmpty ? intersection / menteeInterests.length : 0.0;

      final avgRating = (m['avg_rating'] as num?)?.toDouble() ?? 0.0;
      final ratingScore = avgRating / 5.0;

      final remainingRatio = (mp.maxCapacity - mp.currentCount) / max(1, mp.maxCapacity);
      final capacityBonus = max(0.0, min(1.0, remainingRatio));

      final createdAt = DateTime.tryParse(m['created_at'] as String? ?? '')?.millisecondsSinceEpoch ?? now;
      final age = now - createdAt;
      final recencyBonus = max(0.0, 1.0 - (age / (thirtyDaysMs * 6)));

      final totalScore = (tagOverlap * 0.5) + (ratingScore * 0.25) + (capacityBonus * 0.15) + (recencyBonus * 0.1);

      return MatchResult(
        mentorId: m['id'] as String,
        totalScore: totalScore,
        breakdown: MatchBreakdown(
          skillsScore: tagOverlap,
          aspirationsScore: capacityBonus,
          ratingScore: ratingScore,
          responsivenessScore: recencyBonus,
        ),
        mentorProfile: mp,
        profile: Profile.fromJson(m),
        avgRating: avgRating,
        reviewCount: (m['review_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    scored.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return scored.take(limit).toList();
  }

  // ==========================================
  // CONNECTIONS
  // ==========================================

  static Future<List<Connection>> fetchConnections(String userId, UserRole role) async {
    final column = role == 'mentor' ? 'mentor_id' : 'mentee_id';

    final data = await client
        .from('connections')
        .select('''
          *,
          mentor:profiles!connections_mentor_id_fkey(id, full_name, avatar_url, email, mentor_profiles(*)),
          mentee:profiles!connections_mentee_id_fkey(id, full_name, avatar_url, email, mentee_profiles(*))
        ''')
        .eq(column, userId)
        .order('updated_at', ascending: false);

    return (data as List<dynamic>)
        .map((c) => Connection.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  static Future<Connection?> fetchConnectionStatus(String mentorId, String menteeId) async {
    final data = await client
        .from('connections')
        .select('id, status')
        .eq('mentor_id', mentorId)
        .eq('mentee_id', menteeId)
        .filter('status', 'in', ['pending', 'active'])
        .maybeSingle();

    if (data == null) return null;
    return Connection.fromJson(data);
  }

  static Future<void> sendConnectionRequest({
    required String mentorId,
    required String menteeId,
    required String requestMessage,
  }) async {
    await client.from('connections').insert({
      'mentor_id': mentorId,
      'mentee_id': menteeId,
      'status': 'pending',
      'request_message': requestMessage,
    });
  }

  static Future<void> updateConnectionStatus(String connectionId, String status) async {
    await client.from('connections').update({'status': status}).eq('id', connectionId);
  }

  // ==========================================
  // CURRICULA & GOALS
  // ==========================================

  static Future<Curriculum?> fetchCurriculum(String connectionId) async {
    final data = await client
        .from('curricula')
        .select('*')
        .eq('connection_id', connectionId)
        .maybeSingle();

    if (data == null) return null;
    return Curriculum.fromJson(data);
  }

  static Future<Curriculum> createCurriculum(String connectionId) async {
    final data = await client
        .from('curricula')
        .insert({
          'connection_id': connectionId,
          'goals': [],
          'milestones': [],
        })
        .select()
        .single();

    return Curriculum.fromJson(data);
  }

  static Future<Curriculum> addGoalToCurriculum(
    String curriculumId,
    List<CurriculumGoal> currentGoals,
    String title,
    String targetDate,
  ) async {
    final newGoal = CurriculumGoal(
      id: Random().nextInt(10000000).toString(),
      title: title,
      targetDate: targetDate,
      status: 'not_started',
    );

    final updated = [...currentGoals, newGoal];
    final data = await client
        .from('curricula')
        .update({'goals': updated.map((g) => g.toJson()).toList()})
        .eq('id', curriculumId)
        .select()
        .single();

    return Curriculum.fromJson(data);
  }

  static Future<Curriculum> updateGoalStatus(
    String curriculumId,
    List<CurriculumGoal> goals,
    String goalId,
    String status,
  ) async {
    final updated = goals.map((g) => g.id == goalId ? CurriculumGoal(id: g.id, title: g.title, targetDate: g.targetDate, status: status) : g).toList();
    final data = await client
        .from('curricula')
        .update({'goals': updated.map((g) => g.toJson()).toList()})
        .eq('id', curriculumId)
        .select()
        .single();

    return Curriculum.fromJson(data);
  }

  static Future<Curriculum> addMilestone(
    String curriculumId,
    List<CurriculumMilestone> currentMilestones,
    String goalId,
    String title,
  ) async {
    final newMilestone = CurriculumMilestone(
      id: Random().nextInt(10000000).toString(),
      goalId: goalId,
      title: title,
      completed: false,
    );

    final updated = [...currentMilestones, newMilestone];
    final data = await client
        .from('curricula')
        .update({'milestones': updated.map((m) => m.toJson()).toList()})
        .eq('id', curriculumId)
        .select()
        .single();

    return Curriculum.fromJson(data);
  }

  static Future<Curriculum> toggleMilestone(
    String curriculumId,
    List<CurriculumMilestone> milestones,
    String milestoneId,
  ) async {
    final updated = milestones
        .map((m) => m.id == milestoneId
            ? CurriculumMilestone(id: m.id, goalId: m.goalId, title: m.title, completed: !m.completed)
            : m)
        .toList();

    final data = await client
        .from('curricula')
        .update({'milestones': updated.map((m) => m.toJson()).toList()})
        .eq('id', curriculumId)
        .select()
        .single();

    return Curriculum.fromJson(data);
  }

  static Future<Curriculum> deleteMilestone(
    String curriculumId,
    List<CurriculumMilestone> milestones,
    String milestoneId,
  ) async {
    final updated = milestones.where((m) => m.id != milestoneId).toList();
    final data = await client
        .from('curricula')
        .update({'milestones': updated.map((m) => m.toJson()).toList()})
        .eq('id', curriculumId)
        .select()
        .single();

    return Curriculum.fromJson(data);
  }

  // ==========================================
  // DASHBOARD STATS
  // ==========================================

  static Future<Map<String, dynamic>> fetchMentorDashboardStats(String userId) async {
    final connectionsRes = await client.from('connections').select('id, status').eq('mentor_id', userId);
    final eventsRes = await client.from('events').select('id').eq('mentor_id', userId).gte('event_date', DateTime.now().toIso8601String());

    final connections = (connectionsRes as List<dynamic>).cast<Map<String, dynamic>>();
    final activeCount = connections.where((c) => c['status'] == 'active').length;
    final pendingCount = connections.where((c) => c['status'] == 'pending').length;
    final upcomingEvents = (eventsRes as List<dynamic>).length;

    return {
      'activeCount': activeCount,
      'pendingCount': pendingCount,
      'upcomingEvents': upcomingEvents,
    };
  }

  static Future<Map<String, dynamic>> fetchMenteeDashboardStats(String userId) async {
    final connectionsRes = await client.from('connections').select('id, mentor_id, status').eq('mentee_id', userId);
    final connections = (connectionsRes as List<dynamic>).cast<Map<String, dynamic>>();
    final activeConns = connections.where((c) => c['status'] == 'active').toList();
    final activeIds = activeConns.map((c) => c['id'] as String).toList();

    int goalsInProgress = 0;
    int totalMilestones = 0;
    int completedMilestones = 0;

    if (activeIds.isNotEmpty) {
      final curriculaRes = await client.from('curricula').select('goals, milestones').filter('connection_id', 'in', activeIds);
      for (final c in curriculaRes) {
        final goals = (c['goals'] as List<dynamic>? ?? []).map((g) => CurriculumGoal.fromJson(g as Map<String, dynamic>)).toList();
        final milestones = (c['milestones'] as List<dynamic>? ?? []).map((m) => CurriculumMilestone.fromJson(m as Map<String, dynamic>)).toList();
        goalsInProgress += goals.where((g) => g.status == 'in_progress').length;
        totalMilestones += milestones.length;
        completedMilestones += milestones.where((m) => m.completed).length;
      }
    }

    final growthScore = totalMilestones > 0 ? ((completedMilestones / totalMilestones) * 100).round() : 0;

    return {
      'activeMentors': activeConns.length,
      'goalsInProgress': goalsInProgress,
      'upcomingSessions': 0,
      'growthScore': growthScore,
    };
  }

  // ==========================================
  // MESSAGING
  // ==========================================

  static Future<List<Conversation>> fetchConversations(String userId, UserRole role) async {
    final column = role == 'mentor' ? 'mentor_id' : 'mentee_id';
    final partnerCol = role == 'mentor' ? 'mentee' : 'mentor';

    final connsRes = await client.from('connections').select('id, status, mentor_id, mentee_id').eq(column, userId).eq('status', 'active');
    final rawConns = (connsRes as List<dynamic>).cast<Map<String, dynamic>>();

    final conversations = <Conversation>[];

    if (rawConns.isNotEmpty) {
      final partnerIds = rawConns.map((c) => c[partnerCol == 'mentor' ? 'mentor_id' : 'mentee_id'] as String).toList();
      final profilesRes = await client.from('profiles').select('id, full_name, avatar_url').filter('id', 'in', partnerIds);
      final profileMap = {for (var p in profilesRes) p['id'] as String: p};

      for (final c in rawConns) {
        final pId = c[partnerCol == 'mentor' ? 'mentor_id' : 'mentee_id'] as String;
        final p = profileMap[pId];
        conversations.add(Conversation(
          id: 'dm-${c['id']}',
          type: 'dm',
          name: p != null ? p['full_name'] as String : 'Unknown',
          connectionId: c['id'] as String,
          partnerId: pId,
          partnerAvatar: p != null ? p['avatar_url'] as String? : null,
        ));
      }
    }

    return conversations;
  }

  static Future<List<Message>> fetchMessages(String type, String channelId) async {
    final column = type == 'dm' ? 'connection_id' : 'group_id';

    final rawMsgs = await client
        .from('messages')
        .select('*')
        .eq(column, channelId)
        .eq('type', type)
        .order('created_at', ascending: true)
        .limit(50);

    final msgs = (rawMsgs as List<dynamic>).cast<Map<String, dynamic>>();
    if (msgs.isEmpty) return [];

    final senderIds = msgs.map((m) => m['sender_id'] as String).toSet().toList();
    final sendersRes = await client.from('profiles').select('id, full_name, avatar_url').filter('id', 'in', senderIds);
    final senderMap = {for (var s in sendersRes) s['id'] as String: Profile.fromJson(s)};

    return msgs.map((m) {
      final senderObj = senderMap[m['sender_id']];
      return Message.fromJson({
        ...m,
        'sender': senderObj?.toJson(),
      });
    }).toList();
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
    };
    if (type == 'dm') {
      payload['connection_id'] = channelId;
    } else {
      payload['group_id'] = channelId;
    }

    final data = await client.from('messages').insert(payload).select('*').single();
    final senderProfile = await fetchProfile(senderId);

    return Message.fromJson({
      ...data,
      'sender': senderProfile?.toJson(),
    });
  }

  // ==========================================
  // EVENTS
  // ==========================================

  static Future<List<Event>> fetchEvents(String userId, UserRole role) async {
    var query = client.from('events').select('''
      *,
      mentor:profiles!events_mentor_id_fkey(id, full_name, avatar_url),
      rsvps:event_rsvps(id, event_id, user_id, status, profile:profiles!event_rsvps_user_id_fkey(id, full_name, avatar_url))
    ''').order('event_date', ascending: true);

    if (role == 'mentor') {
      query = query.eq('mentor_id', userId);
    }

    final data = await query;
    return (data as List<dynamic>).map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
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
    final data = await client.from('events').insert({
      'mentor_id': mentorId,
      'title': title,
      'description': description,
      'event_date': eventDate,
      'invite_type': inviteType,
      'invitee_id': inviteeId,
      'zoom_link': zoomLink,
    }).select().single();

    return Event.fromJson(data);
  }

  static Future<void> rsvpToEvent(String eventId, String userId, String status) async {
    await client.from('event_rsvps').upsert({
      'event_id': eventId,
      'user_id': userId,
      'status': status,
    }, onConflict: 'event_id,user_id');
  }

  // ==========================================
  // RATINGS & REVIEWS
  // ==========================================

  static Future<List<Rating>> fetchReviewsAboutMe(String userId) async {
    final data = await client
        .from('ratings')
        .select('*, reviewer:profiles!ratings_reviewer_id_fkey(id, full_name, avatar_url)')
        .eq('reviewee_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>).map((r) => Rating.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<List<Rating>> fetchMyReviews(String userId) async {
    final data = await client
        .from('ratings')
        .select('*, reviewee:profiles!ratings_reviewee_id_fkey(id, full_name, avatar_url)')
        .eq('reviewer_id', userId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>).map((r) => Rating.fromJson(r as Map<String, dynamic>)).toList();
  }

  static Future<void> submitRating({
    required String reviewerId,
    required String revieweeId,
    required String connectionId,
    required double score,
    required String comment,
  }) async {
    await client.from('ratings').insert({
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'connection_id': connectionId,
      'score': score,
      'comment': comment,
    });
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================

  static Future<List<AppNotification>> fetchNotifications(String userId) async {
    final data = await client
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);

    return (data as List<dynamic>).map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList();
  }

  static Future<int> fetchUnreadNotificationCount(String userId) async {
    final res = await client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (res as List<dynamic>).length;
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  static Future<void> markAllNotificationsRead(String userId) async {
    await client.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('is_read', false);
  }
}
