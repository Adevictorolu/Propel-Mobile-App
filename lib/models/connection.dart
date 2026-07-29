import 'profile.dart';
import 'mentor_profile.dart';
import 'mentee_profile.dart';

typedef ConnectionStatus = String; // 'pending' | 'active' | 'rejected' | 'ended'

class Connection {
  final String id;
  final String mentorId;
  final String menteeId;
  final ConnectionStatus status;
  final String requestMessage;
  final String createdAt;
  final String updatedAt;
  final Profile? mentor;
  final MentorProfile? mentorProfile;
  final Profile? mentee;
  final MenteeProfile? menteeProfile;

  Connection({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.status,
    required this.requestMessage,
    required this.createdAt,
    required this.updatedAt,
    this.mentor,
    this.mentorProfile,
    this.mentee,
    this.menteeProfile,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    Profile? mentorProf;
    MentorProfile? mProfDetails;
    if (json['mentor'] != null && json['mentor'] is Map<String, dynamic>) {
      mentorProf = Profile.fromJson(json['mentor']);
      final mProfiles = json['mentor']['mentor_profiles'];
      if (mProfiles != null && mProfiles is List && mProfiles.isNotEmpty) {
        mProfDetails = MentorProfile.fromJson(mProfiles.first);
      }
    }

    Profile? menteeProf;
    MenteeProfile? menteeProfDetails;
    if (json['mentee'] != null && json['mentee'] is Map<String, dynamic>) {
      menteeProf = Profile.fromJson(json['mentee']);
      final meProfiles = json['mentee']['mentee_profiles'];
      if (meProfiles != null && meProfiles is List && meProfiles.isNotEmpty) {
        menteeProfDetails = MenteeProfile.fromJson(meProfiles.first);
      }
    }

    return Connection(
      id: json['id'] as String,
      mentorId: json['mentor_id'] as String,
      menteeId: json['mentee_id'] as String,
      status: json['status'] as String? ?? 'pending',
      requestMessage: json['request_message'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      mentor: mentorProf,
      mentorProfile: mProfDetails,
      mentee: menteeProf,
      menteeProfile: menteeProfDetails,
    );
  }
}
