import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config/themes/CustomColors.dart';

class RoundButton extends StatelessWidget {
  final String title;
  final VoidCallback onPress;
  final bool isLoading;
  final bool disabled;
  final Color? color;
  final double? height;
  final double? width;
  final double borderRadius;
  final IconData? icon;
  final double? iconSize;
  final double? fontSize;
  final double spacing;

  const RoundButton({
    super.key,
    required this.title,
    required this.onPress,
    this.isLoading = false,
    this.disabled = false, // 👈 default false
    this.color,
    this.height,
    this.width,
    this.borderRadius = 4,
    this.icon,
    this.iconSize,
    this.fontSize,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = isLoading || disabled;
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    // Calculate responsive dimensions
    final double baseSize = isLandscape ? screenSize.height * 0.06 : screenSize.height * 0.06;
    final double buttonHeight = height ?? baseSize.clamp(44.0, 60.0);
    final double buttonWidth = width ?? double.infinity;
    final double buttonFontSize = fontSize ?? (buttonHeight * 0.32).clamp(12.0, 18.0);
    final double buttonIconSize = iconSize ?? (buttonHeight * 0.6).clamp(20.0, 30.0);
    final double buttonBorderRadius = borderRadius.clamp(4.0, 8.0);

    return GestureDetector(
      onTap: isDisabled ? null : onPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: buttonHeight,
        width: buttonWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonBorderRadius),
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
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.onPrimary,
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(icon, color: AppColors.onPrimary, size: buttonIconSize),
              if (icon != null) SizedBox(width: spacing),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: buttonFontSize,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
