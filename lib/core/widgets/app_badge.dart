import 'package:flutter/material.dart';
import '../config/app_colors.dart';

enum AppBadgeVariant { green, blue, yellow, red, purple, slate }

class AppBadge extends StatelessWidget {
  final String text;
  final AppBadgeVariant variant;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.variant = AppBadgeVariant.green,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (variant) {
      case AppBadgeVariant.green:
        bgColor = AppColors.brandGreen100;
        textColor = AppColors.brandGreen800;
        break;
      case AppBadgeVariant.blue:
        bgColor = AppColors.brandBlue100;
        textColor = AppColors.brandBlue800;
        break;
      case AppBadgeVariant.yellow:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case AppBadgeVariant.red:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        break;
      case AppBadgeVariant.purple:
        bgColor = const Color(0xFFF3E8FF);
        textColor = const Color(0xFF6B21A8);
        break;
      case AppBadgeVariant.slate:
        bgColor = AppColors.slate200;
        textColor = AppColors.slate700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}
