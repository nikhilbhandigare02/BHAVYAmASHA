import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class Mothercarehomescreen extends StatefulWidget {
  const Mothercarehomescreen({super.key});

  @override
  State<Mothercarehomescreen> createState() => _MothercarehomescreenState();
}

class _MothercarehomescreenState extends State<Mothercarehomescreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.gridMotherCare ?? 'Mother Care',
        showBack: false,
        icon1: Icons.home,
        onIcon1Tap: () => Navigator.pushNamed(context, Route_Names.homeScreen),
      ),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FeatureCard(
                  title: l10n?.motherAncVisitTitle ?? 'ANC Visit',
                  count: 6,
                  image: 'assets/images/pregnant-woman.png',
                  onClick: () {
                    Navigator.pushNamed(context, Route_Names.Ancvisitlistscreen);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  title: l10n?.deliveryOutcomeTitle ?? 'Delivery\nOutcome',
                  count: 0,
                  image: 'assets/images/mother.png',
                  onClick: () {
                    Navigator.pushNamed(context, Route_Names.DeliveryOutcomeScreen);

                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  title: l10n?.hbncMotherTitle ?? 'HBNC Mother',
                  count: 0,
                  image: 'assets/images/pnc-mother.png',
                  onClick: () {
                    Navigator.pushNamed(context, Route_Names.HBNCScreen);

                  },
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

    return InkWell( // ✅ makes the entire card clickable
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
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
