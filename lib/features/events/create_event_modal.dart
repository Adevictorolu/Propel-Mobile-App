import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../providers/auth_provider.dart';

class CreateEventModal extends StatefulWidget {
  const CreateEventModal({super.key});

  @override
  State<CreateEventModal> createState() => _CreateEventModalState();
}

class _CreateEventModalState extends State<CreateEventModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 16),
  );
  final _zoomLinkController = TextEditingController();

  final String _inviteType = 'group';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _zoomLinkController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final mentorId = context.read<AuthProvider>().user?.uid;
    if (mentorId == null) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.createEvent(
        mentorId: mentorId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        eventDate: _dateController.text.trim(),
        inviteType: _inviteType,
        zoomLink: _zoomLinkController.text.trim().isEmpty
            ? null
            : _zoomLinkController.text.trim(),
      );
      if (mounted) {
        ToastOverlay.show(context, 'Event created successfully!',
            type: ToastType.success);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(context, e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Mentorship Event'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Event Title',
                hintText: 'Weekly Q&A Workshop',
                controller: _titleController,
                validator: (v) => AppValidators.validateRequired(v, 'Title'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Description',
                hintText: 'What will be discussed during this session...',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Event Date & Time (YYYY-MM-DDTHH:mm)',
                hintText: '2026-08-01T14:00',
                controller: _dateController,
                validator: (v) =>
                    AppValidators.validateRequired(v, 'Event date'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Zoom / Meeting Link (Optional)',
                hintText: 'https://zoom.us/j/123456',
                controller: _zoomLinkController,
                validator: AppValidators.validateUrlOptional,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: 'Create Event',
          isLoading: _isLoading,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }
}
