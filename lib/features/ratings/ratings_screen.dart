import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/star_rating.dart';
import '../../models/rating.dart';
import '../../providers/auth_provider.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Rating> _reviewsAboutMe = [];
  List<Rating> _myReviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRatings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRatings() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final aboutMe = await SupabaseService.fetchReviewsAboutMe(user.id);
      final myRevs = await SupabaseService.fetchMyReviews(user.id);
      setState(() {
        _reviewsAboutMe = aboutMe;
        _myReviews = myRevs;
      });
    } catch (e) {
      print('[RatingsScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _avgRatingAboutMe {
    if (_reviewsAboutMe.isEmpty) return 0.0;
    final total = _reviewsAboutMe.map((r) => r.score).reduce((a, b) => a + b);
    return total / _reviewsAboutMe.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          const Text('Ratings & Reviews', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Feedback and testimonials from your mentorship connections', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
          const SizedBox(height: 24),

          AppCard(
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Text(
                      _avgRatingAboutMe.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.extrabold, color: AppColors.brandGreen600),
                    ),
                    StarRating(rating: _avgRatingAboutMe, iconSize: 20),
                    const SizedBox(height: 4),
                    Text('Based on ${_reviewsAboutMe.length} reviews', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          TabBar(
            controller: _tabController,
            labelColor: isDark ? AppColors.brandGreen400 : AppColors.brandGreen600,
            indicatorColor: AppColors.brandGreen600,
            tabs: [
              Tab(text: 'Reviews About Me (${_reviewsAboutMe.length})'),
              Tab(text: 'Reviews I Have Written (${_myReviews.length})'),
            ],
          ),
          const SizedBox(height: 16),

          _isLoading
              ? const ShimmerLoading(width: double.infinity, height: 250)
              : SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReviewList(_reviewsAboutMe, isAboutMe: true),
                      _buildReviewList(_myReviews, isAboutMe: false),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<Rating> list, {required bool isAboutMe}) {
    if (list.isEmpty) {
      return const AppCard(
        child: Center(
          child: Text('No reviews found in this category.'),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        final person = isAboutMe ? r.reviewer : r.reviewee;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.brandBlue600,
                      backgroundImage: person?.avatarUrl != null ? NetworkImage(person!.avatarUrl!) : null,
                      child: person?.avatarUrl == null
                          ? Text(person?.firstName.isNotEmpty == true ? person!.firstName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(person?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    StarRating(rating: r.score, iconSize: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r.comment, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 6),
                Text(AppFormatters.formatDate(r.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
              ],
            ),
          ),
        );
      },
    );
  }
}
