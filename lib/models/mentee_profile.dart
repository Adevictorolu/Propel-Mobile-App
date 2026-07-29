class MenteeProfile {
  final String id;
  final String userId;
  final String bio;
  final String areaOfInterest;
  final String aspirations;
  final List<String> learningGoals;
  final List<String> desiredSkills;
  final String createdAt;

  MenteeProfile({
    required this.id,
    required this.userId,
    required this.bio,
    required this.areaOfInterest,
    required this.aspirations,
    required this.learningGoals,
    required this.desiredSkills,
    required this.createdAt,
  });

  factory MenteeProfile.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['learning_goals'] as List<dynamic>? ?? [];
    final goalsList = rawGoals.map((e) => e.toString()).toList();

    final rawSkills = json['desired_skills'] as List<dynamic>? ?? [];
    final skillsList = rawSkills.map((e) => e.toString()).toList();

    return MenteeProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bio: json['bio'] as String? ?? '',
      areaOfInterest: json['area_of_interest'] as String? ?? '',
      aspirations: json['aspirations'] as String? ?? '',
      learningGoals: goalsList,
      desiredSkills: skillsList,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bio': bio,
      'area_of_interest': areaOfInterest,
      'aspirations': aspirations,
      'learning_goals': learningGoals,
      'desired_skills': desiredSkills,
      'created_at': createdAt,
    };
  }
}
