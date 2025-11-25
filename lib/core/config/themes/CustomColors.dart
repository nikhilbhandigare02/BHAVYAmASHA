 import 'package:flutter/material.dart';

/// Centralized application color definitions.
///
/// Update values here to change colors across the app.
class AppColors {
  AppColors._();

  // Brand / Primary
  static const Color primary = Color(0xFF428BCA);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);


  // Secondary / Accent
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // Tertiary (optional accent)
  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiaryContainer = Color(0xFF31111D);

  // Error
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  static const Color background = Colors.white;
  static const Color onBackground = Color(0xFF1C1B1F);
  static const Color surface = Color(0xFFFFFBFE);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
  static const Color shadow = Colors.black54;
  static const Color scrim = Colors.black54;
  static const Color inverseSurface = Color(0xFF313033);
  static const Color onInverseSurface = Color(0xFFF4EFF4);
  static const Color inversePrimary = Color(0xFFD0BCFF);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF0288D1);
  static const Color green = Color(0xFF28A745);
  static const Color blue = Color(0xFF4CBEE5);

  static const Color onGreen = Colors.white;
  static const Color greenContainer = Color(0xFFDFF5E1);
  static const Color onGreenContainer = Color(0xFF1E4620);

  // Text helpers
  static const Color textPrimary = onSurface;
  static const Color textSecondary = Color(0xFF5E5A65);
  static const Color textDisabled = Color(0xFF9E9AA4);

  // UI helpers
  static const Color divider = outlineVariant;
  static const Color border = outline;
  static const Color disabled = Color(0xFFE0E0E0);
  static const Color scaffoldBackground = background;
  static const Color cardBackground = surface;
  // Utility
  static const Color transparent = Colors.transparent;

  static const Color greentick = Color(0xFF028102);

  static const Color greenApp = Color(0xFF1ABC9C);
  static const Color blueApp = Color(0xFF4a90e2);
  static const Color orangeApp = Color(0xFFf5a623);
  static const Color bgColorScreen = Color.fromRGBO(248, 249, 254, 1.0);
}

/// Dark mode colors. Keep brand hues consistent while adjusting luminance.
class AppColorsDark {
  AppColorsDark._();

  static const Color primary = Color(0xFFD0BCFF);
  static const Color onPrimary = Color(0xFF381E72);
  static const Color primaryContainer = Color(0xFF4F378B);
  static const Color onPrimaryContainer = Color(0xFFEADDFF);

   static const Color secondary = Color(0xFFCCC2DC);
   static const Color onSecondary = Color(0xFF332D41);
   static const Color secondaryContainer = Color(0xFF4A4458);
   static const Color onSecondaryContainer = Color(0xFFE8DEF8);

   static const Color tertiary = Color(0xFFEFB8C8);
   static const Color onTertiary = Color(0xFF492532);
   static const Color tertiaryContainer = Color(0xFF633B48);
   static const Color onTertiaryContainer = Color(0xFFFFD8E4);

   static const Color error = Color(0xFFF2B8B5);
   static const Color onError = Color(0xFF601410);
   static const Color errorContainer = Color(0xFF8C1D18);
   static const Color onErrorContainer = Color(0xFFF9DEDC);

   static const Color background = Color(0xFF1C1B1F);
   static const Color onBackground = Color(0xFFE6E1E5);
   static const Color surface = Color(0xFF1C1B1F);
   static const Color onSurface = Color(0xFFE6E1E5);
   static const Color surfaceVariant = Color(0xFF49454F);
   static const Color onSurfaceVariant = Color(0xFFCAC4D0);
   static const Color outline = Color(0xFF938F99);
   static const Color outlineVariant = Color(0xFF49454F);
   static const Color shadow = Colors.black;
   static const Color scrim = Colors.black;
   static const Color inverseSurface = Color(0xFFE6E1E5);
   static const Color onInverseSurface = Color(0xFF313033);
   static const Color inversePrimary = Color(0xFFA190D8);

   static const Color success = Color(0xFF66BB6A);
   static const Color warning = Color(0xFFFFB74D);
   static const Color info = Color(0xFF4FC3F7);

