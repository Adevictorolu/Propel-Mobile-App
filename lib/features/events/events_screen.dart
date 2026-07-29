import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/calendar_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
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
      final list = await SupabaseService.fetchEvents(user.id, role);
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
      await SupabaseService.rsvpToEvent(eventId, user.id, status);
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
    final currentUserId = authProvider.user?.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  Text('Events & Workshops', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Join group sessions, Q&As, and 1-on-1 mentorship calls', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                ],
              ),
              if (isMentor)
                AppButton(
                  text: 'Create Event',
                  icon: const Icon(Icons.add, size: 18),
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

          _isLoading
              ? const ShimmerLoading(width: double.infinity, height: 300)
              : _events.isEmpty
                  ? const AppCard(
                      child: Center(
                        child: Text('No upcoming events scheduled.'),
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
                              crossAxisAlignment: CrossAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandBlue100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.event, color: AppColors.brandBlue800, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAlignment.start,
                                        children: [
                                          Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                      tooltip: 'Export .ics Calendar File',
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
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.video_camera_front_outlined, size: 16, color: AppColors.brandBlue600),
                                      const SizedBox(width: 6),
                                      Text(event.zoomLink!, style: const TextStyle(fontSize: 13, color: AppColors.brandBlue600, decoration: TextDecoration.underline)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    const Text('RSVP Status: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    if (myRsvp != null)
                                      AppBadge(
                                        text: myRsvp.status.toUpperCase(),
                                        variant: myRsvp.status == 'going' ? AppBadgeVariant.green : AppBadgeVariant.yellow,
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
                                          child: const Text('Going', style: TextStyle(fontSize: 12)),
                                        ),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: myRsvp?.status == 'maybe' ? AppColors.brandBlue100 : null,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () => _rsvp(event.id, 'maybe'),
                                          child: const Text('Maybe', style: TextStyle(fontSize: 12)),
                                        ),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onPressed: () => _rsvp(event.id, 'declined'),
                                          child: const Text('Declined', style: TextStyle(fontSize: 12)),
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
}
