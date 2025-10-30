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
    final cardWidth = (MediaQuery.of(context).size.width - 48) / 3;
    const cardHeight = 120.0;

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.gridChildCare ?? 'Child Care',
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    height: cardHeight,
                    title: l10n?.childRegisteredBeneficiaryListTitle ??
                        'Registered Child\nBeneficiary list',
                    count: 0,
                    image: 'assets/images/toddler.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.RegisterChildScreen);
                    },
                  ),
                  const SizedBox(width: 12),
                  _FeatureCard(
                    width: cardWidth,
                    height: cardHeight,
                    title: l10n?.childRegisteredDueListTitle ??
                        'Child Registered\nDue List',
                    count: 0,
                    image: 'assets/images/family.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.RegisterChildDueList);
                    },
                  ),
                  const SizedBox(width: 12),
                  _FeatureCard(
                    width: cardWidth,
                    height: cardHeight,
                    title: l10n?.childTrackingDueListTitle ??
                        'Child Tracking\nDue List',
                    count: 0,
                    image: 'assets/images/notes.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.CHildTrackingDueList);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),


              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    height: cardHeight,
                    title: l10n?.hbycListTitle ?? 'HBYC List',
                    count: 0,
                    image: 'assets/images/pnc-mother.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.HBYCList);
                    },
                  ),
                  const SizedBox(width: 12),
                  _FeatureCard(
                    width: cardWidth,
                    height: cardHeight,
                    title: l10n?.deceasedChildTitle ?? 'Deceased Child',
                    count: 0,
                    image: 'assets/images/death2.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.DeseasedList);
                    },
                  ),
                  const SizedBox(width: 12),
                  // ✅ Empty placeholder to keep alignment of 3 cards
                  SizedBox(width: cardWidth, height: cardHeight),
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
  final double height;

  const _FeatureCard({
    required this.title,
    required this.count,
    required this.image,
    required this.onClick,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  image,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
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
    );
  }
}
