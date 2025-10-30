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
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.trainingTitle ?? 'Training',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: [
              // Scrollable feature cards
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        title: l10n?.trainingReceivedTitle ?? 'Training Received',
                        count: 0,
                        image: 'assets/images/id-card.png',
                        onClick: () {
                          Navigator.pushNamed(context, Route_Names.TrainingReceived);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeatureCard(
                        title: l10n?.trainingProvidedTitle ?? 'Training Provided',
                        count: 0,
                        image: 'assets/images/notes.png',
                        onClick: () {
                          Navigator.pushNamed(context, Route_Names.TrainingProvided);

                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 35,
                  child: RoundButton(
                    title: (l10n?.addNewTrainingButton ?? 'Add New Training').toUpperCase(),
                    color: AppColors.primary,
                    borderRadius: 8,
                    onPress: () {
                      Navigator.pushNamed(context, Route_Names.Trainingform);
                    },
                  ),
                ),
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

  const _FeatureCard({
    required this.title,
    required this.count,
    required this.image,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 100,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style:  TextStyle(
                fontWeight: FontWeight.w600,
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
