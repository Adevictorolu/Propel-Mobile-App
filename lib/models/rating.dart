import 'profile.dart';

class Rating {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final String connectionId;
  final double score;
  final String comment;
  final String createdAt;
  final Profile? reviewer;
  final Profile? reviewee;

  Rating({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.connectionId,
    required this.score,
    required this.comment,
    required this.createdAt,
    this.reviewer,
    this.reviewee,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    Profile? reviewerProf;
    if (json['reviewer'] != null && json['reviewer'] is Map<String, dynamic>) {
      reviewerProf = Profile.fromJson(json['reviewer']);
    }

    Profile? revieweeProf;
    if (json['reviewee'] != null && json['reviewee'] is Map<String, dynamic>) {
      revieweeProf = Profile.fromJson(json['reviewee']);
    }

    return Rating(
      id: json['id'] as String,
      reviewerId: json['reviewer_id'] as String,
      revieweeId: json['reviewee_id'] as String,
      connectionId: json['connection_id'] as String,
      score: (json['score'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      reviewer: reviewerProf,
      reviewee: revieweeProf,
    );
  }
}
