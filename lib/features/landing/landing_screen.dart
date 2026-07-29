import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandGreen600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'PROPEL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AppButton(
              text: 'Get Started',
              onPressed: () => context.go('/signup'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.brandGreen800, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'AI-Powered Mentorship Matching Engine',
                          style: TextStyle(
                            color: AppColors.brandGreen800,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Elevate Your Career with 1-on-1 Mentorship',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.extrabold,
                      color: isDark ? Colors.white : AppColors.slate900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connect with industry leaders, unlock personalized learning goals, track structured growth, and reach your highest potential.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      AppButton(
                        text: 'Find a Mentor',
                        icon: const Icon(Icons.search, size: 18),
                        onPressed: () => context.go('/signup'),
                      ),
                      AppButton(
                        text: 'Become a Mentor',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context.go('/signup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // STATS BAR
            Container(
              color: isDark ? AppColors.slate800 : AppColors.brandBlue50,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('98%', 'Satisfaction Rate'),
                  _buildStat('5,000+', 'Active Mentors'),
                  _buildStat('12,000+', 'Goals Completed'),
                ],
              ),
            ),

            // FEATURES GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                children: [
                  Text(
                    'Everything You Need to Succeed',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 650;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isMobile ? 1 : 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: isMobile ? 2.5 : 1.1,
                        children: const [
                          _FeatureCard(
                            icon: Icons.psychology,
                            title: 'Smart Matching',
                            desc: 'Algorithmic scoring matches you based on skills, aspirations, and communication style.',
                          ),
                          _FeatureCard(
                            icon: Icons.track_changes,
                            title: 'Curriculum Goals',
                            desc: 'Set structured milestones, track progress, and celebrate accomplishments together.',
                          ),
                          _FeatureCard(
                            icon: Icons.chat_bubble_outline,
                            title: 'Real-time Chat',
                            desc: 'Direct messaging and group discussions with instant notifications and file sharing.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // FOOTER
            Container(
              color: AppColors.slate900,
              padding: const EdgeInsets.all(32),
              child: const Center(
                child: Text(
                  '© 2026 Propel Mentorship. All rights reserved.',
                  style: TextStyle(color: AppColors.slate400, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.brandBlue600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.slate600,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandGreen100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brandGreen800, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(fontSize: 13, color: AppColors.slate500, height: 1.4),
          ),
        ],
      ),
    );
  }
}
