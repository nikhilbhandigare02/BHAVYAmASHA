import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:medixcel_new/core/widgets/Loader/Loader.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';

import '../HomeScreen/HomeScreen.dart';

class AllBeneficiaryScreen extends StatefulWidget {
  const AllBeneficiaryScreen({super.key});

  @override
  State<AllBeneficiaryScreen> createState() => _AllBeneficiaryScreenState();
}

class _AllBeneficiaryScreenState extends State<AllBeneficiaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  final List<Map<String, dynamic>> _staticHouseholds = [
    {
      'hhId': '51016121847',
      'RegitrationDate': '16-10-2025',
      'RegitrationType': 'General',
      'BeneficiaryID': '8347683437',
      'Tola/Mohalla': 'Shivpuri',
      'village': 'Rampur',
      'RichID': 'RCH123456',
      'Name': 'Rohit Sharma',
      'Age|Gender': '27 Y | Male',
      'Mobileno.': '9876543210',
      'FatherName': 'Rajesh Sharma',
      'HusbandName': '',
      'WifeName': 'Anjali Sharma',
    },
    {
      'hhId': '51016121848',
      'RegitrationDate': '18-10-2025',
      'RegitrationType': 'Special',
      'BeneficiaryID': '8347683438',
      'Tola/Mohalla': 'Gandhi Nagar',
      'village': 'Mohanpur',
      'RichID': 'RCH987654',
      'Name': 'Priya Verma',
      'Age|Gender': '25 Y | Female',
      'Mobileno.': '9998887776',
      'FatherName': 'Vinod Verma',
      'HusbandName': 'Ravi Verma',
      'WifeName': '',
    },
  ];

  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearchChanged);
  }
  
  Future<void> _loadData() async {
    // Simulate network/database delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _filtered = List<Map<String, dynamic>>.from(_staticHouseholds);
        _isLoading = false;
      });
    }
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
        screenTitle: l10n?.householdBeneficiaryTitle ?? 'Household Beneficiary',
        showBack: false,
        icon2: Icons.home,
        onIcon2Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const CenterBoxLoader()
          : Column(
              children: [
                Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:  'Search All Beneficiary',
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

          // ➕ Add New Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: RoundButton(
                  title: (l10n?.gridRegisterNewHousehold ?? 'Add New Household').toUpperCase(),
                  color: AppColors.primary,
                  borderRadius: 8,
                  height: 45,
                  onPress: () {
                    Navigator.pushNamed(context, Route_Names.addFamilyHead);
                  },
                ),
              ),
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
                            fontSize: 14.sp
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
                        _rowText(l10n?.villageLabel ?? 'Village', data['village']),
                        _rowText(l10n?.mohallaTolaNameLabel ?? 'Tola/Mohalla', data['Tola/Mohalla']),
                        _rowText('RCH ID', data['RichID']),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        _rowText(l10n?.thName ?? 'Name', data['Name']),
                        _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender']),
                        _rowText(l10n?.mobileLabelSimple ?? 'Mobile No.', data['Mobileno.']),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        _rowText(l10n?.fatherNameLabel ?? 'Father Name', data['FatherName']),
                        _rowText( 'Husband Name', data['HusbandName']),
                        _rowText( 'Wife Name', data['WifeName']),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // CBAC Button
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 6, bottom: 8),
          child: SizedBox(
            height: 32,
            child: RoundButton(
              title: l10n!.cbac,
              color: AppColors.primary,
              borderRadius: 6,
              width: 100,
              onPress: () {
                Navigator.pushNamed(context, Route_Names.cbacScreen);
              },
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
          style:  TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? 'N/A' : value,
          style:  TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500, fontSize: 14.sp,

          ),
        ),
      ],
    );
  }

}
