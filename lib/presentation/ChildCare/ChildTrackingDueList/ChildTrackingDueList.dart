import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

class CHildTrackingDueList extends StatefulWidget {
  const CHildTrackingDueList({super.key});

  @override
  State<CHildTrackingDueList> createState() => _CHildTrackingDueListState();
}

class _CHildTrackingDueListState extends State<CHildTrackingDueList> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _staticHouseholds = [
    {
      'hhId': '51016121847',
      'RegitrationDate': '16-10-2025',
      'RegitrationType': 'General',
      'BeneficiaryID': '8347683437',

      'RchID': 'RCH123456',
      'Name': 'Rohit Sharma',
      'Age|Gender': '27 Y | Male',
      'Mobileno.': '9876543210',
      'FatherName': 'Rajesh Sharma',

    },
    {
      'hhId': '51016121847',
      'RegitrationDate': '16-10-2025',
      'RegitrationType': 'General',
      'BeneficiaryID': '8347683437',

      'RchID': 'RCH123456',
      'Name': 'Rohit Sharma',
      'Age|Gender': '27 Y | Male',
      'Mobileno.': '9876543210',
      'FatherName': 'Rajesh Sharma',
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
              (e['Name'] as String).toLowerCase().contains(q) ||
              (e['Mobileno.'] as String).toLowerCase().contains(q) ||
              (e['village'] as String).toLowerCase().contains(q) ||
              (e['Tola/Mohalla'] as String).toLowerCase().contains(q) ||
              (e['BeneficiaryID'] as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle:  l10n?.childTrackingDueListTitle ?? 'Child Tracking\nDue List',
        showBack: true,

      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:  l10n?.searchHint ?? 'Search All Beneficiary',
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



          // 📋 List of Households
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


        ],
      ),
    );
  }

  // 🧱 Household Card UI
  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              Route_Names.addFamilyMember,
              arguments: {'isBeneficiary': true},
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 2,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                  padding: const EdgeInsets.all(6),
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

                // Card Body
                Container(
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow([
                        _rowText(l10n?.registrationDateLabel ?? 'Registration Date', data['RegitrationDate']),
                        _rowText(l10n?.registrationTypeLabel ?? 'Registration Type', data['RegitrationType']),
                        _rowText(l10n?.beneficiaryIdLabel ?? 'Beneficiary ID', data['BeneficiaryID']),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        _rowText(l10n?.nameLabelSimple ?? 'Name', data['Name']),
                        _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender']),
                        _rowText(l10n?.rchIdLabel ?? 'RCH ID', data['RchID']),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        _rowText(l10n?.fatherNameLabel ?? 'Father Name', data['FatherName']),

                        _rowText(l10n?.mobileLabelSimple ?? 'Mobile No.', data['Mobileno.']),
                      ]),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),


      ],
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 10),
        ]
      ],
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
          value.isEmpty ? (AppLocalizations.of(context)?.notAvailable ?? 'N/A') : value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
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
          style: TextStyle(
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
      ],
    );
  }
}
