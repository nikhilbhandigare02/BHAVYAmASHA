import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math' as math;
import '../../data/Database/database_provider.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/Database/tables/followup_form_data_table.dart';
import 'bloc/todays_work_bloc.dart';

class Todaywork extends StatefulWidget {
  const Todaywork({super.key});

  @override
  State<Todaywork> createState() => _TodayworkState();
}

class _TodayworkState extends State<Todaywork> {
  int? _selectedSlice; // selected slice for tooltip
  int? _selectedSliceFromLegend;
  List<Map<String, dynamic>> _riItems = [];
  List<Map<String, dynamic>> _ancItems = [];
  List<Map<String, dynamic>> _familySurveyItems = [];
  List<Map<String, dynamic>> _eligibleCoupleItems = [];
  List<Map<String, dynamic>> _hbncItems = [];
  List<Map<String, dynamic>> _riCompletedItems = [];
  List<Map<String, dynamic>> _ancCompletedItems = [];
  List<Map<String, dynamic>> _eligibleCompletedCoupleItems = [];
  List<Map<String, dynamic>> _hbncCompletedItems = [];
  int _completedVisitsCount = 0;
  int _toDoVisitsCount = 0;
  @override
  void initState() {
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      // Load all the data from the database
      await _loadFamilySurveyItems();
      if (!mounted) return;

      await _loadEligibleCoupleItems();
      if (!mounted) return;

      await _loadAncItems();
      if (!mounted) return;

      await _loadHbncItems();
      if (!mounted) return;

      await _loadRoutineImmunizationItems();
      if (!mounted) return;

      // Finally, load the completed visits count
      await _loadCompletedVisitsCount();

      // Save counts to storage now that all data is loaded
      await _saveTodayWorkCountsToStorage();

      // Trigger a rebuild to ensure UI is updated
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _loadRoutineImmunizationItems() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final results = await db.query(
        FollowupFormDataTable.table,
        where: 'form_json LIKE ? OR forms_ref_key = ?',
        whereArgs: ['%child_registration_due%', '30bycxe4gv7fqnt6'],
        orderBy: 'id DESC',
      );

      final List<Map<String, dynamic>> items = [];
      final Set<String> seenBeneficiaries = <String>{};

      final now = DateTime.now();
      final todayDateOnly = DateTime(now.year, now.month, now.day);

      for (final row in results) {
        try {
          final formJson = row['form_json'] as String?;
          if (formJson == null || formJson.isEmpty) {
            continue;
          }

          final decoded = jsonDecode(formJson);
          final formType = decoded['form_type']?.toString() ?? '';
          final formsRefKey = row['forms_ref_key']?.toString() ?? '';

          final isChildRegistration =
              formType == FollowupFormDataTable.childRegistrationDue;
          final isChildTracking =
              formsRefKey == '30bycxe4gv7fqnt6' ||
              formType == FollowupFormDataTable.childTrackingDue;

          if (!isChildRegistration && !isChildTracking) {
            continue;
          }

          final formDataMap =
              decoded['form_data'] as Map<String, dynamic>? ?? {};
          final childName = formDataMap['child_name']?.toString() ?? '';
          final beneficiaryRefKey =
              row['beneficiary_ref_key']?.toString() ?? '';

          if (childName.isEmpty) {
            continue;
          }

          if (beneficiaryRefKey.isNotEmpty &&
              seenBeneficiaries.contains(beneficiaryRefKey)) {
            continue;
          }
          if (beneficiaryRefKey.isNotEmpty) {
            seenBeneficiaries.add(beneficiaryRefKey);
          }

          if (beneficiaryRefKey.isNotEmpty) {
            final caseClosureRecords = await db.query(
              FollowupFormDataTable.table,
              where:
                  'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0',
              whereArgs: [beneficiaryRefKey, '%case_closure%'],
            );

            if (caseClosureRecords.isNotEmpty) {
              bool hasCaseClosure = false;
              for (final ccRecord in caseClosureRecords) {
                try {
                  final ccFormJson = ccRecord['form_json'] as String?;
                  if (ccFormJson != null) {
                    final ccDecoded = jsonDecode(ccFormJson);
                    final ccFormDataMap =
                        ccDecoded['form_data'] as Map<String, dynamic>? ?? {};
                    final caseClosure =
                        ccFormDataMap['case_closure']
                            as Map<String, dynamic>? ??
                        {};
                    if (caseClosure['is_case_closure'] == true) {
                      hasCaseClosure = true;
                      break;
                    }
                  }
                } catch (_) {}
              }

              if (hasCaseClosure) {
                continue;
              }
            }
          }

          // Use modified_date_time if available, otherwise created_date_time,
          // and only keep records whose date part equals today's date.
          String? rawDate = row['modified_date_time']?.toString();
          rawDate ??= row['created_date_time']?.toString();

          DateTime? recordDate;
          if (rawDate != null && rawDate.isNotEmpty) {
            try {
              String s = rawDate;
              if (s.contains('T')) {
                s = s.split('T')[0];
              }
              recordDate = DateTime.tryParse(s);
            } catch (_) {}
          }

          if (recordDate == null) {
            continue;
          }

          final recordDateOnly = DateTime(
            recordDate.year,
            recordDate.month,
            recordDate.day,
          );
          // Show records whose date is **up to** today (past or today),
          // and skip only those with future dates.
          if (recordDateOnly.isAfter(todayDateOnly)) {
            continue;
          }

          final created = row['created_date_time']?.toString();
          String lastVisitDate = '-';
          if (created != null && created.isNotEmpty) {
            try {
              final date = DateTime.parse(created);
              lastVisitDate =
                  '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
            } catch (_) {}
          }

          String genderRaw =
              formDataMap['gender']?.toString().toLowerCase() ?? '';
          String gender;
          switch (genderRaw) {
            case 'm':
            case 'male':
              gender = 'Male';
              break;
            case 'f':
            case 'female':
              gender = 'Female';
              break;
            default:
              gender = 'Other';
          }

          String ageText = '-';
          final dobRaw = formDataMap['date_of_birth'];
          if (dobRaw != null && dobRaw.toString().isNotEmpty) {
            try {
              String dateStr = dobRaw.toString();
              DateTime? dob = DateTime.tryParse(dateStr);
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
                if (now.month < dob.month ||
                    (now.month == dob.month && now.day < dob.day)) {
                  years--;
                }
                ageText = years >= 0 ? '${years}y' : '0y';
              }
            } catch (_) {}
          }

          final hhId = row['household_ref_key']?.toString() ?? '';

          items.add({
            'id': _last11(beneficiaryRefKey),
            'household_ref_key': hhId,
            'hhId': hhId,
            'BeneficiaryID': beneficiaryRefKey,
            'name': childName,
            'age': ageText,
            'gender': gender,
            'last Visit date': lastVisitDate,
            'mobile': formDataMap['mobile_number']?.toString() ?? '-',
            'badge': 'RI',
          });
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _riItems = items;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFamilySurveyItems() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final List<Map<String, dynamic>> items = [];

      final headKeyByHousehold = <String, String>{};
      for (final hh in households) {
        try {
          final hhRefKey = (hh['unique_key'] ?? '').toString();
          final headId = (hh['head_id'] ?? '').toString();
          if (hhRefKey.isEmpty || headId.isEmpty) continue;
          headKeyByHousehold[hhRefKey] = headId;
        } catch (_) {}
      }

      for (final row in rows) {
        try {
          final isDeath = row['is_death'] == 1;
          final isMigrated = row['is_migrated'] == 1;
          if (isDeath || isMigrated) continue;

          // Only include household head records similar to AllHouseHold_Screen
          final householdRefKey = (row['household_ref_key'] ?? '').toString();
          final uniqueKey = (row['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) continue;
          final configuredHeadKey = headKeyByHousehold[householdRefKey];
          if (configuredHeadKey == null || configuredHeadKey.isEmpty) continue;
          if (configuredHeadKey != uniqueKey) continue;

          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info = infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw as Map);

          final name = (info['headName'] ?? info['memberName'] ?? info['name'])
              ?.toString()
              .trim();
          if (name == null || name.isEmpty) continue;

          final gender = info['gender']?.toString();

          // Prefer calculating age from DOB if available
          String ageText = '-';
          final dobRaw =
              info['dob']?.toString() ?? info['dateOfBirth']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            try {
              String dateStr = dobRaw;
              if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              final birthDate = DateTime.tryParse(dateStr);
              if (birthDate != null) {
                final now = DateTime.now();
                int ageYears = now.year - birthDate.year;
                if (now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day)) {
                  ageYears--;
                }
                if (ageYears >= 0) {
                  ageText = '${ageYears}y';
                }
              }
            } catch (_) {
              // Fallback below if DOB parsing fails
            }
          }

          if (ageText == '-') {
            final years = info['years']?.toString();
            final approxAge = info['approxAge']?.toString();
            ageText = (years != null && years.isNotEmpty)
                ? '${years}Y'
                : (approxAge != null && approxAge.isNotEmpty)
                ? '${approxAge}y'
                : '-';
          }

          final mobile = (info['mobileNo'] ?? info['phone'])?.toString();

          String lastSurveyDate = '-';
          DateTime? lastSurveyDt;

          String? modifiedRaw = row['modified_date_time']?.toString();
          String? createdRaw = row['created_date_time']?.toString();

          String? pickDateStr(String? raw) {
            if (raw == null || raw.isEmpty) return null;
            String s = raw;
            if (s.contains('T')) {
              s = s.split('T')[0];
            }
            return s;
          }

          // Derive lastSurveyDate from modified_date_time if available, otherwise created_date_time
          String? modifiedStr = pickDateStr(modifiedRaw);
          String? createdStr = pickDateStr(createdRaw);

          if (modifiedStr != null) {
            lastSurveyDt = DateTime.tryParse(modifiedStr);
            lastSurveyDate = modifiedStr;
          } else if (createdStr != null) {
            lastSurveyDt = DateTime.tryParse(createdStr);
            lastSurveyDate = createdStr;
          }

          // 6-month condition: show this family only if the last survey
          // was done more than 6 months ago. If there is no lastSurveyDt,
          // skip (treat as not eligible).
          if (lastSurveyDt == null) {
            continue;
          }
          final now = DateTime.now();
          final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

          // Hide records whose last survey is after sixMonthsAgo (i.e. within
          // the last 6 months). Records dated exactly on or before
          // sixMonthsAgo (6+ months ago) are shown.
          if (lastSurveyDt.isAfter(sixMonthsAgo)) {
            continue;
          }

          String rawId =
              row['unique_key']?.toString() ??
              row['server_id']?.toString() ??
              '-';
          if (rawId.length > 11) {
            rawId = rawId.substring(rawId.length - 11);
          }

          items.add({
            'id': rawId,
            'household_ref_key': row['household_ref_key']?.toString(),
            'name': name,
            'age': ageText,
            'gender': gender ?? '-',
            'last survey date': lastSurveyDate,
            'Next HBNC due date': '-',
            'mobile': mobile ?? '-',
            'badge': 'Family',
          });
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _familySurveyItems = items;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadEligibleCoupleItems() async {
    try {
      if (mounted) {
        setState(() {
          _eligibleCoupleItems = [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadHbncItems() async {
    try {
      _hbncItems = [];

      final Set<String> processedBeneficiaries = <String>{};

      // Get delivery outcome data (similar to HBNCList)
      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey =
          '4r7twnycml3ej1vg'; // Delivery outcome form key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final dbOutcomes = await db.query(
        'followup_form_data',
        where: 'forms_ref_key = ? AND current_user_key = ? AND is_deleted = 0',
        whereArgs: [deliveryOutcomeKey, ashaUniqueKey],
      );

      debugPrint('Found ${dbOutcomes.length} delivery outcomes');

      for (final outcome in dbOutcomes) {
        try {
          final formJson = jsonDecode(outcome['form_json'] as String? ?? '{}');
          final formData = formJson['form_data'] ?? {};
          final beneficiaryRefKey = outcome['beneficiary_ref_key']?.toString();

          if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
            debugPrint(
              '⚠️ Missing beneficiary_ref_key in outcome: ${outcome['id']}',
            );
            continue;
          }

          // Skip if already processed
          if (processedBeneficiaries.contains(beneficiaryRefKey)) {
            debugPrint(
              'ℹ️ Skipping duplicate outcome for beneficiary: $beneficiaryRefKey',
            );
            continue;
          }
          processedBeneficiaries.add(beneficiaryRefKey);

          // Get beneficiary details
          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: 'unique_key = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
            whereArgs: [beneficiaryRefKey],
          );

          if (beneficiaryResults.isEmpty) {
            debugPrint('⚠️ No beneficiary found for key: $beneficiaryRefKey');
            continue;
          }

          final beneficiary = beneficiaryResults.first;
          final beneficiaryInfoRaw =
              beneficiary['beneficiary_info'] as String? ?? '{}';

          Map<String, dynamic> beneficiaryInfo;
          try {
            beneficiaryInfo = jsonDecode(beneficiaryInfoRaw);
          } catch (e) {
            debugPrint('Error parsing beneficiary info: $e');
            continue;
          }

          // Extract data
          final name =
              beneficiaryInfo['memberName']?.toString() ??
              beneficiaryInfo['headName']?.toString() ??
              'N/A';
          final dob = beneficiaryInfo['dob']?.toString();
          final age = _calculateAge(dob);
          final gender =
              (beneficiaryInfo['gender']?.toString() ?? 'female')
                      .toLowerCase() ==
                  'female'
              ? 'Female'
              : 'Male';
          final mobile = beneficiaryInfo['mobileNo']?.toString() ?? '-';
          final spouseName = beneficiaryInfo['spouseName']?.toString() ?? '-';
          final householdRefKey =
              beneficiary['household_ref_key']?.toString() ?? '';

          // Get visit count
          final visitCount = await _getHbncVisitCount(beneficiaryRefKey);

          // Get last and next visit dates
          final lastVisitDate = await _getHbncLastVisitDateForDisplay(
            beneficiaryRefKey,
          );
          final nextVisitDate = await _getHbncNextVisitDateForDisplay(
            beneficiaryRefKey,
            formData['delivery_date']?.toString(),
          );

          // Format the data for display
          // In the _loadHbncItems method, update the formattedData map to include the 'badge' field
          final formattedData = {
            'id': _last11(beneficiaryRefKey),
            'unique_key': beneficiaryRefKey,
            'name': name,
            'age': age,
            'gender': gender,
            'mobile': mobile,
            'spouse_name': spouseName,
            'household_ref_key': householdRefKey,
            'delivery_date': formData['delivery_date']?.toString() ?? '-',
            'last_visit_date': lastVisitDate ?? '-',
            'next_visit_date': nextVisitDate ?? '-',
            'visit_count': visitCount,
            'is_hbnc': true,
            'beneficiary_info': jsonEncode(beneficiaryInfo),
            'form_data': formData,
            'badge': 'HBNC', // Add this line to ensure the badge shows "HBNC"
            'last Visit date':
                lastVisitDate ??
                '-', // Ensure this matches the card's expected field name
            'Current HBNC last due date':
                nextVisitDate ??
                '-', // Ensure this matches the card's expected field name
            'fullBeneficiaryId': beneficiaryRefKey, // Add this for navigation
            'fullHhId': householdRefKey, // Add this for navigation
          };

          setState(() {
            _hbncItems.add(formattedData);
          });
        } catch (e) {
          debugPrint('❌ Error processing outcome ${outcome['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _loadHbncItems: $e');
    } finally {}
  }

  Future<void> _loadAncItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final ancFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .ancDueRegistration] ??
          '';

      final List<Map<String, dynamic>> items = [];
      final Set<String> processedBeneficiaries = {};

      final excludedStates = await db.query(
        'mother_care_activities',
        where:
            "mother_care_state IN ('delivery_outcome', 'hbnc_visit', 'pnc_mother')",
        columns: ['beneficiary_ref_key'],
        distinct: true,
      );

      final excludedBeneficiaryIds = excludedStates
          .map((e) => e['beneficiary_ref_key']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .toSet();

      debugPrint('Excluded beneficiary IDs: $excludedBeneficiaryIds');

      // Get all beneficiaries with anc_due state that are not in excluded states
      final query =
          '''
  SELECT 
    mca.*, 
    bn.*, 
    bn.id AS beneficiary_id, 
    mca.id AS mca_id
  FROM mother_care_activities mca
  INNER JOIN beneficiaries_new bn 
      ON mca.beneficiary_ref_key = bn.unique_key
  WHERE (mca.mother_care_state = 'anc_due' 
         OR mca.mother_care_state = 'anc_due')
    AND bn.is_deleted = 0
    ${excludedBeneficiaryIds.isNotEmpty ? 'AND mca.beneficiary_ref_key NOT IN (${excludedBeneficiaryIds.map((_) => '?').join(',')})' : ''}
  ORDER BY mca.created_date_time DESC
''';

      debugPrint('Executing query: $query');
      debugPrint('With parameters: ${excludedBeneficiaryIds.toList()}');

      final ancDueRecords = await db.rawQuery(
        query,
        excludedBeneficiaryIds.isNotEmpty
            ? excludedBeneficiaryIds.toList()
            : [],
      );

      debugPrint(
        'Found ${ancDueRecords.length} ANC due records after filtering',
      );

      // Process the filtered rows
      for (final row in ancDueRecords) {
        final beneficiaryId = row['beneficiary_ref_key']?.toString() ?? '';
        if (beneficiaryId.isEmpty ||
            processedBeneficiaries.contains(beneficiaryId)) {
          continue; // Skip if already processed or no beneficiary ID
        }
        try {
          processedBeneficiaries.add(beneficiaryId);
          final uniqueKeyFull = row['unique_key']?.toString() ?? '';
          final isDeath = row['is_death'] == 1;
          final isMigrated = row['is_migrated'] == 1;
          if (isDeath || isMigrated) continue;

          // Parse beneficiary_info
          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          Map<String, dynamic> info = {};
          try {
            info = infoRaw is String
                ? jsonDecode(infoRaw) as Map<String, dynamic>
                : Map<String, dynamic>.from(infoRaw as Map);
          } catch (e) {
            debugPrint('Error parsing beneficiary_info: $e');
            continue;
          }
          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          final genderRaw = info['gender']?.toString().toLowerCase() ?? '';

          // For ANC due records, we still want to show them even if not marked as pregnant
          if (!isPregnant && genderRaw != 'f' && genderRaw != 'female')
            continue;

          final name =
              (info['memberName'] ??
                      info['headName'] ??
                      info['name'] ??
                      'Unknown')
                  .toString()
                  .trim();

          String ageText = '-';
          final dobRaw =
              info['dob']?.toString() ?? info['dateOfBirth']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            try {
              String dateStr = dobRaw;
              if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              final birthDate = DateTime.tryParse(dateStr);
              if (birthDate != null) {
                final now = DateTime.now();
                int ageYears = now.year - birthDate.year;
                if (now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day)) {
                  ageYears--;
                }
                if (ageYears >= 0) {
                  ageText = '${ageYears}y';
                }
              }
            } catch (_) {}
          }

          if (ageText == '-') {
            final years = info['years']?.toString();
            final approxAge = info['approxAge']?.toString();
            ageText = (years != null && years.isNotEmpty)
                ? '${years}Y'
                : (approxAge != null && approxAge.isNotEmpty)
                ? '${approxAge}y'
                : '-';
          }

          final mobile = (info['mobileNo'] ?? info['phone'])?.toString();

          String lastVisitDate = '-';
          DateTime? lastVisitDt;

          String? modifiedRaw = row['modified_date_time']?.toString();
          String? createdRaw = row['created_date_time']?.toString();

          String? pickDateStr(String? raw) {
            if (raw == null || raw.isEmpty) return null;
            String s = raw;
            if (s.contains('T')) {
              s = s.split('T')[0];
            }
            return s;
          }

          String? modifiedStr = pickDateStr(modifiedRaw);
          String? createdStr = pickDateStr(createdRaw);

          if (modifiedStr != null) {
            lastVisitDt = DateTime.tryParse(modifiedStr);
            lastVisitDate = modifiedStr;
          } else if (createdStr != null) {
            lastVisitDt = DateTime.tryParse(createdStr);
            lastVisitDate = createdStr;
          }

          DateTime? lmpDate;
          try {
            final lmpRaw = info['lmp']?.toString();
            if (lmpRaw != null && lmpRaw.isNotEmpty) {
              String dateStr = lmpRaw;
              if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              lmpDate = DateTime.tryParse(dateStr);
            }
          } catch (_) {}

          if (lmpDate == null) {
            lmpDate = lastVisitDt ?? DateTime.now();
          }

          final ancRanges = _calculateAncDateRangesForToday(lmpDate);

          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          bool _isTodayInWindow(DateTime start, DateTime end) {
            final startDate = DateTime(start.year, start.month, start.day);
            final endDate = DateTime(end.year, end.month, end.day);
            return (todayDate.isAtSameMomentAs(startDate) ||
                    todayDate.isAfter(startDate)) &&
                (todayDate.isAtSameMomentAs(endDate) ||
                    todayDate.isBefore(endDate));
          }

          bool _hasFormInWindow(
            List<Map<String, dynamic>> forms,
            DateTime start,
            DateTime end,
          ) {
            for (final formRow in forms) {
              try {
                final formJsonRaw = formRow['form_json']?.toString();
                String? dateRaw;

                if (formJsonRaw != null && formJsonRaw.isNotEmpty) {
                  final decoded = jsonDecode(formJsonRaw);
                  if (decoded is Map && decoded['form_data'] is Map) {
                    final formData = Map<String, dynamic>.from(
                      decoded['form_data'] as Map,
                    );
                    dateRaw = formData['date_of_inspection']?.toString();
                  }
                }

                dateRaw ??= formRow['created_date_time']?.toString();
                if (dateRaw == null || dateRaw.isEmpty) {
                  return true;
                }

                String dateStr = dateRaw;
                if (dateStr.contains('T')) {
                  dateStr = dateStr.split('T')[0];
                }
                final dt = DateTime.tryParse(dateStr);
                if (dt == null) {
                  return true;
                }

                final d = DateTime(dt.year, dt.month, dt.day);
                final startDate = DateTime(start.year, start.month, start.day);
                final endDate = DateTime(end.year, end.month, end.day);
                final within =
                    (d.isAtSameMomentAs(startDate) || d.isAfter(startDate)) &&
                    (d.isAtSameMomentAs(endDate) || d.isBefore(endDate));
                if (within) return true;
              } catch (_) {}
            }
            return false;
          }

          List<Map<String, dynamic>> existingForms = [];
          if (ancFormKey.isNotEmpty && uniqueKeyFull.isNotEmpty) {
            existingForms = await db.query(
              FollowupFormDataTable.table,
              columns: ['form_json', 'created_date_time'],
              where: 'forms_ref_key = ? AND beneficiary_ref_key = ? ',
              whereArgs: [ancFormKey, uniqueKeyFull],
            );
          }

          // Determine if any ANC visit (1st–4th) is currently due
          DateTime? dueVisitEndDate;

          final firstStart = ancRanges['1st_anc_start'];
          final firstEnd = ancRanges['1st_anc_end'];
          final secondStart = ancRanges['2nd_anc_start'];
          final secondEnd = ancRanges['2nd_anc_end'];
          final thirdStart = ancRanges['3rd_anc_start'];
          final thirdEnd = ancRanges['3rd_anc_end'];
          final fourthStart = ancRanges['4th_anc_start'];
          final fourthEnd = ancRanges['4th_anc_end'];

          bool hasDueVisit = false;

          if (!hasDueVisit &&
              firstStart != null &&
              firstEnd != null &&
              _isTodayInWindow(firstStart, firstEnd)) {
            if (!_hasFormInWindow(existingForms, firstStart, firstEnd)) {
              hasDueVisit = true;
              dueVisitEndDate = firstEnd;
            }
          }

          if (!hasDueVisit &&
              secondStart != null &&
              secondEnd != null &&
              _isTodayInWindow(secondStart, secondEnd)) {
            if (!_hasFormInWindow(existingForms, secondStart, secondEnd)) {
              hasDueVisit = true;
              dueVisitEndDate = secondEnd;
            }
          }

          if (!hasDueVisit &&
              thirdStart != null &&
              thirdEnd != null &&
              _isTodayInWindow(thirdStart, thirdEnd)) {
            if (!_hasFormInWindow(existingForms, thirdStart, thirdEnd)) {
              hasDueVisit = true;
              dueVisitEndDate = thirdEnd;
            }
          }

          if (!hasDueVisit &&
              fourthStart != null &&
              fourthEnd != null &&
              _isTodayInWindow(fourthStart, fourthEnd)) {
            if (!_hasFormInWindow(existingForms, fourthStart, fourthEnd)) {
              hasDueVisit = true;
              dueVisitEndDate = fourthEnd;
            }
          }

          // If no ANC visit is currently due (or all have forms in their windows), skip this beneficiary
          if (!hasDueVisit || dueVisitEndDate == null) {
            continue;
          }

          // For display, use the end date of the currently due visit window
          final currentAncLastDueDateText =
              '${dueVisitEndDate.year.toString().padLeft(4, '0')}-${dueVisitEndDate.month.toString().padLeft(2, '0')}-${dueVisitEndDate.day.toString().padLeft(2, '0')}';

          final householdRefKey = row['household_ref_key']?.toString() ?? '';

          String rawId = row['unique_key']?.toString() ?? '';
          if (rawId.length > 11) {
            rawId = rawId.substring(rawId.length - 11);
          }

          final uniqueKey = row['unique_key']?.toString() ?? '';

          items.add({
            'id': rawId, // trimmed for display
            'household_ref_key': householdRefKey, // full household key
            'hhId': householdRefKey, // explicit for ANCVisitForm
            'unique_key': uniqueKey, // full beneficiary key
            'BeneficiaryID': uniqueKey,
            'name': name,
            'age': ageText,
            'gender': 'Female',
            'last Visit date': lastVisitDate,
            'Current ANC last due date': currentAncLastDueDateText,
            'mobile': mobile ?? '-',
            'badge': 'ANC',
            // Keep raw data for forms that expect it
            'beneficiary_info': jsonEncode(info),
            '_rawRow': row,
          });
        } catch (_) {
          continue;
        }
      }
      if (mounted) {
        setState(() {
          _ancItems = items;
        });
        debugPrint('Updated _ancItems with ${items.length} filtered records');
      }
    } catch (_) {}
  }

  Future<void> _loadCompletedVisitsCount() async {
    try {
      // Load counts from SecureStorage (both to-do and completed)
      final counts = await SecureStorageService.getTodayWorkCounts();

      print('=== WorkProgress Initial Storage Load ===');
      print('Raw storage data: $counts');
      print('To-Do from storage: ${counts['toDo']}');
      print('Completed from storage: ${counts['completed']}');
      print('=====================================');

      if (mounted) {
        setState(() {
          _completedVisitsCount = counts['completed'] ?? 0;
          // Use stored to-do count instead of recalculating
          _toDoVisitsCount = counts['toDo'] ?? 0;
        });
      }

      print('=== WorkProgress After setState ===');
      print(
        'State - To-Do: $_toDoVisitsCount, Completed: $_completedVisitsCount',
      );
      print('===============================');

      // Initialize completed items lists
      _eligibleCompletedCoupleItems = [];
      _ancCompletedItems = [];
      _hbncCompletedItems = [];
      _riCompletedItems = [];

      // Then load completed items from database (same logic as TodaysProgramm)
      try {
        final db = await DatabaseProvider.instance.database;
        final now = DateTime.now();
        final todayStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final currentUserData = await SecureStorageService.getCurrentUserData();
        String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

        // Load ANC completed items
        try {
          final ancFormKey =
              FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                  .ancDueRegistration] ??
              '';
          if (ancFormKey.isNotEmpty) {
            String motherCareWhereClause =
                '(mother_care_state = ? OR mother_care_state = ? OR mother_care_state = ?) AND (is_deleted IS NULL OR is_deleted = 0) AND DATE(modified_date_time) = DATE(?)';
            List<dynamic> motherCareWhereArgs = [
              'anc_due',
              'anc_visit',
              'delivery_outcome',
              todayStr,
            ];

            if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
              motherCareWhereClause += ' AND current_user_key = ?';
              motherCareWhereArgs.add(ashaUniqueKey);
            }

            final motherCareRows = await db.query(
              'mother_care_activities',
              columns: [
                'beneficiary_ref_key',
                'mother_care_state',
                'modified_date_time',
              ],
              where: motherCareWhereClause,
              whereArgs: motherCareWhereArgs,
            );

            final ancBeneficiaryKeys = motherCareRows
                .map((row) => row['beneficiary_ref_key']?.toString())
                .whereType<String>()
                .toSet();

            if (ancBeneficiaryKeys.isNotEmpty) {
              final placeholders = List.filled(
                ancBeneficiaryKeys.length,
                '?',
              ).join(',');
              String query =
                  'SELECT * FROM ${FollowupFormDataTable.table} '
                  'WHERE forms_ref_key = ? '
                  'AND beneficiary_ref_key IN ($placeholders) '
                  'AND (is_deleted IS NULL OR is_deleted = 0) '
                  'AND DATE(created_date_time) = DATE(?) '
                  'AND current_user_key = ?';

              List<dynamic> args = [
                ancFormKey,
                ...ancBeneficiaryKeys,
                todayStr,
                ashaUniqueKey ?? '',
              ];
              final rows = await db.rawQuery(query, args);

              for (final row in rows) {
                _ancCompletedItems.add({
                  'id': row['id'] ?? '',
                  'BeneficiaryID': row['beneficiary_ref_key'] ?? '',
                  'name': row['beneficiary_ref_key'] ?? '',
                  'badge': 'ANC',
                });
              }
            }
          }
        } catch (e) {
          print('Error loading ANC completed items: $e');
        }

        // Load other completed items (HBNC, EC, RI) - simplified for now
        // The actual logic would be similar to ANC loading above

        final totalCount =
            _ancCompletedItems.length +
            _hbncCompletedItems.length +
            _eligibleCompletedCoupleItems.length +
            _riCompletedItems.length;

        print('=== WorkProgress Completed Items Debug ===');
        print('ANC Completed: ${_ancCompletedItems.length}');
        print('HBNC Completed: ${_hbncCompletedItems.length}');
        print('EC Completed: ${_eligibleCompletedCoupleItems.length}');
        print('RI Completed: ${_riCompletedItems.length}');
        print('Total Completed: $totalCount');
        print('Current _completedVisitsCount: $_completedVisitsCount');
        print('=====================================');

        if (mounted && totalCount > _completedVisitsCount) {
          setState(() {
            _completedVisitsCount = totalCount;
          });
          // Don't save here as it will reset to-do count to 0
          // The to-do count should remain what was loaded from storage
        }
      } catch (e) {}
    } catch (_) {
      if (mounted) {
        setState(() {
          _completedVisitsCount = 0;
          _toDoVisitsCount = 0;
        });
      }
    }
  }

  Future<void> _saveTodayWorkCountsToStorage() async {
    try {
      if (!mounted) return;

      // Calculate to-do count from current items
      final familyCount = _familySurveyItems.length;
      final eligibleCoupleCount = _eligibleCoupleItems.length;
      final ancCount = _ancItems.length;
      final hbncCount = _hbncItems.length;
      final riCount = _riItems.length;

      final toDoCount = familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;
      final completedCount = _completedVisitsCount >= 0
          ? _completedVisitsCount
          : 0;

      print('=== WorkProgress Saving to Storage ===');
      print('Calculated To-Do Count: $toDoCount');
      print('Completed Count: $completedCount');
      print('==================================');

      await SecureStorageService.saveTodayWorkCounts(
        toDo: toDoCount,
        completed: completedCount,
      );

      if (mounted) {
        _refreshData();
      }
    } catch (e) {
      debugPrint('Error saving today\'s work counts: $e');
    }
  }

  Future<void> _reloadCountsFromStorage() async {
    try {
      final counts = await SecureStorageService.getTodayWorkCounts();

      print('=== WorkProgress Delayed Reload ===');
      print('Raw storage data: $counts');
      print('To-Do from storage: ${counts['toDo']}');
      print('Completed from storage: ${counts['completed']}');
      print('==============================');

      if (mounted) {
        setState(() {
          _toDoVisitsCount = counts['toDo'] ?? 0;
          _completedVisitsCount = counts['completed'] ?? 0;
        });

        _loadCountsFromStorage(_bloc);
      }
    } catch (e) {
      print('Error reloading counts: $e');
    }
  }

  String _last11(String? input) {
    if (input == null || input.isEmpty) return '-';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }

  Future<void> _loadCountsFromStorage(TodaysWorkBloc bloc) async {
    try {
      final stored = await SecureStorageService.getTodayWorkCounts();
      final toDo = stored['toDo'] ?? 0;
      final completed = stored['completed'] ?? 0;

      if (!mounted) return;
      bloc.add(TwUpdateCounts(toDo: toDo, completed: completed));
    } catch (_) {}
  }

  Future<int> _getHbncVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        return 0;
      }

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      if (hbncVisitKey == null || hbncVisitKey.isEmpty) {
        return 0;
      }

      final List<Map<String, dynamic>> results = await db.query(
        FollowupFormDataTable.table,
        where:
            'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
      );

      if (results.isEmpty) {
        return 0;
      }

      try {
        final latestRecord = results.first;
        final formJson = jsonDecode(
          latestRecord['form_json'] as String? ?? '{}',
        );
        final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};

        if (formData.containsKey('visitDetails')) {
          final visitDetails =
              formData['visitDetails'] as Map<String, dynamic>? ?? {};
          final visitNumber = visitDetails['visitNumber'] as int? ?? 0;
          return visitNumber;
        }
      } catch (_) {}

      return results.length;
    } catch (_) {
      return 0;
    }
  }

  Future<String?> _getNextHbncVisitDate(
    Database db,
    String beneficiaryId,
    String? deliveryDate,
  ) async {
    if (deliveryDate == null || deliveryDate.isEmpty) return null;
    try {
      final d = DateTime.tryParse(deliveryDate);
      if (d == null) return null;

      // Visit count represents the last completed HBNC step.
      // Schedule in days after delivery: 1,3,7,14,21,28,42
      final schedule = <int>[1, 3, 7, 14, 21, 28, 42];
      final visitCount = await _getHbncVisitCount(beneficiaryId);

      int? nextDay;
      if (visitCount <= 0) {
        // No visits yet -> first step (day 1)
        nextDay = schedule.first;
      } else {
        final idx = schedule.indexOf(visitCount);
        if (idx >= 0 && idx < schedule.length - 1) {
          nextDay = schedule[idx + 1];
        } else {
          // Already completed last scheduled visit (42 days) or
          // visitCount not in schedule -> no further HBNC due
          return null;
        }
      }

      final next = d.add(Duration(days: nextDay!));
      return '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getHbncNextVisitDateForDisplay(
    String beneficiaryId,
    String? deliveryDate,
  ) async {
    try {
      // Use the scheduled HBNC visits (1,3,7,14,21,28,42 days after
      // delivery) to determine the next visit date, then format it for
      // display.
      final db = await DatabaseProvider.instance.database;
      final nextRaw = await _getNextHbncVisitDate(
        db,
        beneficiaryId,
        deliveryDate,
      );
      if (nextRaw == null || nextRaw.isEmpty) {
        return null;
      }

      return _formatHbncDate(nextRaw);
    } catch (_) {}
    return null;
  }

  Future<String?> _getHbncLastVisitDateForDisplay(String beneficiaryId) async {
    try {
      final db = await DatabaseProvider.instance.database;

      final hbncVisitKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];

      final results = await db.query(
        FollowupFormDataTable.table,
        where:
            'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (results.isNotEmpty) {
        final result = results.first;
        try {
          final formJson = jsonDecode(result['form_json'] as String? ?? '{}');
          final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};

          if (formData.containsKey('visitDetails')) {
            final visitDetails = formData['visitDetails'];
            if (visitDetails is Map) {
              final visitDate =
                  visitDetails['visitDate'] ??
                  visitDetails['visit_date'] ??
                  visitDetails['dateOfVisit'] ??
                  visitDetails['date_of_visit'];

              if (visitDate != null && visitDate.toString().isNotEmpty) {
                return _formatHbncDate(visitDate.toString());
              }
            }
          }

          final visitDate =
              formData['visit_date'] ??
              formData['visitDate'] ??
              formData['dateOfVisit'] ??
              formData['date_of_visit'] ??
              formData['visitDate'];

          if (visitDate != null && visitDate.toString().isNotEmpty) {
            return _formatHbncDate(visitDate.toString());
          }

          final createdDate = result['created_date_time'];
          if (createdDate != null && createdDate.toString().isNotEmpty) {
            return _formatHbncDate(createdDate.toString());
          }
        } catch (_) {
          final createdDate = result['created_date_time'];
          if (createdDate != null && createdDate.toString().isNotEmpty) {
            return _formatHbncDate(createdDate.toString());
          }
          return null;
        }
      }
    } catch (_) {}
    return null;
  }

  String _formatHbncDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Map<String, DateTime> _calculateAncDateRangesForToday(DateTime lmp) {
    final ranges = <String, DateTime>{};

    ranges['1st_anc_start'] = lmp;
    ranges['1st_anc_end'] = lmp.add(const Duration(days: 12 * 7));

    ranges['2nd_anc_start'] = lmp.add(const Duration(days: 14 * 7));
    ranges['2nd_anc_end'] = lmp.add(const Duration(days: 24 * 7));

    ranges['3rd_anc_start'] = lmp.add(const Duration(days: 26 * 7));
    ranges['3rd_anc_end'] = lmp.add(const Duration(days: 34 * 7));

    ranges['4th_anc_start'] = lmp.add(const Duration(days: 36 * 7));
    ranges['4th_anc_end'] = lmp.add(const Duration(days: 40 * 7));

    ranges['pmsma_start'] = lmp.add(const Duration(days: 40 * 7));
    ranges['pmsma_end'] = lmp.add(const Duration(days: 44 * 7));

    return ranges;
  }

  int _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 0;
    try {
      DateTime? birthDate;

      // Try parsing the date string
      if (dob.contains('T')) {
        birthDate = DateTime.tryParse(dob.split('T')[0]);
      } else {
        birthDate = DateTime.tryParse(dob);
      }

      if (birthDate == null) {
        // If parsing fails, try to extract date parts manually
        final parts = dob.split(RegExp(r'[^0-9]'));
        if (parts.length >= 3) {
          final year = int.tryParse(parts[0]) ?? 0;
          final month = int.tryParse(parts[1]) ?? 1;
          final day = int.tryParse(parts[2]) ?? 1;
          birthDate = DateTime(year, month, day);
        } else {
          return 0;
        }
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;

      // Adjust age if birthday hasn't occurred yet this year
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return age > 0 ? age : 0;
    } catch (e) {
      print('Error calculating age: $e');
      return 0;
    }
  }

  int? detectSlice(Offset local, int completed, int pending) {
    const size = Size(220, 220);
    final center = Offset(size.width / 2, size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final radius = math.sqrt(dx * dx + dy * dy);
    final maxRadius = size.width / 2;
    if (radius > maxRadius) return null;
    final total = completed + pending;
    if (total == 0) return null;
    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    const start = -math.pi / 2;
    double rel = (angle - start) % (2 * math.pi);
    if (rel < 0) rel += 2 * math.pi;
    final sweepCompleted = (completed / total) * (2 * math.pi);
    if (completed > 0 && rel <= sweepCompleted) return 0;
    if (pending > 0) return 1;
    return null;
  }

  Future<void> _refreshData() async {
    _bloc.add(const TwLoad(toDo: 0, completed: 0));
    await _loadCountsFromStorage(_bloc);
  }

  late TodaysWorkBloc _bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: BlocProvider(
        create: (_) {
          _bloc = TodaysWorkBloc()..add(const TwLoad(toDo: 0, completed: 0));
          _loadCountsFromStorage(_bloc);
          return _bloc;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppHeader(
            screenTitle: l10n?.todayWorkTitle ?? "Today's Work Progress",
            showBack: true,
          ),
          body: SafeArea(
            child: BlocBuilder<TodaysWorkBloc, TodaysWorkState>(
              builder: (context, state) {
                int completed = state.completed;
                int pending = state.pending;

                // Adjust for hidden slices
                if (_selectedSliceFromLegend == 0) completed = 0;
                if (_selectedSliceFromLegend == 1) pending = 0;
                if (_selectedSliceFromLegend == 2) completed = pending = 0;

                final total = completed + pending;
                final progress = state.completed + state.pending == 0
                    ? 0
                    : (state.completed / (state.completed + state.pending)) *
                          100;
                final percent = progress.toStringAsFixed(2);

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv("Total Visits:", "${state.completed + state.pending}"),
                            _kv(
                              '${l10n!.completedVisits} :',
                              state.completed.toString(),
                            ),
                            _kv(
                              '${l10n.pendingVisits}:',
                              state.pending.toString(),
                            ),
                            _kv('${l10n.progress} :', '$percent%'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _legend(
                                  color: Colors.green,
                                  label: l10n.completed,
                                  sliceIndex: 0,
                                ),
                                const SizedBox(width: 16),
                                _legend(
                                  color: AppColors.primary,
                                  label: l10n.pending,
                                  sliceIndex: 1,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: Center(
                                child: SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTapDown: (details) {
                                          int? tappedSlice = detectSlice(
                                            details.localPosition,
                                            completed,
                                            pending,
                                          );
                                          setState(() {
                                            if (_selectedSlice == tappedSlice) {
                                              _selectedSlice = null;
                                            } else {
                                              _selectedSlice = tappedSlice;
                                            }
                                          });
                                        },
                                        child: CustomPaint(
                                          size: const Size(220, 220),
                                          painter: _PiePainter(
                                            completed: completed,
                                            pending: pending,
                                            legendSelected:
                                                _selectedSliceFromLegend,
                                          ),
                                        ),
                                      ),
                                      if (_selectedSlice != null)
                                        _buildTooltip(
                                          completed,
                                          pending,
                                          _selectedSlice!,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: TextStyle(fontSize: 15.sp, color: AppColors.primary),
            ),
          ),
          Text(
            v,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _legend({
    required Color color,
    required String label,
    required int sliceIndex,
  }) {
    // Determine if this slice is striked
    bool isStriked = false;
    if (_selectedSliceFromLegend != null) {
      if (_selectedSliceFromLegend == 2) {
        isStriked = true; // both are striked
      } else if (_selectedSliceFromLegend == sliceIndex) {
        isStriked = true;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          // Toggle this slice only
          if (_selectedSliceFromLegend == null) {
            _selectedSliceFromLegend = sliceIndex; // strike this
          } else if (_selectedSliceFromLegend == sliceIndex) {
            _selectedSliceFromLegend = null; // unstrike this
          } else if (_selectedSliceFromLegend == 2) {
            // Both are striked, toggle only this slice
            // Unstriking this slice => only the other remains
            _selectedSliceFromLegend = sliceIndex == 0 ? 1 : 0;
          } else {
            // One is already striked, toggle the other => both striked
            _selectedSliceFromLegend = 2;
          }

          // Reset pie tooltip
          _selectedSlice = null;
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              decoration: isStriked
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }

  /*Widget _legend({
    required Color color,
    required String label,
    required int sliceIndex,
  }) {
    final bool isStriked =
    (_selectedSliceFromLegend == sliceIndex || _selectedSliceFromLegend == 2);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedSliceFromLegend == sliceIndex) {
            _selectedSliceFromLegend = null; // unstrike
          } else if (_selectedSliceFromLegend == null) {
            _selectedSliceFromLegend = sliceIndex; // strike this
          } else if (_selectedSliceFromLegend != sliceIndex && _selectedSliceFromLegend != 2) {
            _selectedSliceFromLegend = 2; // both strike
          } else if (_selectedSliceFromLegend == 2) {
            _selectedSliceFromLegend = sliceIndex; // only this remains
          }

          _selectedSlice = null; // reset tooltip
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              decoration:
              isStriked ? TextDecoration.lineThrough : TextDecoration.none,
              decorationThickness: 2,
            ),
          ),
        ],
      ),
    );
  }*/

  Widget _balloonTooltip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label: $count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(int completed, int pending, int sliceIndex) {
    final l = AppLocalizations.of(context);
    final total = completed + pending;
    if (total == 0) return const SizedBox.shrink();

    const size = 220.0;
    const center = size / 2;

    double midAngle;
    int count;
    String label;
    Color color;

    const start = -math.pi / 2;
    final full = 2 * math.pi;
    final sweepCompleted = completed / total * full;
    final remainingSweep = full - sweepCompleted;

    if (sliceIndex == 0) {
      label = l!.completed;
      count = completed;
      color = Colors.green;
      midAngle = start + sweepCompleted / 2;
    } else {
      label = l!.pending;
      count = pending;
      color = AppColors.primary;
      midAngle = start + sweepCompleted + remainingSweep / 2;
    }

    const radius = 90.0;
    final dx = center + math.cos(midAngle) * radius;
    final dy = center + math.sin(midAngle) * radius;

    return Positioned(
      left: dx - 40,
      top: dy - 30,
      child: _balloonTooltip(label: label, count: count, color: color),
    );
  }
}

class _PiePainter extends CustomPainter {
  final int completed;
  final int pending;
  final int? legendSelected;

  _PiePainter({
    required this.completed,
    required this.pending,
    required this.legendSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const start = -math.pi / 2;
    const full = 2 * math.pi;

    int comp = completed;
    int pend = pending;

    // Handle legend hiding
    if (legendSelected == 0) comp = 0;
    if (legendSelected == 1) pend = 0;
    if (legendSelected == 2) comp = pend = 0;

    final total = comp + pend;
    if (total == 0) return;

    final paintCompleted = Paint()..color = Colors.green;
    final paintPending = Paint()..color = AppColors.primary;

    if (comp > 0) {
      final sweep = comp / total * full;
      canvas.drawArc(rect, start, sweep, true, paintCompleted);
    }
    if (pend > 0) {
      final sweep = pend / total * full;
      final startAngle = comp > 0 ? (comp / total * full) + start : start;
      canvas.drawArc(rect, startAngle, sweep, true, paintPending);
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.completed != completed ||
      old.pending != pending ||
      old.legendSelected != legendSelected;
}
