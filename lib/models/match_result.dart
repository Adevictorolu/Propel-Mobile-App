import 'profile.dart';
import 'mentor_profile.dart';

class MatchBreakdown {
  final double skillsScore;
  final double aspirationsScore;
  final double ratingScore;
  final double responsivenessScore;

  MatchBreakdown({
    required this.skillsScore,
    required this.aspirationsScore,
    required this.ratingScore,
    required this.responsivenessScore,
  });

  factory MatchBreakdown.fromJson(Map<String, dynamic> json) {
    return MatchBreakdown(
      skillsScore: (json['skills_score'] as num?)?.toDouble() ?? 0.0,
      aspirationsScore: (json['aspirations_score'] as num?)?.toDouble() ?? 0.0,
      ratingScore: (json['rating_score'] as num?)?.toDouble() ?? 0.0,
      responsivenessScore: (json['responsiveness_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MatchResult {
  final String mentorId;
  final double totalScore;
  final MatchBreakdown breakdown;
  final MentorProfile mentorProfile;
  final Profile profile;
  final double avgRating;
  final int reviewCount;

  MatchResult({
    required this.mentorId,
    required this.totalScore,
    required this.breakdown,
    required this.mentorProfile,
    required this.profile,
    required this.avgRating,
    required this.reviewCount,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      mentorId: json['mentor_id'] as String,
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
      breakdown: MatchBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>? ?? {}),
      mentorProfile: MentorProfile.fromJson(json['mentor_profile'] as Map<String, dynamic>? ?? {}),
      profile: Profile.fromJson(json['profile'] as Map<String, dynamic>? ?? {}),
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
    );
  }
}
