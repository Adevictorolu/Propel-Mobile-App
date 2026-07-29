typedef UserRole = String; // 'mentor' | 'mentee'

class Profile {
  final String id;
  final String email;
  final String fullName;
  final String firstName;
  final String lastName;
  final String? username;
  final String? gender;
  final UserRole role;
  final String? avatarUrl;
  final bool onboardingComplete;
  final String? calendlyUrl;
  final Map<String, dynamic>? notificationPrefs;
  final Map<String, dynamic>? fieldVisibility;
  final String createdAt;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    this.username,
    this.gender,
    required this.role,
    this.avatarUrl,
    required this.onboardingComplete,
    this.calendlyUrl,
    this.notificationPrefs,
    this.fieldVisibility,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawFullName = json['full_name'] as String? ?? '';
    final parts = rawFullName.trim().split(' ');
    final derivedFirstName = json['first_name'] as String? ?? (parts.isNotEmpty ? parts.first : '');
    final derivedLastName = json['last_name'] as String? ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');

    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: rawFullName,
      firstName: derivedFirstName,
      lastName: derivedLastName,
      username: json['username'] as String?,
      gender: json['gender'] as String?,
      role: json['role'] as String? ?? 'mentee',
      avatarUrl: json['avatar_url'] as String?,
      onboardingComplete: json['onboarding_complete'] as bool? ?? false,
      calendlyUrl: json['calendly_url'] as String?,
      notificationPrefs: json['notification_prefs'] as Map<String, dynamic>?,
      fieldVisibility: json['field_visibility'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'gender': gender,
      'role': role,
      'avatar_url': avatarUrl,
      'onboarding_complete': onboardingComplete,
      'calendly_url': calendlyUrl,
      'notification_prefs': notificationPrefs,
      'field_visibility': fieldVisibility,
      'created_at': createdAt,
    };
  }
}
