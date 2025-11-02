import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/presentation/Incentive_portal/NationalPrograms/TBScreen.dart';
import 'package:sizer/sizer.dart';

import 'AESJEScreen.dart';
import 'AMBScreen.dart';
import 'FilariasisScreen.dart';
import 'KalaAzarScreen.dart';
import 'LeprosyScreen.dart';
import 'MalariaScreen.dart';
import 'NIDDCPscreen.dart';
import 'ABPMJAYscreen.dart';



class NationalProgramsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> programs = [
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'Tuberculosis Eradication Program',
      'route': (context) => TbProgramScreen(),
    },
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'Leprosy Eradication program',
      'route': (context) => LeprosyScreen(),
    },
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'Kala-azar Eradication Program',
      'route': (context) => KalaAzarScreen(),
    },
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'Malaria Eradication Program',
      'route': (context) => MalariaScreen(),
    },
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'Filaria Eradication Program',
       'route': (context) => FilariasisScreen(),
    },
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'AES/JE Eradication Program ',
       'route': (context) => AESJEScreen(),
    },
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'AMB Eradication Program',
       'route': (context) => AMBScreen(),
    },
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'NIDDCP Program',
      'route': (context) => NIDDCPScreen(),
    },
    {
      'icon': 'assets/images/capsule2.png',
      'title': 'AB-PMJAY Program',
      'route': (context) => ABPMJAYScreen(),
    },

  ];

  NationalProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppHeader(
            screenTitle: 'National Program',
            showBack: true,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            child: ListView.separated(
              itemCount: programs.length,
              separatorBuilder: (_, __) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final item = programs[index];
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
