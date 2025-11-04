import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../core/widgets/RoundButton/RoundButton.dart';

class TrainingHomeScreen extends StatefulWidget {
  const TrainingHomeScreen({super.key});

  @override
  State<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends State<TrainingHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final double totalHorizontalPadding = 12 * 2;
    final double spacingBetweenCards = 8;
    final double cardWidth = (MediaQuery.of(context).size.width -
        totalHorizontalPadding -
        spacingBetweenCards) /
        2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        screenTitle: l10n?.trainingTitle ?? 'Training',
        showBack: true,
      ),
      drawer: const CustomDrawer(),

      // 🔹 Button stays at the bottom of the screen
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SizedBox(
          width: double.infinity,
          height: 45,
          child: RoundButton(
            title: (l10n?.addNewTrainingButton ?? 'Add New Training')
                .toUpperCase(),
            color: AppColors.primary,
            borderRadius: 8,
            onPress: () {
              Navigator.pushNamed(context, Route_Names.Trainingform);
            },
          ),
        ),
      ),


      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureCard(
                    width: cardWidth,
                    title: (l10n?.trainingReceivedTitle ?? 'Training Received')
                        .toString(),
                    count: 0,
                    image: 'assets/images/id-card.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.TrainingReceived);
                    },
                  ),
                  const SizedBox(width: 8),
                  _FeatureCard(
                    width: cardWidth,
                    title: (l10n?.trainingProvidedTitle ?? 'Training Provided')
                        .toString(),
                    count: 0,
                    image: 'assets/images/notes.png',
                    onClick: () {
                      Navigator.pushNamed(context, Route_Names.TrainingProvided);
                    },
                  ),
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
    final double cardHeight = 15.h;

    return InkWell(
      onTap: onClick,
       borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: cardHeight,
        child: Card(
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      image,
                      width: 28.sp,
                      height: 28.sp,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Text(
                  title,
                  textAlign: TextAlign.left,
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
