import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onOkPressed;

  static const Color primary = Color(0xFF428BCA);

  const CustomDialog({
    Key? key,
    required this.title,
    required this.message,
    this.onOkPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              message,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // OK Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOkPressed ?? () => Navigator.of(context).pop(),
                child: const Text(
                  'OKAY',
                  style: TextStyle(
                    color: primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to show the dialog
  static Future<void> show(
      BuildContext context, {
        required String title,
        required String message,
        VoidCallback? onOkPressed,
      }) {
    return showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        message: message,
        onOkPressed: onOkPressed,
      ),
    );
  }
}

// Example usage:
// CustomDialog.show(
//   context,
//   title: 'Form has been saved successfully.',
//   message: 'Beneficiary has been added to HBNC list.',
// );