   static const Color textPrimary = onSurface;
   static const Color textSecondary = Color(0xFFB0AAB6);
   static const Color textDisabled = Color(0xFF7A7580);

   static const Color divider = outlineVariant;
   static const Color border = outline;
   static const Color disabled = Color(0xFF3A3940);
   static const Color scaffoldBackground = background;
   static const Color cardBackground = surface;


  static const Color greentick = Color(0xFF028102);

  static const Color green = Color(0xFF4CAF50);
  static const Color greenApp = Color(0xFF1ABC9C);
  static const Color blueApp = Color(0xFF4a90e2);
  static const Color orangeApp = Color(0xFFf5a623);
 }

 /// App color schemes for light and dark themes.
 class AppColorSchemes {
   AppColorSchemes._();

   static const ColorScheme light = ColorScheme(
     brightness: Brightness.light,
     primary: AppColors.primary,
     onPrimary: AppColors.onPrimary,
     primaryContainer: AppColors.primaryContainer,
     onPrimaryContainer: AppColors.onPrimaryContainer,
     secondary: AppColors.secondary,
     onSecondary: AppColors.onSecondary,
     secondaryContainer: AppColors.secondaryContainer,
     onSecondaryContainer: AppColors.onSecondaryContainer,
     tertiary: AppColors.tertiary,
     onTertiary: AppColors.onTertiary,
     tertiaryContainer: AppColors.tertiaryContainer,
     onTertiaryContainer: AppColors.onTertiaryContainer,
     error: AppColors.error,
     onError: AppColors.onError,
     errorContainer: AppColors.errorContainer,
     onErrorContainer: AppColors.onErrorContainer,
     background: AppColors.background,
     onBackground: AppColors.onBackground,
     surface: AppColors.surface,
     onSurface: AppColors.onSurface,
     surfaceVariant: AppColors.surfaceVariant,
     onSurfaceVariant: AppColors.onSurfaceVariant,
     outline: AppColors.outline,
     outlineVariant: AppColors.outlineVariant,
     shadow: AppColors.shadow,
     scrim: AppColors.scrim,
     inverseSurface: AppColors.inverseSurface,
     onInverseSurface: AppColors.onInverseSurface,
     inversePrimary: AppColors.inversePrimary,
   );

   static const ColorScheme dark = ColorScheme(
     brightness: Brightness.dark,
     primary: AppColorsDark.primary,
     onPrimary: AppColorsDark.onPrimary,
     primaryContainer: AppColorsDark.primaryContainer,
     onPrimaryContainer: AppColorsDark.onPrimaryContainer,
     secondary: AppColorsDark.secondary,
     onSecondary: AppColorsDark.onSecondary,
     secondaryContainer: AppColorsDark.secondaryContainer,
     onSecondaryContainer: AppColorsDark.onSecondaryContainer,
     tertiary: AppColorsDark.tertiary,
     onTertiary: AppColorsDark.onTertiary,
     tertiaryContainer: AppColorsDark.tertiaryContainer,
     onTertiaryContainer: AppColorsDark.onTertiaryContainer,
     error: AppColorsDark.error,
     onError: AppColorsDark.onError,
     errorContainer: AppColorsDark.errorContainer,
     onErrorContainer: AppColorsDark.onErrorContainer,
     background: AppColorsDark.background,
     onBackground: AppColorsDark.onBackground,
     surface: AppColorsDark.surface,
     onSurface: AppColorsDark.onSurface,
     surfaceVariant: AppColorsDark.surfaceVariant,
     onSurfaceVariant: AppColorsDark.onSurfaceVariant,
     outline: AppColorsDark.outline,
     outlineVariant: AppColorsDark.outlineVariant,
     shadow: AppColorsDark.shadow,
     scrim: AppColorsDark.scrim,
     inverseSurface: AppColorsDark.inverseSurface,
     onInverseSurface: AppColorsDark.onInverseSurface,
     inversePrimary: AppColorsDark.inversePrimary,
   );
 }

 extension ColorSchemeX on BuildContext {
   ColorScheme get colors => Theme.of(this).colorScheme;
 }

