import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/constants.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../providers/auth_provider.dart';

class MenteeOnboardingScreen extends StatefulWidget {
  const MenteeOnboardingScreen({super.key});

  @override
  State<MenteeOnboardingScreen> createState() => _MenteeOnboardingScreenState();
}

class _MenteeOnboardingScreenState extends State<MenteeOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _aspirationsController = TextEditingController();
  final _goalInputController = TextEditingController();
  final _skillInputController = TextEditingController();

  String _gender = 'Prefer not to say';
  String _areaOfInterest = AppConstants.availableMentorshipAreas.first;

  final List<String> _learningGoals = ['Master Flutter Web & Mobile Architecture'];
  final List<String> _desiredSkills = ['Dart', 'State Management'];

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _aspirationsController.dispose();
    _goalInputController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  void _addGoal() {
    final text = _goalInputController.text.trim();
    if (text.isNotEmpty && !_learningGoals.contains(text)) {
      setState(() {
        _learningGoals.add(text);
        _goalInputController.clear();
      });
    }
  }

  void _addSkill() {
    final text = _skillInputController.text.trim();
    if (text.isNotEmpty && !_desiredSkills.contains(text)) {
      setState(() {
        _desiredSkills.add(text);
        _skillInputController.clear();
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_learningGoals.isEmpty || _desiredSkills.isEmpty) {
      ToastOverlay.show(context, 'Please add at least one learning goal and skill', type: ToastType.error);
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService.completeMenteeOnboarding(
        userId: user.id,
        username: _usernameController.text.trim(),
        gender: _gender,
        areaOfInterest: _areaOfInterest,
        bio: _bioController.text.trim(),
        aspirations: _aspirationsController.text.trim(),
        learningGoals: _learningGoals,
        desiredSkills: _desiredSkills,
      );

      await context.read<AuthProvider>().refreshProfile();
      if (mounted) {
        ToastOverlay.show(context, 'Onboarding complete! Welcome to Propel.', type: ToastType.success);
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentee Onboarding'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            maxWidth: 600,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Text(
                    'Set Up Your Learning Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tell us about your aspirations and goals so we can match you with ideal mentors.',
                    style: TextStyle(color: AppColors.slate500, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Username',
                          hintText: 'johndoe_learner',
                          controller: _usernameController,
                          validator: AppValidators.validateUsername,
                        ),
                        const SizedBox(height: 16),
                        const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          items: AppConstants.genderOptions
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _gender = v!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Primary Area of Interest', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _areaOfInterest,
                          items: AppConstants.availableMentorshipAreas
                              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                              .toList(),
                          onChanged: (v) => setState(() => _areaOfInterest = v!),
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Bio',
                          hintText: 'Share a quick summary about your background and interests...',
                          controller: _bioController,
                          maxLines: 3,
                          validator: (v) => AppValidators.validateMinLength(v, 20, 'Bio'),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Career Aspirations',
                          hintText: 'Where do you see yourself in 2-3 years? What do you want to build?',
                          controller: _aspirationsController,
                          maxLines: 3,
                          validator: (v) => AppValidators.validateMinLength(v, 20, 'Aspirations'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        const Text('Learning Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _goalInputController,
                                decoration: const InputDecoration(hintText: 'Add a goal (e.g. Build fullstack app)'),
                                onSubmitted: (_) => _addGoal(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _addGoal,
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(backgroundColor: AppColors.brandBlue600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: _learningGoals.map((goal) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.check_circle_outline, color: AppColors.brandBlue600, size: 20),
                            title: Text(goal, style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() => _learningGoals.remove(goal)),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        const Text('Desired Skills to Learn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _skillInputController,
                                decoration: const InputDecoration(hintText: 'Add a skill (e.g. GraphQL, System Design)'),
                                onSubmitted: (_) => _addSkill(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _addSkill,
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(backgroundColor: AppColors.brandGreen600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _desiredSkills.map((skill) => Chip(
                            label: Text(skill),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() => _desiredSkills.remove(skill)),
                            backgroundColor: AppColors.brandBlue100,
                            labelStyle: const TextStyle(color: AppColors.brandBlue800, fontWeight: FontWeight.w600),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  AppButton(
                    text: 'Complete Profile & Explore Mentors',
                    isFullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _handleSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
