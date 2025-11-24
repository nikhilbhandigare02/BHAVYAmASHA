import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:sizer/sizer.dart';

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
                Builder(
                  builder: (context) {
                    final text = l10n?.aboutUsP1Title ?? '';
                    const target = 'ASHA';
                    final index = text.indexOf(target);

                    if (index == -1) {
                      return Text(
                        text,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.onSurface,
                        ),
                      );
                    }

                    final before = text.substring(0, index);
                    final after = text.substring(index + target.length);

                    return RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          if (before.isNotEmpty)
                            TextSpan(text: before),
                          TextSpan(
                            text: target,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (after.isNotEmpty)
                            TextSpan(text: after),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.aboutUsP2 ?? '',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.aboutUsP3 ?? '',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.aboutUsP4 ?? '',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
