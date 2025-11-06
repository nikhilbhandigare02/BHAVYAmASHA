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

  Future<void> _loadEligibleCouples() async {
    setState(() { _isLoading = true; });
    final rows = await LocalStorageDao.instance.getAllBeneficiaries();
    final couples = <Map<String, dynamic>>[];
    for (final row in rows) {
      final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
      final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
      final spouse = Map<String, dynamic>.from((head['spousedetails'] as Map?) ?? const {});

      if (_isEligibleFemale(head)) {
        couples.add(_formatCoupleData(row, head, spouse, isHead: true));
      }

      if (spouse.isNotEmpty && _isEligibleFemale(spouse, head: head)) {
        couples.add(_formatCoupleData(row, spouse, head, isHead: false));
      }
    }
    setState(() {
      _filtered = couples;
      _isLoading = false;
    });
  }

  bool _isEligibleFemale(Map<String, dynamic> person, {Map<String, dynamic>? head}) {
    if (person.isEmpty) return false;
    final genderRaw = person['gender']?.toString().toLowerCase() ?? '';
    final maritalStatusRaw = person['maritalStatus']?.toString().toLowerCase() ?? head?['maritalStatus']?.toString().toLowerCase() ?? '';
    final gender = genderRaw == 'f' || genderRaw == 'female';
    final maritalStatus = maritalStatusRaw == 'married';
    final dob = person['dob'];
    final age = _calculateAge(dob);
    return gender && maritalStatus && age >= 15 && age <= 49;
  }

  Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead}) {
    final hhId = row['household_ref_key']?.toString() ?? '';
    final uniqueKey = row['unique_key']?.toString() ?? '';
    final createdDate = row['created_date_time']?.toString() ?? '';
    final info = Map<String, dynamic>.from((row['beneficiary_info'] as Map?) ?? const {});
    final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
    final name = female['memberName']?.toString() ?? female['headName']?.toString() ?? '';
    final gender = female['gender']?.toString().toLowerCase();
    final displayGender = gender == 'f' ? 'Female' : gender == 'm' ? 'Male' : 'Other';
    final age = _calculateAge(female['dob']);
    final richId = female['RichID']?.toString() ?? '';
    final mobile = female['mobileNo']?.toString() ?? '';
    final husbandName = isHead
      ? (headOrSpouse['memberName']?.toString() ?? headOrSpouse['spouseName']?.toString() ?? '')
      : (headOrSpouse['headName']?.toString() ?? headOrSpouse['memberName']?.toString() ?? '');

    // children summary can live at top-level children_details or under head childrendetails/childrenDetails
    final dynamic childrenRaw = info['children_details'] ?? head['childrendetails'] ?? head['childrenDetails'];
    Map<String, dynamic>? childrenSummary;
    if (childrenRaw is Map) {
      childrenSummary = {
        'totalBorn': childrenRaw['totalBorn'],
        'totalLive': childrenRaw['totalLive'],
        'totalMale': childrenRaw['totalMale'],
        'totalFemale': childrenRaw['totalFemale'],
        'youngestAge': childrenRaw['youngestAge'],
        'ageUnit': childrenRaw['ageUnit'],
        'youngestGender': childrenRaw['youngestGender'],
      }..removeWhere((k, v) => v == null);
    }
    return {
      'hhId': hhId.length > 11 ? hhId.substring(hhId.length - 11) : hhId,
      'RegistrationDate': _formatDate(createdDate),
      'RegistrationType': 'General',
      'BeneficiaryID': uniqueKey.length > 11 ? uniqueKey.substring(uniqueKey.length - 11) : uniqueKey,
      'Name': name,
      'age': age > 0 ? '$age Y / $displayGender' : 'N/A',
      'RichID': richId,
      'mobileno': mobile,
      'HusbandName': husbandName,
      'childrenSummary': childrenSummary,
      '_rawRow': row,
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
    return Scaffold(
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
    );
  }

  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);
    final rowData = data['_rawRow'] ?? {};
    final beneficiaryInfo = Map<String, dynamic>.from((rowData['beneficiary_info'] as Map?) ?? {});
    final headDetails = Map<String, dynamic>.from((beneficiaryInfo['head_details'] as Map?) ?? {});
    final spouseDetails = Map<String, dynamic>.from(
      (beneficiaryInfo['spouse_details'] as Map?) ?? {},
    );
    return InkWell(
      onTap: () {
        // Extract children details from either children_details or childrendetails
        final childrenDetails = Map<String, dynamic>.from(
          (beneficiaryInfo['children_details'] as Map? ?? 
           beneficiaryInfo['childrendetails'] as Map? ?? {}),
        );
        
        // Extract head and spouse details with fallbacks
        final headName = headDetails['headName']?.toString() ?? '';
        final spouseName = spouseDetails['memberName']?.toString() ?? 
                          spouseDetails['spouseName']?.toString() ?? '';
        
        // Determine if current card is for head or spouse
        final isHead = (data['Name']?.toString() ?? '').toLowerCase() == headName.toLowerCase();
        final womanName = isHead ? headName : spouseName;
        
        // Calculate current age from DOB if available
        String currentAge = '';
        try {
          final dob = isHead 
              ? headDetails['dob']?.toString() 
              : spouseDetails['dob']?.toString();
          if (dob != null && dob.isNotEmpty) {
            final birthDate = DateTime.tryParse(dob);
            if (birthDate != null) {
              final age = (DateTime.now().difference(birthDate).inDays / 365).floor();
              currentAge = age.toString();
            }
          }
        } catch (e) {
          print('Error calculating age: $e');
        }
        
        // Prepare navigation data with all fields needed for auto-fill
        final navigationData = {
          // Basic info
          'rchId': data['RichID']?.toString() ?? '',
          'womanName': womanName,
          'currentAge': currentAge,
          'ageAtMarriage': (isHead 
              ? headDetails['ageAtMarriage']?.toString() 
              : spouseDetails['ageAtMarriage']?.toString()) ?? '',
          
          // Address
          'address': [
            headDetails['village']?.toString(),
            headDetails['mohalla']?.toString() ?? headDetails['tola']?.toString(),
            headDetails['ward']?.toString(),
          ].where((e) => e != null && e.isNotEmpty).join(', '),
          
          // Mobile details
          'whoseMobile': isHead ? 'Wife' : 'Self', // Assuming if it's the wife's card, it's her mobile
          'mobileNo': isHead 
              ? (spouseDetails['mobileNo']?.toString() ?? headDetails['mobileNo']?.toString() ?? '')
              : (headDetails['mobileNo']?.toString() ?? ''),
          
          // Religion and category
          'religion': headDetails['religion']?.toString() ?? '',
          'category': headDetails['category']?.toString() ?? headDetails['caste']?.toString() ?? '',
          
          // Children details
          'totalChildrenBorn': childrenDetails['totalBorn']?.toString() ?? '0',
          'totalLiveChildren': childrenDetails['totalLive']?.toString() ?? '0',
          'totalMaleChildren': childrenDetails['totalMale']?.toString() ?? '0',
          'totalFemaleChildren': childrenDetails['totalFemale']?.toString() ?? '0',
          'youngestChildAge': childrenDetails['youngestAge']?.toString() ?? '0',
          'youngestChildAgeUnit': (childrenDetails['ageUnit']?.toString() ?? 'Years').toLowerCase().contains('month') ? 'Months' : 'Years',
          'youngestChildGender': childrenDetails['youngestGender']?.toString() ?? '',
          
          // Additional fields for reference
          'registrationDate': DateTime.now().toIso8601String(),
          
          // Raw data for debugging
          '_rawRow': rowData,
          'head_details': headDetails,
          'spouse_details': spouseDetails,
        }..removeWhere((key, value) => value == null || value == '');
        
        // Debug print the navigation data
        print('🚀 Navigating with data: ${jsonEncode(navigationData)}');

        print('🚀 Navigating with data: $navigationData');
        
        // Ensure all required fields are present in the navigation data
        final Map<String, dynamic> updateData = {
          'rchId': navigationData['rchId'] ?? '',
          'womanName': navigationData['womanName'] ?? '',
          'currentAge': navigationData['currentAge'] ?? '',
          'ageAtMarriage': navigationData['ageAtMarriage'] ?? '',
          'address': navigationData['address'] ?? '',
          'whoseMobile': navigationData['whoseMobile'] ?? 'Self',
          'mobileNo': navigationData['mobileNo'] ?? '',
          'religion': navigationData['religion'] ?? '',
          'category': navigationData['category'] ?? '',
          'totalChildrenBorn': navigationData['totalChildrenBorn'] ?? '0',
          'totalLiveChildren': navigationData['totalLiveChildren'] ?? '0',
          'totalMaleChildren': navigationData['totalMaleChildren'] ?? '0',
          'totalFemaleChildren': navigationData['totalFemaleChildren'] ?? '0',
          'youngestChildAge': navigationData['youngestChildAge'] ?? '0',
          'youngestChildAgeUnit': navigationData['youngestChildAgeUnit'] ?? 'Years',
          'youngestChildGender': navigationData['youngestChildGender'] ?? '',
          'registrationDate': navigationData['registrationDate'] ?? DateTime.now().toIso8601String(),
          '_rawRow': navigationData['_rawRow'],
        };
        
        Navigator.pushNamed(
          context,
          Route_Names.UpdatedEligibleCoupleList,
          arguments: updateData,
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
                      Expanded(child: _rowText(l10n?.ageGenderLabel ?? 'Age', data['age']?.toString() ?? '')),
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
                          child: _rowText(l10n?.husbandLabel ?? 'Husband Name', data['HusbandName'] ?? '')),
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
