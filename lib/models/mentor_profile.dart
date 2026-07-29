class WorkHistoryEntry {
  final String role;
  final String company;
  final int years;

  WorkHistoryEntry({
    required this.role,
    required this.company,
    required this.years,
  });

  factory WorkHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkHistoryEntry(
      role: json['role'] as String? ?? '',
      company: json['company'] as String? ?? '',
      years: (json['years'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'company': company,
      'years': years,
    };
  }
}

class MentorProfile {
  final String id;
  final String userId;
  final String bio;
  final List<String> expertiseTags;
  final List<WorkHistoryEntry> workHistory;
  final String mentorshipStyle;
  final int maxCapacity;
  final int currentCount;
  final bool isAtCapacity;
  final String areaOfMentorship;
  final int yearsOfExperience;
  final String? portfolio;
  final int totalRequests;
  final int totalResponded;
  final int totalAccepted;
  final double responseRate;
  final double acceptanceRatio;
  final String createdAt;

  MentorProfile({
    required this.id,
    required this.userId,
    required this.bio,
    required this.expertiseTags,
    required this.workHistory,
    required this.mentorshipStyle,
    required this.maxCapacity,
    required this.currentCount,
    required this.isAtCapacity,
    required this.areaOfMentorship,
    required this.yearsOfExperience,
    this.portfolio,
    required this.totalRequests,
    required this.totalResponded,
    required this.totalAccepted,
    required this.responseRate,
    required this.acceptanceRatio,
    required this.createdAt,
  });

  factory MentorProfile.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['work_history'] as List<dynamic>? ?? [];
    final historyList = rawHistory
        .map((item) => WorkHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();

    final rawTags = json['expertise_tags'] as List<dynamic>? ?? [];
    final tagsList = rawTags.map((e) => e.toString()).toList();

    return MentorProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bio: json['bio'] as String? ?? '',
      expertiseTags: tagsList,
      workHistory: historyList,
      mentorshipStyle: json['mentorship_style'] as String? ?? '',
      maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 5,
      currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
      isAtCapacity: json['is_at_capacity'] as bool? ?? false,
      areaOfMentorship: json['area_of_mentorship'] as String? ?? '',
      yearsOfExperience: (json['years_of_experience'] as num?)?.toInt() ?? 0,
      portfolio: json['portfolio'] as String?,
      totalRequests: (json['total_requests'] as num?)?.toInt() ?? 0,
      totalResponded: (json['total_responded'] as num?)?.toInt() ?? 0,
      totalAccepted: (json['total_accepted'] as num?)?.toInt() ?? 0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 0.0,
      acceptanceRatio: (json['acceptance_ratio'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bio': bio,
      'expertise_tags': expertiseTags,
      'work_history': workHistory.map((e) => e.toJson()).toList(),
      'mentorship_style': mentorshipStyle,
      'max_capacity': maxCapacity,
      'current_count': currentCount,
      'is_at_capacity': isAtCapacity,
      'area_of_mentorship': areaOfMentorship,
      'years_of_experience': yearsOfExperience,
      'portfolio': portfolio,
      'total_requests': totalRequests,
      'total_responded': totalResponded,
      'total_accepted': totalAccepted,
      'response_rate': responseRate,
      'acceptance_ratio': acceptanceRatio,
      'created_at': createdAt,
    };
  }
}
