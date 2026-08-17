import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;
    final mentorProfile = authProvider.mentorProfile;
    final menteeProfile = authProvider.menteeProfile;
    final isMentor = profile?.role == 'mentor';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              AppButton(
                text: 'Edit Profile',
                icon: const Icon(Icons.edit_outlined, size: 16),
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.brandGreen600,
                  backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                  child: profile?.avatarUrl == null
                      ? Text(
                          profile?.firstName.isNotEmpty == true ? profile!.firstName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.fullName ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(profile?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
                      const SizedBox(height: 8),
                      AppBadge(
                        text: (profile?.role ?? 'mentee').toUpperCase(),
                        variant: isMentor ? AppBadgeVariant.green : AppBadgeVariant.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (isMentor && mentorProfile != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mentor Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Area of Mentorship: ${mentorProfile.areaOfMentorship}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Years of Experience: ${mentorProfile.yearsOfExperience} years'),
                  const SizedBox(height: 12),
                  const Text('Bio:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(mentorProfile.bio, style: const TextStyle(color: AppColors.slate600, height: 1.4)),
                  const SizedBox(height: 16),
                  const Text('Expertise Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mentorProfile.expertiseTags.map((tag) => AppBadge(text: tag, variant: AppBadgeVariant.green)).toList(),
                  ),
                ],
              ),
            ),
          ] else if (!isMentor && menteeProfile != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mentee Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Area of Interest: ${menteeProfile.areaOfInterest}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const Text('Bio:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(menteeProfile.bio, style: const TextStyle(color: AppColors.slate600, height: 1.4)),
                  const SizedBox(height: 12),
                  const Text('Aspirations:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(menteeProfile.aspirations, style: const TextStyle(color: AppColors.slate600, height: 1.4)),
                  const SizedBox(height: 16),
                  const Text('Desired Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: menteeProfile.desiredSkills.map((skill) => AppBadge(text: skill, variant: AppBadgeVariant.blue)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
