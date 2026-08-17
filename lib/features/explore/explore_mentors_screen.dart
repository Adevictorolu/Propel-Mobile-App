import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/mentor_profile.dart';
import '../../providers/auth_provider.dart';

class ExploreMentorsScreen extends StatefulWidget {
  const ExploreMentorsScreen({super.key});

  @override
  State<ExploreMentorsScreen> createState() => _ExploreMentorsScreenState();
}

class _ExploreMentorsScreenState extends State<ExploreMentorsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  bool _availableOnly = false;
  String? _selectedCategory;
  List<Map<String, dynamic>> _mentors = [];

  final List<String> _categories = [
    'All',
    'Growth',
    'Product',
    'Marketing',
    'Engineering',
    'Design',
    'Leadership',
  ];

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
      final tagFilter = (_selectedCategory != null && _selectedCategory != 'All')
          ? [_selectedCategory!]
          : null;

      final results = await FirebaseService.fetchMentors(
        search: _searchController.text.trim(),
        tags: tagFilter,
        availableOnly: _availableOnly,
      );
      setState(() => _mentors = results);
    } catch (e) {
      print('[ExploreMentorsScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBookingModal(BuildContext context, Map<String, dynamic> mentor, MentorProfile mp) {
    final name = mentor['full_name'] as String? ?? 'Mentor';
    final currentUserId = context.read<AuthProvider>().user?.uid;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.brandGreen600,
                        backgroundImage: mentor['avatar_url'] != null ? NetworkImage(mentor['avatar_url'] as String) : null,
                        child: mentor['avatar_url'] == null ? Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Book 1-on-1 Call with $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(mp.areaOfMentorship, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Date & Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 60)),
                            );
                            if (picked != null) setModalState(() => selectedDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(selectedTime.format(context)),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) setModalState(() => selectedTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('What would you like advice on?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your key questions or challenges for this session...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Confirm Session'),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          final sessionDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          if (currentUserId != null) {
                            try {
                              await FirebaseService.createEvent(
                                mentorId: mentor['id'] as String,
                                title: '1-on-1 Call with $name',
                                description: noteController.text.trim().isEmpty ? 'Mentorship session' : noteController.text.trim(),
                                eventDate: sessionDateTime.toIso8601String(),
                                inviteType: 'one_on_one',
                                inviteeId: currentUserId,
                                zoomLink: 'https://meet.jit.si/propel-${DateTime.now().millisecondsSinceEpoch}',
                              );
                            } catch (_) {}
                          }

                          ToastOverlay.show(
                            context,
                            'Session request sent to $name!',
                            type: ToastType.success,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
          const Text(
            'Find Your Growth Mentor',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Book 1-on-1 mentorship calls with experienced founders & operators',
            style: TextStyle(color: AppColors.slate500, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Search & Filter Box
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchMentors(),
                  decoration: InputDecoration(
                    hintText: 'Search by mentor name, company, or skills...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.brandGreen600),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: AppColors.brandGreen600),
                      onPressed: _fetchMentors,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // GrowthMentor Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = (_selectedCategory == cat) || (_selectedCategory == null && cat == 'All');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() => _selectedCategory = val ? cat : 'All');
                            _fetchMentors();
                          },
                          selectedColor: AppColors.brandGreen600,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.slate700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Available Sessions Only'),
                      selected: _availableOnly,
                      onSelected: (val) {
                        setState(() => _availableOnly = val);
                        _fetchMentors();
                      },
                      selectedColor: AppColors.brandGreen100,
                      checkmarkColor: AppColors.brandGreen800,
                    ),
                    const Spacer(),
                    Text(
                      '${_mentors.length} mentors found',
                      style: const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w500),
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
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No mentors found matching your criteria. Try adjusting your search query.'),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 390,
                        childAspectRatio: 0.76,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 6),
                                        StarRating(rating: (m['avg_rating'] as num?)?.toDouble() ?? 4.9),
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
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.bolt, color: AppColors.brandGreen600, size: 16),
                                      SizedBox(width: 4),
                                      Text('Available', style: TextStyle(fontSize: 12, color: AppColors.brandGreen800, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandGreen600,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                    onPressed: () => _showBookingModal(context, m, mp),
                                    child: const Text('Book 1-on-1', style: TextStyle(fontSize: 12)),
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
