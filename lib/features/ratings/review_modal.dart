import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../providers/auth_provider.dart';

class ReviewModal extends StatefulWidget {
  final String revieweeId;
  final String revieweeName;
  final String connectionId;

  const ReviewModal({
    super.key,
    required this.revieweeId,
    required this.revieweeName,
    required this.connectionId,
  });

  @override
  State<ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<ReviewModal> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _score = 5.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final reviewerId = context.read<AuthProvider>().user?.uid;
    if (reviewerId == null) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.submitRating(
        reviewerId: reviewerId,
        revieweeId: widget.revieweeId,
        connectionId: widget.connectionId,
        score: _score,
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        ToastOverlay.show(context, 'Review submitted successfully!', type: ToastType.success);
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
      title: Text('Review ${widget.revieweeName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rate your mentorship experience:'),
            const SizedBox(height: 12),
            StarRating(
              rating: _score,
              iconSize: 28,
              isInteractive: true,
              onRatingChanged: (val) => setState(() => _score = val),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Detailed Feedback',
              hintText: 'Share how this mentorship helped you and areas of strength...',
              controller: _commentController,
              maxLines: 4,
              validator: (v) => AppValidators.validateMinLength(v, 10, 'Review comment'),
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
          text: 'Submit Review',
          isLoading: _isLoading,
          onPressed: _handleSubmit,
        ),
      ],
    );
  }
}
