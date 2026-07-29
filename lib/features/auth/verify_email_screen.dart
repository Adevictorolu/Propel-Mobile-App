import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/widgets/app_button.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.brandBlue100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.brandBlue800,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verify your email',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please check your email inbox and click the verification link to activate your Propel account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.slate500, height: 1.4),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Back to Sign In',
          isFullWidth: true,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
