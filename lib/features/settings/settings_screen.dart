import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/constants.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _calendlyController;
  late TextEditingController _bioController;

  String _gender = 'Prefer not to say';
  bool _isLoading = false;

  bool _inAppConnections = true;
  bool _inAppMessages = true;
  bool _inAppEvents = true;
  bool _inAppReviews = true;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.profile;
    final mentorProfile = authProvider.mentorProfile;
    final menteeProfile = authProvider.menteeProfile;

    _firstNameController =
        TextEditingController(text: profile?.firstName ?? '');
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _calendlyController =
        TextEditingController(text: profile?.calendlyUrl ?? '');
    _bioController = TextEditingController(
        text: mentorProfile?.bio ?? menteeProfile?.bio ?? '');
    _gender = profile?.gender ?? 'Prefer not to say';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _calendlyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final profile = authProvider.profile;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseService.db.collection('profiles').doc(user.uid).set({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'full_name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                .trim(),
        'username': _usernameController.text.trim(),
        'gender': _gender,
        'calendly_url': _calendlyController.text.trim().isEmpty
            ? null
            : _calendlyController.text.trim(),
      }, SetOptions(merge: true));

      if (profile?.role == 'mentor') {
        await FirebaseService.db.collection('mentor_profiles').doc(user.uid).set({
          'bio': _bioController.text.trim(),
        }, SetOptions(merge: true));
      } else {
        await FirebaseService.db.collection('mentee_profiles').doc(user.uid).set({
          'bio': _bioController.text.trim(),
        }, SetOptions(merge: true));
      }

      await context.read<AuthProvider>().refreshProfile();
      if (mounted) {
        ToastOverlay.show(context, 'Settings saved successfully!',
            type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account',
              style: TextStyle(color: AppColors.error)),
          content: const Text(
            'Are you sure you want to delete your account? All your data and active connections will be permanently removed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: 'Delete Permanently',
              variant: AppButtonVariant.danger,
              onPressed: () async {
                Navigator.pop(context);
                final uid = context.read<AuthProvider>().user?.uid;
                if (uid != null) {
                  await FirebaseService.db
                      .collection('profiles')
                      .doc(uid)
                      .delete();
                  if (mounted) {
                    await context.read<AuthProvider>().logout();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Manage profile information and notification preferences',
              style: TextStyle(color: AppColors.slate500, fontSize: 13)),
          const SizedBox(height: 24),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'First Name',
                          controller: _firstNameController,
                          validator: (v) =>
                              AppValidators.validateRequired(v, 'First name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          validator: (v) =>
                              AppValidators.validateRequired(v, 'Last name'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Username',
                    controller: _usernameController,
                    validator: AppValidators.validateUsername,
                  ),
                  const SizedBox(height: 14),
                  const Text('Gender',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: AppConstants.genderOptions.contains(_gender)
                        ? _gender
                        : AppConstants.genderOptions.first,
                    items: AppConstants.genderOptions
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gender = v!),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Calendly URL (Optional)',
                    controller: _calendlyController,
                    validator: AppValidators.validateUrlOptional,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Bio',
                    controller: _bioController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _handleSaveProfile,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notification Preferences',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Connection Requests'),
                  subtitle: const Text(
                      'Get notified when someone requests to connect'),
                  value: _inAppConnections,
                  activeThumbColor: AppColors.brandGreen600,
                  onChanged: (v) => setState(() => _inAppConnections = v),
                ),
                SwitchListTile(
                  title: const Text('Chat Messages'),
                  subtitle: const Text(
                      'Get notified when you receive a new DM or group message'),
                  value: _inAppMessages,
                  activeThumbColor: AppColors.brandGreen600,
                  onChanged: (v) => setState(() => _inAppMessages = v),
                ),
                SwitchListTile(
                  title: const Text('Event Reminders'),
                  subtitle: const Text(
                      'Get notified for upcoming workshops and sessions'),
                  value: _inAppEvents,
                  activeThumbColor: AppColors.brandGreen600,
                  onChanged: (v) => setState(() => _inAppEvents = v),
                ),
                SwitchListTile(
                  title: const Text('Reviews & Ratings'),
                  subtitle: const Text(
                      'Get notified when a connection leaves a review'),
                  value: _inAppReviews,
                  activeThumbColor: AppColors.brandGreen600,
                  onChanged: (v) => setState(() => _inAppReviews = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Danger Zone',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error)),
                const SizedBox(height: 8),
                const Text(
                    'Permanently delete your account and all associated mentorship data.',
                    style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Delete Account',
                  variant: AppButtonVariant.danger,
                  onPressed: _confirmDeleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
