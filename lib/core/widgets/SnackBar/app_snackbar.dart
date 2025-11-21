import 'package:flutter/material.dart';

/// Common SnackBar helper used across RegisterNewHouseHold screens.
/// Shows a short message with black background and white text.
void showAppSnackBar(BuildContext context, String message) {
  if (message.isEmpty) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}
