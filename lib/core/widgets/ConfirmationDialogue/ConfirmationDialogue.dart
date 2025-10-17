import 'package:flutter/material.dart';
import '../../config/themes/CustomColors.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String yesText,
  required String noText,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.warning, // red background
            borderRadius:  BorderRadius.circular(4
            ),
          ),
          child: Text(
            title,
            style:  TextStyle(
              color: AppColors.background, // title text white
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            message,
            style:  TextStyle(
              color: AppColors.warning,
              fontSize: 16,
              fontWeight: FontWeight.w500
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              yesText,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              noText,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}
