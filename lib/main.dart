import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';
import 'data/Database/database_provider.dart';
import 'data/sync/sync_service.dart';

import 'core/config/routes/Route_Name.dart';
import 'core/config/routes/Routes.dart';
import 'core/config/themes/CustomColors.dart';
import 'core/locale/bloc/locale_bloc.dart';
import 'core/locale/bloc/locale_state.dart';
import 'core/locale/bloc/locale_event.dart';
import 'l10n/app_localizations.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final db   = await DatabaseProvider.instance.database;
  await DatabaseProvider.instance.ensureTablesExist(db);

  await DatabaseProvider.instance.runMigration(db);

  runApp(
    Sizer(
      builder: (context, orientation, deviceType) {
        return BlocProvider(
          create: (_) => LocaleBloc()..add(const LoadSavedLocale()),
          child: const MyApp(),
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleBloc, LocaleState>(
      builder: (context, state) {
        // Create a base text theme with Lato as the default font
        final baseTextTheme = Theme.of(context).textTheme.apply(
              fontFamily: 'Lato',
              displayColor: Colors.black87,
              bodyColor: Colors.black87,
            );

        return MaterialApp(
          title: 'BHAVYA mASHA',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            canvasColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              surface: Colors.white,
              onSurface: Colors.black87,
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.primary,
            ),
            useMaterial3: true,
            // Set Lato as the default font
            // fontFamily: 'Lato',
            // Apply Lato to all text themes
            textTheme: baseTextTheme,
            // Apply to other text themes
            primaryTextTheme: baseTextTheme.copyWith(
              bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: Colors.white),
              bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            // Style form fields
            inputDecorationTheme: InputDecorationTheme(
              labelStyle: const TextStyle(fontFamily: 'Lato'),
              hintStyle: const TextStyle(fontFamily: 'Lato'),
              helperStyle: const TextStyle(fontFamily: 'Lato'),
              errorStyle: const TextStyle(fontFamily: 'Lato'),
              prefixStyle: const TextStyle(fontFamily: 'Lato'),
              suffixStyle: const TextStyle(fontFamily: 'Lato'),
              counterStyle: const TextStyle(fontFamily: 'Lato'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            // Style buttons
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(fontFamily: 'Lato', fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          locale: state.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: ThemeMode.light,
          initialRoute: Route_Names.splashScreen,
          onGenerateRoute: Routes.generateRoute,
        );
      },
    );
  }
}

