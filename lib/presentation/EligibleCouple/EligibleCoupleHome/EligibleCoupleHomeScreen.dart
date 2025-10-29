import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/routes/Route_Name.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/config/themes/CustomColors.dart';
import '../../../core/widgets/AppHeader/AppHeader.dart' show AppHeader;

class EligibleCoupleHomeScreen extends StatefulWidget {
  const EligibleCoupleHomeScreen({super.key});

  @override
  State<EligibleCoupleHomeScreen> createState() =>
      _EligibleCoupleHomeScreenState();
}

class _EligibleCoupleHomeScreenState extends State<EligibleCoupleHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final cards = [
      {
        'image': 'assets/images/couple.png',
        'count': '6',
        'title': l10n?.gridEligibleCouple ?? 'Eligible Couple',
        'route': Route_Names.EligibleCoupleIdentified,
      },
      {
        'image': 'assets/images/npcb-refer.png',
        'count': '0',
        'title': l10n?.updatedEligibleCoupleListTitle ??
            'Updated Eligible Couple List',
        'route': Route_Names.UpdatedEligibleCoupleScreen,
      },
    ];

    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.gridEligibleCouple ?? 'Eligible Couple',
        showBack: false,
        icon1: Icons.home,
        onIcon1Tap: () => Navigator.pushNamed(context, Route_Names.homeScreen),
      ),
      drawer: CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Fits up to 3 small square cards per row
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1, // Make square
          ),
          itemBuilder: (context, index) {
            final item = cards[index];
            return _DashboardCard(
              image: item['image']!,
              count: item['count']!,
              title: item['title']!,
              onTap: () => Navigator.pushNamed(context, item['route']!),
            );
          },
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
      borderRadius: BorderRadius.circular(1),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(

        ),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(

       //  mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Image.asset(
                    image,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  Text(
                    count,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                ],
              ),
                  SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.outline
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
