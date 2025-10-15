import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

import '../../core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class Aboutus extends StatefulWidget {
  const Aboutus({super.key});

  @override
  State<Aboutus> createState() => _AboutusState();
}

class _AboutusState extends State<Aboutus> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(screenTitle: l10n?.drawerAboutUs ?? 'About Us', showBack: true,),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          color: AppColors.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.aboutUsP1Title ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.aboutUsP2 ?? '',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.aboutUsP3 ?? '',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.aboutUsP4 ?? '',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
