import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';

import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class HouseHold_BeneficiaryScreen extends StatefulWidget {
  const HouseHold_BeneficiaryScreen({super.key});

  @override
  State<HouseHold_BeneficiaryScreen> createState() =>
      _HouseHold_BeneficiaryScreenState();
}

class _HouseHold_BeneficiaryScreenState
    extends State<HouseHold_BeneficiaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _staticHouseholds = [
    {
      'hhId': '51016121847',

      'RegitrationDate': '16-10-2025',
      'RegitrationType': 'General',
      'BeneficiaryID': '8347683437',
      'Name': 0,
      'Age|Gender': '19 Y | Male',
      'Mobileno.': '1365124512',
      'FatherName': 'flagyht ujy',
    },
    {
      'hhId': '510161265767',

      'RegitrationDate': '16-10-2025',
      'RegitrationType': 'General',
      'BeneficiaryID': '83476834477',
      'Name': 0,
      'Age|Gender': '19 Y | Male',
      'Mobileno.': '1365124512',
      'FatherName': 'flagyht ujy',
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
        screenTitle: l10n?.householdBeneficiaryTitle ?? 'Household Beneficiary',
        showBack: true,
        icon1: CupertinoIcons.arrow_left_right,
        onIcon1Tap: () => Navigator.pushNamed(context, Route_Names.homeScreen),
        icon2: Icons.home,
        onIcon2Tap: () => Navigator.pushNamed(context, Route_Names.homeScreen),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.householdBeneficiarySearch ?? 'Household Beneficiary Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoColumn(l10n?.villageLabel ?? 'Village', l10n?.notAvailable ?? 'Not Available'),
                  _infoColumn(l10n?.mohallaTolaNameLabel ?? 'Tola/Mohalla', l10n?.notAvailable ?? 'Not Available'),
                ],
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 35,
                child: RoundButton(
                  title: (l10n?.addNewBeneficiaryButton ?? 'Add New Beneficiary').toUpperCase(),
                  color: AppColors.primary,
                  borderRadius: 8,
                  height: 50,
                  onPress: () {
                    Navigator.pushNamed(context, Route_Names.addFamilyMember);

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
          Route_Names.addFamilyMember,
          arguments: {
            'isBeneficiary': true,
          },
        );
      },
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
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data['hhId'] ?? '',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/sync.png',
                      width: 25,
                      height: 25,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.registrationDateLabel ?? 'Registration Date',
                          data['RegitrationDate'],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _rowText(
                          l10n?.registrationTypeLabel ?? 'Registration Type',
                          data['RegitrationType'],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          data['BeneficiaryID'].toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.thName ?? 'Name', data['Name'].toString())),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _rowText(
                          l10n?.ageGenderLabel ?? 'Age | Gender',
                          data['Age|Gender'].toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _rowText(
                          l10n?.mobileLabelSimple ?? 'Mobile no.',
                          data['Mobileno'].toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.fatherNameLabel ?? 'Father Name',
                          data['FatherName'].toString(),
                        ),
                      ),
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  Widget _infoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: 13,
            color: AppColors.background,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
        const SizedBox(height: 0),

      ],
    );
  }
}
