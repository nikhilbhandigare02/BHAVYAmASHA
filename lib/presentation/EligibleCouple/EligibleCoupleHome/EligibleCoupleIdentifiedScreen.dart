import 'dart:convert';

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
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../EligibleCoupleUpdate/EligibleCoupleUpdateScreen.dart';

class EligibleCoupleIdentifiedScreen extends StatefulWidget {
  const EligibleCoupleIdentifiedScreen({super.key});

  @override
  State<EligibleCoupleIdentifiedScreen> createState() =>
      _EligibleCoupleIdentifiedScreenState();
}

class _EligibleCoupleIdentifiedScreenState
    extends State<EligibleCoupleIdentifiedScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEligibleCouples();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // Helper function to safely convert dynamic Map to Map<String, dynamic>
  Map<String, dynamic> _toStringMap(dynamic map) {
    if (map == null) return {};
    if (map is Map<String, dynamic>) return map;
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    return {};
  }

  Future<void> _loadEligibleCouples() async {
    setState(() { _isLoading = true; });
    final rows = await LocalStorageDao.instance.getAllBeneficiaries();
    final couples = <Map<String, dynamic>>[];

    final households = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final hhKey = row['household_ref_key']?.toString() ?? '';
      households.putIfAbsent(hhKey, () => []).add(row);
    }

    for (final household in households.values) {
      Map<String, dynamic>? head;
      Map<String, dynamic>? spouse;

      for (final member in household) {
        final info = _toStringMap(member['beneficiary_info']);
        String rawRelation =
            (info['relation_to_head'] ?? info['relation'])?.toString().toLowerCase().trim() ?? '';
        rawRelation = rawRelation.replaceAll('_', ' ');
        if (rawRelation.endsWith(' w') || rawRelation.endsWith(' h')) {
          rawRelation = rawRelation.substring(0, rawRelation.length - 2).trim();
        }

        final relation = () {
          if (rawRelation == 'self' || rawRelation == 'head' || rawRelation == 'family head') {
            return 'self';
          }
          if (rawRelation == 'spouse' || rawRelation == 'wife' || rawRelation == 'husband') {
            return 'spouse';
          }
          return rawRelation;
        }();

        if (relation == 'self') {
          head = info;
          head['_row'] = _toStringMap(member);
        } else if (relation == 'spouse') {
          spouse = info;
          spouse['_row'] = _toStringMap(member);
        }
      }

      const allowedRelations = <String>{
        'self',
        'spouse',
        'husband',
        'son',
        'daughter',
        'father',
        'mother',
        'brother',
        'sister',
        'wife',
        'nephew',
        'niece',
        'grand father',
        'grand mother',
        'father in law',
        'mother in low',
        'grand son',
        'grand daughter',
        'son in law',
        'daughter in law',
        'other',
      };

      for (final member in household) {
        final info = _toStringMap(member['beneficiary_info']);
        String rawRelation =
            (info['relation_to_head'] ?? info['relation'])?.toString().toLowerCase().trim() ?? '';
        rawRelation = rawRelation.replaceAll('_', ' ');
        if (rawRelation.endsWith(' w') || rawRelation.endsWith(' h')) {
          rawRelation = rawRelation.substring(0, rawRelation.length - 2).trim();
        }

        if (!allowedRelations.contains(rawRelation)) {
          continue;
        }

        // Only consider females 15-49 and married
        if (!_isEligibleFemale(info, head: head)) {
          continue;
        }

        // Decide counterpart and isHead flag
        final bool isHeadRelation =
            rawRelation == 'self' || rawRelation == 'head' || rawRelation == 'family head';
        final bool isSpouseRelation =
            rawRelation == 'spouse' || rawRelation == 'wife' || rawRelation == 'husband';

        final counterpart = () {
          if (isHeadRelation) {
            return spouse ?? <String, dynamic>{};
          }
          if (isSpouseRelation) {
            return head ?? <String, dynamic>{};
          }
          // For other relations, use head as counterpart if available
          return head ?? <String, dynamic>{};
        }();

        couples.add(_formatCoupleData(
          _toStringMap(member),
          info,
          counterpart,
          isHead: isHeadRelation,
        ));
      }
    }

    setState(() {
      _filtered = couples;
      _isLoading = false;
    });
  }

  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;

    // Check gender (case-insensitive)
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final isFemale = genderRaw == 'f' || genderRaw == 'female';
    if (!isFemale) return false;

    // Prefer woman's own marital status, fall back to head's if missing
    final maritalStatusRaw =
        person['maritalStatus']?.toString().toLowerCase() ??
        head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final isMarried = maritalStatusRaw == 'married';
    if (!isMarried) return false;

    // Check age between 15-49
    final dob = person['dob'];
    final age = _calculateAge(dob);
    return age >= 15 && age <= 49;
  }

  Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead}) {
    final hhId = row['household_ref_key']?.toString() ?? '';
    final uniqueKey = row['unique_key']?.toString() ?? '';
    final createdDate = row['created_date_time']?.toString() ?? '';
    final info = _toStringMap(row['beneficiary_info']);
    final head = _toStringMap(info['head_details']);
    final name = female['memberName']?.toString() ?? female['headName']?.toString() ?? '';
    final gender = female['gender']?.toString().toLowerCase();
    final displayGender = gender == 'f' ? 'Female' : gender == 'm' ? 'Male' : 'Other';
    final age = _calculateAge(female['dob']);
    final richId = female['RichID']?.toString() ?? '';
    final mobile = female['mobileNo']?.toString() ?? '';
    final husbandName = isHead
        ? (headOrSpouse['memberName']?.toString() ?? headOrSpouse['spouseName']?.toString() ?? '')
        : (headOrSpouse['headName']?.toString() ?? headOrSpouse['memberName']?.toString() ?? '');

    final dynamic childrenRaw = info['children_details'] ?? head['childrendetails'] ?? head['childrenDetails'];
    String last11(String s) => s.length > 11 ? s.substring(s.length - 11) : s;

    Map<String, dynamic>? childrenSummary;
    if (childrenRaw != null) {
      final childrenMap = _toStringMap(childrenRaw);
      childrenSummary = {
        'totalBorn': childrenMap['totalBorn'],
        'totalLive': childrenMap['totalLive'],
        'totalMale': childrenMap['totalMale'],
        'totalFemale': childrenMap['totalFemale'],
        'youngestAge': childrenMap['youngestAge'],
        'ageUnit': childrenMap['ageUnit'],
        'youngestGender': childrenMap['youngestGender'],
      }..removeWhere((k, v) => v == null);
    }
    return {
      'hhId': hhId,
      'hhIdShort': last11(hhId),
      'RegistrationDate': _formatDate(createdDate),
      'RegistrationType': 'General',
      'BeneficiaryID': uniqueKey,
      'BeneficiaryIDShort': last11(uniqueKey) ,
      'Name': name,
      'age': age > 0 ? '$age Y / $displayGender' : 'N/A',
      'RichID': richId,
      'mobileno': mobile,
      'HusbandName': husbandName,
      'childrenSummary': childrenSummary,
      '_rawRow': row,
      'fullHhId': hhId,
      'fullBeneficiaryId': uniqueKey,
    };
  }

  int _calculateAge(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (_) {
      return 0;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _loadEligibleCouples();
      } else {
        _filtered = _filtered.where((e) {
          return ((e['hhId'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['Name'] ?? '') as String).toLowerCase().contains(q) ||
              ((e['mobileno'] ?? '') as String).toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppHeader(
          screenTitle: l10n?.updatedEligibleCoupleListSubtitle ?? 'Eligible Couple List',
          showBack: false,
          icon1Image: 'assets/images/home.png',

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
                  hintText: l10n?.searchEligibleCouple ?? 'search Eligible Couple',
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

          ],
        ),
      ),
    );
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;
    final t = AppLocalizations.of(context);

    final rowData = data['_rawRow'] ?? {};
    final beneficiaryInfo = rowData['beneficiary_info'] is String
        ? jsonDecode(rowData['beneficiary_info'])
        : (rowData['beneficiary_info'] ?? {});

    final headDetails = _toStringMap(beneficiaryInfo['head_details']);
    final spouseDetails = _toStringMap(beneficiaryInfo['spouse_details']);

    final childrenDetails = _toStringMap(
        beneficiaryInfo['children_details'] ??
            headDetails['childrendetails'] ??
            headDetails['childrenDetails']
    );

    return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () async {

            final fullHhId = rowData['household_ref_key']?.toString() ?? '';
            final fullBeneficiaryId = rowData['unique_key']?.toString() ??
                data['fullBeneficiaryId']?.toString() ??
                data['BeneficiaryID']?.toString() ?? '';
            final name = data['Name']?.toString() ?? '';
            final richId = data['RichID']?.toString() ?? '';
            final mobile = data['mobileno']?.toString() ?? '';
            final husbandName = data['HusbandName']?.toString() ?? '';
            final ageGender = data['age']?.toString() ?? '';
            final registrationDate = data['RegistrationDate']?.toString() ?? '';

            print('🚀 Navigating to update screen with:');
            print('   Household ID (full): $fullHhId');
            print('   Beneficiary ID (full): $fullBeneficiaryId');
            print('   Name: $name');

            final result = await Navigator.pushNamed(
              context,
              Route_Names.UpdatedEligibleCoupleList,
              arguments: {
                'hhId': fullHhId,
                'name': name,

                'unique_key': fullBeneficiaryId,
                'RichID': richId,
                'mobile': mobile,
                'husbandName': husbandName,
                'ageGender': ageGender,
                'registrationDate': registrationDate,
                'formData': data,
              },
            );


            if (result == true) {
              _loadEligibleCouples();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 0),
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
                          data['hhIdShort'] ?? data['hhId'] ?? '',
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
                          Expanded(child: _rowText('Registration Date', data['RegistrationDate'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Registration Type', data['RegistrationType'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Beneficiary ID', data['BeneficiaryIDShort'] ?? data['BeneficiaryID'] ?? '')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _rowText(  'Name', data['Name'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText( 'Age', data['age']?.toString() ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Rich ID', data['RichID']?.toString() ?? '')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: _rowText( 'Mobile No.', data['mobileno']?.toString() ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: SizedBox.shrink()),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _rowText('Husband Name', data['HusbandName'] ?? '')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
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