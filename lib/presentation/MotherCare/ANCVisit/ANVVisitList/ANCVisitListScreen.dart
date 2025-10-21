import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';


import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';

import '../../../../core/config/routes/Route_Name.dart';
import '../../../../core/config/themes/CustomColors.dart';
import '../../../../core/widgets/AppDrawer/Drawer.dart';


class Ancvisitlistscreen extends StatefulWidget {
  const Ancvisitlistscreen({super.key});

  @override
  State<Ancvisitlistscreen> createState() => _AncvisitlistscreenState();
}

class _AncvisitlistscreenState extends State<Ancvisitlistscreen> {
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
        screenTitle: 'ANC Visit List',
        showBack: true,
        icon1: Icons.refresh,
        onIcon1Tap: () => setState(() {}),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ANC Visit Search',
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
                return _ancCard(context, data);
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _ancCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(context, Route_Names.Ancvisitform);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header strip
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.home, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(
                        data['hhId'] ?? '',
                        style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Visits : 0',
                    style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 25,
                    child: Image.asset('assets/images/sync.png'),
                  )
                ],
              ),
            ),

            // Blue body
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _rowText('Beneficiary ID', data['hhId'] ?? '')),
                      Expanded(child: _rowText('Name', data['name'] ?? '')),
                      Expanded(child: _rowText('Age', 'Not Available')),
                      Expanded(child: _rowText('Husband', 'Not Available')),
                      Expanded(child: _rowText('Registration Date', 'Not Available')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _rowText('RCH ID', 'Not Available')),
                      Expanded(child: _rowText('First ANC', 'Not Available')),
                      Expanded(child: _rowText('Second ANC', 'Not Available')),
                      Expanded(child: _rowText('Third ANC', 'Not Available')),
                      Expanded(child: _rowText('PMSMA', 'Not Available')),
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
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }

}
