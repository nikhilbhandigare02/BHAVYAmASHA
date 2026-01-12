import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
  int _pendingCountVisitsCount = 0;
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

      // Save the counts to storage
      if (mounted) {
        await _saveTodayWorkCountsToStorage();
        // Trigger a rebuild to ensure UI is updated
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }


  Future<void> _loadFamilySurveyItems() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();

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
          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            final rowUserKey = row['current_user_key']?.toString();
            if (rowUserKey != null && rowUserKey != ashaUniqueKey) continue;
          }

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
      //  _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
  }


  Future<void> _loadEligibleCoupleItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final ecFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .eligibleCoupleTrackingDue] ??
              '';

      if (ecFormKey.isEmpty) return;

      // Get current date and 1 month ago date
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 30));
      final oneMonthAgoStr = oneMonthAgo.toIso8601String().split('T')[0];
      final todayStr = now.toIso8601String().split('T')[0];

      // Step 1: Get all eligible_couple records with state = 'eligible_couple'
      // and created/modified before 1 month ago
      String whereClause =
          'eligible_couple_state = ? AND (is_deleted IS NULL OR is_deleted = 0)';
      List<dynamic> whereArgs = ['eligible_couple'];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final eligibleCoupleRows = await db.query(
        'eligible_couple_activities',
        columns: [
          'beneficiary_ref_key',
          'created_date_time',
          'modified_date_time',
        ],
        where: whereClause,
        whereArgs: whereArgs,
      );

      // Filter records where created_date_time or modified_date_time is before 1 month ago
      final eligibleBeneficiaryKeys = <String>{};
      for (final row in eligibleCoupleRows) {
        final beneficiaryKey = row['beneficiary_ref_key']?.toString();
        if (beneficiaryKey == null || beneficiaryKey.isEmpty) continue;

        final createdDateStr = row['created_date_time']?.toString();
        final modifiedDateStr = row['modified_date_time']?.toString();

        bool isOldEnough = false;

        // Check created_date_time
        if (createdDateStr != null && createdDateStr.isNotEmpty) {
          try {
            final createdDate = DateTime.parse(createdDateStr);
            if (createdDate.isBefore(oneMonthAgo)) {
              isOldEnough = true;
            }
          } catch (e) {
            print('Error parsing created_date_time: $e');
          }
        }

        // Check modified_date_time if created_date_time is not old enough
        if (!isOldEnough &&
            modifiedDateStr != null &&
            modifiedDateStr.isNotEmpty) {
          try {
            final modifiedDate = DateTime.parse(modifiedDateStr);
            if (modifiedDate.isBefore(oneMonthAgo)) {
              isOldEnough = true;
            }
          } catch (e) {
            print('Error parsing modified_date_time: $e');
          }
        }

        if (isOldEnough) {
          eligibleBeneficiaryKeys.add(beneficiaryKey);
        }
      }

      if (eligibleBeneficiaryKeys.isEmpty) {
        _eligibleCoupleItems.clear();
        if (mounted) {
          setState(() {});
         // _saveTodayWorkCountsToStorage();
        }
        return;
      }

      final placeholders = List.filled(
        eligibleBeneficiaryKeys.length,
        '?',
      ).join(',');

      // Step 2: Check followup_form_table for entries created TODAY only
      final todayForms = await db.rawQuery(
        '''
        SELECT DISTINCT beneficiary_ref_key
        FROM ${FollowupFormDataTable.table}
        WHERE forms_ref_key = ?
        AND beneficiary_ref_key IN ($placeholders)
        AND (is_deleted IS NULL OR is_deleted = 0)
        AND DATE(created_date_time) = DATE(?)
        ''',
        [ecFormKey, ...eligibleBeneficiaryKeys, todayStr],
      );

      // Create a set of beneficiaries with today's followup forms
      final beneficiariesWithTodayForms = todayForms
          .map((row) => row['beneficiary_ref_key']?.toString())
          .whereType<String>()
          .toSet();

      // Step 3: Only show beneficiaries that have today's followup forms
      final keysToShow = beneficiariesWithTodayForms;

      if (keysToShow.isEmpty) {
        _eligibleCoupleItems.clear();
        if (mounted) {
          setState(() {});
         // _saveTodayWorkCountsToStorage();
        }
        return;
      }

      final placeholdersShow = List.filled(keysToShow.length, '?').join(',');
      final rows = await db.query(
        'beneficiaries_new',
        where:
        'unique_key IN ($placeholdersShow) AND (is_deleted IS NULL OR is_deleted = 0) AND (is_migrated IS NULL OR is_migrated = 0)',
        whereArgs: keysToShow.toList(),
      );

      _eligibleCoupleItems.clear();

      // Group by household to find spouse/head relations for complete data
      final households = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        final hhKey = row['household_ref_key']?.toString() ?? '';
        households.putIfAbsent(hhKey, () => []).add(row);
      }

      for (final household in households.values) {
        Map<String, dynamic>? head;
        Map<String, dynamic>? spouse;

        // Identify Head and Spouse
        for (final member in household) {
          try {
            final dynamic infoRaw = member['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});

            final relation =
            (info['relation_to_head'] ?? info['relation'] ?? '')
                .toString()
                .toLowerCase();
            if (relation.contains('head') || relation == 'self') {
              head = info;
            } else if (relation == 'spouse' ||
                relation == 'wife' ||
                relation == 'husband') {
              spouse = info;
            }
          } catch (_) {}
        }

        for (final member in household) {
          final dynamic infoRaw = member['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info = infoRaw is String
              ? jsonDecode(infoRaw)
              : Map<String, dynamic>.from(infoRaw ?? {});

          final uniqueKey = member['unique_key']?.toString() ?? '';
          final hhKey = member['household_ref_key']?.toString() ?? '';
          // Only show if this member is in our target list
          if (!keysToShow.contains(uniqueKey)) continue;

          final isHead = info == head;
          final isSpouse = info == spouse;
          final Map<String, dynamic> counterpart = isHead && spouse != null
              ? spouse!
              : isSpouse && head != null
              ? head!
              : <String, dynamic>{};

          final name =
              info['memberName']?.toString() ??
                  info['headName']?.toString() ??
                  info['name']?.toString() ??
                  '';
          final dob = info['dob']?.toString() ?? '';

          // Use _calculateAge if available, or parse manually
          int age = 0;
          try {
            if (dob.isNotEmpty) {
              final birthDate = DateTime.tryParse(
                dob.contains('T') ? dob.split('T')[0] : dob,
              );
              if (birthDate != null) {
                final now = DateTime.now();
                age = now.year - birthDate.year;
                if (now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day)) {
                  age--;
                }
              }
            }
          } catch (_) {}

          String ageText = age > 0 ? '$age' : (info['age']?.toString() ?? '-');

          final gender = (info['gender']?.toString().toLowerCase() ?? 'female');
          final mobile = info['mobileNo']?.toString() ?? 'Not Available';

          String lastVisitDate = '-';
          final modified = member['modified_date_time']?.toString();
          final created = member['created_date_time']?.toString();
          if (modified != null && modified.isNotEmpty) {
            lastVisitDate = _formatDateOnly(modified);
          } else if (created != null && created.isNotEmpty) {
            lastVisitDate = _formatDateOnly(created);
          }

          _eligibleCoupleItems.add({
            'id': member['id'] ?? '',
            'household_ref_key': hhKey,
            'hhId': hhKey,
            'unique_key': uniqueKey,
            'BeneficiaryID': uniqueKey,
            'name': name,
            'gender': gender,
            'age': ageText,
            'mobile': mobile,
            'badge': 'EligibleCouple',
            'last Visit date': lastVisitDate,
            '_rawRow': member,
            'spouse_name': counterpart.isNotEmpty
                ? (counterpart['memberName'] ??
                counterpart['headName'] ??
                counterpart['name'])
                : '',
          });
        }
      }

      if (mounted) {
        setState(() {});
        //_saveTodayWorkCountsToStorage();
      }
    } catch (e) {
      debugPrint('EC load error: $e');
    }
  }

  Future<void> _loadAncItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

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
      String query =
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
''';

      List<dynamic> args = excludedBeneficiaryIds.isNotEmpty
          ? excludedBeneficiaryIds.toList()
          : [];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        query += ' AND bn.current_user_key = ?';
        args.add(ashaUniqueKey);
      }

      query += ' ORDER BY mca.created_date_time DESC';

      debugPrint('Executing query: $query');
      debugPrint('With parameters: $args');

      final ancDueRecords = await db.rawQuery(query, args);

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

          // Check if beneficiary has abortion followup form with is_abortion = 'yes'
          final abortionForms = await db.query(
            'followup_form_data',
            where: "forms_ref_key = 'bt7gs9rl1a5d26mz' AND beneficiary_ref_key = ? AND form_json LIKE '%\"is_abortion\"%'",
            whereArgs: [beneficiaryId],
          );

          bool hasAbortion = false;
          for (final form in abortionForms) {
            try {
              final formJson = form['form_json']?.toString();
              if (formJson != null && formJson.isNotEmpty) {
                final decoded = jsonDecode(formJson);
                if (decoded is Map<String, dynamic>) {
                  final ancForm = decoded['anc_form'];
                  if (ancForm is Map<String, dynamic>) {
                    final isAbortion = ancForm['is_abortion']?.toString().toLowerCase();
                    if (isAbortion == 'yes' || isAbortion == 'true' || isAbortion == '1') {
                      hasAbortion = true;
                      break;
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('Error checking abortion form: $e');
            }
          }

          if (hasAbortion) {
            debugPrint('Excluding beneficiary $beneficiaryId - has abortion record');
            continue;
          }

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
                int years = now.year - birthDate.year;
                int months = now.month - birthDate.month;
                int days = now.day - birthDate.day;

                if (days < 0) {
                  final lastMonth = now.month - 1 < 1 ? 12 : now.month - 1;
                  final lastMonthYear = now.month - 1 < 1
                      ? now.year - 1
                      : now.year;
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
                  ageText = '$years Y';
                } else if (months > 0) {
                  ageText = '$months M';
                } else {
                  ageText = '$days D';
                }
              }
            } catch (_) {}
          }

          if (ageText == '-') {
            final years = info['years']?.toString();
            final approxAge = info['approxAge']?.toString();
            ageText = (years != null && years.isNotEmpty)
                ? '${years} Y'
                : (approxAge != null && approxAge.isNotEmpty)
                ? '${approxAge} Y'
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
            lastVisitDate = _formatAncDateOnly(modifiedStr);
          } else if (createdStr != null) {
            lastVisitDt = DateTime.tryParse(createdStr);
            lastVisitDate = _formatAncDateOnly(createdStr);
          }

          // Extract LMP date using the comprehensive logic from ANCVisitListScreen
          DateTime? lmpDate = await _extractLmpDate(row);

          if (lmpDate == null) {
            lmpDate = lastVisitDt ?? DateTime.now();
          }

          final ancRanges = _calculateAncDateRanges(lmpDate);

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

          DateTime? dueVisitStartDate;
          DateTime? dueVisitEndDate;
          String? currentAncVisitName;

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
              dueVisitStartDate = firstStart;
              dueVisitEndDate = firstEnd;
              currentAncVisitName = '1st ANC';
            }
          }

          if (!hasDueVisit &&
              secondStart != null &&
              secondEnd != null &&
              _isTodayInWindow(secondStart, secondEnd)) {
            if (!_hasFormInWindow(existingForms, secondStart, secondEnd)) {
              hasDueVisit = true;
              dueVisitStartDate = secondStart;
              dueVisitEndDate = secondEnd;
              currentAncVisitName = '2nd ANC';
            }
          }

          if (!hasDueVisit &&
              thirdStart != null &&
              thirdEnd != null &&
              _isTodayInWindow(thirdStart, thirdEnd)) {
            if (!_hasFormInWindow(existingForms, thirdStart, thirdEnd)) {
              hasDueVisit = true;
              dueVisitStartDate = thirdStart;
              dueVisitEndDate = thirdEnd;
              currentAncVisitName = '3rd ANC';
            }
          }

          if (!hasDueVisit &&
              fourthStart != null &&
              fourthEnd != null &&
              _isTodayInWindow(fourthStart, fourthEnd)) {
            if (!_hasFormInWindow(existingForms, fourthStart, fourthEnd)) {
              hasDueVisit = true;
              dueVisitStartDate = fourthStart;
              dueVisitEndDate = fourthEnd;
              currentAncVisitName = '4th ANC';
            }
          }

          if (!hasDueVisit ||
              dueVisitStartDate == null ||
              dueVisitEndDate == null) {
            continue;
          }

          final visitCount = await _getVisitCountFromFollowupForm(uniqueKeyFull);
          print('🔍 Visit count for beneficiary $uniqueKeyFull: $visitCount');

          String currentAncLastDueDateText = '';
          DateTime? displayEndDate;

          if (visitCount >= 1 && firstEnd != null) {
            displayEndDate = firstEnd;
          }
          if (visitCount >= 2 && secondEnd != null) {
            displayEndDate = secondEnd;
          }
          if (visitCount >= 3 && thirdEnd != null) {
            displayEndDate = thirdEnd;
          }
          if (visitCount >= 4 && fourthEnd != null) {
            displayEndDate = fourthEnd;
          }

          if (displayEndDate != null) {
            currentAncLastDueDateText = _formatDate(displayEndDate);
            print('✅ ANC end date for visit count $visitCount: $currentAncLastDueDateText');
          } else {
            DateTime displayEndDate = dueVisitEndDate;

            if (currentAncVisitName == '4th ANC') {
              displayEndDate = dueVisitStartDate!.add(const Duration(days: 15));
            }

            currentAncLastDueDateText =
            '${_formatDate(dueVisitStartDate!)} TO ${_formatDate(displayEndDate)}';
          }

          final householdRefKey = row['household_ref_key']?.toString() ?? '';

          String rawId = row['unique_key']?.toString() ?? '';
          if (rawId.length > 11) {
            rawId = rawId.substring(rawId.length - 11);
          }

          final uniqueKey = row['unique_key']?.toString() ?? '';

          items.add({
            'id': rawId,
            'household_ref_key': householdRefKey, // full household key
            'hhId': householdRefKey,
            'unique_key': uniqueKey,
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

      // Removed duplicate ANC due items query as we're now handling this in the main query above

      if (mounted) {
        setState(() {
          _ancItems = items; // Use the already filtered items list
        });
      //  _saveTodayWorkCountsToStorage();
        debugPrint('Updated _ancItems with ${items.length} filtered records');
      }
    } catch (_) {}
  }

  Future<int> _getVisitCountFromFollowupForm(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiary ID provided to _getVisitCountFromFollowupForm');
        return 0;
      }

      final db = await DatabaseProvider.instance.database;
      final ancFormKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';

      if (ancFormKey.isEmpty) {
        print('⚠️ ANC form key is empty');
        return 0;
      }

      // Get the most recent ANC form for this beneficiary
      final result = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND beneficiary_ref_key = ? ',
        whereArgs: [ancFormKey, beneficiaryId],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (result.isEmpty) {
        print('ℹ️ No ANC followup forms found for beneficiary: $beneficiaryId');
        return 0;
      }

      final formJsonStr = result.first['form_json']?.toString();
      if (formJsonStr == null || formJsonStr.isEmpty) {
        print('⚠️ No form_json found in followup form for beneficiary: $beneficiaryId');
        return 0;
      }

      try {
        final formJson = jsonDecode(formJsonStr) as Map<String, dynamic>;

        // Try to get visit_count from anc_form structure
        final ancForm = formJson['anc_form'] as Map<String, dynamic>?;
        if (ancForm != null) {
          final visitCount = ancForm['anc_visit'] as int?;
          if (visitCount != null) {
            print('✅ Found visit count $visitCount in anc_form for beneficiary: $beneficiaryId');
            return visitCount;
          }
        }

        // Try alternative structure (form_data)
        final formData = formJson['form_data'] as Map<String, dynamic>?;
        if (formData != null) {
          final visitCount = formData['anc_visit'] as int?;
          if (visitCount != null) {
            print('✅ Found visit count $visitCount in form_data for beneficiary: $beneficiaryId');
            return visitCount;
          }
        }

        // Try top level
        final visitCount = formJson['anc_visit'] as int?;
        if (visitCount != null) {
          print('✅ Found visit count $visitCount at top level for beneficiary: $beneficiaryId');
          return visitCount;
        }

        print('⚠️ No visit count found in followup form for beneficiary: $beneficiaryId');
        return 0;
      } catch (e) {
        print('❌ Error parsing followup form JSON for beneficiary $beneficiaryId: $e');
        return 0;
      }
    } catch (e) {
      print('❌ Error in _getVisitCountFromFollowupForm for $beneficiaryId: $e');
      return 0;
    }
  }


  String _formatAncDateOnly(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return '-';
    }
  }


  Future<DateTime?> _extractLmpDate(Map<String, dynamic> data) async {
    try {
      dynamic rawInfo = data['beneficiary_info'];
      Map<String, dynamic> info;

      if (rawInfo is String && rawInfo.isNotEmpty) {
        info = jsonDecode(rawInfo) as Map<String, dynamic>;
      } else if (rawInfo is Map) {
        info = Map<String, dynamic>.from(rawInfo as Map);
      } else {
        info = <String, dynamic>{};
      }

      final lmpRaw = info['lmp']?.toString();
      if (lmpRaw != null && lmpRaw.isNotEmpty) {
        String dateStr = lmpRaw;
        if (dateStr.contains('T')) {
          dateStr = dateStr.split('T')[0];
        }
        final lmpDate = DateTime.tryParse(dateStr);
        if (lmpDate != null) {
          print('✅ Found LMP date from beneficiaries_new: ${_formatDate(lmpDate)}');
          return lmpDate;
        }
      }

      // Fallback: try to get from _rawRow if available
      final rawRow = data['_rawRow'] as Map<String, dynamic>?;
      if (rawRow != null) {
        rawInfo = rawRow['beneficiary_info'];
        if (rawInfo is String && rawInfo.isNotEmpty) {
          info = jsonDecode(rawInfo) as Map<String, dynamic>;
        } else if (rawInfo is Map) {
          info = Map<String, dynamic>.from(rawInfo as Map);
        } else {
          info = <String, dynamic>{};
        }

        final lmpRaw = info['lmp']?.toString();
        if (lmpRaw != null && lmpRaw.isNotEmpty) {
          String dateStr = lmpRaw;
          if (dateStr.contains('T')) {
            dateStr = dateStr.split('T')[0];
          }
          final lmpDate = DateTime.tryParse(dateStr);
          if (lmpDate != null) {
            print('✅ Found LMP date from _rawRow: ${_formatDate(lmpDate)}');
            return lmpDate;
          }
        }
      }

      // If not found in beneficiaries_new, check followup forms
      print('⚠️ No LMP found in beneficiaries_new, checking followup forms...');
      final lmpFromFollowup = await _getLmpFromFollowupForm(data);
      if (lmpFromFollowup != null) {
        print('✅ Found LMP date from followup form: ${_formatDate(lmpFromFollowup)}');
        return lmpFromFollowup;
      }

      print('⚠️ No LMP date found in beneficiaries_new or followup forms');
      return null;
    } catch (e) {
      print('⚠️ Error extracting LMP date: $e');
      return null;
    }
  }

  Future<DateTime?> _getLmpFromFollowupForm(Map<String, dynamic> data) async {
    try {
      final benId = data['BeneficiaryID']?.toString() ??
          data['unique_key']?.toString() ??
          (data['_rawRow'] is Map ? (data['_rawRow'] as Map)['unique_key']?.toString() : null);

      final hhId = data['hhId']?.toString() ??
          (data['_rawRow'] is Map ? (data['_rawRow'] as Map)['household_ref_key']?.toString() : null);

      if (benId == null || benId.isEmpty || hhId == null || hhId.isEmpty) {
        print('⚠️ Missing beneficiary ID or household ID for followup form LMP lookup');
        return null;
      }

      final dao = LocalStorageDao();
      final forms = await dao.getFollowupFormsByHouseholdAndBeneficiary(
        formType: FollowupFormDataTable.eligibleCoupleTrackingDue,
        householdId: hhId,
        beneficiaryId: benId,
      );

      if (forms.isEmpty) {
        print('ℹ️ No eligible couple tracking due forms found for beneficiary');
        return null;
      }

      for (final form in forms) {
        final formJsonStr = form['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) {
          continue;
        }

        try {
          final root = Map<String, dynamic>.from(jsonDecode(formJsonStr));

          // Check for LMP date in eligible_couple_tracking_due_from structure
          final trackingData = root['eligible_couple_tracking_due_from'];
          if (trackingData is Map) {
            final lmpStr = trackingData['lmp_date']?.toString();

            if (lmpStr != null && lmpStr.isNotEmpty) {
              try {
                final lmpDate = DateTime.parse(lmpStr);
                print('✅ Found LMP date from followup form: $lmpDate');
                return lmpDate;
              } catch (e) {
                print('⚠️ Error parsing LMP date from followup form: $e');
              }
            }
          }
        } catch (e) {
          print('⚠️ Error parsing followup form JSON: $e');
        }
      }

      print('ℹ️ No LMP date found in any eligible couple tracking due forms');
      return null;
    } catch (e) {
      print('❌ Error loading LMP from followup form: $e');
      return null;
    }
  }



  Map<String, DateTime> _calculateAncDateRanges(DateTime lmp) {
    final ranges = <String, DateTime>{};

    ranges['1st_anc_start'] = lmp;
    ranges['1st_anc_end'] = _dateAfterWeeks(lmp, 12);

    ranges['2nd_anc_start'] = _dateAfterWeeks(lmp, 14);
    ranges['2nd_anc_end'] = _dateAfterWeeks(lmp, 24);
    ranges['3rd_anc_start'] = _dateAfterWeeks(lmp, 26);
    ranges['3rd_anc_end'] = _dateAfterWeeks(lmp, 34);

    ranges['4th_anc_start'] = _dateAfterWeeks(lmp, 36);
    ranges['4th_anc_end'] = _calculateEdd(lmp);

    ranges['pmsma_start'] = ranges['1st_anc_end']!.add(const Duration(days: 1));
    ranges['pmsma_end'] = ranges['2nd_anc_start']!.subtract(const Duration(days: 1));

    return ranges;
  }
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  DateTime _dateAfterWeeks(DateTime startDate, int noOfWeeks) {
    final days = noOfWeeks * 7;
    return startDate.add(Duration(days: days));
  }

  DateTime _calculateEdd(DateTime lmp) {
    return _dateAfterWeeks(lmp, 40);
  }


  Future<void> _loadHbncItems() async {
    try {
      //setState(() => _isLoading = true);
      _hbncItems = [];

      final Set<String> processedBeneficiaries = <String>{};

      // Get delivery outcome data (similar to HBNCList)
      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey =
          '4r7twnycml3ej1vg'; // Delivery outcome form key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      String whereClause = 'forms_ref_key = ?';
      List<dynamic> whereArgs = [deliveryOutcomeKey];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final dbOutcomes = await db.query(
        'followup_form_data',
        where: whereClause,
        whereArgs: whereArgs,
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
          String benWhere =
              'unique_key = ? AND (is_deleted = 0 OR is_deleted IS NULL)';
          List<dynamic> benArgs = [beneficiaryRefKey];

          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            benWhere += ' AND current_user_key = ?';
            benArgs.add(ashaUniqueKey);
          }

          final beneficiaryResults = await db.query(
            'beneficiaries_new',
            where: benWhere,
            whereArgs: benArgs,
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

          // Get visit count and visit number from latest HBNC record
          final visitCount = await _getHbncVisitCount(beneficiaryRefKey);
          final visitNumber = await _getHbncVisitNumber(beneficiaryRefKey);

          // Get last and next visit dates
          final lastVisitDate = await _getHbncLastVisitDateForDisplay(
            beneficiaryRefKey,
          );
          final nextVisitDate = await _getHbncNextVisitDateForDisplay(
            beneficiaryRefKey,
            formData['delivery_date']?.toString(),
          );

          // Apply filtering logic based on visit number
          if (visitNumber != null) {
            // Handle visit number 0 case - show record if today's date matches any criteria
            if (visitNumber == 0) {

              debugPrint(
                '✅ Including HBNC record for $beneficiaryRefKey - visit number 0',
              );
            } else {
              // For other visit numbers, apply specific filtering
              final specificVisitNumbers = [3, 7, 14, 21, 28, 42];
              if (!specificVisitNumbers.contains(visitNumber)) {
                debugPrint(
                  '🗑️ Skipping HBNC record for $beneficiaryRefKey - visit number $visitNumber not in specific list',
                );
                continue;
              }

              // Check if next visit date is today, in the past, or matches today's date
              if (nextVisitDate != null && nextVisitDate.isNotEmpty) {
                final nextDate = _parseDate(nextVisitDate);
                if (nextDate != null) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final nextDateOnly = DateTime(
                    nextDate.year,
                    nextDate.month,
                    nextDate.day,
                  );

                  // Show if next visit date is today, in the past, or exactly matches today
                  if (nextDateOnly.isAfter(today)) {
                    debugPrint(
                      '🗑️ Skipping HBNC record for $beneficiaryRefKey - next visit date $nextVisitDate is in the future',
                    );
                    continue;
                  }

                  // If next visit date is today or in the past, show the record
                  if (nextDateOnly.isBefore(today) ||
                      nextDateOnly.isAtSameMomentAs(today)) {
                    debugPrint(
                      '✅ Including HBNC record for $beneficiaryRefKey - next visit date $nextVisitDate is today or in the past',
                    );
                  } else {
                    debugPrint(
                      '🗑️ Skipping HBNC record for $beneficiaryRefKey - next visit date $nextVisitDate is in the future',
                    );
                    continue;
                  }
                }
              }
            }
          }
          // If visitNumber is null, show all records (existing behavior)

          // Check if beneficiary already has a completed HBNC form (to exclude from to-do list)
          final hasCompletedHbncForm = await _hasCompletedHbncForm(
            beneficiaryRefKey,
          );
          if (hasCompletedHbncForm) {
            debugPrint(
              '🗑️ Skipping HBNC record for $beneficiaryRefKey - already has completed HBNC form',
            );
            continue;
          }

          // Check if visit count will change between current date and next HBNC visit date
          final shouldRemoveFromList =
          await _shouldRemoveHbncRecordDueToCountChange(
            beneficiaryRefKey,
            formData['delivery_date']?.toString(),
            visitCount,
          );

          // If count will change, skip adding this record to list
          if (shouldRemoveFromList) {
            debugPrint(
              '🗑️ Removing HBNC record for $beneficiaryRefKey - visit count will change before next visit',
            );
            continue;
          }

          // Format the data for display
          // In the _loadHbncItems method, update the formattedData map to include the 'badge' field
          final formattedData = {
            'id': _last11(beneficiaryRefKey),
            'unique_key': beneficiaryRefKey,
            'name': name,
            'age': _formatAgeWithSuffix(age),
            'gender': gender,
            'mobile': mobile,
            // spouse_name removed as requested
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
            'next hbnc visit due date':
            nextVisitDate ??
                '-', // Changed from 'Current HBNC last due date' to 'next hbnc visit due date'
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
    } finally {
      //setState(() => _isLoading = false);
    }
  }

  // Helper method to parse date strings in different formats
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      // Try parsing in different formats
      // ISO format: yyyy-MM-dd or yyyy-MM-ddTHH:mm:ss
      if (dateStr.contains('-')) {
        return DateTime.tryParse(dateStr);
      }

      // Format: dd-MM-yyyy
      if (RegExp(r'\d{2}-\d{2}-\d{4}').hasMatch(dateStr)) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
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
  // Helper method to get visit number from latest HBNC record
  Future<int?> _getHbncVisitNumber(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        return null;
      }

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey =
      FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      if (hbncVisitKey == null || hbncVisitKey.isEmpty) {
        return null;
      }

      final results = await db.query(
        FollowupFormDataTable.table,
        where:
        'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      try {
        final latestRecord = results.first;
        final formJson = jsonDecode(
          latestRecord['form_json'] as String? ?? '{}',
        );

        // Check for hbyc_form structure first (based on sample data)
        if (formJson.containsKey('hbyc_form')) {
          final hbycForm = formJson['hbyc_form'] as Map<String, dynamic>? ?? {};
          if (hbycForm.containsKey('visitDetails')) {
            final visitDetails =
                hbycForm['visitDetails'] as Map<String, dynamic>? ?? {};
            final visitNumber = visitDetails['visitNumber']?.toString();
            if (visitNumber != null) {
              final number = int.tryParse(visitNumber);
              if (number != null) {
                return number;
              }
            }
          }
        }

        // Fallback to form_data structure
        final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};

        if (formData.containsKey('visitDetails')) {
          final visitDetails =
              formData['visitDetails'] as Map<String, dynamic>? ?? {};
          final visitNumber =
              visitDetails['visitNumber']?.toString() ??
                  visitDetails['visit_number']?.toString();
          if (visitNumber != null) {
            final number = int.tryParse(visitNumber);
            if (number != null) {
              return number;
            }
          }
        }
      } catch (_) {}
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _hasCompletedHbncForm(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final hbncFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .pncMother] ??
              '';

      if (hbncFormKey.isEmpty) return false;

      String whereClause =
          'forms_ref_key = ? AND beneficiary_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0) AND created_date_time IS NOT NULL AND created_date_time != ""';
      List<dynamic> whereArgs = [hbncFormKey, beneficiaryRefKey];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final result = await db.query(
        FollowupFormDataTable.table,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint(
        'Error checking completed HBNC form for $beneficiaryRefKey: $e',
      );
      return false;
    }
  }
  Future<String?> _getHbncNextVisitDateForDisplay(
      String beneficiaryId,
      String? deliveryDate,
      ) async {
    try {
      // First try to get next visit date from the latest HBNC form data
      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey =
      FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];

      if (hbncVisitKey != null && hbncVisitKey.isNotEmpty) {
        final results = await db.query(
          FollowupFormDataTable.table,
          where:
          'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0',
          whereArgs: [beneficiaryId, hbncVisitKey],
          orderBy: 'created_date_time DESC',
          limit: 1,
        );

        if (results.isNotEmpty) {
          final latestRecord = results.first;
          final formJson = jsonDecode(
            latestRecord['form_json'] as String? ?? '{}',
          );
          final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};

          if (formData.containsKey('visitDetails')) {
            final visitDetails =
                formData['visitDetails'] as Map<String, dynamic>? ?? {};
            final nextVisitDate = visitDetails['nextVisitDate']?.toString();

            // If nextVisitDate is null, assume current date as next visit date
            if (nextVisitDate != null && nextVisitDate.isNotEmpty) {
              return _formatHbncDate(nextVisitDate);
            }
          }
        }
      }

      // Fallback to calculated next visit date if nextVisitDate is null or not found
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

  Future<String?> _getNextHbncVisitDate(
      Database db,
      String beneficiaryId,
      String? deliveryDate,
      ) async {
    if (deliveryDate == null || deliveryDate.isEmpty) return null;
    try {
      final d = DateTime.tryParse(deliveryDate);
      if (d == null) return null;

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
  Future<bool> _shouldRemoveHbncRecordDueToCountChange(
      String beneficiaryId,
      String? deliveryDate,
      int currentVisitCount,
      ) async {
    try {
      if (deliveryDate == null || deliveryDate.isEmpty) return false;

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey =
      FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      if (hbncVisitKey == null || hbncVisitKey.isEmpty) return false;

      // Parse delivery date
      final deliveryDt = DateTime.tryParse(deliveryDate);
      if (deliveryDt == null) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final schedule = <int>[1, 3, 7, 14, 21, 28, 42];
      final futureVisitDates = <DateTime>[];

      for (final day in schedule) {
        final visitDate = deliveryDt.add(Duration(days: day));
        if (visitDate.isAfter(today) || visitDate.isAtSameMomentAs(today)) {
          futureVisitDates.add(visitDate);
        }
      }

      if (futureVisitDates.isEmpty) return false;

      final existingVisits = await db.query(
        FollowupFormDataTable.table,
        where:
        'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time ASC',
      );

      for (final futureVisitDate in futureVisitDates) {
        int visitsByFutureDate = 0;

        for (final visit in existingVisits) {
          final visitCreatedDate = DateTime.tryParse(
            visit['created_date_time']?.toString() ?? '',
          );
          if (visitCreatedDate != null) {
            final visitDateOnly = DateTime(
              visitCreatedDate.year,
              visitCreatedDate.month,
              visitCreatedDate.day,
            );
            if (visitDateOnly.isBefore(futureVisitDate) ||
                visitDateOnly.isAtSameMomentAs(futureVisitDate)) {
              visitsByFutureDate++;
            }
          }
        }

        // Calculate expected visit count based on schedule
        int expectedCount = 0;
        for (int i = 0; i < schedule.length; i++) {
          final scheduledDate = deliveryDt.add(Duration(days: schedule[i]));
          if (scheduledDate.isBefore(futureVisitDate) ||
              scheduledDate.isAtSameMomentAs(futureVisitDate)) {
            expectedCount = i + 1;
          } else {
            break;
          }
        }

        // If counts don't match, the record should be removed
        if (visitsByFutureDate != expectedCount) {
          debugPrint(
            '📊 Count mismatch for $beneficiaryId by ${_formatHbncDate(futureVisitDate.toIso8601String())}: expected=$expectedCount, actual=$visitsByFutureDate',
          );
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking HBNC count change: $e');
      return false;
    }
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

  String _formatAgeWithSuffix(int age) {
    if (age <= 0) return '0 Y';

    final now = DateTime.now();
    // We need to calculate more precise age, so let's use the same logic as _formatAgeGender
    // But since we only have years, we'll just show years with Y suffix
    return '$age Y';
  }

  Future<void> _loadRoutineImmunizationItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // Get all child beneficiaries (same logic as RoutineScreen)
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        '''
        SELECT 
          B.*
        FROM beneficiaries_new B
        WHERE 
          B.is_deleted = 0
          AND B.is_adult = 0
          AND B.is_migrated = 0
          AND B.current_user_key = ?
        ORDER BY B.created_date_time DESC
      ''',
        [ashaUniqueKey],
      );

      // Get last visit dates from child_care_activities (same logic as RoutineScreen)
      final lastVisitDates = <String, String>{};
      final childCareRecords = await db.rawQuery('''
        SELECT 
          beneficiary_ref_key, 
          created_date_time,
          child_care_state
        FROM child_care_activities 
        ORDER BY created_date_time DESC
      ''');

      final Map<String, Map<String, dynamic>> latestRecordsByBeneficiary = {};
      for (var record in childCareRecords) {
        final beneficiaryKey = record['beneficiary_ref_key']?.toString();
        if (beneficiaryKey != null &&
            !latestRecordsByBeneficiary.containsKey(beneficiaryKey)) {
          latestRecordsByBeneficiary[beneficiaryKey] = record;
        }
      }

      // Extract latest dates from records
      for (var entry in latestRecordsByBeneficiary.entries) {
        final beneficiaryKey = entry.key;
        final record = entry.value;
        final createdDate = record['created_date_time']?.toString();
        if (createdDate != null) {
          lastVisitDates[beneficiaryKey] = createdDate;
        }
      }

      final List<Map<String, dynamic>> items = [];
      final Set<String> seenBeneficiaries = <String>{};

      for (final row in rows) {
        try {
          final beneficiaryRefKey = row['unique_key']?.toString() ?? '';

          if (beneficiaryRefKey.isEmpty) continue;
          if (seenBeneficiaries.contains(beneficiaryRefKey)) continue;
          seenBeneficiaries.add(beneficiaryRefKey);

          // Get beneficiary info
          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          final memberType = info['memberType']?.toString().toLowerCase() ?? '';
          final relation = info['relation']?.toString().toLowerCase() ?? '';

          // Only include children
          if (!(memberType == 'child' ||
              relation == 'child' ||
              memberType == 'Child' ||
              relation == 'daughter')) {
            continue;
          }

          // Check if child has tracking_due status in child_care_activities
          final hasTrackingDue = await _hasTrackingDueStatus(beneficiaryRefKey);
          if (!hasTrackingDue) {
            continue;
          }

          // Check if there's a followup record with form_ref_key "30bycxe4gv7fqnt6" created today
          final now = DateTime.now();
          final todayStr =
              '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          final followupQuery = '''
            SELECT * FROM ${FollowupFormDataTable.table}
            WHERE forms_ref_key = ?
            AND beneficiary_ref_key = ?
            AND (is_deleted IS NULL OR is_deleted = 0)
            AND DATE(created_date_time) = DATE(?)
            ORDER BY created_date_time DESC
            LIMIT 1
          ''';

          final followupRecords = await db.rawQuery(followupQuery, ['30bycxe4gv7fqnt6', beneficiaryRefKey, todayStr]);

          // If there's a record created today, exclude this beneficiary from the to-do list
          if (followupRecords.isNotEmpty) {
            print('Excluding beneficiary $beneficiaryRefKey from RI to-do list - followup record created today');
            continue;
          }

          // Check for case closure (deceased)
          String ccWhere =
              'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
          List<dynamic> ccArgs = [beneficiaryRefKey, '%case_closure%'];

          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            ccWhere += ' AND current_user_key = ?';
            ccArgs.add(ashaUniqueKey);
          }

          final caseClosureRecords = await db.query(
            FollowupFormDataTable.table,
            where: ccWhere,
            whereArgs: ccArgs,
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
                      ccFormDataMap['case_closure'] as Map<String, dynamic>? ??
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

          // Extract child information
          final name =
              info['name']?.toString() ??
                  info['memberName']?.toString() ??
                  info['member_name']?.toString() ??
                  '';

          final mobileNo =
              info['mobileNo']?.toString() ??
                  info['mobile']?.toString() ??
                  info['mobile_number']?.toString() ??
                  '';

          final richId =
              info['RichIDChanged']?.toString() ??
                  info['richIdChanged']?.toString() ??
                  info['richId']?.toString() ??
                  '';

          final dob =
              info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];
          final gender = info['gender'] ?? info['sex'];

          // Calculate age using same logic as RegisterChildListScreen
          String ageText = _formatAgeOnly(dob);
          final genderRaw = gender?.toString().toLowerCase() ?? '';
          String displayGender;
          switch (genderRaw) {
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

          // Get last visit date from child_care_activities (same logic as RoutineScreen)
          String lastVisitDate;
          if (lastVisitDates.containsKey(beneficiaryRefKey)) {
            lastVisitDate = _formatDateFromString(
              lastVisitDates[beneficiaryRefKey],
            );
          } else {
            lastVisitDate = 'Not Available';
          }

          final hhId = row['household_ref_key']?.toString() ?? '';

          items.add({
            'id': _last11(beneficiaryRefKey),
            'household_ref_key': hhId,
            'hhId': hhId,
            'BeneficiaryID': beneficiaryRefKey,
            'name': name,
            'age': ageText,
            'gender': displayGender,
            'last Visit date': lastVisitDate,
            'mobile': mobileNo.isNotEmpty ? mobileNo : '-',
            'badge': 'RI',
          });
        } catch (e) {
          print('⚠️ Error processing beneficiary record: $e');
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _riItems = items;
        });
       // _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
  }

  Future<bool> _hasTrackingDueStatus(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        'child_care_activities',
        where:
        'beneficiary_ref_key = ? AND child_care_state = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey, 'tracking_due'],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (e) {
      print('Error checking tracking_due status for $beneficiaryRefKey: $e');
      return false;
    }
  }

  String _formatDateFromString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not Available';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatAgeOnly(dynamic dobRaw) {
    String age = 'Not Available';

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

    return age;
  }

  Future<void> _loadCompletedVisitsCount() async {
    try {
      final counts = await SecureStorageService.getTodayWorkCounts();
      if (mounted) {
        setState(() {
          _completedVisitsCount = counts['completed'] ?? 0;
          _toDoVisitsCount = counts['toDo'] ?? 0;
        });
      }

      _eligibleCompletedCoupleItems = [];
      _ancCompletedItems = [];
      _hbncCompletedItems = [];
      _riCompletedItems = [];

      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      try {
        final db = await DatabaseProvider.instance.database;

        final now = DateTime.now();
        final todayStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        // Only get today's date for completed visits filter

        print('=== Date Range for Completed Visits Filter ===');
        print('Today String: $todayStr');
        print('Current DateTime: $now');
        print('============================================');

        // Debug: Check all records in followup_form_data for today only
        final debugQuery =
            'SELECT * FROM ${FollowupFormDataTable.table} WHERE DATE(created_date_time) = DATE(?) AND (is_deleted IS NULL OR is_deleted = 0)';
        final debugRows = await db.rawQuery(debugQuery, [todayStr]);
        print('=== DEBUG: All followup_form_data records for today ===');
        print('Total records found: ${debugRows.length}');
        for (final row in debugRows) {
          print(
            'ID: ${row['id']}, forms_ref_key: ${row['forms_ref_key']}, beneficiary_ref_key: ${row['beneficiary_ref_key']}, created_date_time: ${row['created_date_time']}, current_user_key: ${row['current_user_key']}',
          );
        }
        print('================================================');

        // Debug: Check what form keys we're looking for
        print('=== DEBUG: Form Keys We Are Looking For ===');
        final ancFormKey =
            FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                .ancDueRegistration] ??
                '';
        final ecFormKey =
            FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                .eligibleCoupleTrackingDue] ??
                '';
        final hbncFormKey =
            FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                .pncMother] ??
                '';
        print('ANC Form Key: $ancFormKey');
        print('EC Form Key: $ecFormKey');
        print('HBNC Form Key: $hbncFormKey');
        print('RI Form Key: 30bycxe4gv7fqnt6');
        print('Current ASHA Key: $ashaUniqueKey');
        print('=========================================');

        if (ancFormKey.isEmpty) return;

        try {
          // Direct query for ANC completed forms created today only
          String query =
              'SELECT f.* FROM ${FollowupFormDataTable.table} f '
              'JOIN beneficiaries_new b ON f.beneficiary_ref_key = b.unique_key '
              'WHERE f.forms_ref_key = ? '
              'AND (f.is_deleted IS NULL OR f.is_deleted = 0) '
              'AND DATE(f.created_date_time) = DATE(?) '
              'AND f.current_user_key = ? '
              'AND (b.is_death IS NULL OR b.is_death = 0)';

          List<dynamic> args = [ancFormKey, todayStr, ashaUniqueKey ?? ''];

          print('=== ANC Completed Query ===');
          print('Query: $query');
          print('Args: $args');
          print('============================');

          final rows = await db.rawQuery(query, args);

          print(
            'Found ${rows.length} ANC followup forms with created_date_time',
          );

          for (final row in rows) {
            final beneficiaryId = row['beneficiary_ref_key']?.toString() ?? '';

            // Decode form_json
            final Map<String, dynamic> formJson = row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};

            // Get anc_form
            final Map<String, dynamic> ancForm = formJson['anc_form'] ?? {};

            final fields = beneficiaryId.isNotEmpty
                ? await _getBeneficiaryFields(beneficiaryId)
                : {
              'name': ancForm['woman_name']?.toString() ?? '',
              'age': ancForm['age']?.toString() ?? '',
              'gender': 'Female',
              'mobile': ancForm['mobile']?.toString() ?? '-',
            };

            _ancCompletedItems.add({
              'id': row['id'] ?? '',
              'household_ref_key': row['household_ref_key'] ?? '',
              'hhId': row['household_ref_key'] ?? '',
              'unique_key': row['beneficiary_ref_key'] ?? '',
              'BeneficiaryID': row['beneficiary_ref_key'] ?? '',
              'name': fields['name'],
              'age': fields['age'],
              'gender': fields['gender']?.isNotEmpty == true
                  ? fields['gender']
                  : 'Female',
              'last Visit date': _formatAncDateOnly(
                row['created_date_time']?.toString(),
              ),
              'Current ANC last due date': '',
              'mobile': fields['mobile'],
              'badge': 'ANC',
              '_rawRow': row,
            });
          }
        } catch (e) {
          print('Error in ANC query: $e');
        }
        try {
          _eligibleCompletedCoupleItems = [];

          final ecFormKey =
              FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                  .eligibleCoupleTrackingDue] ??
                  '';

          if (ecFormKey.isNotEmpty) {
            // 1. Get all EC Tracking Due forms created TODAY only
            String queryForms =
                'SELECT * FROM ${FollowupFormDataTable.table} '
                'WHERE forms_ref_key = ? '
                'AND (is_deleted IS NULL OR is_deleted = 0) '
                'AND DATE(created_date_time) = DATE(?)';

            List<dynamic> argsForms = [ecFormKey, todayStr];

            if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
              queryForms += ' AND current_user_key = ?';
              argsForms.add(ashaUniqueKey);
            }

            queryForms += ' ORDER BY created_date_time DESC';

            print('=== EC Completed Query ===');
            print('Query: $queryForms');
            print('Args: $argsForms');
            print('===========================');

            final formRows = await db.rawQuery(queryForms, argsForms);

            final processedBeneficiaries = <String>{};

            for (final row in formRows) {
              final beneficiaryId =
                  row['beneficiary_ref_key']?.toString() ?? '';
              if (beneficiaryId.isEmpty ||
                  processedBeneficiaries.contains(beneficiaryId))
                continue;

              // 2. Check Eligible Couple Activities conditions
              // Condition A: State is 'tracking_due'
              // Condition B: First created_date_time < 1 month ago

              final activityCheckQuery = '''
                 SELECT MIN(created_date_time) as first_created,
                        MAX(CASE WHEN eligible_couple_state = 'tracking_due' THEN 1 ELSE 0 END) as has_tracking_due
                 FROM eligible_couple_activities
                 WHERE beneficiary_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)
               ''';

              final activityResult = await db.rawQuery(activityCheckQuery, [
                beneficiaryId,
              ]);

              if (activityResult.isEmpty) continue;

              final firstCreated = activityResult.first['first_created']
                  ?.toString();
              final hasTrackingDue =
                  (activityResult.first['has_tracking_due'] as int?) == 1;

              if (!hasTrackingDue) continue; // Condition A failed

              if (firstCreated == null) continue;

              // Date comparison: created < 1 month ago
              // Using SQLite DATE function logic in Dart or just comparing ISO strings if standard
              // To be safe, parse DateTime
              bool isOldEnough = false;
              try {
                final firstDate = DateTime.parse(firstCreated);
                final oneMonthAgo = DateTime.now().subtract(
                  const Duration(days: 30),
                );
                if (firstDate.isBefore(oneMonthAgo)) {
                  isOldEnough = true;
                }
              } catch (e) {
                print('Error parsing date for EC check: $e');
              }

              if (!isOldEnough) continue; // Condition B failed

              processedBeneficiaries.add(beneficiaryId);

              // Decode form_json
              final Map<String, dynamic> formJson = row['form_json'] != null
                  ? jsonDecode(row['form_json'] as String)
                  : {};

              final Map<String, dynamic> ecForm =
                  formJson['eligible_couple_tracking_due_from'] ?? {};

              final fields = await _getBeneficiaryFields(beneficiaryId);

              _eligibleCompletedCoupleItems.add({
                'id': row['id'] ?? '',
                'household_ref_key': row['household_ref_key']?.toString() ?? '',
                'hhId': row['household_ref_key']?.toString() ?? '',
                'unique_key': row['beneficiary_ref_key'] ?? '',
                'BeneficiaryID': row['beneficiary_ref_key'] ?? '',
                'name': fields['name'],
                'age': fields['age'],
                'gender': fields['gender']?.isNotEmpty == true
                    ? fields['gender']
                    : 'Female',
                'last Visit date': _formatDateOnly(
                  row['created_date_time']?.toString(),
                ),
                'Current ANC last due date': '',
                'mobile': fields['mobile'],
                'badge': 'EligibleCouple',
                '_rawRow': row,
              });
            }
          }
        } catch (e) {
          print('Error in eligible couple query: $e');
        }

        try {
          final hbncFormKey =
              FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                  .pncMother] ??
                  '';

          final formKeysHBNC = <String>[];
          if (hbncFormKey.isNotEmpty) formKeysHBNC.add(hbncFormKey);

          if (formKeysHBNC.isEmpty) return;

          final placeholdersHBNC = List.filled(
            formKeysHBNC.length,
            '?',
          ).join(',');

          String queryHBNC =
              'SELECT * FROM ${FollowupFormDataTable.table} '
              'WHERE forms_ref_key IN ($placeholdersHBNC) '
              'AND (is_deleted IS NULL OR is_deleted = 0) '
              'AND created_date_time LIKE ?';
          List<dynamic> argsHBNC = [...formKeysHBNC, '$todayStr%'];

          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            queryHBNC += ' AND current_user_key = ?';
            argsHBNC.add(ashaUniqueKey);
          }

          print('=== HBNC Completed Query ===');
          print('Query: $queryHBNC');
          print('Args: $argsHBNC');
          print('============================');

          final rowsHBNC = await db.rawQuery(queryHBNC, argsHBNC);

          print('=== HBNC Query Results ===');
          print('HBNC Records Found: ${rowsHBNC.length}');
          for (final row in rowsHBNC) {
            print(
              'HBNC Row: ID=${row['id']}, forms_ref_key=${row['forms_ref_key']}, beneficiary=${row['beneficiary_ref_key']}',
            );
          }
          print('==========================');

          final List<Map<String, dynamic>> hbncCompleted = [];

          for (final row in rowsHBNC) {
            final beneficiaryId = row['beneficiary_ref_key']?.toString() ?? '';

            final Map<String, dynamic> formJson = row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};

            final Map<String, dynamic> hbncForm =
                formJson['pnc_mother_form'] ?? {};

            final fields = beneficiaryId.isNotEmpty
                ? await _getBeneficiaryFields(beneficiaryId)
                : {
              'name': hbncForm['mother_name']?.toString() ?? '',
              'age': hbncForm['age']?.toString() ?? '',
              'gender': 'Female',
              'mobile': hbncForm['mobile']?.toString() ?? '-',
            };

            hbncCompleted.add({
              'id': row['id'] ?? '',
              'household_ref_key': row['household_ref_key']?.toString() ?? '',
              'hhId': row['household_ref_key']?.toString() ?? '',
              'unique_key': row['beneficiary_ref_key']?.toString() ?? '',
              'BeneficiaryID': row['beneficiary_ref_key']?.toString() ?? '',
              'name': fields['name'],
              'age': fields['age'],
              'gender': fields['gender']?.isNotEmpty == true
                  ? fields['gender']
                  : 'Female',
              'last Visit date': _formatDateOnly(
                row['created_date_time']?.toString(),
              ),
              'mobile': fields['mobile'],
              'badge': 'HBNC',
              '_rawRow': row,
            });
          }

          if (mounted) {
            setState(() {
              _hbncCompletedItems = hbncCompleted;
            });
          }
        } catch (e) {
          debugPrint('HBNC error: $e');
        }

        try {
          String queryRI =
              'SELECT f.* FROM ${FollowupFormDataTable.table} f '
              'JOIN beneficiaries_new b ON f.beneficiary_ref_key = b.unique_key '
              'WHERE f.forms_ref_key = ? '
              'AND f.created_date_time LIKE ? '
              'AND (b.is_death IS NULL OR b.is_death = 0)';

          List<dynamic> argsRI = ['30bycxe4gv7fqnt6', '$todayStr%'];

          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            queryRI += ' AND f.current_user_key = ?';
            argsRI.add(ashaUniqueKey);
          }

          queryRI += ' ORDER BY f.id DESC';

          print('=== RI Completed Query ===');
          print('Query: $queryRI');
          print('Args: $argsRI');
          print('===========================');

          final resulrowsRI = await db.rawQuery(queryRI, argsRI);

          print('=== RI Query Results ===');
          print('RI Records Found: ${resulrowsRI.length}');
          for (final row in resulrowsRI) {
            print(
              'RI Row: ID=${row['id']}, forms_ref_key=${row['forms_ref_key']}, beneficiary=${row['beneficiary_ref_key']}',
            );
          }
          print('=========================');

          _riCompletedItems = [];

          for (final row in resulrowsRI) {
            final beneficiaryId = row['beneficiary_ref_key']?.toString() ?? '';

            final Map<String, dynamic> formJson = row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};

            final Map<String, dynamic> riForm =
                formJson['child_registration_due_form'] ??
                    formJson['tracking_due_form'] ??
                    formJson['form_data'] ??
                    {};

            // Get beneficiary data to extract DOB for proper age calculation
            final beneficiaryData = beneficiaryId.isNotEmpty
                ? await LocalStorageDao.instance.getBeneficiaryByUniqueKey(
              beneficiaryId,
            )
                : null;

            String childName = '';
            String childDob = '';
            String childGender = '';
            String mobile = '';

            // Try to get child info from form data first
            childName =
                riForm['child_name']?.toString() ??
                    riForm['name']?.toString() ??
                    '';
            childGender = riForm['gender']?.toString() ?? '';
            mobile =
                riForm['mobile']?.toString() ??
                    riForm['mother_mobile']?.toString() ??
                    '-';

            // Extract DOB from beneficiary data if available
            if (beneficiaryData != null) {
              dynamic info = beneficiaryData['beneficiary_info'];
              Map<String, dynamic> beneficiaryInfo = {};

              if (info is Map) {
                beneficiaryInfo = Map<String, dynamic>.from(info);
              } else if (info is String && info.isNotEmpty) {
                try {
                  beneficiaryInfo = Map<String, dynamic>.from(jsonDecode(info));
                } catch (_) {}
              }

              // Use beneficiary name if form name is empty
              if (childName.isEmpty) {
                childName =
                    beneficiaryInfo['name']?.toString() ??
                        beneficiaryInfo['memberName']?.toString() ??
                        '';
              }

              // Extract DOB from beneficiary info
              childDob =
                  beneficiaryInfo['dob']?.toString() ??
                      beneficiaryInfo['dateOfBirth']?.toString() ??
                      beneficiaryInfo['date_of_birth']?.toString() ??
                      '';

              // Use beneficiary gender if form gender is empty
              if (childGender.isEmpty) {
                childGender =
                    beneficiaryInfo['gender']?.toString() ??
                        beneficiaryInfo['sex']?.toString() ??
                        'Female';
              }

              // Use beneficiary mobile if form mobile is empty
              if (mobile == '-' || mobile.isEmpty) {
                mobile =
                    beneficiaryInfo['mobileNo']?.toString() ??
                        beneficiaryInfo['mobile']?.toString() ??
                        beneficiaryInfo['phone']?.toString() ??
                        '-';
              }
            }

            // Calculate age using DOB with same logic as RegisterChildListScreen
            String calculatedAgeGender = _formatAgeGenderFromDob(
              childDob,
              childGender,
            );

            // Extract only the age part (before the |) to avoid duplication in UI
            String calculatedAge = calculatedAgeGender.contains('|')
                ? calculatedAgeGender.split('|')[0].trim()
                : calculatedAgeGender;

            _riCompletedItems.add({
              'id': row['id'] ?? '',
              'household_ref_key': row['household_ref_key']?.toString() ?? '',
              'hhId': row['household_ref_key']?.toString() ?? '',
              'unique_key': row['beneficiary_ref_key']?.toString() ?? '',
              'BeneficiaryID': row['beneficiary_ref_key']?.toString() ?? '',

              'name': childName.isNotEmpty ? childName : 'Unknown',
              'age': calculatedAge,
              'gender': childGender.isNotEmpty ? childGender : 'Female',
              'last Visit date': _formatDateOnly(
                row['created_date_time']?.toString(),
              ),
              'mobile': mobile,
              'badge': 'RI',

              '_rawRow': row,
            });
          }
        } catch (e) {
          debugPrint('RI error: $e');
        }

        /* final rows = await db.rawQuery(
          'SELECT COUNT(*) AS cnt FROM ${FollowupFormDataTable.table} '
              'WHERE forms_ref_key IN ($placeholders) '
              'AND (is_deleted IS NULL OR is_deleted = 0) '
              'AND DATE(created_date_time) = DATE(?)',
          [...formKeys, todayStr],
        );*/

        final count =
            (_ancCompletedItems.length) +
                (_eligibleCompletedCoupleItems.length ?? 0) +
                (_hbncCompletedItems.length ?? 0) +
                (_riCompletedItems.length ?? 0);
        if (mounted) {
          setState(() {
            _completedVisitsCount = count;
          });
          //await _saveTodayWorkCountsToStorage();
        }

        // Print completed items count to console
       // _printCompletedItemsCount();
      } catch (e) {
        print(e);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _completedVisitsCount = 0;
        });
      }
    }
  }

  String _formatAgeGenderFromDob(dynamic dobRaw, dynamic genderRaw) {
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


  Future<Map<String, String>> _getBeneficiaryFields(String uniqueKey) async {
    final rec = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(
      uniqueKey,
    );
    if (rec == null) {
      return {'name': '', 'age': '', 'gender': '', 'mobile': '-'};
    }

    dynamic info = rec['beneficiary_info'];
    Map<String, dynamic> m = {};
    if (info is Map) {
      m = Map<String, dynamic>.from(info);
    } else if (info is String && info.isNotEmpty) {
      try {
        m = Map<String, dynamic>.from(jsonDecode(info));
      } catch (_) {}
    }

    final name =
        (m['name']?.toString()?.trim().isNotEmpty == true
            ? m['name']?.toString()
            : null) ??
            m['memberName']?.toString() ??
            m['headName']?.toString() ??
            '';

    final dob = m['dob']?.toString() ?? m['date_of_birth']?.toString();
    var ageYears = _calculateAge(dob);
    if (ageYears == 0) {
      final updateYearStr = m['updateYear']?.toString() ?? '';
      final approxAgeStr = m['approxAge']?.toString() ?? '';
      final parsedUpdateYear = int.tryParse(updateYearStr);
      if (parsedUpdateYear != null && parsedUpdateYear > 0) {
        ageYears = parsedUpdateYear;
      } else if (approxAgeStr.isNotEmpty) {
        final matches = RegExp(r"\d+").allMatches(approxAgeStr).toList();
        if (matches.isNotEmpty) {
          ageYears = int.tryParse(matches.first.group(0) ?? '') ?? 0;
        }
      }
    }

    final gender = m['gender']?.toString() ?? '';
    final mobile =
        (m['mobileNo'] ?? m['mobile'] ?? m['phone'])?.toString() ?? '-';

    return {
      'name': name,
      'age': ageYears > 0 ? ageYears.toString() : '',
      'gender': gender,
      'mobile': mobile.isNotEmpty ? mobile : '-',
    };
  }


  Future<void> _saveTodayWorkCountsToStorage() async {
    try {
      if (!mounted) return;

      final familyCount = _familySurveyItems.length;
      final eligibleCoupleCount = _eligibleCoupleItems.length;
      final ancCount = _ancItems.length;
      final hbncCount = _hbncItems.length;
      final riCount = _riItems.length;

      // Calculate total to-do count (excluding completed visits)
      final totalToDoCount =
          familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;

      print('Completed Count: $_completedVisitsCount');
      // Ensure we don't have negative counts
      final toDoCount = totalToDoCount >= 0 ? totalToDoCount : 0;
      final completedCount = _completedVisitsCount >= 0
          ? _completedVisitsCount
          : 0;

      // Save to secure storage
      print('=== TodaysProgramm Saving to Storage ===');
      print('To-Do Count: $toDoCount');
      print('Completed Count: $completedCount');
      print('====================================');

      _pendingCountVisitsCount = toDoCount;
      _toDoVisitsCount = _pendingCountVisitsCount +_completedVisitsCount;

      setState(() {
        _pendingCountVisitsCount;
        _toDoVisitsCount;
        _completedVisitsCount;

      });

      // 5. Update the Bloc DIRECTLY (This stops the flickering)
     // if (mounted && _bloc != null) {
        _bloc.add(TwUpdateCounts(
            toDo: toDoCount,
            completed: completedCount
        ));
    //  }

      /*await SecureStorageService.saveTodayWorkCounts(
        toDo: toDoCount,
        completed: completedCount,
      );

      if (mounted) {
        // Update the UI with the latest counts
        setState(() {
          // Ensure the UI reflects the same values we saved
          _completedVisitsCount = completedCount;
          _toDoVisitsCount = toDoCount;
        });
        print('=== TodaysProgramm After setState ===');
        print(
          'State - To-Do: $_toDoVisitsCount, Completed: $_completedVisitsCount',
        );
        print('==================================');
      }*/
    } catch (e) {
      // Log error if needed
      debugPrint('Error saving today\'s work counts: $e');
    }
  }

  String _formatDateOnly(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return '-';
    }
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

  String _last11(String? input) {
    if (input == null || input.isEmpty) return '-';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }
  Future<void> _refreshData() async {
    // Clear the UI momentarily to show loading
    _bloc.add(const TwLoad(toDo: 0, completed: 0));
    // Start the load process
    await _loadData();
  }

  late TodaysWorkBloc _bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: BlocProvider(
        create: (_) {
          _bloc = TodaysWorkBloc();
          // Don't load counts here, let _loadData handle it
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
                            _kv("Total Visits:", "${_toDoVisitsCount.toString()}"),
                            _kv(
                              '${l10n!.completedVisits} :',
                              _completedVisitsCount.toString(),
                            ),
                            _kv(
                              '${l10n.pendingVisits}:',
                              _pendingCountVisitsCount.toString(),
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
