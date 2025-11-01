import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/widgets/AppDrawer/Drawer.dart';
import '../../HomeScreen/HomeScreen.dart';

class EligibleCoupleIdentifiedScreen extends StatefulWidget {
  const EligibleCoupleIdentifiedScreen({super.key});

  @override
  State<EligibleCoupleIdentifiedScreen> createState() =>
      _EligibleCoupleIdentifiedScreenState();
}

class _EligibleCoupleIdentifiedScreenState
    extends State<EligibleCoupleIdentifiedScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _staticHouseholds = [
    {
      'hhId': 'HH001',
      'houseNo': '12A',
      'RegistrationDate': '10-10-2025',
      'RegistrationType': 'ga',
      'BeneficiaryID': 'VA001',
      'Name': 'Rohit Chavan',
      'age': 30,
      'RichID': 123,
      'mobileno': '9923175398',
      'HusbandName': 'Rajesh Chavan',
    },
    {
      'hhId': 'HH002',
      'houseNo': '15B',
      'RegistrationDate': '11-10-2025',
      'RegistrationType': 'ga',
      'BeneficiaryID': 'VA002',
      'Name': 'Suresh Patil',
      'age': 28,
      'RichID': 124,
      'mobileno': '9876543210',
      'HusbandName': 'Mahesh Patil',
    },
    // Add more sample entries if needed
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
          return ((e['hhId'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['houseNo'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['Name'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['mobileno'] ?? '') as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.updatedEligibleCoupleListTitle ?? 'Eligible Couple List',
        showBack: false,
        icon1: Icons.home,
        onIcon1Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.gridAllHousehold ?? 'All Household',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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

          // Household List
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

          // Bottom Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: RoundButton(
                  title: l10n?.gridRegisterNewHousehold
                      .toUpperCase() ??
                      'NEW HOUSEHOLD REGISTRATION',
                  color: AppColors.primary,
                  borderRadius: 8,
                  onPress: () {
                    Navigator.pushNamed(
                        context, Route_Names.RegisterNewHousehold);
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
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Route_Names.UpdatedEligibleCoupleList,
          arguments: data,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
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
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    height: 24,
                    child: Image.asset('assets/images/sync.png'),
                  ),
                ],
              ),
            ),
            // Body
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.registrationDateLabel ?? 'Registration Date', data['RegistrationDate'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.registrationTypeLabel ?? 'Registration Type', data['RegistrationType'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.beneficiaryIdLabel ?? 'Beneficiary ID', data['BeneficiaryID'] ?? '')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.nameOfMemberLabel ?? 'Name', data['Name'] ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.ageLabelSimple ?? 'Age', data['age']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('Rich ID', data['RichID']?.toString() ?? '')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _rowText(l10n?.mobileLabelSimple ?? 'Mobile No.', data['mobileno']?.toString() ?? '')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _rowText(l10n?.spouseNameLabel ?? 'Husband Name', data['HusbandName'] ?? '')),
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
          style:  TextStyle(color: AppColors.background, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:  TextStyle(color: AppColors.background, fontWeight: FontWeight.w400, fontSize: 13.sp),
        ),
      ],
    );
  }
}
