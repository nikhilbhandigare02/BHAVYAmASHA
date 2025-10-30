import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';

import 'core/config/routes/Route_Name.dart';
import 'core/config/routes/Routes.dart';
import 'core/config/themes/CustomColors.dart';
import 'core/locale/bloc/locale_bloc.dart';
import 'core/locale/bloc/locale_state.dart';
import 'core/locale/bloc/locale_event.dart';
import 'l10n/app_localizations.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

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
      builder: (context, localeState) {
        return MaterialApp(
          locale: localeState.locale,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          theme: ThemeData(
            colorScheme: AppColorSchemes.light,
            textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
            scaffoldBackgroundColor: AppColors.scaffoldBackground,
          ),
          darkTheme: ThemeData(
            colorScheme: AppColorSchemes.light,
            textTheme: GoogleFonts.latoTextTheme(Theme.of(context).textTheme),
            scaffoldBackgroundColor: AppColors.scaffoldBackground,
          ),
          themeMode: ThemeMode.light,
          initialRoute: Route_Names.splashScreen,
          onGenerateRoute: Routes.generateRoute,
        );
      },
    );
  }
}

