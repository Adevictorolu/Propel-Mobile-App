import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../models/connection.dart';
import '../../models/match_result.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Connection> _connections = [];
  List<MatchResult> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final profile = authProvider.profile;

    if (user == null || profile == null) return;

    setState(() => _isLoading = true);

    try {
      if (profile.role == 'mentor') {
        final stats = await SupabaseService.fetchMentorDashboardStats(user.id);
        final conns = await SupabaseService.fetchConnections(user.id, 'mentor');
        setState(() {
          _stats = stats;
          _connections = conns;
        });
      } else {
        final stats = await SupabaseService.fetchMenteeDashboardStats(user.id);
        final conns = await SupabaseService.fetchConnections(user.id, 'mentee');
        List<MatchResult> recs = [];
        if (authProvider.menteeProfile != null) {
          recs = await SupabaseService.fetchRecommendedMentors(authProvider.menteeProfile!);
        }
        setState(() {
          _stats = stats;
          _connections = conns;
          _recommendations = recs;
        });
      }
    } catch (e) {
      print('[DashboardScreen] Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMentor = profile?.role == 'mentor';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.slate800, AppColors.slate700]
                    : [AppColors.brandGreen600, AppColors.brandBlue600],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${profile?.firstName ?? 'User'}! 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isMentor
                            ? 'Here is an overview of your active mentees and upcoming sessions.'
                            : 'Track your learning goals and discover top mentor recommendations.',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.slate900,
                  ),
                  onPressed: () => context.go('/explore'),
                  child: Text(isMentor ? 'View Mentees' : 'Find Mentors'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _isLoading
              ? Row(
                  children: List.generate(
                    3,
                    (_) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: ShimmerLoading(width: double.infinity, height: 100),
                      ),
                    ),
                  ),
                )
              : Row(
                  children: isMentor
                      ? [
                          _buildStatCard('Active Mentees', '${_stats['activeCount'] ?? 0}', Icons.people_outline, AppColors.brandGreen600),
                          const SizedBox(width: 12),
                          _buildStatCard('Pending Requests', '${_stats['pendingCount'] ?? 0}', Icons.pending_actions, AppColors.warning),
                          const SizedBox(width: 12),
                          _buildStatCard('Upcoming Events', '${_stats['upcomingEvents'] ?? 0}', Icons.calendar_today_outlined, AppColors.brandBlue600),
                        ]
                      : [
                          _buildStatCard('Active Mentors', '${_stats['activeMentors'] ?? 0}', Icons.school_outlined, AppColors.brandBlue600),
                          const SizedBox(width: 12),
                          _buildStatCard('Goals In Progress', '${_stats['goalsInProgress'] ?? 0}', Icons.track_changes, AppColors.brandGreen600),
                          const SizedBox(width: 12),
                          _buildStatCard('Growth Score', '${_stats['growthScore'] ?? 0}%', Icons.auto_graph, AppColors.brandBlue600),
                        ],
                ),
          const SizedBox(height: 32),

          Text(
            isMentor ? 'My Active Mentees' : 'My Active Mentors',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const ShimmerLoading(width: double.infinity, height: 150)
              : _connections.isEmpty
                  ? AppCard(
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.people_outline, size: 40, color: AppColors.slate400),
                            const SizedBox(height: 12),
                            Text(
                              isMentor ? 'No active mentees yet' : 'No active mentors yet',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isMentor ? 'Accept connection requests to begin mentoring.' : 'Explore mentors to send a connection request.',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _connections.length,
                      itemBuilder: (context, index) {
                        final c = _connections[index];
                        final partner = isMentor ? c.mentee : c.mentor;
                        return AppCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.brandBlue600,
                                backgroundImage: partner?.avatarUrl != null ? NetworkImage(partner!.avatarUrl!) : null,
                                child: partner?.avatarUrl == null
                                    ? Text(
                                        partner?.firstName.isNotEmpty == true ? partner!.firstName[0].toUpperCase() : 'U',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAlignment.start,
                                  children: [
                                    Text(
                                      partner?.fullName ?? 'User',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    AppBadge(
                                      text: c.status.toUpperCase(),
                                      variant: c.status == 'active' ? AppBadgeVariant.green : AppBadgeVariant.yellow,
                                    ),
                                  ],
                                ),
                              ),
                              AppButton(
                                text: 'Chat',
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                onPressed: () => context.go('/messages'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

          if (!isMentor && _recommendations.isNotEmpty) ...[
            const SizedBox(height: 36),
            const Text(
              'Recommended Mentors For You',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final rec = _recommendations[index];
                return AppCard(
                  onTap: () => context.go('/mentor/${rec.mentorId}'),
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.brandGreen600,
                            backgroundImage: rec.profile.avatarUrl != null ? NetworkImage(rec.profile.avatarUrl!) : null,
                            child: rec.profile.avatarUrl == null
                                ? Text(rec.profile.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rec.profile.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppBadge(
                        text: '${(rec.totalScore * 100).round()}% Match',
                        variant: AppBadgeVariant.green,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec.mentorProfile.bio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                      const Spacer(),
                      AppButton(
                        text: 'View Profile',
                        isFullWidth: true,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => context.go('/mentor/${rec.mentorId}'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
