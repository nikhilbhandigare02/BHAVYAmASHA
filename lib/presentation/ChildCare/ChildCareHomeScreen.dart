import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../HomeScreen/HomeScreen.dart';

class ChildCareHomeScreen extends StatefulWidget {
  const ChildCareHomeScreen({super.key});

  @override
  State<ChildCareHomeScreen> createState() => _ChildCareHomeScreenState();
}

class _ChildCareHomeScreenState extends State<ChildCareHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 🔹 3 cards per row (with spacing)
    final double totalHorizontalPadding = 12 * 2; // outer padding
    final double spacingBetweenCards = 12 * 2; // 2 gaps of 12px between 3 cards
    final double cardWidth = (MediaQuery.of(context).size.width -
        totalHorizontalPadding -
        spacingBetweenCards) /
        2.9;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        screenTitle: (l10n?.gridChildCare ?? 'Child Care').toString(),
        showBack: false,
        icon1: Icons.home,
        onIcon1Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    title: (l10n?.childRegisteredBeneficiaryListTitle ??
                        'Registered Child\nBeneficiary List')
                        .toString(),
                    count: 0,
                    image: 'assets/images/toddler.png',
                    onClick: () {
                      Navigator.pushNamed(
                          context, Route_Names.RegisterChildScreen);
                    },
                  ),
                  const SizedBox(width: 4),
                  _FeatureCard(
                    width: cardWidth,
                    title: (l10n?.childRegisteredDueListTitle ??
                        'Child Registered\nDue List')
                        .toString(),
                    count: 0,
                    image: 'assets/images/family.png',
                    onClick: () {
                      Navigator.pushNamed(
                          context, Route_Names.RegisterChildDueList);
                    },
                  ),
                  const SizedBox(width: 4),
                  _FeatureCard(
                    width: cardWidth,
                    title: (l10n?.childTrackingDueListTitle ??
                        'Child Tracking\nDue List')
                        .toString(),
                    count: 0,
                    image: 'assets/images/notes.png',
                    onClick: () {
                      Navigator.pushNamed(
                          context, Route_Names.CHildTrackingDueList);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    title: (l10n?.hbycListTitle ?? 'HBYC List').toString(),
                    count: 0,
                    image: 'assets/images/pnc-mother.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.HBYCList);
                    },
                  ),
                  const SizedBox(width: 4),
                  _FeatureCard(
                    width: cardWidth,
                    title:
                    (l10n?.deceasedChildTitle ?? 'Deceased Child').toString(),
                    count: 0,
                    image: 'assets/images/death2.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.DeseasedList);
                    },
                  ),
                  const SizedBox(width: 4),
                  // Empty placeholder for alignment
                  SizedBox(width: cardWidth),
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
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        child: Card(
          color: AppColors.background,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min, // auto height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      image,
                      width: 30.sp,
                      height: 30.sp,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.outline,
                    fontSize: 14.sp,
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
