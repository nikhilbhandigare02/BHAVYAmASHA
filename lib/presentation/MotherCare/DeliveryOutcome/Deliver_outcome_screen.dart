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
import '../../../data/Local_Storage/tables/followup_form_data_table.dart';
import '../../../data/Local_Storage/tables/beneficiaries_table.dart';
import '../../../data/Local_Storage/database_provider.dart';
import '../../../data/SecureStorage/SecureStorage.dart';
import '../../HomeScreen/HomeScreen.dart';
import '../../../data/Local_Storage/local_storage_dao.dart';
import '../OutcomeForm/OutcomeForm.dart';

class DeliveryOutcomeScreen extends StatefulWidget {
  const DeliveryOutcomeScreen({super.key});

  @override
  State<DeliveryOutcomeScreen> createState() =>
      _DeliveryOutcomeScreenState();
}

class _DeliveryOutcomeScreenState
    extends State<DeliveryOutcomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPregnancyOutcomeeCouples();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPregnancyOutcomeeCouples() async {
    setState(() { _isLoading = true; });

    try {

      final db = await DatabaseProvider.instance.database;
      final ancForms = await db.rawQuery('''
        SELECT 
          f.beneficiary_ref_key,
          f.form_json,
          f.household_ref_key
        FROM ${FollowupFormDataTable.table} f
        WHERE 
          f.forms_ref_key = '${FollowupFormDataTable.formUniqueKeys['ancDueRegistration']}'
          AND f.form_json LIKE '%"gives_birth_to_baby":"Yes"%'
          AND f.is_deleted = 0
      ''');

      if (ancForms.isEmpty) {
        setState(() {
          _isLoading = false;
          _filtered = [];
        });
        return;
      }

      // Get unique beneficiary keys
      final beneficiaryKeys = ancForms
          .map((f) => f['beneficiary_ref_key']?.toString())
          .where((key) => key != null && key.isNotEmpty)
          .toSet()
          .toList();

      if (beneficiaryKeys.isEmpty) {
        setState(() {
          _isLoading = false;
          _filtered = [];
        });
        return;
      }

      // Get beneficiary details
      final placeholders = List.filled(beneficiaryKeys.length, '?').join(',');
      final beneficiaries = await db.rawQuery('''
        SELECT 
          b.unique_key,
          b.household_ref_key,
          b.beneficiary_info,
          b.created_date_time
        FROM ${BeneficiariesTable.table} b
        WHERE b.unique_key IN ($placeholders)
          AND b.is_deleted = 0
      ''', beneficiaryKeys);

      final couples = <Map<String, dynamic>>[];

      for (final beneficiary in beneficiaries) {
        try {
          final info = jsonDecode(beneficiary['beneficiary_info'] as String? ?? '{}') as Map<String, dynamic>;
          final head = Map<String, dynamic>.from((info['head_details'] as Map?) ?? const {});
          final spouse = Map<String, dynamic>.from((info['spousedetails'] as Map?) ?? const {});
          
          if (head.isNotEmpty && _isEligibleFemale(head)) {
            couples.add(_formatCoupleData(beneficiary, head, spouse, isHead: true));
          }
          
          if (spouse.isNotEmpty && _isEligibleFemale(spouse, head: head)) {
            couples.add(_formatCoupleData(beneficiary, spouse, head, isHead: false));
          }
        } catch (e) {
          print('Error processing beneficiary ${beneficiary['unique_key']}: $e');
        }
      }

      setState(() {
        _filtered = couples;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pregnancy outcome couples: $e');
      setState(() {
        _isLoading = false;
        _filtered = [];
      });
    }
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
        _loadPregnancyOutcomeeCouples();
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
        screenTitle: l10n?.pregnancyOutcome ?? '',
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
    final t = AppLocalizations.of(context);

    // Extract the raw row data and beneficiary info
    final rowData = data['_rawRow'] ?? {};
    final beneficiaryInfo = rowData['beneficiary_info'] is String
        ? jsonDecode(rowData['beneficiary_info'])
        : (rowData['beneficiary_info'] ?? {});

    // Extract head and spouse details with proper fallbacks
    final headDetails = (beneficiaryInfo['head_details'] ?? {}) as Map<String, dynamic>;
    final spouseDetails = (beneficiaryInfo['spouse_details'] ?? {}) as Map<String, dynamic>;

    // Get children details with fallbacks
    final childrenDetails = (beneficiaryInfo['children_details'] ??
        headDetails['childrendetails'] ??
        headDetails['childrenDetails'] ??
        {}) as Map<String, dynamic>;

    return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () {
            final beneficiaryData = <String, dynamic>{};

            print('📋 Raw data: $data');
            
            // First try to get from _rawRow
            if (data['_rawRow'] is Map) {
              final rawRow = data['_rawRow'] as Map;
              final uniqueKey = rawRow['unique_key']?.toString() ?? '';
              final beneficiaryId = uniqueKey.length > 11 
                  ? uniqueKey.substring(uniqueKey.length - 11) 
                  : uniqueKey;
                  
              beneficiaryData['unique_key'] = uniqueKey;
              beneficiaryData['BeneficiaryID'] = beneficiaryId;
              
              print('🔑 Passing to form:');
              print('   - unique_key: ${beneficiaryData['unique_key']}');
              print('   - BeneficiaryID: ${beneficiaryData['BeneficiaryID']} (derived from unique_key)');
            } 
            // Fallback to data['BeneficiaryID'] if _rawRow is not available
            else if (data['BeneficiaryID'] != null) {
              beneficiaryData['BeneficiaryID'] = data['BeneficiaryID'].toString();
              print('🔍 Using direct BeneficiaryID: ${beneficiaryData['BeneficiaryID']}');
            } 
            // Last resort - try to get from the data map
            else {
              final uniqueKey = data['_rawRow']?['unique_key']?.toString() ?? '';
              final beneficiaryId = uniqueKey.isNotEmpty 
                  ? (uniqueKey.length > 11 ? uniqueKey.substring(uniqueKey.length - 11) : uniqueKey)
                  : '';
                  
              beneficiaryData['BeneficiaryID'] = beneficiaryId;
              print('⚠️ Using fallback BeneficiaryID: ${beneficiaryData['BeneficiaryID']}');
            }
            
            if ((beneficiaryData['BeneficiaryID'] as String?)?.isEmpty ?? true) {
              print('❌ No BeneficiaryID could be determined!');
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OutcomeFormPage(beneficiaryData: beneficiaryData),
              ),
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
                          Expanded(child: _rowText('Registration Date', data['RegistrationDate'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Registration Type', data['RegistrationType'] ?? '')),
                          const SizedBox(width: 12),
                          Expanded(child: _rowText('Beneficiary ID', data['BeneficiaryID'] ?? '')),
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
