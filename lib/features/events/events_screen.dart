import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import 'create_event_modal.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isLoading = true;
  List<Event> _events = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final role = authProvider.role;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final list = await FirebaseService.fetchEvents(user.uid, role);
      setState(() => _events = list);
    } catch (e) {
      print('[EventsScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rsvp(String eventId, String status) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      await FirebaseService.rsvpToEvent(eventId, user.uid, status);
      await _loadEvents();
      ToastOverlay.show(context, 'RSVP updated to $status', type: ToastType.success);
    } catch (e) {
      ToastOverlay.show(context, e.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isMentor = authProvider.role == 'mentor';
    final currentUserId = authProvider.user?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Calendar & Scheduling', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Manage your 1-on-1 calls, workshops, and upcoming sessions', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                ],
              ),
              if (isMentor)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Schedule Call'),
                  onPressed: () async {
                    final res = await showDialog<bool>(
                      context: context,
                      builder: (_) => const CreateEventModal(),
                    );
                    if (res == true) _loadEvents();
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Selector Strip
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 7)));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() => _selectedDate = _selectedDate.add(const Duration(days: 7)));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    itemBuilder: (context, idx) {
                      final dayDate = DateTime.now().add(Duration(days: idx - 2));
                      final isSelected = dayDate.day == _selectedDate.day && dayDate.month == _selectedDate.month;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = dayDate),
                        child: Container(
                          width: 52,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.brandGreen600 : AppColors.slate100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weekDayAbbr(dayDate.weekday),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : AppColors.slate500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dayDate.day}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isSelected ? Colors.white : AppColors.slate800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Events & Sessions List
          _isLoading
              ? const ShimmerLoading(width: double.infinity, height: 300)
              : _events.isEmpty
                  ? const AppCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No mentorship sessions scheduled for this period.'),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        final myRsvp = event.rsvps.where((r) => r.userId == currentUserId).firstOrNull;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandGreen100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.video_call, color: AppColors.brandGreen800, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(event.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Text(
                                            AppFormatters.formatDateTime(event.eventDate),
                                            style: const TextStyle(fontSize: 13, color: AppColors.slate500, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.calendar_month_outlined, color: AppColors.brandGreen600),
                                      tooltip: 'Download .ics for Google/Apple Calendar',
                                      onPressed: () => CalendarService.generateAndDownloadICS(
                                        title: event.title,
                                        description: event.description,
                                        eventDateStr: event.eventDate,
                                        zoomLink: event.zoomLink,
                                      ),
                                    ),
                                  ],
                                ),
                                if (event.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(event.description, style: const TextStyle(fontSize: 14, height: 1.4)),
                                ],
                                if (event.zoomLink != null && event.zoomLink!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandBlue50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.brandBlue200),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.video_camera_front, size: 18, color: AppColors.brandBlue600),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            event.zoomLink!,
                                            style: const TextStyle(fontSize: 13, color: AppColors.brandBlue600, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    AppBadge(
                                      text: (myRsvp?.status ?? 'Confirmed').toUpperCase(),
                                      variant: (myRsvp?.status == 'going' || myRsvp == null) ? AppBadgeVariant.green : AppBadgeVariant.yellow,
                                    ),
                                    const Spacer(),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: myRsvp?.status == 'going' ? AppColors.brandGreen100 : null,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () => _rsvp(event.id, 'going'),
                                          child: const Text('Attending', style: TextStyle(fontSize: 12)),
                                        ),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () => _rsvp(event.id, 'declined'),
                                          child: const Text('Reschedule', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _weekDayAbbr(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }
}
