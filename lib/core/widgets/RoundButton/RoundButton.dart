import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config/themes/CustomColors.dart';

class RoundButton extends StatelessWidget {
  final String title;
  final VoidCallback onPress;
  final bool isLoading;
  final bool disabled; // 👈 add this
  final Color? color;
  final double height;
  final double width;
  final double borderRadius;
  final IconData? icon;
  final double iconSize;
  final double fontSize;
  final double spacing;

  const RoundButton({
    super.key,
    required this.title,
    required this.onPress,
    this.isLoading = false,
    this.disabled = false, // 👈 default false
    this.color,
    this.height = 44,
    this.width = double.infinity,
    this.borderRadius = 4,
    this.icon,
    this.iconSize = 25,
    this.fontSize = 16,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = isLoading || disabled; // combine loading + disabled

    return GestureDetector(
      onTap: isDisabled ? null : onPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: isDisabled
              ? (color ?? AppColors.primary).withOpacity(0.5) // faded color
              : color ?? AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: (color ?? AppColors.primary).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ?  SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.onPrimary,
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, color: AppColors.onPrimary, size: iconSize),
              if (icon != null) SizedBox(width: spacing),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
