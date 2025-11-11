import 'dart:convert';
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

    // Create a map to store head and spouse info by household_ref_key for linking
    final householdMap = <String, Map<String, dynamic>>{};

    // Create a map for quick lookup of beneficiaries by unique_key
    final beneficiaryMap = <String, Map<String, dynamic>>{};

    // First pass: collect all records and organize by household
    for (final row in rows) {
      final hhId = row['household_ref_key']?.toString() ?? '';
      if (hhId.isEmpty) continue;

      final info = row['beneficiary_info'] is String
          ? jsonDecode(row['beneficiary_info'] as String)
          : (row['beneficiary_info'] as Map?) ?? {};

      if (info is! Map) continue;

      final relation = (info['relation']?.toString().toLowerCase() ??
          info['relation_to_head']?.toString().toLowerCase() ?? '');

      // Store in beneficiary map for quick lookup
      final uniqueKey = row['unique_key']?.toString() ?? '';
      if (uniqueKey.isNotEmpty) {
        beneficiaryMap[uniqueKey] = {
          'row': row,
          'info': info,
          'relation': relation,
          'spouse_key': row['spouse_key']?.toString(),
          'name': info['headName'] ?? info['memberName'] ?? info['name'] ?? ''
        };
      }

      if (!householdMap.containsKey(hhId)) {
        householdMap[hhId] = {
          'head': null,
          'spouse': null,
          'children': [],
          'rows': [],
        };
      }

      householdMap[hhId]!['rows'].add({'row': row, 'info': info, 'relation': relation});

      if (relation == 'head' || relation == 'self') {
        householdMap[hhId]!['head'] = {'row': row, 'info': info};
      } else if (relation == 'spouse') {
        householdMap[hhId]!['spouse'] = {'row': row, 'info': info};
      } else if (relation == 'child') {
        householdMap[hhId]!['children'].add({'row': row, 'info': info});
      }
    }

    // Second pass: build beneficiary cards
    for (final hhId in householdMap.keys) {
      final household = householdMap[hhId]!;
      final headData = household['head'] as Map?;
      final spouseData = household['spouse'] as Map?;
      final childrenList = household['children'] as List;

      // Add head card
      if (headData != null) {
        final row = headData['row'] as Map<String, dynamic>;
        final info = headData['info'] as Map<String, dynamic>;
        final createdDate = row['created_date_time']?.toString() ?? '';
        final gender = (info['gender']?.toString().toLowerCase() ?? '');
        final isFemale = gender == 'female' || gender == 'f';
        final richId = info['RichIDChanged']?.toString() ?? info['richIdChanged']?.toString() ?? '';

        // Find spouse name if exists
        String spouseName = '';
        String spouseGender = '';
        final spouseKey = row['spouse_key']?.toString();
        if (spouseKey?.isNotEmpty == true && beneficiaryMap.containsKey(spouseKey)) {
          final spouse = beneficiaryMap[spouseKey]!;
          spouseName = spouse['name']?.toString() ?? '';
          spouseGender = spouse['info']?['gender']?.toString().toLowerCase() ?? '';
        }

        beneficiaries.add({
          'hhId': hhId,
          'RegitrationDate': createdDate,
          'RegitrationType': 'General',
          'BeneficiaryID': (row['unique_key']?.toString().length ?? 0) > 11
              ? row['unique_key'].toString().substring(row['unique_key'].toString().length - 11)
              : (row['unique_key']?.toString() ?? ''),
          'Tola/Mohalla': info['mohalla']?.toString() ?? '',
          'village': info['village']?.toString() ?? '',
          'RichID': richId,
          'Gender': gender,
          'Name': info['headName']?.toString() ?? '',
          'Age|Gender': _formatAgeGender(info['dob'], info['gender']),
          'Mobileno.': info['mobileNo']?.toString() ?? '',
          'WifeName': isFemale ? '' : spouseName, // Only show if head is male
          'HusbandName': isFemale ? spouseName : '', // Only show if head is female
          'SpouseName': spouseName, // Store raw spouse name for reference
          'SpouseGender': spouseGender, // Store spouse gender for reference
          'FatherName': info['fatherName']?.toString() ?? '',
          'Relation': 'Head',
        });
      }

      // Add spouse card
      if (spouseData != null) {
        final row = spouseData['row'] as Map<String, dynamic>;
        final info = spouseData['info'] as Map<String, dynamic>;
        final createdDate = row['created_date_time']?.toString() ?? '';
        final gender = (info['gender']?.toString().toLowerCase() ?? '');
        final isFemale = gender == 'female' || gender == 'f';
        final richId = info['RichIDChanged']?.toString() ?? info['richIdChanged']?.toString() ?? '';
        
        // Find spouse (head) info if exists
        String spouseName = '';
        String spouseGender = '';
        String headVillage = '';
        String headMohalla = '';
        final spouseKey = row['spouse_key']?.toString();
        
        if (spouseKey?.isNotEmpty == true && beneficiaryMap.containsKey(spouseKey)) {
          final spouse = beneficiaryMap[spouseKey]!;
          spouseName = spouse['name']?.toString() ?? '';
          spouseGender = spouse['info']?['gender']?.toString().toLowerCase() ?? '';
          
          // Get village and mohalla from head's data if available
          if (headData != null) {
            final headInfo = headData['info'] as Map<String, dynamic>;
            headVillage = headInfo['village']?.toString() ?? info['village']?.toString() ?? '';
            headMohalla = headInfo['mohalla']?.toString() ?? info['mohalla']?.toString() ?? '';
          }
        }

        beneficiaries.add({
          'hhId': hhId,
          'RegitrationDate': createdDate,
          'RegitrationType': 'General',
          'BeneficiaryID': (row['unique_key']?.toString().length ?? 0) > 11
              ? row['unique_key'].toString().substring(row['unique_key'].toString().length - 11)
              : (row['unique_key']?.toString() ?? ''),
          'Tola/Mohalla': headMohalla.isNotEmpty ? headMohalla : (info['mohalla']?.toString() ?? ''),
          'village': headVillage.isNotEmpty ? headVillage : (info['village']?.toString() ?? ''),
          'RichID': richId,
          'Gender': gender,
          'Name': info['memberName']?.toString() ?? '',
          'Age|Gender': _formatAgeGender(info['dob'], info['gender']),
          'Mobileno.': info['mobileNo']?.toString() ?? '',
          'FatherName': info['fatherName']?.toString() ?? 'Not Available',
          'HusbandName': isFemale ? spouseName : '', // Only show if spouse is female
          'WifeName': isFemale ? '' : spouseName,    // Only show if spouse is male
          'SpouseName': spouseName, // Store raw spouse name for reference
          'SpouseGender': spouseGender, // Store spouse gender for reference
          'Relation': 'Spouse',
        });
      }

      // Add children cards
      for (final childData in childrenList) {
        final row = childData['row'] as Map<String, dynamic>;
        final info = childData['info'] as Map<String, dynamic>;
        final createdDate = row['created_date_time']?.toString() ?? '';
        final gender = (info['gender']?.toString().toLowerCase() ?? '');
        final isFemale = gender == 'female' || gender == 'f';
        final richId = info['RichIDChanged']?.toString() ?? info['richIdChanged']?.toString() ?? '';

        // Find father's name for child
        String fatherName = info['fatherName']?.toString() ?? '';

        // If father's name is not directly available, try to find from head of household
        if (fatherName.isEmpty) {
          // Get head of household
          final head = householdMap[hhId]?['head'];
          if (head != null && head['info'] is Map) {
            final headInfo = head['info'] as Map;
            // Only set father's name if head is male
            if (headInfo['gender']?.toString().toLowerCase() == 'male') {
              fatherName = headInfo['headName']?.toString() ?? '';
            }
          }
        }

        beneficiaries.add({
          'hhId': hhId,
          'RegitrationDate': createdDate,
          'RegitrationType': 'Child',
          'BeneficiaryID': (row['unique_key']?.toString().length ?? 0) > 11
              ? row['unique_key'].toString().substring(row['unique_key'].toString().length - 11)
              : (row['unique_key']?.toString() ?? ''),
          'Tola/Mohalla': info['mohalla']?.toString() ?? '',
          'village': info['village']?.toString() ?? '',
          'RichID': richId,
          'Gender': gender,
          'Name': info['name']?.toString() ?? '',
          'Age|Gender': _formatAgeGender(info['dob'], info['gender']),
          'Mobileno.': info['mobileNo']?.toString() ?? '',
          'WifeName': '',
          'HusbandName': '',
          'FatherName': fatherName,
          'Relation': 'Child',
        });
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

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    // Get gender and registration type
    final gender = (data['Gender']?.toString().toLowerCase() ?? '');
    final isFemale = gender == 'female' || gender == 'f';
    final isChild = data['RegitrationType']?.toString().toLowerCase() == 'child';

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
                        // Show RCH ID only if Female AND Child registration type
                        _rowText('RCH ID', (isFemale && isChild)
                            ? (data['RichID']?.isNotEmpty == true ? data['RichID'] : 'Not Available')
                            : 'N/A'),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        _rowText(l10n?.thName ?? 'Name', data['Name']?.isNotEmpty == true ? data['Name'] : 'Not Available'),
                        _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender']?.isNotEmpty == true ? data['Age|Gender'] : 'Not Available'),
                        _rowText(l10n?.mobileLabelSimple ?? 'Mobile No.', data['Mobileno.']?.isNotEmpty == true ? data['Mobileno.'] : 'Not Available'),
                      ]),
                      const SizedBox(height: 8),
                      _buildRow([
                        // For Child registration type - show Father Name instead of Husband/Wife
                        if (isChild)
                          _rowText('Father Name', data['FatherName']?.isNotEmpty == true && data['FatherName'] != 'Not Available' ? data['FatherName'] : 'Not Available')
                        else ...[
                          // Show appropriate spouse/head name based on relationship and gender
                          if (data['SpouseName']?.isNotEmpty == true)
                            _rowText(
                              data['SpouseGender'] == 'female' ? 'Wife Name' : 'Husband Name',
                              data['SpouseName']
                            )
                          else
                            _rowText(data['Relation'] == 'Head' 
                              ? (data['Gender']?.toString().toLowerCase() == 'male' ? 'Wife Name' : 'Husband Name')
                              : (data['Gender']?.toString().toLowerCase() == 'female' ? 'Husband Name' : 'Wife Name'),
                              'Not Available'
                            ),
                        ],
                        // Always fill remaining columns for layout
                        for (int i = 0; i < 2; i++) _rowText('', ''),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),


        // Show CBAC button only for age 30 or older
        if (_isEligibleForCBAC(data['Age|Gender'] as String))
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

  bool _isEligibleForCBAC(String ageGender) {
    try {
      final ageStr = ageGender.split(' ').first;
      final age = int.tryParse(ageStr) ?? 0;
      return age >= 30;
    } catch (e) {
      debugPrint('Error checking CBAC eligibility: $e');
      return false;
    }
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