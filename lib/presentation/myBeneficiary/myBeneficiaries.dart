import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';

import '../../core/config/routes/Route_Name.dart';

class Mybeneficiaries extends StatefulWidget {
  const Mybeneficiaries({super.key});

  @override
  State<Mybeneficiaries> createState() => _MybeneficiariesState();
}

class _MybeneficiariesState extends State<Mybeneficiaries> {
  final List<_BeneficiaryTileData> _items = const [
    _BeneficiaryTileData(
      title: 'Family Update',
      asset: 'assets/images/family.png',
      count: 8,
    ),
    _BeneficiaryTileData(
      title: 'Eligible Couple List',
      asset: 'assets/images/couple.png',
      count: 5,
    ),
    _BeneficiaryTileData(
      title: 'Pregnant Women List',
      asset: 'assets/images/pregnant-woman.png',
      count: 5,
    ),
    _BeneficiaryTileData(
      title: 'Pregnancy Outcome',
      asset: 'assets/images/safe_motherhood.png',
      count: 0,
      highlighted: true,
    ),
    _BeneficiaryTileData(
      title: 'HBNC List',
      asset: 'assets/images/infant-pnc.png',
      count: 0,
    ),
    _BeneficiaryTileData(
      title: 'LBW Referred',
      asset: 'assets/images/lbw.png',
      count: 0,
    ),
    _BeneficiaryTileData(
      title: 'Abortion List',
      asset: 'assets/images/forms.png',
      count: 0,
    ),
    _BeneficiaryTileData(
      title: 'Death Register',
      asset: 'assets/images/hospital-bed.png',
      count: 0,
    ),
    _BeneficiaryTileData(
      title: 'Migrated Out',
      asset: 'assets/images/id-card.png',
      count: 0,
    ),
    _BeneficiaryTileData(
      title: 'Guest Beneficiary List',
      asset: 'assets/images/beneficiaries.png',
      count: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(screenTitle: 'My Beneficiaries'),
      drawer: CustomDrawer(),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _BeneficiaryTile(
            data: item,
            onTap: () {
              switch (index) {
                case 0:
                  Navigator.pushNamed(context, Route_Names.FamliyUpdate);
                  break;
                case 1:
                  Navigator.pushNamed(context, Route_Names.EligibleCoupleList);
                  break;
                case 2:
                  Navigator.pushNamed(context, Route_Names.PregnantWomenList);
                  break;
                // case 3:
                //   Navigator.pushNamed(context, Route_Names.PregnancyOutcome);
                //   break;
                // case 4:
                //   Navigator.pushNamed(context, Route_Names.HBNCList);
                //   break;
                // case 5:
                //   Navigator.pushNamed(context, Route_Names.LBWReferred);
                //   break;
                // case 6:
                //   Navigator.pushNamed(context, Route_Names.AbortionList);
                //   break;
                // case 7:
                //   Navigator.pushNamed(context, Route_Names.DeathRegister);
                //   break;
                // case 8:
                //   Navigator.pushNamed(context, Route_Names.MigratedOut);
                //   break;
                // case 9:
                //   Navigator.pushNamed(context, Route_Names.GuestBeneficiaryList);
                //   break;
                default:
                  break;
              }
            },
          );
        },
      ),

    );
  }


}

class _BeneficiaryTileData {
  final String title;
  final String asset;
  final int count;
  final bool highlighted;

  const _BeneficiaryTileData({
    required this.title,
    required this.asset,
    required this.count,
    this.highlighted = false,
  });
}

class _BeneficiaryTile extends StatelessWidget {
  final _BeneficiaryTileData data;
  final VoidCallback? onTap;

  const _BeneficiaryTile({
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: data.highlighted ? 2 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      margin: EdgeInsets.zero,
      color:  Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset(
                    data.asset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A4A),
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  data.count.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3A86CF),
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
