import 'package:flutter/material.dart';
import '../config/app_colors.dart';

enum ToastType { success, error, info }

class ToastMessage {
  final String id;
  final ToastType type;
  final String message;

  ToastMessage({
    required this.id,
    required this.type,
    required this.message,
  });
}

class ToastOverlay {
  static void show(BuildContext context, String message, {ToastType type = ToastType.info}) {
    Color bgColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        bgColor = AppColors.brandGreen600;
        icon = Icons.check_circle_outline;
        break;
      case ToastType.error:
        bgColor = AppColors.error;
        icon = Icons.error_outline;
        break;
      case ToastType.info:
        bgColor = AppColors.brandBlue600;
        icon = Icons.info_outline;
        break;
    }

    final snackBar = SnackBar(
      elevation: 6,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: bgColor,
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
