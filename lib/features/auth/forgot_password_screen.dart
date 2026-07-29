import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/toast_overlay.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.resetPassword(_emailController.text.trim());
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastOverlay.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.brandGreen100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.brandGreen800,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Check your inbox',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a password reset link to ${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Back to Sign In',
            isFullWidth: true,
            onPressed: () => context.go('/login'),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAlignment.start,
        children: [
          const Text(
            'Reset Password',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your email address and we will send you a reset link.',
            style: TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Email Address',
            hintText: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: AppValidators.validateEmail,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Send Reset Link',
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _handleReset,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}
