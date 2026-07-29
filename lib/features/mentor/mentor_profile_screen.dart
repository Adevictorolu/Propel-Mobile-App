import 'package:flutter/material.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/star_rating.dart';
import '../../models/mentor_profile.dart';
import 'connection_request_modal.dart';

class MentorProfileScreen extends StatefulWidget {
  final String mentorId;

  const MentorProfileScreen({super.key, required this.mentorId});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _mentorData;

  @override
  void initState() {
    super.initState();
    _loadMentor();
  }

  Future<void> _loadMentor() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.fetchMentorById(widget.mentorId);
      setState(() => _mentorData = data);
    } catch (e) {
      print('[MentorProfileScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRequestModal() {
    if (_mentorData == null) return;
    showDialog(
      context: context,
      builder: (_) => ConnectionRequestModal(
        mentorId: widget.mentorId,
        mentorName: _mentorData!['full_name'] as String? ?? 'Mentor',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: ShimmerLoading(width: 400, height: 300)));
    }

    if (_mentorData == null) {
      return const Scaffold(body: Center(child: Text('Mentor not found.')));
    }

    final m = _mentorData!;
    final mpRaw = (m['mentor_profiles'] as List<dynamic>).first as Map<String, dynamic>;
    final mp = MentorProfile.fromJson(mpRaw);
    final ratings = (m['ratings'] as List<dynamic>? ?? []);

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
                    backgroundColor: AppColors.brandGreen600,
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
                        Text(mp.areaOfMentorship, style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StarRating(rating: (m['avg_rating'] as num).toDouble()),
                            const SizedBox(width: 8),
                            Text('${m['avg_rating']} (${m['review_count']} reviews)', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    text: 'Request Mentorship',
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    onPressed: mp.isAtCapacity ? null : _openRequestModal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  const Text('About Mentor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(mp.bio, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.slate700)),
                  const SizedBox(height: 20),
                  const Text('Expertise Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mp.expertiseTags.map((tag) => AppBadge(text: tag, variant: AppBadgeVariant.green)).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  const Text('Work History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...mp.workHistory.map((w) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.work_outline, color: AppColors.brandBlue600),
                    title: Text('${w.role} at ${w.company}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${w.years} years experience'),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Text('Reviews (${ratings.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ratings.isEmpty
                      ? const Text('No reviews yet for this mentor.', style: TextStyle(color: AppColors.slate400))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ratings.length,
                          separatorBuilder: (_, __) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final r = ratings[index];
                            final rev = r['reviewer'] as Map<String, dynamic>?;
                            return Column(
                              crossAxisAlignment: CrossAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.brandBlue600,
                                      child: Text(rev != null ? (rev['full_name'] as String)[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(rev?['full_name'] as String? ?? 'Reviewer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const Spacer(),
                                    StarRating(rating: (r['score'] as num).toDouble(), iconSize: 14),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(r['comment'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.slate600)),
                              ],
                            );
                          },
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
