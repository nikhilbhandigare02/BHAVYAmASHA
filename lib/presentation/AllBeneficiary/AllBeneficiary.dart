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

import '../../data/Local_Storage/local_storage_dao.dart';
import '../HomeScreen/HomeScreen.dart';

class AllBeneficiaryScreen extends StatefulWidget {
  const AllBeneficiaryScreen({super.key});

  @override
  State<AllBeneficiaryScreen> createState() => _AllBeneficiaryScreenState();
}

class _AllBeneficiaryScreenState extends State<AllBeneficiaryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  late List<Map<String, dynamic>> _filtered;
  List<Map<String, dynamic>> _allBeneficiaries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearchChanged);
  }
  
  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    final beneficiaries = <Map<String, dynamic>>[];
    // Fetch all rows from the beneficiaries table
    final rows = await LocalStorageDao.instance.getAllBeneficiaries();
    for (final row in rows) {
      final hhId = row['household_ref_key']?.toString() ?? '';
      final createdDate = row['created_date_time']?.toString() ?? '';
      final regType = 'General';
      final beneficiaryId = row['id']?.toString() ?? '';
      final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
      final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
      final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? const {});
      // Head
      if (head.isNotEmpty) {
        final gender = (head['gender']?.toString().toLowerCase() ?? '');
        final isFemale = gender == 'female' || gender == 'f';
        final isChild = regType.toLowerCase() == 'child';
        final richId = head['RichIDChanged']?.toString() ?? head['richIdChanged']?.toString() ?? '';
        beneficiaries.add({
          'hhId': hhId,
          'RegitrationDate': createdDate,
          'RegitrationType': regType,
          'BeneficiaryID': beneficiaryId,
          'Tola/Mohalla': head['mohalla']?.toString() ?? '',
          'village': head['village']?.toString() ?? '',
          'RichID': (isFemale || isChild) ? richId : '',
          'Name': head['headName']?.toString() ?? '',
          'Age|Gender': _formatAgeGender(head['dob'], head['gender']),
          'Mobileno.': head['mobileNo']?.toString() ?? '',
          'FatherName': (head['fatherName']?.toString()?.isNotEmpty ?? false) ? head['fatherName'] : 'Not Available',
          'HusbandName': '',
          'WifeName': (spouse['memberName']?.toString()?.isNotEmpty ?? false) ? spouse['memberName'] : 'Not Available',
          'Relation': 'Head',
        });
      }
      // Spouse
      if (spouse.isNotEmpty) {
        final gender = (spouse['gender']?.toString().toLowerCase() ?? '');
        final isFemale = gender == 'female' || gender == 'f';
        final isChild = regType.toLowerCase() == 'child';
        final richId = spouse['RichIDChanged']?.toString() ?? spouse['richIdChanged']?.toString() ?? '';
        beneficiaries.add({
          'hhId': hhId,
          'RegitrationDate': createdDate,
          'RegitrationType': regType,
          'BeneficiaryID': beneficiaryId,
          'Tola/Mohalla': spouse['mohalla']?.toString() ?? '',
          'village': spouse['village']?.toString() ?? '',
          'RichID': (isFemale || isChild) ? richId : '',
          'Name': spouse['memberName']?.toString() ?? '',
          'Age|Gender': _formatAgeGender(spouse['dob'], spouse['gender']),
          'Mobileno.': spouse['mobileNo']?.toString() ?? '',
          'FatherName': (spouse['fatherName']?.toString()?.isNotEmpty ?? false) ? spouse['fatherName'] : 'Not Available',
          'HusbandName': (spouse['spouseName']?.toString()?.isNotEmpty ?? false) ? spouse['spouseName'] : (head['headName']?.toString()?.isNotEmpty ?? false) ? head['headName'] : 'Not Available',
          'WifeName': '',
          'Relation': 'Spouse',
        });
      }

      final children = (head['childrenDetails'] as List?) ?? [];
      for (final child in children) {
        if (child is Map) {
          final gender = (child['gender']?.toString().toLowerCase() ?? '');
          final isFemale = gender == 'female' || gender == 'f';
          final isChild = true;
          final richId = child['RichIDChanged']?.toString() ?? child['richIdChanged']?.toString() ?? '';
          beneficiaries.add({
            'hhId': hhId,
            'RegitrationDate': createdDate,
            'RegitrationType': regType,
            'BeneficiaryID': beneficiaryId,
            'Tola/Mohalla': child['mohalla']?.toString() ?? '',
            'village': child['village']?.toString() ?? '',
            'RichID': (isFemale || isChild) ? richId : '',
            'Name': child['name']?.toString() ?? '',
            'Age|Gender': _formatAgeGender(child['dob'], child['gender']),
            'Mobileno.': child['mobileNo']?.toString() ?? '',
            'FatherName': (child['fatherName']?.toString()?.isNotEmpty ?? false) ? child['fatherName'] : (head['headName']?.toString()?.isNotEmpty ?? false) ? head['headName'] : 'Not Available',
            'ChildName': child['name']?.toString() ?? 'Not Available',
            'HusbandName': '',
            'WifeName': '',
            'Relation': 'Child',
          });
          // Add a father card for each child if needed
          beneficiaries.add({
            'hhId': hhId,
            'RegitrationDate': createdDate,
            'RegitrationType': regType,
            'BeneficiaryID': beneficiaryId,
            'Tola/Mohalla': head['mohalla']?.toString() ?? '',
            'village': head['village']?.toString() ?? '',
            'RichID': '',
            'Name': head['headName']?.toString() ?? '',
            'Age|Gender': _formatAgeGender(head['dob'], head['gender']),
            'Mobileno.': head['mobileNo']?.toString() ?? '',
            'FatherName': (head['fatherName']?.toString()?.isNotEmpty ?? false) ? head['fatherName'] : 'Not Available',
            'ChildName': child['name']?.toString() ?? 'Not Available',
            'HusbandName': '',
            'WifeName': '',
            'Relation': 'Father',
          });
        }
      }
    }
    if (mounted) {
      setState(() {
        _allBeneficiaries = beneficiaries;
        _filtered = List<Map<String, dynamic>>.from(_allBeneficiaries);
        _isLoading = false;
      });
    }
  }

  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) { 
    String age = 'N/A';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');
    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      DateTime? dob;
      try {
        dob = DateTime.tryParse(dobRaw.toString());
      } catch (_) {}
      if (dob != null) {
        age = '${DateTime.now().difference(dob).inDays ~/ 365}';
      }
    }
    String displayGender = gender == 'm' || gender == 'male'
        ? 'Male'
        : gender == 'f' || gender == 'female'
            ? 'Female'
            : 'Other';
    return '$age Y | $displayGender';
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
        _filtered = List<Map<String, dynamic>>.from(_allBeneficiaries);
      } else {
        _filtered = _allBeneficiaries.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['village']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Tola/Mohalla']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['BeneficiaryID']?.toString().toLowerCase() ?? '').contains(q);
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
        icon2Image: 'assets/images/home.png',
        onIcon2Tap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
// Pass the count to AshaDashboardSection
// Example usage:
// AshaDashboardSection(allBeneficiaryCount: _allBeneficiaries.length,allBeneficiaryCount: _allBeneficiaries.length)

      body: _isLoading
          ? const CenterBoxLoader()
          : Column(
              children: [
                Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:  l10n!.searchBeneficiaries,
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
                          (data['hhId']?.toString().length ?? 0) > 11 ? data['hhId'].toString().substring(data['hhId'].toString().length - 11) : (data['hhId'] ?? ''),
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
                        _rowText('RCH ID', (data['Age|Gender']?.toString().toLowerCase().contains('male') ?? false) ? 'Not Available' : (data['RichID']?.isNotEmpty == true ? data['RichID'] : 'Not Available')),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        _rowText(l10n?.thName ?? 'Name', data['Name']?.isNotEmpty == true ? data['Name'] : 'Not Available'),
                        _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender']?.isNotEmpty == true ? data['Age|Gender'] : 'Not Available'),
                        _rowText(l10n?.mobileLabelSimple ?? 'Mobile No.', data['Mobileno.']?.isNotEmpty == true ? data['Mobileno.'] : 'Not Available'),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        // Wife name on head's card if spouse is wife
                        if (data['Relation']?.toString().toLowerCase() == 'head')
                          _rowText('Wife Name', data['WifeName']?.isNotEmpty == true ? data['WifeName'] : 'Not Available'),
                        // Husband name on spouse card if spouse is husband
                        if (data['Relation']?.toString().toLowerCase() == 'spouse')
                          _rowText('Husband Name', data['HusbandName']?.isNotEmpty == true ? data['HusbandName'] : 'Not Available'),
                        // Father name on child card (only if available)
                        if (data['Relation']?.toString().toLowerCase() == 'child' && data['FatherName']?.isNotEmpty == true && data['FatherName'] != 'Not Available')
                          _rowText('Father Name', data['FatherName']),
                        // Child name on father card (if available)
                        if (data['Relation']?.toString().toLowerCase() == 'father')
                          _rowText('Child Name', data['ChildName']?.isNotEmpty == true ? data['ChildName'] : 'Not Available'),
                        // Always fill to 3 columns for layout
                        for (int i = 0; i < 3 - [
                          if (data['Relation']?.toString().toLowerCase() == 'head') 1,
                          if (data['Relation']?.toString().toLowerCase() == 'spouse') 1,
                          if (data['Relation']?.toString().toLowerCase() == 'child' && data['FatherName']?.isNotEmpty == true && data['FatherName'] != 'Not Available') 1,
                          if (data['Relation']?.toString().toLowerCase() == 'father') 1,
                        ].length; i++) _rowText('', ''),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),


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
