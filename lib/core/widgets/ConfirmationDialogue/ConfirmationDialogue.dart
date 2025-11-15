import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../config/themes/CustomColors.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
   String? message,
  required String yesText,
  String? noText, // ✅ Optional for single-button case
  VoidCallback? onYes,
  VoidCallback? onNo,

  // ✅ Optional color customizations
  Color? titleBackgroundColor,
  Color? titleTextColor,
  Color? messageTextColor,
  Color? yesButtonColor,
  Color? noButtonColor,
  Color? dialogBackgroundColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final hasTwoButtons = noText != null && noText.isNotEmpty;

      return AlertDialog(
        backgroundColor: dialogBackgroundColor ?? AppColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

        // 🟡 Title Section
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: titleBackgroundColor ?? AppColors.warning,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: titleTextColor ?? AppColors.background,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),

        // 🟡 Message Section
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            message ?? '',
            style: TextStyle(
              color: messageTextColor ?? AppColors.warning,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 🟡 Buttons (Dynamic Layout)
        actionsAlignment:
        hasTwoButtons ? MainAxisAlignment.end : MainAxisAlignment.end,
        actions: [
          if (hasTwoButtons)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                if (onNo != null) onNo();
              },
              child: Text(
                noText!,
                style: TextStyle(
                  color: noButtonColor ?? AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              if (onYes != null) onYes();
            },
            child: Text(
              yesText,
              style: TextStyle(
                color: yesButtonColor ?? AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}
