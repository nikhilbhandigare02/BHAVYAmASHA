import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

class NCDHome extends StatefulWidget {
  const NCDHome({super.key});

  @override
  State<NCDHome> createState() => _NCDHomeState();
}

class _NCDHomeState extends State<NCDHome> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 3;
    const cardHeight = 120.0;

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.ncdTitle ?? 'NCD',
        showBack: false,
        icon1: Icons.home,
        onIcon1Tap: () =>
            Navigator.pushNamed(context, Route_Names.homeScreen),
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      title: l10n?.ncdListTitle ?? 'NCD List',
                      count: 0,
                      image: 'assets/images/home.png',
                      onClick: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.ncdMsgRegisteredChildBeneficiary ??
                                  'Registered Child Beneficiary list',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _FeatureCard(
                      width: cardWidth,
                      height: cardHeight,
                      title:
                      l10n?.ncdEligibleListTitle ?? 'NCD Eligible List',
                      count: 0,
                      image: 'assets/images/home.png',
                      onClick: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.ncdMsgChildRegisteredDueList ??
                                  'Child Registered Due List',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _FeatureCard(
                      width: cardWidth,
                      height: cardHeight,
                      title:
                      l10n?.ncdPriorityListTitle ?? 'NCD Priority List',
                      count: 0,
                      image: 'assets/images/home.png',
                      onClick: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.ncdMsgChildTrackingDueList ??
                                  'Child Tracking Due List',
                            ),
                          ),
                        );
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
                      title: l10n?.ncdNonEligibleListTitle ??
                          'NCD Non-Eligible List',
                      count: 0,
                      image: 'assets/images/home.png',
                      onClick: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.ncdMsgHbycList ?? 'HBYC List',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: cardWidth, height: cardHeight),
                    const SizedBox(width: 12),
                    SizedBox(width: cardWidth, height: cardHeight),
                  ],
                ),
              ],
            ),
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
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          //borderRadius: BorderRadius.circular(8),
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
                  width: 25,
                  height: 25,
                  fit: BoxFit.contain,
                ),
                  Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              title,
              style:   TextStyle(
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
