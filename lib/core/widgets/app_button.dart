import 'package:flutter/material.dart';
import '../config/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool isFullWidth;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.brandGreen600;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = Colors.transparent;
        fgColor = isDark ? AppColors.brandBlue400 : AppColors.brandBlue600;
        borderSide = BorderSide(
          color: isDark ? AppColors.slate600 : AppColors.slate300,
          width: 1.5,
        );
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = isDark ? AppColors.slate400 : AppColors.slate600;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.error;
        fgColor = Colors.white;
        break;
    }

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
