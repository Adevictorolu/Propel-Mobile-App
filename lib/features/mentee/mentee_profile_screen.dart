import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../models/mentee_profile.dart';

class MenteeProfileScreen extends ConsumerStatefulWidget {
  final String menteeId;

  const MenteeProfileScreen({super.key, required this.menteeId});

  @override
  ConsumerState<MenteeProfileScreen> createState() => _MenteeProfileScreenState();
}

class _MenteeProfileScreenState extends ConsumerState<MenteeProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _menteeData;

  @override
  void initState() {
    super.initState();
    _loadMentee();
  }

  Future<void> _loadMentee() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.fetchMenteeById(widget.menteeId);
      setState(() => _menteeData = data);
    } catch (e) {
      print('[MenteeProfileScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: ShimmerLoading(width: 400, height: 300)));
    }

    if (_menteeData == null) {
      return const Scaffold(body: Center(child: Text('Mentee profile not found.')));
    }

    final m = _menteeData!;
    final meProfRaw = (m['mentee_profiles'] as List<dynamic>).first as Map<String, dynamic>;
    final me = MenteeProfile.fromJson(meProfRaw);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.brandBlue600,
                    backgroundImage: m['avatar_url'] != null ? NetworkImage(m['avatar_url'] as String) : null,
                    child: m['avatar_url'] == null
                        ? Text(
                            (m['full_name'] as String)[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Text(m['full_name'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Area of Interest: ${me.areaOfInterest}', style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  const Text('About Mentee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(me.bio, style: const TextStyle(fontSize: 14, height: 1.5)),
                  const SizedBox(height: 16),
                  const Text('Aspirations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(me.aspirations, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.slate600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  const Text('Learning Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...me.learningGoals.map((goal) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline, color: AppColors.brandGreen600),
                    title: Text(goal),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  const Text('Desired Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: me.desiredSkills.map((skill) => AppBadge(text: skill, variant: AppBadgeVariant.blue)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
