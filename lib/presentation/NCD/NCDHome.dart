import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart' as ffd;
import 'package:sizer/sizer.dart';

import 'NCDList.dart';
import 'NCDNonEligibleList.dart';
import 'NCDPriorityList.dart';
import 'NCDeligibleList.dart';

class NCDHome extends StatefulWidget {
  const NCDHome({super.key});

  @override
  State<NCDHome> createState() => _NCDHomeState();
}

class _NCDHomeState extends State<NCDHome> {
  int _cbacFormsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCBACFormsCount();
    _loadCBACFormsData();
  }

  Future<void> _loadCBACFormsCount() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final List<Map<String, dynamic>> result = await db.query(
        ffd.FollowupFormDataTable.table,
        where: 'forms_ref_key = ?',
        whereArgs: [ffd.FollowupFormDataTable.formUniqueKeys[ffd.FollowupFormDataTable.cbac]],
      );

      if (mounted) {
        setState(() {
          _cbacFormsCount = result.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading CBAC forms count: $e');
    }
  }

  Future<void> _loadCBACFormsData() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final List<Map<String, dynamic>> result = await db.query(
        ffd.FollowupFormDataTable.table,
        where: 'forms_ref_key = ?',
        whereArgs: ['vl7o6r9b6v3fbesk'],
      );

      // Log the raw query results
      debugPrint('CBAC Forms Data (${result.length} records):');
      for (var form in result) {
        debugPrint('Form ID: ${form['id']}');
        try {
          final formJson = jsonDecode(form['form_json']);
          debugPrint('Form Data: $formJson');
        } catch (e) {
          debugPrint('Error parsing form JSON: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading CBAC forms data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 🔹 3 cards per row
    final double totalHorizontalPadding = 12 * 2;
    final double spacingBetweenCards = 8;
    final double cardWidth = (screenWidth - totalHorizontalPadding - (2 * spacingBetweenCards)) / 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        screenTitle: l10n?.ncdTitle ?? 'NCD',
        showBack: false,
        icon1Image: 'assets/images/home.png',

        onIcon1Tap: () => Navigator.pushNamed(context, Route_Names.homeScreen),
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              // 🔹 First Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    title: l10n?.ncdListTitle ?? 'NCD List',
                    count: _cbacFormsCount,
                    image: 'assets/images/home.png',
                    onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Ncdlist()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _FeatureCard(
                    width: cardWidth,
                    title: l10n?.ncdEligibleListTitle ?? 'NCD Eligible List',
                    count: 0,
                    image: 'assets/images/home.png',
                    onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Ncdeligiblelist()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _FeatureCard(
                    width: cardWidth,
                    title: l10n?.ncdPriorityListTitle ?? 'NCD Priority List',
                    count: 0,
                    image: 'assets/images/home.png',
                    onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  Ncdprioritylist()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 🔹 Second Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    title: l10n?.ncdNonEligibleListTitle ?? 'NCD Non-Eligible List',
                    count: 0,
                    image: 'assets/images/home.png',
                    onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>   Ncdnoneligiblelist()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Empty placeholders for alignment
                  SizedBox(width: cardWidth, height: 14.h),
                  const SizedBox(width: 8),
                  SizedBox(width: cardWidth, height: 14.h),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final int count;
  final String image;
  final VoidCallback onClick;
  final double width;

  const _FeatureCard({
    required this.title,
    required this.count,
    required this.image,
    required this.onClick,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: 14.h,
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Image and Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      image,
                      width: 22.sp,
                      height: 22.sp,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.6.h),
                // 🔹 Title
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.outline,
                    fontSize: 14.sp,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}