import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../../../core/widgets/AppHeader/AppHeader.dart' show AppHeader;

class EligibleCoupleHomeScreen extends StatefulWidget {
  const EligibleCoupleHomeScreen({super.key});

  @override
  State<EligibleCoupleHomeScreen> createState() => _EligibleCoupleHomeScreenState();
}

class _EligibleCoupleHomeScreenState extends State<EligibleCoupleHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.gridEligibleCouple ?? 'Eligible Couple',
        showBack: false,
        icon1: Icons.home,
        onIcon1Tap: () =>
            Navigator.pushNamed(context, Route_Names.homeScreen),
      ),
      drawer: CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: _DashboardCard(
                image: 'assets/images/couple.png',
                count: '6',
                title: 'Number Of\nEligible Couple\nIdentified',
                onTap: () => Navigator.pushNamed(
                  context,
                  Route_Names.EligibleCoupleIdentified,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardCard(
                image: 'assets/images/npcb-refer.png',
                count: '0',
                title: 'Updated Eligible\nCouple List',
                onTap: () => Navigator.pushNamed(
                  context,
                  Route_Names.UpdatedEligibleCoupleScreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String image;
  final String count;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.image,
    required this.count,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Image.asset(
                    image,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),

                  const Spacer(),
                  Text(
                    count,
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
