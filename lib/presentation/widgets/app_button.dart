import 'package:flutter/material.dart';
import 'package:progress_pals/core/theme/app_colors.dart';

enum ButtonType { primary, outline, warning }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = type == ButtonType.primary;
    final isWarning = type == ButtonType.warning;
    final isOutline = type == ButtonType.outline;

    return SizedBox(
      width: double.infinity, // Full width
      height: 56, // Standard mobile button height
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primary : isWarning ? AppColors.error : Colors.transparent,
          elevation: 0,
          side: isPrimary ? null :  BorderSide(color: isOutline ? AppColors.primary : AppColors.error , width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Smooth corners
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isOutline ? AppColors.primary : Colors.white ,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}