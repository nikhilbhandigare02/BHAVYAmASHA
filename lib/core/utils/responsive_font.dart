import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

// Shared responsive font sizing utility for all widgets
class ResponsiveFont {
  static double getLabelFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 11.0.sp;
    } else if (screenWidth < 600) {
      return 12.5.sp;
    } else {
      return 14.0.sp; 
    }
  }

  static double getTextFieldLabelFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 12.5.sp;
    } else if (screenWidth < 600) {
      return 14.5.sp;
    } else {
      return 16.5.sp;
    }
  }

  static double getHintFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 14.0.sp; // Small screens
    } else if (screenWidth < 600) {
      return 16.0.sp; // Medium screens
    } else {
      return 18.0.sp; // Large screens
    }
  }

  static double textFieldgetHintFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 13.0.sp; // Small screens
    } else if (screenWidth < 600) {
      return 15.0.sp; // Medium screens
    } else {
      return 17.0.sp; // Large screens
    }
  }


  static double getInputFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 13.0.sp; // Small screens
    } else if (screenWidth < 600) {
      return 15.0.sp; // Medium screens
    } else {
      return 17.0.sp; // Large screens
    }
  }
}
