import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../providers/auth_provider.dart';

class ConnectionRequestModal extends StatefulWidget {
  final String mentorId;
  final String mentorName;

  const ConnectionRequestModal({
    super.key,
    required this.mentorId,
    required this.mentorName,
  });

  @override
  State<ConnectionRequestModal> createState() => _ConnectionRequestModalState();
}

class _ConnectionRequestModalState extends State<ConnectionRequestModal> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final menteeId = context.read<AuthProvider>().user?.uid;
    if (menteeId == null) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.sendConnectionRequest(
        mentorId: widget.mentorId,
        menteeId: menteeId,
        requestMessage: _messageController.text.trim(),
      );
      if (mounted) {
        ToastOverlay.show(context, 'Connection request sent successfully!', type: ToastType.success);
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
      title: Text('Request Mentorship from ${widget.mentorName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Introduce yourself and state what you hope to achieve through this mentorship connection.',
              style: TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Personalized Message',
              hintText: 'Hi, I would love to connect to discuss software architecture and career advice...',
              controller: _messageController,
              maxLines: 4,
              validator: (v) => AppValidators.validateMinLength(v, 20, 'Request message'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: 'Send Request',
          isLoading: _isLoading,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }
}
