import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/constants.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/star_rating.dart';
import '../../models/mentor_profile.dart';

class ExploreMentorsScreen extends StatefulWidget {
  const ExploreMentorsScreen({super.key});

  @override
  State<ExploreMentorsScreen> createState() => _ExploreMentorsScreenState();
}

class _ExploreMentorsScreenState extends State<ExploreMentorsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  bool _availableOnly = false;
  String? _selectedArea;
  List<Map<String, dynamic>> _mentors = [];

  @override
  void initState() {
    super.initState();
    _fetchMentors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMentors() async {
    setState(() => _isLoading = true);
    try {
      final results = await SupabaseService.fetchMentors(
        search: _searchController.text.trim(),
        tags: _selectedArea != null ? [_selectedArea!] : null,
        availableOnly: _availableOnly,
      );
      setState(() => _mentors = results);
    } catch (e) {
      print('[ExploreMentorsScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          const Text(
            'Explore Mentors',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Discover world-class mentors ready to guide your growth',
            style: TextStyle(color: AppColors.slate500, fontSize: 14),
          ),
          const SizedBox(height: 24),

          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _fetchMentors(),
                        decoration: InputDecoration(
                          hintText: 'Search by mentor name, company, or keyword...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: AppColors.brandGreen600),
                            onPressed: _fetchMentors,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Available Slots Only'),
                      selected: _availableOnly,
                      onSelected: (val) {
                        setState(() => _availableOnly = val);
                        _fetchMentors();
                      },
                      selectedColor: AppColors.brandGreen100,
                      checkmarkColor: AppColors.brandGreen800,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedArea,
                        hint: const Text('Filter by Area'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('All Areas')),
                          ...AppConstants.availableMentorshipAreas.map(
                            (a) => DropdownMenuItem(value: a, child: Text(a)),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedArea = val);
                          _fetchMentors();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _isLoading
              ? const ShimmerLoading(width: double.infinity, height: 300)
              : _mentors.isEmpty
                  ? const AppCard(
                      child: Center(
                        child: Text('No mentors found matching your filter criteria.'),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: _mentors.length,
                      itemBuilder: (context, index) {
                        final m = _mentors[index];
                        final mProfRaw = (m['mentor_profiles'] as List<dynamic>).first as Map<String, dynamic>;
                        final mp = MentorProfile.fromJson(mProfRaw);

                        return AppCard(
                          onTap: () => context.go('/mentor/${m['id']}'),
                          child: Column(
                            crossAxisAlignment: CrossAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppColors.brandGreen600,
                                    backgroundImage: m['avatar_url'] != null ? NetworkImage(m['avatar_url'] as String) : null,
                                    child: m['avatar_url'] == null
                                        ? Text(
                                            (m['full_name'] as String? ?? 'M')[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAlignment.start,
                                      children: [
                                        Text(
                                          m['full_name'] as String? ?? 'Mentor',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          mp.areaOfMentorship,
                                          style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                        ),
                                        const SizedBox(height: 4),
                                        StarRating(rating: (m['avg_rating'] as num?)?.toDouble() ?? 0.0),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                mp.bio,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: mp.expertiseTags.take(3).map((tag) => AppBadge(text: tag, variant: AppBadgeVariant.slate)).toList(),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${mp.currentCount}/${mp.maxCapacity} slots filled',
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                  ),
                                  AppButton(
                                    text: 'View Profile',
                                    onPressed: () => context.go('/mentor/${m['id']}'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
