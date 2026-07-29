import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/connection.dart';
import '../../models/curriculum.dart';
import '../../providers/auth_provider.dart';
import 'add_goal_modal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _isLoading = true;
  List<Connection> _connections = [];
  Connection? _selectedConnection;
  Curriculum? _curriculum;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final role = authProvider.role;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final conns = await SupabaseService.fetchConnections(user.id, role);
      final activeConns = conns.where((c) => c.status == 'active').toList();
      setState(() {
        _connections = activeConns;
        if (activeConns.isNotEmpty) {
          _selectedConnection = activeConns.first;
        }
      });
      if (_selectedConnection != null) {
        await _loadCurriculum(_selectedConnection!.id);
      }
    } catch (e) {
      print('[GoalsScreen] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCurriculum(String connectionId) async {
    try {
      var curr = await SupabaseService.fetchCurriculum(connectionId);
      if (curr == null) {
        curr = await SupabaseService.createCurriculum(connectionId);
      }
      setState(() => _curriculum = curr);
    } catch (e) {
      print('[GoalsScreen] Load curriculum error: $e');
    }
  }

  Future<void> _addGoal(String title, String targetDate) async {
    if (_curriculum == null) return;
    try {
      final updated = await SupabaseService.addGoalToCurriculum(
        _curriculum!.id,
        _curriculum!.goals,
        title,
        targetDate,
      );
      setState(() => _curriculum = updated);
      ToastOverlay.show(context, 'Goal added successfully!', type: ToastType.success);
    } catch (e) {
      ToastOverlay.show(context, e.toString(), type: ToastType.error);
    }
  }

  Future<void> _addMilestone(String goalId, String title) async {
    if (_curriculum == null) return;
    try {
      final updated = await SupabaseService.addMilestone(
        _curriculum!.id,
        _curriculum!.milestones,
        goalId,
        title,
      );
      setState(() => _curriculum = updated);
    } catch (e) {
      ToastOverlay.show(context, e.toString(), type: ToastType.error);
    }
  }

  Future<void> _toggleMilestone(String milestoneId) async {
    if (_curriculum == null) return;
    try {
      final updated = await SupabaseService.toggleMilestone(
        _curriculum!.id,
        _curriculum!.milestones,
        milestoneId,
      );
      setState(() => _curriculum = updated);
    } catch (e) {
      ToastOverlay.show(context, e.toString(), type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMentor = context.watch<AuthProvider>().role == 'mentor';

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
                  Text('Goals & Curriculum', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Track structured mentorship roadmap and milestones', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                ],
              ),
              if (_selectedConnection != null)
                AppButton(
                  text: 'Add Goal',
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddGoalModal(onSubmit: _addGoal),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (_connections.isNotEmpty) ...[
            const Text('Select Mentorship Connection:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Connection>(
              value: _selectedConnection,
              isExpanded: true,
              items: _connections.map((c) {
                final partner = isMentor ? c.mentee : c.mentor;
                return DropdownMenuItem(
                  value: c,
                  child: Text('Connection with ${partner?.fullName ?? "User"}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedConnection = val);
                  _loadCurriculum(val.id);
                }
              },
            ),
            const SizedBox(height: 24),
          ],

          _isLoading
              ? const ShimmerLoading(width: double.infinity, height: 300)
              : _connections.isEmpty
                  ? const AppCard(
                      child: Center(
                        child: Text('No active connections found. Connect with a mentor to start your curriculum.'),
                      ),
                    )
                  : _curriculum == null || _curriculum!.goals.isEmpty
                      ? AppCard(
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.track_changes, size: 40, color: AppColors.slate400),
                                const SizedBox(height: 12),
                                const Text('No curriculum goals yet', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Click "Add Goal" above to create your first learning milestone.', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _curriculum!.goals.length,
                          itemBuilder: (context, index) {
                            final goal = _curriculum!.goals[index];
                            final goalMilestones = _curriculum!.milestones.where((m) => m.goalId == goal.id).toList();
                            final completedCount = goalMilestones.where((m) => m.completed).length;
                            final progressRatio = goalMilestones.isEmpty ? 0.0 : completedCount / goalMilestones.length;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            goal.title,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        AppBadge(
                                          text: goal.status.replaceAll('_', ' ').toUpperCase(),
                                          variant: goal.status == 'completed' ? AppBadgeVariant.green : AppBadgeVariant.blue,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Target Date: ${goal.targetDate}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                                    const SizedBox(height: 12),

                                    LinearProgressIndicator(
                                      value: progressRatio,
                                      backgroundColor: isDark ? AppColors.slate700 : AppColors.slate200,
                                      color: AppColors.brandGreen600,
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    const SizedBox(height: 16),

                                    const Text('Milestones', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    ...goalMilestones.map((m) => CheckboxListTile(
                                      value: m.completed,
                                      title: Text(
                                        m.title,
                                        style: TextStyle(
                                          decoration: m.completed ? TextDecoration.lineThrough : null,
                                          color: m.completed ? AppColors.slate400 : null,
                                        ),
                                      ),
                                      activeColor: AppColors.brandGreen600,
                                      onChanged: (_) => _toggleMilestone(m.id),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    )),

                                    const SizedBox(height: 8),
                                    _AddMilestoneField(
                                      onAdd: (title) => _addMilestone(goal.id, title),
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

class _AddMilestoneField extends StatefulWidget {
  final void Function(String title) onAdd;

  const _AddMilestoneField({required this.onAdd});

  @override
  State<_AddMilestoneField> createState() => _AddMilestoneFieldState();
}

class _AddMilestoneFieldState extends State<_AddMilestoneField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Add a new milestone step...',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                widget.onAdd(val.trim());
                _controller.clear();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.add_circle, color: AppColors.brandGreen600),
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onAdd(_controller.text.trim());
              _controller.clear();
            }
          },
        ),
      ],
    );
  }
}
