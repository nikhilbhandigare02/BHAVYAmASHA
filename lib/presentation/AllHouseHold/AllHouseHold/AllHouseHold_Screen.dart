import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';

import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/AddNewFamilyHead.dart';

import '../../../core/widgets/AppDrawer/Drawer.dart';

class AllhouseholdScreen extends StatefulWidget {
  const AllhouseholdScreen({super.key});

  @override
  State<AllhouseholdScreen> createState() => _AllhouseholdScreenState();
}

class _AllhouseholdScreenState extends State<AllhouseholdScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _staticHouseholds = [
    {
      'hhId': '51016121847',
      'houseNo': 'ga',
      'name': 'va',
      'mobile': '9923175398',
      'totalMembers': 1,
      'eligibleCouples': 0,
      'pregnantWomen': 0,
      'elderly': 0,
      'child0to1': 0,
      'child1to2': 0,
      'child2to5': 0,
    },
    {
      'hhId': '51016102919',
      'houseNo': 'gaa',
      'name': 'hs',
      'mobile': '7620593001',
      'totalMembers': 1,
      'eligibleCouples': 0,
      'pregnantWomen': 0,
      'elderly': 0,
      'child0to1': 0,
      'child1to2': 0,
      'child2to5': 0,
    },
    {
      'hhId': '51014184212',
      'houseNo': 'A006',
      'name': 'Shrikant jadhav',
      'mobile': '9657908015',
      'totalMembers': 3,
      'eligibleCouples': 1,
      'pregnantWomen': 0,
      'elderly': 0,
      'child0to1': 0,
      'child1to2': 0,
      'child2to5': 0,
    },
    {
      'hhId': '51014110459',
      'houseNo': 'A003',
      'name': 'Shrikant patil',
      'mobile': '7620593002',
      'totalMembers': 2,
      'eligibleCouples': 1,
      'pregnantWomen': 1,
      'elderly': 0,
      'child0to1': 0,
      'child1to2': 0,
      'child2to5': 0,
    },
  ];

  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List<Map<String, dynamic>>.from(_staticHouseholds);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<Map<String, dynamic>>.from(_staticHouseholds);
      } else {
        _filtered = _staticHouseholds.where((e) {
          return (e['hhId'] as String).toLowerCase().contains(q) ||
              (e['houseNo'] as String).toLowerCase().contains(q) ||
              (e['name'] as String).toLowerCase().contains(q) ||
              (e['mobile'] as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.gridAllHousehold ?? 'All Household',
        showBack: false,
        icon1: Icons.home,
        onIcon1Tap: () => Navigator.pushNamed(context, Route_Names.homeScreen),
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.gridAllHousehold ?? 'All Household',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final data = _filtered[index];
                return _householdCard(context, data);
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 35,
                child: RoundButton(
                  title: l10n?.gridRegisterNewHousehold.toUpperCase() ?? 'NEW HOUSEHOLD REGISTRATION',
                  color: AppColors.primary,
                  borderRadius: 8,
                  height: 50,
                  onPress: () {
                    Navigator.pushNamed(context, Route_Names.RegisterNewHousehold);
                    },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);

    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Route_Names.houseHoldBeneficiaryScreen,
          arguments: data,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
            boxShadow: [
              // Bottom shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, 2), // down
              ),
              // Top shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 2,
                spreadRadius: 1,
                offset: const Offset(0, -2), // up
              ),
            ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  Expanded(
                    child: Text(
                      data['hhId'] ?? '',
                      style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${l10n?.houseNoLabel ?? 'House No.'} : ${data['houseNo']}',
                    style: TextStyle(color: primary, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    height: 24,
                    child: RoundButton(
                      icon: Icons.edit,
                      iconSize: 14,
                      title:  l10n?.edit ?? 'Edit',
                      color: AppColors.primary,
                      borderRadius: 4,
                      height: 44,
                      fontSize: 14,
                      onPress: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddNewFamilyHeadScreen(
                              isEdit: true,
                              initial: {
                                'houseNo': data['houseNo'],
                                'name': data['name'],
                                'mobile': data['mobile'],
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.thName ?? 'Name', data['name'])),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.mobileLabelSimple ?? 'Mobile no.', data['mobile'])),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.rnhTotalMembers ?? 'No. of total members', data['totalMembers'].toString())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.eligibleCouples ?? 'Eligible couples', data['eligibleCouples'].toString())),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.pregnantWomen ?? 'Pregnant women', data['pregnantWomen'].toString())),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.elderlyAbove65 ?? 'Elderly (>65 Y)', data['elderly'].toString())),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.children0to1 ?? '0-1 year old children', data['child0to1'].toString())),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.children1to2 ?? '1-2 year old children', data['child1to2'].toString())),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.children2to5 ?? '2-5 year old children', data['child2to5'].toString())),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
