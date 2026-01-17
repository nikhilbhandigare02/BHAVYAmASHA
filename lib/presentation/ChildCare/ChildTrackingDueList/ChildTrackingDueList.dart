import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/widgets/AppDrawer/Drawer.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/widgets/RoundButton/RoundButton.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/config/routes/Route_Name.dart';
import '../../../core/config/routes/Routes.dart';
import '../../../core/config/themes/CustomColors.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import '../../../core/widgets/SnackBar/app_snackbar.dart';
import '../../../data/Database/database_provider.dart';
import '../../../data/Database/tables/followup_form_data_table.dart';
import '../../../data/Database/tables/beneficiaries_table.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'ChildTrackingDueListForm.dart';

class CHildTrackingDueList extends StatefulWidget {
  const CHildTrackingDueList({super.key});

  @override
  State<CHildTrackingDueList> createState() => _CHildTrackingDueListState();
}

class _CHildTrackingDueListState extends State<CHildTrackingDueList> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _childTrackingList = [];
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = [];
    _searchCtrl.addListener(_onSearchChanged);
    _loadChildTrackingData();
  }

  Future<void> _loadChildTrackingData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final List<Map<String, dynamic>> childActivities = await db.rawQuery(
        '''
  WITH ranked AS (
      SELECT
          cca.*,
          ROW_NUMBER() OVER (
              PARTITION BY cca.beneficiary_ref_key
              ORDER BY datetime(cca.created_date_time) DESC, cca.rowid DESC
          ) AS rn
      FROM child_care_activities cca
      WHERE cca.is_deleted = 0
        ${ashaUniqueKey != null && ashaUniqueKey.isNotEmpty ? 'AND cca.current_user_key = ?' : ''}
  )
  SELECT
      ranked.*,
      bn.created_date_time AS beneficiary_created_date_time
  FROM ranked
  INNER JOIN beneficiaries_new bn
      ON bn.unique_key = ranked.beneficiary_ref_key
  WHERE ranked.rn = 1
    AND ranked.child_care_state IN (?, ?)
    AND bn.is_death = 0
    AND bn.is_deleted = 0
  ORDER BY datetime(bn.created_date_time) DESC
  ''',
        [
          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) ashaUniqueKey,
          'tracking_due',

        ],
      );

      if (childActivities.isEmpty) {
        debugPrint('No child care activities found with states: tracking_due, infant_pnc');
        setState(() {
          _childTrackingList = [];
          _filtered = [];
          _isLoading = false;
        });
        return;
      }

      debugPrint('🎯 Found ${childActivities.length} unique child care activities with tracking_due/infant_pnc status');

      final List<Map<String, dynamic>> childTrackingList = [];
      final Set<String> seenBeneficiaries = <String>{};

      for (final activity in childActivities) {
        final beneficiaryRefKey = activity['beneficiary_ref_key']?.toString();

        if (beneficiaryRefKey == null) continue;

        if (seenBeneficiaries.contains(beneficiaryRefKey)) {
          debugPrint('⏭️ Skipping duplicate record for beneficiary: $beneficiaryRefKey');
          continue;
        }
        seenBeneficiaries.add(beneficiaryRefKey);

        final List<Map<String, dynamic>> beneficiaryRows = await db.query(
          'beneficiaries_new',
          where: 'unique_key = ?',
          whereArgs: [beneficiaryRefKey],
        );

        if (beneficiaryRows.isEmpty) continue;

        final row = beneficiaryRows.first;

        // Parse beneficiary_info
        dynamic info;
        try {
          info = (row['beneficiary_info'] is String)
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];
        } catch (e) {
          debugPrint('❌ Error parsing beneficiary_info: $e');
          continue;
        }

        if (info is! Map) continue;

        final memberData = Map<String, dynamic>.from(info);
        final memberType = (memberData['memberType']?.toString() ?? '')
            .trim()
            .toLowerCase();

        if (memberType != 'child') continue;

        final name = memberData['name']?.toString().trim() ??
            '';

        if (name.isEmpty) continue;

        // Check for case closure from followup table
        final caseClosureWhere =
            (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
            ? 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?'
            : 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
        final caseClosureArgs =
            (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
            ? [beneficiaryRefKey, '%case_closure%', ashaUniqueKey]
            : [beneficiaryRefKey, '%case_closure%'];
        final caseClosureRecords = await db.query(
          FollowupFormDataTable.table,
          where: caseClosureWhere,
          whereArgs: caseClosureArgs,
        );

        if (caseClosureRecords.isNotEmpty) {
          // Check if any of these records have case_closure with is_case_closure = true
          bool hasCaseClosure = false;
          for (final ccRecord in caseClosureRecords) {
            try {
              final ccFormJson = ccRecord['form_json'] as String?;
              if (ccFormJson != null) {
                final ccFormData = jsonDecode(ccFormJson);
                final ccFormDataMap =
                    ccFormData['form_data'] as Map<String, dynamic>? ?? {};
                final caseClosure =
                    ccFormDataMap['case_closure']
                        as Map<String, dynamic>? ??
                    {};
                if (caseClosure['is_case_closure'] == true) {
                  hasCaseClosure = true;
                  break;
                }
              }
            } catch (e) {
              debugPrint('Error checking case closure: $e');
            }
          }

          if (hasCaseClosure) {
            debugPrint('⏭️ Skipping child $name - case closure already recorded');
            continue;
          }
        }

        // Check for death closure from followup table
        final deathClosureWhere =
            (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
            ? 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0 AND current_user_key = ?'
            : 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
        final deathClosureArgs =
            (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty)
            ? [beneficiaryRefKey, '%death_closure%', ashaUniqueKey]
            : [beneficiaryRefKey, '%death_closure%'];
        final deathClosureRecords = await db.query(
          FollowupFormDataTable.table,
          where: deathClosureWhere,
          whereArgs: deathClosureArgs,
        );

        if (deathClosureRecords.isNotEmpty) {
          // Check if any of these records have death_closure with is_death_closure = true
          bool hasDeathClosure = false;
          for (final dcRecord in deathClosureRecords) {
            try {
              final dcFormJson = dcRecord['form_json'] as String?;
              if (dcFormJson != null) {
                final dcFormData = jsonDecode(dcFormJson);
                final dcFormDataMap =
                    dcFormData['form_data'] as Map<String, dynamic>? ?? {};
                final deathClosure =
                    dcFormDataMap['death_closure']
                        as Map<String, dynamic>? ??
                    {};
                if (deathClosure['is_death_closure'] == true) {
                  hasDeathClosure = true;
                  break;
                }
              }
            } catch (e) {
              debugPrint('Error checking death closure: $e');
            }
          }

          if (hasDeathClosure) {
            debugPrint('⏭️ Skipping child $name - death closure already recorded');
            continue;
          }
        }

        // Format registration date
        final registrationDate = activity['created_date_time'] != null
            ? _formatDate(activity['created_date_time'].toString())
            : 'N/A';

        // Extract other details from memberData
        final motherName = memberData['motherName']?.toString()?.trim() ?? '';
        final fatherName = memberData['fatherName']?.toString()?.trim() ?? '';
        final rchId = memberData['RichIDChanged']?.toString()?.trim() ?? '';
        final mobileNumber = memberData['mobileNo']?.toString()?.trim() ?? 
            memberData['mobile_no']?.toString()?.trim() ?? '';
        final address = memberData['address']?.toString()?.trim() ?? '';
        final dateOfBirth = memberData['dob']?.toString() ?? '';
        final gender = memberData['gender']?.toString() ?? '';

        String _normalizeGender(String g) {
          final s = g.toLowerCase().trim();
          if (s == 'm' || s == 'male' || s == 'boy' || s == 'b' || s == '1')
            return 'Male';
          if (s == 'f' ||
              s == 'female' ||
              s == 'girl' ||
              s == 'g' ||
              s == '2')
            return 'Female';
          if (s == 'other' || s == 'o' || s == '3') return 'Other';
          return 'Other';
        }

        final ageGenderDisplay = dateOfBirth.isNotEmpty
            ? _formatAgeGender(dateOfBirth, gender)
            : _formatAgeGender(dateOfBirth, gender);
        final cleanedAgeGenderDisplay = ageGenderDisplay.contains(' | Other')
            ? ageGenderDisplay.replaceAll(' | Other', '').trim()
            : ageGenderDisplay;

        // Create child data map matching the form structure
        final childData = {
          'hhId': row['household_ref_key']?.toString() ?? 'N/A',
          'RegitrationDate': registrationDate,
          'RegitrationType': 'Child Registration',
          'BeneficiaryID': beneficiaryRefKey,
          'RchID': rchId,
          'Name': name,
          'Age|Gender': cleanedAgeGenderDisplay,
          'Mobileno.': mobileNumber,
          'FatherName': fatherName,
          'MotherName': motherName,
          'Address': address,
          'Weight': '', // Weight not available in beneficiaries_new table
          'is_synced': activity['is_synced'] ?? 0,
          'formData': memberData, // Store the member data
        };

        debugPrint('✅ Successfully added child: $name');
        childTrackingList.add(childData);
      }

      debugPrint(
        '📊 Total child records processed: ${childTrackingList.length}',
      );

      if (mounted) {
        setState(() {
          _childTrackingList = childTrackingList;
          _filtered = List<Map<String, dynamic>>.from(childTrackingList);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading child registration data: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load child registration data. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
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
          final m = RegExp(
            r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$',
          ).firstMatch(dateStr);
          if (m != null) {
            final d = int.parse(m.group(1)!);
            final mo = int.parse(m.group(2)!);
            final y = int.parse(m.group(3)!);
            dob = DateTime(y, mo, d);
          }
        }

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
            final daysInLastMonth = DateTime(
              lastMonthYear,
              lastMonth + 1,
              0,
            ).day;
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
      case 'boy':
      case 'b':
      case '1':
        displayGender = 'Male';
        break;
      case 'f':
      case 'female':
      case 'girl':
      case 'g':
      case '2':
        displayGender = 'Female';
        break;
      case 'other':
      case 'o':
      case '3':
        displayGender = 'Other';
        break;
      default:
        displayGender = 'Other';
    }

    return '$age | $displayGender';
  }

  Future<Map<String, dynamic>> _getSyncStatus(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;

      // First try to get the latest record from followup_form_data
      final formRows = await db.query(
        FollowupFormDataTable.table,
        columns: ['is_synced', 'server_id', 'created_date_time'],
        where:
            'beneficiary_ref_key = ? AND (forms_ref_key = ? OR form_json LIKE ?) AND is_deleted = 0',
        whereArgs: [
          beneficiaryRefKey,
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .childTrackingDue],
          '%${FollowupFormDataTable.childTrackingDue}%',
        ],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (formRows.isNotEmpty) {
        final isSynced = formRows.first['is_synced'] == 1;
        debugPrint(
          'Sync status for $beneficiaryRefKey from followup_form_data: $isSynced',
        );
        return {
          'is_synced': isSynced,
          'server_id': formRows.first['server_id'],
        };
      }

      // Fallback to check child_care_activities if no form data found
      final activityRows = await db.query(
        'child_care_activities',
        columns: ['is_synced', 'server_id', 'created_date_time'],
        where: 'beneficiary_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (activityRows.isNotEmpty) {
        final isSynced = activityRows.first['is_synced'] == 1;
        debugPrint(
          'Sync status for $beneficiaryRefKey from child_care_activities: $isSynced',
        );
        return {
          'is_synced': isSynced,
          'server_id': activityRows.first['server_id'],
        };
      }

      debugPrint('No sync status found for beneficiary: $beneficiaryRefKey');
      return {'is_synced': false, 'server_id': null};
    } catch (e) {
      debugPrint('Error fetching sync status for $beneficiaryRefKey: $e');
      return {'is_synced': false, 'server_id': null};
    }
  }

  Future<String> _getAgeGenderRealtime(
    String beneficiaryRefKey,
    String fallback,
  ) async {
    try {
      if (beneficiaryRefKey.isEmpty) {
        final f = fallback.replaceAll(' | Other', '').trim();
        return f.isNotEmpty ? f : 'N/A';
      }
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        BeneficiariesTable.table,
        where: 'unique_key = ?',
        whereArgs: [beneficiaryRefKey],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        Map<String, dynamic> info = {};
        try {
          final raw = rows.first['beneficiary_info'];
          info = raw is String
              ? jsonDecode(raw)
              : Map<String, dynamic>.from(raw as Map);
        } catch (_) {}
        final dob = info['dob']?.toString() ?? '';
        final genderRaw = info['gender']?.toString() ?? '';
        String display = _formatAgeGender(dob, genderRaw);
        if (display.contains(' | Other')) {
          display = display.replaceAll(' | Other', '').trim();
        }
        if (display.isEmpty || display == 'Not Available') {
          final f = fallback.replaceAll(' | Other', '').trim();
          return f.isNotEmpty ? f : 'N/A';
        }
        return display;
      }
    } catch (_) {}
    final f = fallback.replaceAll(' | Other', '').trim();
    return f.isNotEmpty ? f : 'N/A';
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
        _filtered = List<Map<String, dynamic>>.from(_childTrackingList);
      } else {
        _filtered = _childTrackingList.where((e) {
          return (e['hhId']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Name']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['Mobileno.']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['RchID']?.toString().toLowerCase() ?? '').contains(q) ||
              (e['FatherName']?.toString().toLowerCase() ?? '').contains(q) ||
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
        screenTitle:
            l10n?.childTrackingDueListTitle ?? 'Child Tracking Due List',
        showBack: true,
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: TextStyle(fontSize: 16.sp, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadChildTrackingData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 🔍 Search Field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: l10n!.childTrackingDueSearch,
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
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No children found',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadChildTrackingData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(5, 0, 5, 12),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final childData = _filtered[index];
                              return _householdCard(context, childData);
                            },
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
        final formData = data['formData'] as Map<String, dynamic>?;

        if (formData == null) {
          debugPrint('❌ formData is null, cannot navigate');
          return;
        }
        // 1. Try to find 'child_registration_due' directly at the top level (Scenario 2)
        // 2. If not found, try to find it inside 'form_data' (Scenario 1)
        // 3. Default to an empty map if neither exists
        final childRegistrationMap =
            formData['child_registration_due'] ??
            formData['form_data']?['child_registration_due'] ??
            {};

        final completeFormData = {
          ...formData,
          'household_ref_key': data['hhId']?.toString() ?? '',
          'household_id': data['hhId']?.toString() ?? '',
          'beneficiary_ref_key': data['BeneficiaryID']?.toString() ?? '',
          'beneficiary_id': data['BeneficiaryID']?.toString() ?? '',
          'child_name':
              data['Name']?.toString() ?? formData['child_name'] ?? '',
          'age': data['Age|Gender']?.toString() ?? '',
          'gender': formData['gender'] ?? '',
          'father_name':
              data['FatherName']?.toString() ?? formData['father_name'] ?? '',
          'mother_name':
              data['MotherName']?.toString() ?? formData['mother_name'] ?? '',
          'mobile_number':
              data['Mobileno.']?.toString() ?? formData['mobile_number'] ?? '',
          'rch_id': data['RchID']?.toString() ?? formData['rch_id_child'] ?? '',
          'registration_type':
              data['RegitrationType']?.toString() ?? 'Child Registration',
          'registration_date': data['RegitrationDate']?.toString() ?? '',

          // --- UPDATED LINES ---
          // Now we use childRegistrationMap which holds the correct data regardless of structure
          'weight_grams':
              childRegistrationMap['weight_grams']?.toString() ?? '',
          'birth_weight_grams':
              childRegistrationMap['birth_weight_grams']?.toString() ?? '',
        };

        debugPrint('Complete form data to pass:');
        debugPrint(
          '  household_ref_key: ${completeFormData['household_ref_key']}',
        );
        debugPrint(
          '  beneficiary_ref_key: ${completeFormData['beneficiary_ref_key']}',
        );
        debugPrint('  child_name: ${completeFormData['child_name']}');
        debugPrint('  age: ${completeFormData['age']}');
        debugPrint('  gender: ${completeFormData['gender']}');

        Navigator.pushNamed(
          context,
          Route_Names.ChildTrackingDueListForm,
          arguments: {'formData': completeFormData, 'isEdit': true},
        )?.then((result) {
          // Always reload data to reflect the latest state from the database
          // This ensures that if case closure wasn't selected, the card remains visible
          _loadChildTrackingData();

          if (result is Map && result['saved'] == true) {
            // Optional: You can show a message here if needed, but the form already shows one
            debugPrint('✅ Form saved, reloading list...');
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.home, color: AppColors.primary, size: 15.sp),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (data['hhId'] != null &&
                              data['hhId'].toString().length > 11)
                          ? data['hhId'].toString().substring(
                              data['hhId'].toString().length - 11,
                            )
                          : (data['hhId']?.toString() ?? ''),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),

                  FutureBuilder<Map<String, dynamic>>(
                    future: _getSyncStatus(
                      data['BeneficiaryID']?.toString() ?? '',
                    ),
                    builder: (context, snapshot) {
                      final isSynced = snapshot.data?['is_synced'] == true;
                      return Image.asset(
                        'assets/images/sync.png',
                        width: 25,
                        color: isSynced ? null : Colors.grey[500],
                      );
                    },
                  ),

                  /*FutureBuilder<Map<String, dynamic>>(
                    future: _getSyncStatus(data['is_synced']?.toString() ??''),
                    builder: (context, snapshot) {
                      final isSynced = snapshot.data?['is_synced'] == true;
                      return Image.asset(
                        'assets/images/sync.png',
                        width: 25,
                        color: isSynced ? null : Colors.grey[500],
                      );
                    },
                  )*/
                ],
              ),
            ),

            // Card Body
            Container(
              decoration: BoxDecoration(
                color: primary.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.registrationDateLabel ?? 'Registration Date',
                          data['RegitrationDate'] ?? 'N/A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.registrationTypeLabel ?? 'Registration Type',
                          'Child',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.beneficiaryIdLabel ?? 'Beneficiary ID',
                          (data['BeneficiaryID']?.toString().length ?? 0) > 11
                              ? data['BeneficiaryID'].toString().substring(
                                  data['BeneficiaryID'].toString().length - 11,
                                )
                              : (data['BeneficiaryID']?.toString() ?? 'N/A'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          "${l10n?.nameLabel}",
                          data['Name'] ?? 'N/A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _getAgeGenderRealtime(
                            data['BeneficiaryID']?.toString() ?? '',
                            data['Age|Gender']?.toString() ?? 'N/A',
                          ),
                          builder: (context, snapshot) {
                            final display =
                                snapshot.data ??
                                (data['Age|Gender']?.toString() ?? 'N/A');
                            return _rowText(
                              l10n?.ageGenderLabel ?? 'Age | Gender',
                              display,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.rchIdLabel ?? 'RCH ID',
                          data['RchID']?.isNotEmpty == true
                              ? data['RchID']
                              : l10n!.na,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _rowText(
                          l10n?.mobileLabelSimple ?? 'Mobile No.',
                          data['Mobileno.']?.isNotEmpty == true
                              ? data['Mobileno.']
                              : 'N/A',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: _rowText('', '')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _rowText(
                          l10n?.fatherNameLabel ?? 'Father\'s Name',
                          data['FatherName']?.isNotEmpty == true
                              ? data['FatherName']
                              : 'N/A',
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
    final Color primary = Theme.of(context).primaryColor;
    final bool isLight = primary.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor.withOpacity(0.9),
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w400,
            fontSize: 14.sp,
          ),
        ),
      ],
    );
  }
}
