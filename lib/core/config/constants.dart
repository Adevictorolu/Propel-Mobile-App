class AppConstants {
  static const String appName = 'Propel';
  static const String appTagline = 'Professional Mentorship Program for Emerging Leaders';
  


  static const List<String> publicRoutes = [
    '/',
    '/login',
    '/signup',
    '/forgot-password',
    '/verify-email',
    '/auth/callback',
  ];

  static const List<String> availableMentorshipAreas = [
    'Software Engineering',
    'Product Management',
    'UX/UI Design',
    'Data Science & AI',
    'DevOps & Cloud',
    'Cybersecurity',
    'Digital Marketing',
    'Business & Entrepreneurship',
    'Career Transition',
    'Leadership & Management',
  ];

  static const List<String> mentorshipStyles = [
    '1-on-1 Weekly Coaching',
    'Bi-weekly Strategic Check-ins',
    'Project-based Mentorship',
    'Async Code/Design Review',
    'Group Workshops',
  ];

  static const List<String> genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];
}
