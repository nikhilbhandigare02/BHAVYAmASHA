import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:sizer/sizer.dart';
import '../../l10n/app_localizations.dart';

import '../../core/config/routes/Route_Name.dart';

class Mybeneficiaries extends StatefulWidget {
  const Mybeneficiaries({super.key});

  @override
  State<Mybeneficiaries> createState() => _MybeneficiariesState();
}

class _MybeneficiariesState extends State<Mybeneficiaries> {
  int familyUpdateCount = 0;
  int eligibleCoupleCount = 0;
  int pregnantWomenCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      int familyCount = 0;
      int coupleCount = 0;
      int pregnantCount = 0;

      for (final row in rows) {
        final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
        final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
        final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? const {});

        // Count family updates (all heads of household)
        if (head.isNotEmpty) {
          familyCount++;
        }

        // Count eligible couples (married females 15-49)
        if ((head['maritalStatus']?.toString().toLowerCase() == 'married') &&
            (spouse['gender']?.toString().toLowerCase() == 'female') &&
            (spouse['memberName']?.toString().isNotEmpty ?? false)) {
          final age = _calculateAge(spouse['dob']?.toString() ?? '');
          if (age >= 15 && age <= 49) {
            coupleCount++;
          }
        }

        // Count pregnant women (check head, spouse, and family members)
        // Check if head is pregnant
        if (_isPregnant(head)) {
          pregnantCount++;
        }
        
        // Check if spouse is pregnant
        if (spouse.isNotEmpty && _isPregnant(spouse)) {
          pregnantCount++;
        }
        
        // Check family members
        final familyMembers = (info['family_details'] as List?) ?? [];
        for (final member in familyMembers) {
          final memberData = Map<String, dynamic>.from(member as Map? ?? const {});
          if (_isPregnant(memberData)) {
            pregnantCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          familyUpdateCount = familyCount;
          eligibleCoupleCount = coupleCount;
          pregnantWomenCount = pregnantCount;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading beneficiary counts: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _isPregnant(Map<String, dynamic> person) {
    if (person.isEmpty) return false;
    final flag = person['isPregnant']?.toString().toLowerCase();
    final typoFlag = person['isPregrant']?.toString().toLowerCase();
    final statusFlag = person['pregnancyStatus']?.toString().toLowerCase();
    return flag == 'true' || flag == 'yes' || typoFlag == 'true' || typoFlag == 'yes' || statusFlag == 'pregnant';
  }

  int _calculateAge(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (e) {
      print('Error calculating age: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<_BeneficiaryTileData> _items = [
      _BeneficiaryTileData(
        title: l10n.familyUpdate,
        asset: 'assets/images/family.png',
        count: isLoading ? 0 : familyUpdateCount,
      ),
      _BeneficiaryTileData(
        title: l10n.eligibleCoupleList,
        asset: 'assets/images/couple.png',
        count: isLoading ? 0 : eligibleCoupleCount,
      ),
      _BeneficiaryTileData(
        title: l10n.pregnantWomenList,
        asset: 'assets/images/pregnant-woman.png',
        count: isLoading ? 0 : pregnantWomenCount,
      ),
      _BeneficiaryTileData(
        title: l10n.pregnancyOutcome,
        asset: 'assets/images/mother.png',
        count: 0,
      ),
      _BeneficiaryTileData(
        title: l10n.hbcnList,
        asset: 'assets/images/pnc-mother.png',
        count: 0,
      ),
      _BeneficiaryTileData(
        title: l10n.lbwReferred,
        asset: 'assets/images/lbw.png',
        count: 0,
      ),
      _BeneficiaryTileData(
        title: l10n.abortionList,
        asset: 'assets/images/npcb-refer.png',
        count: 0,
      ),
      _BeneficiaryTileData(
        title: l10n.deathRegister,
        asset: 'assets/images/death2.png',
        count: 0,
      ),
      _BeneficiaryTileData(
        title: l10n.migratedOut,
        asset: 'assets/images/lbw.png',
        count: 0,
      ),
      _BeneficiaryTileData(
        title: l10n.guestBeneficiaryList,
        asset: 'assets/images/beneficiaries.png',
        count: 6,
      ),
    ];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(screenTitle: l10n.myBeneficiariesTitle, showBack: true,),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                case 7:
                  Navigator.pushNamed(context, Route_Names.DeathRegister);
                  break;
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
                  style:  TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A4A),
                  ),
                ),
              ),
              Text(
                data.count.toString(),
                style:  TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A86CF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
