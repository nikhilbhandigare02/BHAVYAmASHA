import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/Incentive_portal/NationalPrograms/TBScreen.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'AESJEScreen.dart';
import 'AMBScreen.dart';
import 'FilariasisScreen.dart';
import 'KalaAzarScreen.dart';
import 'LeprosyScreen.dart';
import 'MalariaScreen.dart';
import 'NIDDCPscreen.dart';
import 'ABPMJAYscreen.dart';



class NationalProgramsScreen extends StatelessWidget {
  List<Map<String, dynamic>> _getPrograms(BuildContext context) {
    return [
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.tbEradicationProgram,
        'route': (context) => TbProgramScreen(),
      },
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.leprosyEradicationProgram,
        'route': (context) => LeprosyScreen(),
      },
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.kalaAzarEradicationProgram,
        'route': (context) => KalaAzarScreen(),
      },
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.malariaEradicationProgram,
        'route': (context) => MalariaScreen(),
      },
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.filariaEradicationProgram,
        'route': (context) => FilariasisScreen(),
      },
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.aesJeEradicationProgram,
        'route': (context) => AESJEScreen(),
      },
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.ambEradicationProgram,
        'route': (context) => AMBScreen(),
      },
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.niddcpProgram,
        'route': (context) => NIDDCPScreen(),
      },
      {
        'icon': 'assets/images/capsule2.png',
        'title': AppLocalizations.of(context)!.abPmjayProgram,
        'route': (context) => ABPMJAYScreen(),
      },
    ];
  }

  NationalProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppHeader(
            screenTitle: AppLocalizations.of(context)!.nationalProgramsTitle,
            showBack: true,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            child: ListView.separated(
              itemCount: _getPrograms(context).length,
              separatorBuilder: (_, __) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final item = _getPrograms(context)[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Image.asset(
                      item['icon']!,
                      height: 22.sp,
                      width: 22.sp,
                      color: const Color(0xFF1976D2),
                    ),
                    title: Text(
                      item['title']!,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: item['route'],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
