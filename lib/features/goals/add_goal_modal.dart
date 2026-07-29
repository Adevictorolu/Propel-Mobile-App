import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';

class AddGoalModal extends StatefulWidget {
  final void Function(String title, String targetDate) onSubmit;

  const AddGoalModal({super.key, required this.onSubmit});

  @override
  State<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<AddGoalModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController(
    text: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T').first,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Curriculum Goal'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Goal Title',
              hintText: 'e.g. Complete System Design Architecture',
              controller: _titleController,
              validator: (v) => AppValidators.validateRequired(v, 'Goal title'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Target Date (YYYY-MM-DD)',
              hintText: '2026-12-31',
              controller: _dateController,
              validator: (v) => AppValidators.validateRequired(v, 'Target date'),
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
          text: 'Add Goal',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSubmit(_titleController.text.trim(), _dateController.text.trim());
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
