import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/SecureStorage/SecureStorage.dart';

class RegisterChildScreen extends StatefulWidget {
  const RegisterChildScreen({super.key});

  @override
  State<RegisterChildScreen> createState() => _RegisterChildScreenState();
}

class _RegisterChildScreenState extends State<RegisterChildScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _childBeneficiaries = [];
  late List<Map<String, dynamic>> _filtered;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _childBeneficiaries = [];
    _loadChildBeneficiaries();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // Future<void> _loadChildBeneficiaries() async {
  //   if (!mounted) return;
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final db = await DatabaseProvider.instance.database;
  //
  //     // Get current user key from secure storage
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     print('🔍 Fetching deceased beneficiaries...');
  //
  //     // Build where clause for deceased children query
  //     String deceasedWhere = 'form_json LIKE ?';
  //     List<Object?> deceasedWhereArgs = ['%"reason_of_death":%'];
  //
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       deceasedWhere += ' AND current_user_key = ?';
  //       deceasedWhereArgs.add(ashaUniqueKey);
  //     }
  //
  //     final deceasedChildren = await db.query(
  //       'followup_form_data',
  //       columns: ['DISTINCT beneficiary_ref_key', 'form_json'],
  //       where: deceasedWhere,
  //       whereArgs: deceasedWhereArgs,
  //     );
  //
  //     print('✅ Found ${deceasedChildren.length} potential deceased records');
  //
  //     final deceasedIds = <String>{};
  //     for (var child in deceasedChildren) {
  //       try {
  //         final jsonData = jsonDecode(child['form_json'] as String);
  //         final formData = jsonData['form_data'] as Map<String, dynamic>?;
  //         final caseClosure = formData?['case_closure'] as Map<String, dynamic>?;
  //
  //         if (caseClosure?['is_case_closure'] == true &&
  //             caseClosure?['reason_of_death']?.toString().toLowerCase() == 'death') {
  //           final beneficiaryId = child['beneficiary_ref_key']?.toString();
  //           if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
  //             print('Found deceased beneficiary: $beneficiaryId');
  //             deceasedIds.add(beneficiaryId);
  //           }
  //         }
  //       } catch (e) {
  //         print('⚠️ Error processing deceased record: $e');
  //       }
  //     }
  //
  //     print('✅ Total deceased beneficiaries: ${deceasedIds.length}');
  //
  //     // Build where clause for beneficiaries query
  //     String where = 'is_deleted = ? AND is_adult = ?';
  //     List<Object?> whereArgs = [0, 0]; // 0 for false, 1 for true
  //
  //     if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //       where += ' AND current_user_key = ?';
  //       whereArgs.add(ashaUniqueKey);
  //     }
  //
  //     final List<Map<String, dynamic>> rows = await db.query(
  //       'beneficiaries_new',
  //       columns: ['*', 'is_death'],
  //       where: where,
  //       whereArgs: whereArgs,
  //     );
  //
  //     print('📊 Found ${rows.length} total beneficiaries');
  //     final childBeneficiaries = <Map<String, dynamic>>[];
  //
  //     for (final row in rows) {
  //       try {
  //         final rowHhId = row['household_ref_key']?.toString();
  //         if (rowHhId == null) continue;
  //
  //         // Parse beneficiary info
  //         final info = row['beneficiary_info'] is String
  //             ? jsonDecode(row['beneficiary_info'] as String)
  //             : row['beneficiary_info'];
  //
  //         if (info is! Map) continue;
  //
  //         // Check if this is a direct child record (new format)
  //         final memberType = info['memberType']?.toString().toLowerCase() ?? '';
  //         final relation = info['relation']?.toString().toLowerCase() ?? '';
  //
  //         if (memberType == 'child' || relation == 'child' ||
  //             relation == 'son' || relation == 'daughter') {
  //
  //           final name = info['name']?.toString() ??
  //               info['memberName']?.toString() ??
  //               info['member_name']?.toString() ??
  //               '';
  //
  //           if (name.isEmpty) continue; // Skip if no name
  //
  //           final fatherName = info['fatherName']?.toString() ??
  //               info['father_name']?.toString() ?? '';
  //
  //           final motherName = info['motherName']?.toString() ??
  //               info['mother_name']?.toString() ?? '';
  //
  //           final mobileNo = info['mobileNo']?.toString() ??
  //               info['mobile']?.toString() ??
  //               info['mobile_number']?.toString() ?? '';
  //
  //           final richId = info['RichIDChanged']?.toString() ??
  //               info['richIdChanged']?.toString() ??
  //               info['richId']?.toString() ?? '';
  //
  //           final dob = info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];
  //           final gender = info['gender'] ?? info['sex'];
  //
  //           final beneficiaryId = row['unique_key']?.toString() ?? '';
  //           final isDeceased = deceasedIds.contains(beneficiaryId);
  //
  //           if (isDeceased) {
  //             print('ℹ️ Marking as deceased - ID: $beneficiaryId, Name: $name');
  //           }
  //
  //           final card = <String, dynamic>{
  //             'hhId': rowHhId,
  //             'RegitrationDate': _formatDate(row['created_date_time']?.toString()),
  //             'RegitrationType': 'Child',
  //             'BeneficiaryID': beneficiaryId,
  //             'RchID': richId,
  //             'Name': name,
  //             'Age|Gender': _formatAgeGender(dob, gender),
  //             'Mobileno.': mobileNo,
  //             'FatherName': fatherName,
  //             'MotherName': motherName,
  //             'is_deceased': isDeceased,
  //             'is_death': row['is_death'] ?? 0,
  //             '_raw': row,
  //           };
  //
  //           childBeneficiaries.add(card);
  //         }
  //       } catch (e) {
  //         print('⚠️ Error processing beneficiary record: $e');
  //       }
  //     }
  //
  //     if (mounted) {
  //       setState(() {
  //         _childBeneficiaries = List<Map<String, dynamic>>.from(childBeneficiaries);
  //         _filtered = List<Map<String, dynamic>>.from(childBeneficiaries);
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Error loading child beneficiaries: $e');
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Future<void> _loadChildBeneficiaries() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseProvider.instance.database;

      final currentUserData =
      await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      /* -----------------------------------------------------------
     * STEP 1: FETCH DECEASED CHILD BENEFICIARIES
     * ----------------------------------------------------------- */
      final deceasedChildren = await db.rawQuery('''
      SELECT DISTINCT beneficiary_ref_key, form_json
      FROM followup_form_data
      WHERE form_json LIKE '%"reason_of_death":%'
        AND current_user_key = ?
         ORDER BY id
    ''', [ashaUniqueKey]);

      final Set<String> deceasedIds = {};

      for (final child in deceasedChildren) {
        try {
          final jsonData = jsonDecode(child['form_json'] as String);
          final formData =
          jsonData['form_data'] as Map<String, dynamic>?;
          final caseClosure =
          formData?['case_closure'] as Map<String, dynamic>?;

          if (caseClosure?['is_case_closure'] == true &&
              caseClosure?['reason_of_death']
                  ?.toString()
                  .toLowerCase() ==
                  'death') {
            final id =
            child['beneficiary_ref_key']?.toString();
            if (id != null && id.isNotEmpty) {
              deceasedIds.add(id);
            }
          }
        } catch (_) {}
      }

      /* -----------------------------------------------------------
     * STEP 2: FETCH FIRST CHILD CARE REGISTRATION DATE
     * ----------------------------------------------------------- */
      final Map<String, String> registrationDates = {};

      final childCareRecords = await db.rawQuery('''
      SELECT beneficiary_ref_key, created_date_time
      FROM child_care_activities
      ORDER BY id ASC
    ''');

      for (final record in childCareRecords) {
        final key =
        record['beneficiary_ref_key']?.toString();
        if (key != null && !registrationDates.containsKey(key)) {
          registrationDates[key] =
              record['created_date_time']?.toString() ?? '';
        }
      }

      final rows = await db.rawQuery('''
      SELECT DISTINCT B.*
      FROM beneficiaries_new B
      INNER JOIN child_care_activities CCA
        ON B.unique_key = CCA.beneficiary_ref_key
      WHERE B.is_deleted = 0
        AND B.is_adult = 0
        AND B.is_migrated = 0
        AND B.current_user_key = ?
        AND CCA.child_care_state IN ('registration_due', 'tracking_due', 'infant_pnc')
      ORDER BY B.id DESC
    ''', [ashaUniqueKey]);

      final List<Map<String, dynamic>> childBeneficiaries = [];
      final Set<String> processedBeneficiaries = {};

      for (final row in rows) {
        try {
          final beneficiaryId =
              row['unique_key']?.toString() ?? '';
          if (beneficiaryId.isEmpty) continue;

          if (!processedBeneficiaries.add(beneficiaryId)) {
            continue;
          }

          final householdId =
          row['household_ref_key']?.toString();
          if (householdId == null) continue;

          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          final memberType =
              info['memberType']?.toString().toLowerCase() ?? '';
          final relation =
              info['relation']?.toString().toLowerCase() ?? '';

          if (!(memberType == 'child' ||
              relation == 'child' ||
              relation == 'daughter')) {
            continue;
          }

          final name = info['name']?.toString() ??
              info['memberName']?.toString() ??
              '';

          final fatherName =
              info['fatherName']?.toString() ?? info['spouseName']?.toString() ?? '';
          final motherName =
              info['motherName']?.toString() ?? '';
          final mobileNo =
              info['mobileNo']?.toString() ?? '';

          final dob = info['dob'] ??
              info['dateOfBirth'] ??
              info['date_of_birth'];
          final gender = info['gender'] ?? info['sex'];

          final bool isDeceased =
          deceasedIds.contains(beneficiaryId);

          final String registrationDate =
          registrationDates.containsKey(beneficiaryId)
              ? _formatDate(
              registrationDates[beneficiaryId])
              : _formatDate(
              row['created_date_time']?.toString());

          childBeneficiaries.add({
            'hhId': householdId,
            'RegitrationDate': registrationDate,
            'RegitrationType': 'Child',
            'BeneficiaryID': beneficiaryId,
            'Name': name,
            'Age|Gender': _formatAgeGender(dob, gender),
            'Mobileno.': mobileNo,
            'FatherName': fatherName,
            'MotherName': motherName,
            'is_deceased': isDeceased,
            'is_death': row['is_death'] ?? 0,
            '_raw': row,
          });
        } catch (_) {}
      }

      /* -----------------------------------------------------------
     * STEP 5: UPDATE UI
     * ----------------------------------------------------------- */
      if (mounted) {
        setState(() {
          _childBeneficiaries = List.from(childBeneficiaries);
          _filtered = List.from(childBeneficiaries);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading child beneficiaries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not Available';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAgeGender(dynamic dobRaw, dynamic genderRaw) {
    String age = 'Not Available';
    String gender = (genderRaw?.toString().toLowerCase() ?? '');

    if (dobRaw != null && dobRaw.toString().isNotEmpty) {
      try {
        String dateStr = dobRaw.toString();
        DateTime? dob;

        dob = DateTime.tryParse(dateStr);

        if (dob == null) {
          final timestamp = int.tryParse(dateStr);
          if (timestamp != null && timestamp > 0) {
            dob = DateTime.fromMillisecondsSinceEpoch(
              timestamp > 1000000000000 ? timestamp : timestamp * 1000,
              isUtc: true,
            );
          }
        }

        if (dob != null) {
          final now = DateTime.now();
          int years = now.year - dob.year;
          int months = now.month - dob.month;
          int days = now.day - dob.day;

          if (days < 0) {
            final lastMonth = now.month - 1 < 1 ? 12 : now.month - 1;
            final lastMonthYear = now.month - 1 < 1 ? now.year - 1 : now.year;
            final daysInLastMonth = DateTime(lastMonthYear, lastMonth + 1, 0).day;
            days += daysInLastMonth;
            months--;
          }

          if (months < 0) {
            months += 12;
            years--;
          }

          if (years > 0) {
            age = '$years Y';
          } else if (months > 0) {
            age = '$months M';
          } else {
            age = '$days D';
          }
        }
      } catch (e) {
        debugPrint('Error parsing date of birth: $e');
      }
    }

    String displayGender;
    switch (gender) {
      case 'm':
      case 'male':
        displayGender = 'Male';
        break;
      case 'f':
      case 'female':
        displayGender = 'Female';
        break;
      default:
        displayGender = 'Other';
    }

    return '$age | $displayGender';
  }

  void _onSearchChanged() {
    if (!mounted) return;

    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        // Reset to show all records when search is cleared
        _filtered = List<Map<String, dynamic>>.from(_childBeneficiaries);
        debugPrint('🔍 Search cleared. Showing all ${_filtered.length} records');
      } else {
        _filtered = _childBeneficiaries.where((e) {
          final match = (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['FatherName']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['MotherName']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['BeneficiaryID']?.toString().toLowerCase() ?? '').contains(q);
          
          if (match) {
            debugPrint('🔍 Found match: ${e['Name']} (ID: ${e['BeneficiaryID']})');
          }
          
          return match;
        }).toList();
        
        debugPrint('🔍 Found ${_filtered.length} matching records for "$q"');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(
        screenTitle: l10n?.childRegisteredBeneficiaryListTitle ?? 'Register child beneficiary list',
        showBack: true,
      ),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n?.childRegisteredBeneficiaryListSearch ?? 'Search All Beneficiary',
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

          // 📋 List of Child Beneficiaries
          _isLoading
              ? const Expanded(
              child: Center(child: CircularProgressIndicator()))
              : _filtered.isEmpty
              ? Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _childBeneficiaries.isEmpty
                      ? l10n!.noChildBeneficiaries
                      : l10n!.noMatchingChild,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            ),
          )
              : Expanded(
            child: RefreshIndicator(
              onRefresh: _loadChildBeneficiaries,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final data = _filtered[index];
                  return _householdCard(context, data);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🧱 Child Beneficiary Card UI
  Widget _householdCard(BuildContext context, Map<String, dynamic> data) {
    final l10n = AppLocalizations.of(context);
    final Color primary = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () {
        // Navigate to child detail screen if needed
        // Navigator.pushNamed(
        //   context,
        //   Route_Names.childDetail,
        //   arguments: {'childData': data},
        // );
      },
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
            // Header Row
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.home, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (data['hhId'] != null && data['hhId'].toString().length > 11)
                          ? data['hhId'].toString().substring(data['hhId'].toString().length - 11)
                          : (data['hhId']?.toString() ?? ''),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (data['is_deceased'] == true) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.red.shade600, size: 10),
                          const SizedBox(width: 4),
                          Text(
                            'Deceased'.toUpperCase(),
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (data['is_death'] == 1) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Decease',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/sync.png',
                      width: 6.w,
                      height: 6.w,
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.registrationDateLabel ?? 'Registration Date', data['RegitrationDate'] ?? 'Not Available')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.registrationTypeLabel ?? 'Registration Type', data['RegitrationType'] ?? 'Child')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          (data['BeneficiaryID']?.toString().length ?? 0) > 11
                              ? data['BeneficiaryID'].toString().substring(data['BeneficiaryID'].toString().length - 11)
                              : (data['BeneficiaryID']?.toString() ?? 'Not Available'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.nameLabel ?? 'Name', data['Name'] ??  l10n!.na)),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.ageGenderLabel ?? 'Age | Gender', data['Age|Gender'] ??  l10n!.na)),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(l10n?.rchIdLabel ?? 'RCH ID', data['RchID']?.isNotEmpty == true ? data['RchID'] : l10n!.na)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(child: _rowText(l10n?.mobileLabelSimple ?? '', data['Mobileno.']?.isNotEmpty == true ? data['Mobileno.'] :  l10n!.na,)),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText('', '')),
                      const SizedBox(width: 12),
                      Expanded(child: _rowText(
                        data['FatherName']?.toString().isNotEmpty == true
                            ? (l10n?.fatherNameLabel ?? 'Father Name')
                            : (data['SpouseName']?.toString().isNotEmpty == true
                                ? (l10n?.husbandName ?? 'Husband Name')
                                : (l10n?.fatherNameLabel ?? 'Father Name')),
                        data['FatherName']?.toString().isNotEmpty == true
                            ? data['FatherName']
                            : (data['SpouseName']?.toString().isNotEmpty == true
                                ? data['SpouseName']
                                : l10n!.na),
                      )),
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
          style: TextStyle(
            color: AppColors.background,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }
}