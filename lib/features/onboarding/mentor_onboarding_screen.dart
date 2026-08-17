import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/constants.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/mentor_profile.dart';
import '../../providers/auth_provider.dart';

class MentorOnboardingScreen extends StatefulWidget {
  const MentorOnboardingScreen({super.key});

  @override
  State<MentorOnboardingScreen> createState() => _MentorOnboardingScreenState();
}

class _MentorOnboardingScreenState extends State<MentorOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _yearsController = TextEditingController(text: '5');
  final _portfolioController = TextEditingController();
  final _tagInputController = TextEditingController();

  String _gender = 'Prefer not to say';
  String _areaOfMentorship = AppConstants.availableMentorshipAreas.first;
  String _mentorshipStyle = AppConstants.mentorshipStyles.first;
  int _maxCapacity = 5;

  final List<String> _expertiseTags = ['Flutter', 'Mobile Dev'];
  final List<WorkHistoryEntry> _workHistory = [
    WorkHistoryEntry(role: 'Senior Engineer', company: 'Tech Corp', years: 4),
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    _portfolioController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagInputController.text.trim();
    if (text.isNotEmpty && !_expertiseTags.contains(text)) {
      setState(() {
        _expertiseTags.add(text);
        _tagInputController.clear();
      });
    }
  }

  void _addWorkHistory() {
    setState(() {
      _workHistory.add(WorkHistoryEntry(
          role: 'Software Developer', company: 'Acme Inc', years: 2));
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expertiseTags.isEmpty) {
      ToastOverlay.show(context, 'Please add at least one expertise tag',
          type: ToastType.error);
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseService.completeMentorOnboarding(
        userId: user.uid,
        username: _usernameController.text.trim(),
        gender: _gender,
        areaOfMentorship: _areaOfMentorship,
        yearsOfExperience: int.tryParse(_yearsController.text.trim()) ?? 0,
        portfolio: _portfolioController.text.trim().isEmpty
            ? null
            : _portfolioController.text.trim(),
        bio: _bioController.text.trim(),
        expertiseTags: _expertiseTags,
        workHistory: _workHistory,
        mentorshipStyle: _mentorshipStyle,
        maxCapacity: _maxCapacity,
      );

      await context.read<AuthProvider>().refreshProfile();
      if (mounted) {
        ToastOverlay.show(context, 'Onboarding complete! Welcome to Propel.',
            type: ToastType.success);
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
        title: const Text('Mentor Onboarding'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SizedBox(
              width: double.infinity,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Your Mentor Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help mentees discover your expertise and mentorship style.',
                      style: TextStyle(color: AppColors.slate500, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Username',
                            hintText: 'johndoe_mentor',
                            controller: _usernameController,
                            validator: AppValidators.validateUsername,
                          ),
                          const SizedBox(height: 16),
                          const Text('Gender',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            items: AppConstants.genderOptions
                                .map((g) =>
                                    DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) => setState(() => _gender = v!),
                            decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
                          ),
                          const SizedBox(height: 16),
                          const Text('Primary Area of Mentorship',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _areaOfMentorship,
                            items: AppConstants.availableMentorshipAreas
                                .map((a) =>
                                    DropdownMenuItem(value: a, child: Text(a)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _areaOfMentorship = v!),
                            decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Years of Experience',
                            hintText: '5',
                            controller: _yearsController,
                            keyboardType: TextInputType.number,
                            validator: (v) => AppValidators.validateRequired(
                                v, 'Years of experience'),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Portfolio URL (Optional)',
                            hintText: 'https://github.com/johndoe',
                            controller: _portfolioController,
                            validator: AppValidators.validateUrlOptional,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Bio',
                            hintText:
                                'Describe your professional background and passions...',
                            controller: _bioController,
                            maxLines: 4,
                            validator: (v) =>
                                AppValidators.validateMinLength(v, 20, 'Bio'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Expertise Tags',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _tagInputController,
                                  decoration: const InputDecoration(
                                      hintText:
                                          'Add a tag (e.g. React, System Design)'),
                                  onSubmitted: (_) => _addTag(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _addTag,
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                    backgroundColor: AppColors.brandGreen600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _expertiseTags
                                .map((tag) => Chip(
                                      label: Text(tag),
                                      deleteIcon:
                                          const Icon(Icons.close, size: 16),
                                      onDeleted: () => setState(
                                          () => _expertiseTags.remove(tag)),
                                      backgroundColor: AppColors.brandGreen100,
                                      labelStyle: const TextStyle(
                                          color: AppColors.brandGreen800,
                                          fontWeight: FontWeight.w600),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Work Experience',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              TextButton.icon(
                                onPressed: _addWorkHistory,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Experience'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _workHistory.length,
                            itemBuilder: (context, index) {
                              final w = _workHistory[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.slate700
                                      : AppColors.slate100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${w.role} at ${w.company} (${w.years} yrs)',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (_workHistory.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppColors.error, size: 20),
                                        onPressed: () => setState(
                                            () => _workHistory.removeAt(index)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mentorship Style',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _mentorshipStyle,
                            items: AppConstants.mentorshipStyles
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _mentorshipStyle = v!),
                            decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12)),
                          ),
                          const SizedBox(height: 16),
                          Text('Max Mentee Capacity: $_maxCapacity mentees',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          Slider(
                            value: _maxCapacity.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: '$_maxCapacity',
                            activeColor: AppColors.brandGreen600,
                            onChanged: (v) =>
                                setState(() => _maxCapacity = v.toInt()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      text: 'Complete Profile & Launch',
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
      ),
    );
  }
}
