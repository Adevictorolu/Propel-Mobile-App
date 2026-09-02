import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/toast_overlay.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = 'mentee';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<AuthProvider>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            role: _selectedRole,
          );
      if (mounted) {
        ToastOverlay.show(
          context,
          'Account created successfully!',
          type: ToastType.success,
        );
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

  Future<void> _handleGoogleSignUp() async {
    try {
      await context.read<AuthProvider>().loginWithGoogle();
      if (mounted) {
        ToastOverlay.show(context, 'Signed up with Google successfully!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(
          context,
          'Google Sign-Up error: ${e.toString().replaceAll('Exception: ', '')}',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join the Propel Mentorship Network today',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 24),

          // Google Sign Up Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: BorderSide(
                color: isDark ? AppColors.slate700 : AppColors.slate300,
                width: 1.5,
              ),
              backgroundColor: isDark ? AppColors.slate800 : Colors.white,
              elevation: 0,
            ),
            onPressed: authProvider.isLoading ? null : _handleGoogleSignUp,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.g_mobiledata_rounded, size: 24, color: AppColors.brandBlue600),
                ),
                const SizedBox(width: 10),
                Text(
                  'Sign Up with Google',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.slate800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: isDark ? AppColors.slate700 : AppColors.slate200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR EMAIL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDark ? AppColors.slate700 : AppColors.slate200)),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'SELECT ROLE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  title: 'Mentee',
                  subtitle: 'Seek guidance & grow',
                  icon: Icons.school_outlined,
                  isSelected: _selectedRole == 'mentee',
                  onTap: () => setState(() => _selectedRole = 'mentee'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleCard(
                  title: 'Mentor',
                  subtitle: 'Share & guide others',
                  icon: Icons.workspace_premium_outlined,
                  isSelected: _selectedRole == 'mentor',
                  onTap: () => setState(() => _selectedRole = 'mentor'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'First Name',
                  hintText: 'John',
                  controller: _firstNameController,
                  validator: (v) =>
                      AppValidators.validateRequired(v, 'First name'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Last Name',
                  hintText: 'Doe',
                  controller: _lastNameController,
                  validator: (v) =>
                      AppValidators.validateRequired(v, 'Last name'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Email Address',
            hintText: 'john@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.brandGreen600),
            validator: AppValidators.validateEmail,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Password',
            hintText: 'At least 8 characters',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.brandGreen600),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: AppColors.slate400,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: AppValidators.validatePassword,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Create Account',
            isFullWidth: true,
            isLoading: authProvider.isLoading,
            onPressed: _handleSignUp,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.slate500,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.inter(
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.brandGreen900.withValues(alpha: 0.3)
                  : AppColors.brandGreen50)
              : (isDark ? AppColors.slate800 : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.brandGreen600
                : (isDark ? AppColors.slate700 : AppColors.slate200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandGreen600.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.brandGreen600 : AppColors.slate400,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.brandGreen600
                          : (isDark ? Colors.white : AppColors.slate800),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.slate500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
