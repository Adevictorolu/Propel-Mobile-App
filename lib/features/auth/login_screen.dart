import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        ToastOverlay.show(context, 'Welcome back!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await context.read<AuthProvider>().loginWithGoogle();
      if (mounted) {
        ToastOverlay.show(context, 'Signed in with Google successfully!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(
          context,
          'Google Sign-In error: ${e.toString().replaceAll('Exception: ', '')}',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign In to Propel',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your credentials or use Google to sign in',
            style: TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
          const SizedBox(height: 20),

          // Google Sign In Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: AppColors.slate300),
            ),
            onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.g_mobiledata_rounded, size: 28, color: AppColors.brandBlue600),
                SizedBox(width: 8),
                Text(
                  'Continue with Google',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR', style: TextStyle(fontSize: 11, color: AppColors.slate400, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Email Address',
            hintText: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: AppValidators.validateEmail,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Password',
            hintText: '••••••••',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: AppValidators.validatePassword,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Sign In',
            isFullWidth: true,
            isLoading: authProvider.isLoading,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 13, color: AppColors.slate500),
              ),
              GestureDetector(
                onTap: () => context.go('/signup'),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandBlue600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
