class CurriculumMilestone {
  final String id;
  final String goalId;
  final String title;
  final bool completed;

  CurriculumMilestone({
    required this.id,
    required this.goalId,
    required this.title,
    required this.completed,
  });

  factory CurriculumMilestone.fromJson(Map<String, dynamic> json) {
    return CurriculumMilestone(
      id: json['id'] as String,
      goalId: json['goal_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'title': title,
      'completed': completed,
    };
  }
}

class CurriculumGoal {
  final String id;
  final String title;
  final String targetDate;
  final String status; // 'not_started' | 'in_progress' | 'completed'

  CurriculumGoal({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.status,
  });

  factory CurriculumGoal.fromJson(Map<String, dynamic> json) {
    return CurriculumGoal(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      targetDate: json['target_date'] as String? ?? '',
      status: json['status'] as String? ?? 'not_started',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'target_date': targetDate,
      'status': status,
    };
  }
}

class Curriculum {
  final String id;
  final String connectionId;
  final List<CurriculumGoal> goals;
  final List<CurriculumMilestone> milestones;
  final String createdAt;

  Curriculum({
    required this.id,
    required this.connectionId,
    required this.goals,
    required this.milestones,
    required this.createdAt,
  });

  factory Curriculum.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['goals'] as List<dynamic>? ?? [];
    final goalsList = rawGoals
        .map((g) => CurriculumGoal.fromJson(g as Map<String, dynamic>))
        .toList();

    final rawMilestones = json['milestones'] as List<dynamic>? ?? [];
    final milestonesList = rawMilestones
        .map((m) => CurriculumMilestone.fromJson(m as Map<String, dynamic>))
        .toList();

    return Curriculum(
      id: json['id'] as String,
      connectionId: json['connection_id'] as String,
      goals: goalsList,
      milestones: milestonesList,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
