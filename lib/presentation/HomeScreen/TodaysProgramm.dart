import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart' show Database;
import 'package:url_launcher/url_launcher.dart';
import '../../data/Local_Storage/local_storage_dao.dart';
import '../../data/Local_Storage/database_provider.dart';
import '../../data/Local_Storage/tables/followup_form_data_table.dart';
import '../../data/SecureStorage/SecureStorage.dart';
import '../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../l10n/app_localizations.dart';
import '../AllHouseHold/HouseHole_Beneficiery/HouseHold_Beneficiery.dart';
import '../EligibleCouple/TrackEligibleCouple/TrackEligibleCoupleScreen.dart';
import '../MotherCare/ANCVisit/ANCVisitForm/ANCVisitForm.dart';
import '../MotherCare/HBNCVisitForm/HBNCVisitScreen.dart';
import 'package:intl/intl.dart';

class TodayProgramSection extends StatefulWidget {
  final int? selectedGridIndex;
  final Function(int) onGridTap;
  final Map<String, List<String>> apiData;

  const TodayProgramSection({
    super.key,
    required this.selectedGridIndex,
    required this.onGridTap,
    required this.apiData,
  });

  @override
  State<TodayProgramSection> createState() => _TodayProgramSectionState();
}

class _TodayProgramSectionState extends State<TodayProgramSection> {
  String? _expandedKey;
  List<Map<String, dynamic>> _familySurveyItems = [];
  List<Map<String, dynamic>> _eligibleCoupleItems = [];
  List<Map<String, dynamic>> _ancItems = [];
  List<Map<String, dynamic>> _hbncItems = [];
  List<Map<String, dynamic>> _pwList = [];
  int _completedVisitsCount = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onGridTap(0);
    });

    _loadFamilySurveyItems();
    _loadEligibleCoupleItems();
    _loadAncItems();
    _loadHbncItems();
    _loadPregnantWomen();
    _loadCompletedVisitsCount();
  }

  String _last11(String? input) {
    if (input == null || input.isEmpty) return '-';
    return input.length <= 11 ? input : input.substring(input.length - 11);
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

  Future<void> _launchPhoneDialer(String? mobile) async {
    if (mobile == null || mobile.trim().isEmpty || mobile == '-') return;
    final uri = Uri(scheme: 'tel', path: mobile.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  bool _isExpanded(String key) {
    return _expandedKey == key;
  }

  Future<void> _saveTodayWorkCountsToStorage() async {
    try {
      final l10n = AppLocalizations.of(context);
      final familyCount = _familySurveyItems.length;
      final eligibleCoupleCount = _eligibleCoupleItems.length;
      final ancCount = _ancItems.length;
      final hbncCount = _hbncItems.length;
      final riCount = l10n == null
          ? 0
          : widget.apiData[l10n.listRoutineImmunization]?.length ?? 0;

      final totalToDoCount =
          familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;

      await SecureStorageService.saveTodayWorkCounts(
        toDo: totalToDoCount,
        completed: _completedVisitsCount,
      );
    } catch (_) {}
  }

  Future<void> _loadCompletedVisitsCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final ecFormKey = FollowupFormDataTable
              .formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue] ??
          '';
      final ancFormKey = FollowupFormDataTable
              .formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ??
          '';

      final formKeys = <String>[];
      if (ecFormKey.isNotEmpty) formKeys.add(ecFormKey);
      if (ancFormKey.isNotEmpty) formKeys.add(ancFormKey);

      if (formKeys.isEmpty) return;

      // Limit count to forms completed **today** so the completed
      // visits count effectively resets every new day.
      final placeholders = List.filled(formKeys.length, '?').join(',');

      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM ${FollowupFormDataTable.table} '
        'WHERE forms_ref_key IN ($placeholders) '
        'AND (is_deleted IS NULL OR is_deleted = 0) '
        'AND DATE(created_date_time) = DATE(?)',
        [
          ...formKeys,
          todayStr,
        ],
      );

      int count = 0;
      if (rows.isNotEmpty) {
        final value = rows.first['cnt'];
        if (value is int) {
          count = value;
        } else if (value is num) {
          count = value.toInt();
        } else if (value != null) {
          count = int.tryParse(value.toString()) ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          _completedVisitsCount = count;
        });
        _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
  }

  Future<void> _loadEligibleCoupleItems() async {
    try {
      // Currently no special logic; just clear the list.
      if (mounted) {
        setState(() {
          _eligibleCoupleItems = [];
        });
        _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
  }

  Future<void> _loadAncItems() async {
    try {
      // Load ANC forms DB reference for per-beneficiary visit checks
      final db = await DatabaseProvider.instance.database;
      final ancFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';

      final rows = await LocalStorageDao.instance.getANCList();

      final List<Map<String, dynamic>> items = [];

      for (final row in rows) {
        try {
          final uniqueKeyFull = row['unique_key']?.toString() ?? '';

          final isDeath = row['is_death'] == 1;
          final isMigrated = row['is_migrated'] == 1;
          if (isDeath || isMigrated) continue;

          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info = infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw as Map);

          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) continue;

          final genderRaw = info['gender']?.toString().toLowerCase();
          if (genderRaw != 'f' && genderRaw != 'female') continue;

          final name = (info['memberName'] ?? info['headName'] ?? info['name'])
              ?.toString()
              .trim();
          if (name == null || name.isEmpty) continue;

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
                    (now.month == birthDate.month &&
                        now.day < birthDate.day)) {
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

          // Calculate ANC visit windows based on LMP (same logic as ANCVisitListScreen)
          final ancRanges = _calculateAncDateRangesForToday(lmpDate);

          // We will check each ANC window (1st–4th). If today is within a
          // window and there is NO ANC form whose date_of_inspection falls
          // inside that window, the record will be shown in Today's ANC list.
          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          bool _isTodayInWindow(DateTime start, DateTime end) {
            final startDate = DateTime(start.year, start.month, start.day);
            final endDate = DateTime(end.year, end.month, end.day);
            return (todayDate.isAtSameMomentAs(startDate) || todayDate.isAfter(startDate)) &&
                (todayDate.isAtSameMomentAs(endDate) || todayDate.isBefore(endDate));
          }

          bool _hasFormInWindow(List<Map<String, dynamic>> forms, DateTime start, DateTime end) {
            for (final formRow in forms) {
              try {
                final formJsonRaw = formRow['form_json']?.toString();
                String? dateRaw;

                if (formJsonRaw != null && formJsonRaw.isNotEmpty) {
                  final decoded = jsonDecode(formJsonRaw);
                  if (decoded is Map && decoded['form_data'] is Map) {
                    final formData = Map<String, dynamic>.from(decoded['form_data'] as Map);
                    dateRaw = formData['date_of_inspection']?.toString();
                  }
                }

                // Fallback to created_date_time if date_of_inspection is missing
                dateRaw ??= formRow['created_date_time']?.toString();
                if (dateRaw == null || dateRaw.isEmpty) {
                  // If we can't get any date, treat this form as within the window
                  return true;
                }

                String dateStr = dateRaw;
                if (dateStr.contains('T')) {
                  dateStr = dateStr.split('T')[0];
                }
                final dt = DateTime.tryParse(dateStr);
                if (dt == null) {
                  // If parsing fails, still consider it as within the window
                  return true;
                }

                final d = DateTime(dt.year, dt.month, dt.day);
                final startDate = DateTime(start.year, start.month, start.day);
                final endDate = DateTime(end.year, end.month, end.day);
                final within = (d.isAtSameMomentAs(startDate) || d.isAfter(startDate)) &&
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

          if (!hasDueVisit && firstStart != null && firstEnd != null && _isTodayInWindow(firstStart, firstEnd)) {
            if (!_hasFormInWindow(existingForms, firstStart, firstEnd)) {
              hasDueVisit = true;
              dueVisitEndDate = firstEnd;
            }
          }

          if (!hasDueVisit && secondStart != null && secondEnd != null && _isTodayInWindow(secondStart, secondEnd)) {
            if (!_hasFormInWindow(existingForms, secondStart, secondEnd)) {
              hasDueVisit = true;
              dueVisitEndDate = secondEnd;
            }
          }

          if (!hasDueVisit && thirdStart != null && thirdEnd != null && _isTodayInWindow(thirdStart, thirdEnd)) {
            if (!_hasFormInWindow(existingForms, thirdStart, thirdEnd)) {
              hasDueVisit = true;
              dueVisitEndDate = thirdEnd;
            }
          }

          if (!hasDueVisit && fourthStart != null && fourthEnd != null && _isTodayInWindow(fourthStart, fourthEnd)) {
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
        _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
  }

  Future<void> _loadHbncItems() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final rows = await LocalStorageDao.instance.getHbncListTodaysProgram();

      final List<Map<String, dynamic>> items = [];
      final Set<String> seenHbncBeneficiaries = <String>{};

      for (final row in rows) {
        try {
          final isDeath = row['is_death'] == 1;
          final isMigrated = row['is_migrated'] == 1;
          if (isDeath || isMigrated) continue;

          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info = infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw as Map);

          // Do not limit to current pregnancies here. HBNC list should be
          // driven by delivery outcome records (same source as HBNCList).

          final name = (info['memberName'] ?? info['headName'] ?? info['name'])
              ?.toString()
              .trim();
          if (name == null || name.isEmpty) continue;

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

          final householdRefKey = row['household_ref_key']?.toString() ?? '';

          final beneficiaryRefKey = row['unique_key']?.toString() ?? '';

          // Avoid duplicate HBNC cards for the same beneficiary.
          if (beneficiaryRefKey.isEmpty) {
            continue;
          }
          if (seenHbncBeneficiaries.contains(beneficiaryRefKey)) {
            continue;
          }

          // Fetch delivery date from delivery outcome form (same as HBNCList)
          final deliveryDate = await _getHbncDeliveryDateForBeneficiary(
            beneficiaryRefKey,
          );

          // If there is no delivery outcome for this beneficiary, skip it.
          if (deliveryDate == null || deliveryDate.isEmpty) {
            continue;
          }

          // Compute next HBNC visit date using same logic as HBNCList
          final nextHbncDate = await _getHbncNextVisitDateForDisplay(
            beneficiaryRefKey,
            deliveryDate,
          );

          // If no next HBNC date is due/available, exclude.
          if (nextHbncDate == null || nextHbncDate.isEmpty) {
            continue;
          }

          // Use the existing helper to decide visibility: show this
          // beneficiary only if there is **no** HBNC visit whose
          // created_date_time lies between (nextHbncDate - 7 days)
          // and nextHbncDate.
          final shouldShow = await _shouldShowHbncItemForDueDate(
            db,
            beneficiaryRefKey,
            nextHbncDate,
          );
          if (!shouldShow) {
            continue;
          }

          final gender = info['gender']?.toString() ?? 'N/A';

          items.add({
            'id': _last11(beneficiaryRefKey),
            'household_ref_key': householdRefKey,
            'name': name,
            'age': ageText,
            'gender': gender,
            'last HBNC due date': nextHbncDate ?? 'N/A',
            'mobile': mobile,
            'badge': 'HBNC',
            // Full IDs for navigation if needed
            'fullBeneficiaryId': beneficiaryRefKey,
            'fullHhId': householdRefKey,
          });

          // Mark this beneficiary as already added to avoid duplicates.
          seenHbncBeneficiaries.add(beneficiaryRefKey);
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _hbncItems = items;
        });
        _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
  }

  /// Decide whether a beneficiary should appear in HBNC list for a given
  /// last HBNC due date. We show only if there is **no** HBNC visit record
  /// whose created_date_time lies between (dueDate - 7 days) and dueDate.
  Future<bool> _shouldShowHbncItemForDueDate(
    Database db,
    String beneficiaryId,
    String dueDateDisplay, // format dd-MM-yyyy
  ) async {
    try {
      if (beneficiaryId.isEmpty || dueDateDisplay.isEmpty) return true;

      final parts = dueDateDisplay.split('-');
      if (parts.length != 3) return true;
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return true;

      final dueDate = DateTime(year, month, day);
      final windowStart = dueDate.subtract(const Duration(days: 7));

      final hbncVisitKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      if (hbncVisitKey == null || hbncVisitKey.isEmpty) return true;

      final rows = await db.query(
        FollowupFormDataTable.table,
        columns: ['created_date_time'],
        where:
            'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryId, hbncVisitKey],
      );

      for (final row in rows) {
        final raw = row['created_date_time']?.toString();
        if (raw == null || raw.isEmpty) continue;
        String s = raw;
        if (s.contains('T')) {
          s = s.split('T')[0];
        }
        final dt = DateTime.tryParse(s);
        if (dt == null) continue;

        final d = DateTime(dt.year, dt.month, dt.day);
        final start =
            DateTime(windowStart.year, windowStart.month, windowStart.day);
        final end = DateTime(dueDate.year, dueDate.month, dueDate.day);

        final inWindow =
            (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
            (d.isAtSameMomentAs(end) || d.isBefore(end));
        if (inWindow) {
          // There is a record in the 7-day window, so do NOT show.
          return false;
        }
      }

      // No record in this window -> show the item
      return true;
    } catch (_) {
      // On any error, default to showing the record
      return true;
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

  /// HBNC helper: get last visit date formatted as dd-MM-yyyy, same logic as
  /// HBNCList._getLastVisitDate
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
          final formJson =
              jsonDecode(result['form_json'] as String? ?? '{}');
          final formData =
              formJson['form_data'] as Map<String, dynamic>? ?? {};

          if (formData.containsKey('visitDetails')) {
            final visitDetails = formData['visitDetails'];
            if (visitDetails is Map) {
              final visitDate = visitDetails['visitDate'] ??
                  visitDetails['visit_date'] ??
                  visitDetails['dateOfVisit'] ??
                  visitDetails['date_of_visit'];

              if (visitDate != null && visitDate.toString().isNotEmpty) {
                return _formatHbncDate(visitDate.toString());
              }
            }
          }

          final visitDate = formData['visit_date'] ??
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

  Future<int> _getHbncVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        return 0;
      }

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      if (hbncVisitKey == null || hbncVisitKey.isEmpty) {
        return 0;
      }

      final List<Map<String, dynamic>> results = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
      );

      if (results.isEmpty) {
        return 0;
      }

      try {
        final latestRecord = results.first;
        final formJson = jsonDecode(latestRecord['form_json'] as String? ?? '{}');
        final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};

        if (formData.containsKey('visitDetails')) {
          final visitDetails = formData['visitDetails'] as Map<String, dynamic>? ?? {};
          final visitNumber = visitDetails['visitNumber'] as int? ?? 0;
          return visitNumber;
        }
      } catch (_) {}

      return results.length;
    } catch (_) {
      return 0;
    }
  }

  Future<String?> _getNextHbncVisitDate(Database db, String beneficiaryId, String? deliveryDate) async {
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

  /// HBNC helper: get next visit date formatted as dd-MM-yyyy, same logic as
  /// HBNCList._getNextVisitDate
  Future<String?> _getHbncNextVisitDateForDisplay(
    String beneficiaryId,
    String? deliveryDate,
  ) async {
    try {
      // Use the scheduled HBNC visits (1,3,7,14,21,28,42 days after
      // delivery) to determine the next visit date, then format it for
      // display.
      final db = await DatabaseProvider.instance.database;
      final nextRaw = await _getNextHbncVisitDate(db, beneficiaryId, deliveryDate);
      if (nextRaw == null || nextRaw.isEmpty) {
        return null;
      }

      return _formatHbncDate(nextRaw);
    } catch (_) {}
    return null;
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

  Future<void> _loadPregnantWomen() async {
    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];

      for (final row in rows) {
        try {
          final dynamic rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          Map<String, dynamic> info = {};
          try {
            info = rawInfo is String
                ? jsonDecode(rawInfo) as Map<String, dynamic>
                : Map<String, dynamic>.from(rawInfo as Map);
          } catch (e) {
            print('Error parsing beneficiary_info: $e');
            continue;
          }

          final isPregnant = info['isPregnant']?.toString().toLowerCase() == 'yes';
          if (!isPregnant) continue;

          final gender = info['gender']?.toString().toLowerCase() ?? '';
          if (gender != 'f' && gender != 'female') continue;

          final name = info['memberName'] ?? info['headName'] ?? 'Unknown';
          final age = _calculateAge(info['dob']);
          final mobile = info['mobileNo'] ?? '';
          final lmp = info['lmp']?.toString();
          final uniqueKey = row['unique_key']?.toString() ?? '';
          final householdRefKey = row['household_ref_key']?.toString() ?? '';

          // Format last visit date if available
          String lastVisitDate = '-';
          if (info.containsKey('lastVisitDate') && info['lastVisitDate'] != null) {
            try {
              final date = DateTime.tryParse(info['lastVisitDate'].toString());
              if (date != null) {
                lastVisitDate = DateFormat('dd MMM yyyy').format(date);
              }
            } catch (e) {
              print('Error parsing last visit date: $e');
            }
          }

          pregnantWomen.add({
            'name': name,
            'age': age,
            'gender': 'Female',
            'mobile': mobile,
            'id': uniqueKey,
            'badge': 'RI',
            'last Visit date': lastVisitDate,
            'unique_key': uniqueKey,
            'household_ref_key': householdRefKey,
            'lmp': lmp,
          });
        } catch (e) {
          print('Error processing beneficiary: $e');
        }
      }

      setState(() {
        _pwList = pregnantWomen;
      });
    } catch (e) {
      print('Error loading pregnant women: $e');
    }
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

          final name =
              (info['headName'] ?? info['memberName'] ?? info['name'])
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
        _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
  }

  /// HBNC helper: get delivery_date for a beneficiary from delivery outcome
  /// followup form, same source as HBNCList.
  Future<String?> _getHbncDeliveryDateForBeneficiary(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) return null;

      final db = await DatabaseProvider.instance.database;
      const deliveryOutcomeKey = '4r7twnycml3ej1vg';

      final results = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
        whereArgs: [beneficiaryId, deliveryOutcomeKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (results.isEmpty) return null;

      final formJsonRaw = results.first['form_json'] as String?;
      if (formJsonRaw == null || formJsonRaw.isEmpty) return null;

      final decoded = jsonDecode(formJsonRaw);
      if (decoded is! Map) return null;
      final formData = decoded['form_data'] as Map<String, dynamic>? ?? {};
      final deliveryDate = formData['delivery_date']?.toString();
      return deliveryDate?.isNotEmpty == true ? deliveryDate : null;
    } catch (_) {
      return null;
    }
  }

  List<Widget> _getAncListItems() {
    final List<Map<String, dynamic>> ancItems = _ancItems;

    return ancItems.map((item) => _routineCard(item)).toList();
  }

  Widget _routineCard(Map<String, dynamic> item) {
    final primary = Theme.of(context).primaryColor;
    final badge = item['badge']?.toString() ?? '';

    return InkWell(
      onTap: () async {
        final confirmed = await showConfirmationDialog(
          context: context,
          message: 'Move forward?',
          yesText: 'Yes',
          noText: 'No',
        );

        if (confirmed != true) {
          return;
        }

        if (badge == 'Family') {
          final hhKey = item['household_ref_key']?.toString() ?? '';
          if (hhKey.isEmpty) return;

          Map<String, String> initial = {};
          try {
            final households = await LocalStorageDao.instance.getAllHouseholds();
            String? headId;
            for (final hh in households) {
              final key = (hh['unique_key'] ?? '').toString();
              if (key == hhKey) {
                headId = (hh['head_id'] ?? '').toString();
                break;
              }
            }

            final members = await LocalStorageDao.instance.getBeneficiariesByHousehold(hhKey);

            Map<String, dynamic>? headRow;
            if (headId != null && headId.isNotEmpty) {
              for (final m in members) {
                if ((m['unique_key'] ?? '').toString() == headId) {
                  headRow = m;
                  break;
                }
              }
            }

            headRow ??= members.isNotEmpty ? members.first : null;

            if (headRow != null) {
              final rawInfo = headRow['beneficiary_info'];
              Map<String, dynamic> info;
              if (rawInfo is Map<String, dynamic>) {
                info = rawInfo;
              } else if (rawInfo is String && rawInfo.isNotEmpty) {
                info = jsonDecode(rawInfo) as Map<String, dynamic>;
              } else {
                info = <String, dynamic>{};
              }

              // Convert all primitive fields to String for AddNewFamilyHeadScreen.initial
              final map = <String, String>{};
              info.forEach((key, value) {
                if (value != null) {
                  map[key] = value.toString();
                }
              });

              // Technical identifiers to support edit/update flow
              map['hh_unique_key'] = hhKey;
              map['head_unique_key'] = headRow['unique_key']?.toString() ?? '';
              if (headRow['id'] != null) {
                map['head_id_pk'] = headRow['id'].toString();
              }

              // Try to attach spouse info from the dedicated spouse beneficiary row
              try {
                Map<String, dynamic>? spouseRow;

                for (final m in members) {
                  final rawSpInfo = m['beneficiary_info'];
                  Map<String, dynamic> sInfo;
                  if (rawSpInfo is Map<String, dynamic>) {
                    sInfo = rawSpInfo;
                  } else if (rawSpInfo is String && rawSpInfo.isNotEmpty) {
                    try {
                      sInfo = jsonDecode(rawSpInfo) as Map<String, dynamic>;
                    } catch (_) {
                      continue;
                    }
                  } else {
                    continue;
                  }

                  final rel = (sInfo['relation_to_head'] ?? sInfo['relation'])
                      ?.toString()
                      .toLowerCase();
                  if (rel == 'spouse') {
                    spouseRow = m;
                    break;
                  }
                }

                if (spouseRow != null) {
                  final rawSpInfo = spouseRow['beneficiary_info'];
                  Map<String, dynamic> spInfo;
                  if (rawSpInfo is Map<String, dynamic>) {
                    spInfo = rawSpInfo;
                  } else if (rawSpInfo is String && rawSpInfo.isNotEmpty) {
                    spInfo = jsonDecode(rawSpInfo) as Map<String, dynamic>;
                  } else {
                    spInfo = <String, dynamic>{};
                  }

                  // Technical identifiers for spouse row
                  map['spouse_unique_key'] = spouseRow['unique_key']?.toString() ?? '';
                  if (spouseRow['id'] != null) {
                    map['spouse_id_pk'] = spouseRow['id'].toString();
                  }

                  spInfo.forEach((key, value) {
                    if (value != null) {
                      map['sp_$key'] = value.toString();
                    }
                  });
                }
              } catch (_) {}

              // Ensure some core fields are present/fallbacks from card item
              map['headName'] ??= item['name']?.toString() ?? '';
              map['mobileNo'] ??= item['mobile']?.toString() ?? '';
              initial = map;
            }
          } catch (_) {
            // If anything fails, fall back to minimal initial data
            initial = {
              'headName': item['name']?.toString() ?? '',
              'mobileNo': item['mobile']?.toString() ?? '',
            };
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewFamilyHeadScreen(
                isEdit: true,
                initial: initial,
              ),
            ),
          );
        } else if (badge == 'EligibleCouple') {
          // Align with UpdatedEligibleCoupleListScreen: pass short ID + full ref key
          final displayId = item['id']?.toString() ?? '';
          final beneficiaryRefKey = item['beneficiaryId']?.toString() ?? '';
          if (displayId.isEmpty || beneficiaryRefKey.isEmpty) return;

          final result = await Navigator.push(
            context,
            TrackEligibleCoupleScreen.route(
              beneficiaryId: displayId,
              beneficiaryRefKey: beneficiaryRefKey,
            ),
          );

          if (result == true && mounted) {
            setState(() {
              _completedVisitsCount++;
            });
            _loadEligibleCoupleItems();
            _saveTodayWorkCountsToStorage();
          }
        } else if (badge == 'ANC') {
          // Navigate to ANC Visit Form with full beneficiary data
          final hhId = item['hhId']?.toString() ??
              item['household_ref_key']?.toString() ?? '';
          final beneficiaryId = item['BeneficiaryID']?.toString() ??
              item['unique_key']?.toString() ?? '';
          if (hhId.isEmpty || beneficiaryId.isEmpty) return;

          final formData = Map<String, dynamic>.from(item);
          formData['hhId'] = hhId;
          formData['BeneficiaryID'] = beneficiaryId;
          formData['unique_key'] = item['unique_key']?.toString() ?? beneficiaryId;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Ancvisitform(beneficiaryData: formData),
            ),
          );

          if (result == true && mounted) {
            setState(() {
              _completedVisitsCount++;
            });
            _loadAncItems();
            _saveTodayWorkCountsToStorage();
          }
        } else if (badge == 'HBNC') {
          // Navigate to HBNC Visit Form with full beneficiary IDs
          final fullBeneficiaryId =
              item['fullBeneficiaryId']?.toString() ?? '';
          final fullHhId = item['fullHhId']?.toString() ?? '';
          if (fullBeneficiaryId.isEmpty || fullHhId.isEmpty) return;

          final beneficiaryData = <String, dynamic>{
            'unique_key': fullBeneficiaryId,
            'household_ref_key': fullHhId,
            'name': item['name']?.toString() ?? '-',
          };

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HbncVisitScreen(
                beneficiaryData: beneficiaryData,
              ),
            ),
          );

          if (result == true && mounted) {
            await _loadHbncItems();
            _saveTodayWorkCountsToStorage();
          }
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.home, color: primary, size: 15.sp),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      () {
                        if (badge == 'EligibleCouple') {
                          return _last11(item['beneficiaryId']?.toString());
                        }

                        // Prefer beneficiary/unique identifiers over household_ref_key
                        final beneficiaryId = item['BeneficiaryID']?.toString();
                        if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
                          return _last11(beneficiaryId);
                        }

                        final uniqueKey = item['unique_key']?.toString();
                        if (uniqueKey != null && uniqueKey.isNotEmpty) {
                          return _last11(uniqueKey);
                        }

                        return _last11(item['id']?.toString());
                      }(),
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                  if (badge != 'Family')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F7E9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF0E7C3A),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']?.toString() ?? '-',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item['age'] ?? '-'} | ${item['gender'] ?? '-'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (badge == 'ANC') ...[
                          Text(
                            'last Visit date: ${item['last Visit date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current ANC last due date: ${item['Current ANC last due date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ] else if (badge == 'Family') ...[
                          Text(
                            'Last survey date: ${item['last survey date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ] else if (badge == 'EligibleCouple') ...[
                          Text(
                            'last Visit date: ${item['last Visit date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ] else if (badge == 'HBNC') ...[
                          Text(
                            'Last HBNC due date: ${item['last HBNC due date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ] else if (badge == 'RI') ...[
                          Text(
                            'last Visit date: ${item['last Visit date'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          'Mobile: ${item['mobile'] ?? '-'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _launchPhoneDialer(item['mobile']?.toString()),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.phone, color: primary, size: 24),
                        ),
                      ),
                      if (badge != 'Family') ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.asset(
                              badge == 'ANC'
                                  ? 'assets/images/pregnant-woman.png'
                                  : badge == 'EligibleCouple'
                                  ? 'assets/images/couple.png'
                                  : badge == 'HBNC'
                                  ? 'assets/images/pnc-mother.png'
                                  : 'assets/images/capsule2.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Calculate total count for To Do Visits card across all expansion tiles
    final familyCount = _familySurveyItems.length;
    final eligibleCoupleCount = _eligibleCoupleItems.length;
    final ancCount = _ancItems.length;
    final hbncCount = _hbncItems.length;
    final riCount = widget.apiData[l10n.listRoutineImmunization]?.length ?? 0;
    final totalToDoCount =
        familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grid Boxes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 4,
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => widget.onGridTap(0),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Card(
                    elevation: 3,
                    color: widget.selectedGridIndex == 0
                        ? AppColors.primary
                        : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/schedule.png',
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Text(
                                "$totalToDoCount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.selectedGridIndex == 0
                                      ? AppColors.onPrimary
                                      : AppColors.onSurface,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.toDoVisits,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15.sp,
                              color: widget.selectedGridIndex == 0
                                  ? AppColors.onPrimary
                                  : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Grid Box 2
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () => widget.onGridTap(1),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Card(
                    elevation: 3,
                    color: widget.selectedGridIndex == 1
                        ? AppColors.primary
                        : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/comment.png',
                                    width: 6.w,
                                    height: 6.w,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              Text(
                                "$_completedVisitsCount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.selectedGridIndex == 1
                                      ? AppColors.onPrimary
                                      : AppColors.onSurface,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.completedVisits,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15.sp,
                              color: widget.selectedGridIndex == 1
                                  ? AppColors.onPrimary
                                  : AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ExpansionTile list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              // Control ExpansionTile animation speed globally
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Column(
              children: [
                for (var entry in widget.apiData.entries) ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: ExpansionTile(
                      key: ValueKey('${entry.key}_$_expandedKey'),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedKey = expanded ? entry.key : null;
                        });
                      },
                      initiallyExpanded: _expandedKey == entry.key,
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                          color: _expandedKey == entry.key
                              ? Colors.blueAccent
                              : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key == l10n.listFamilySurvey
                                ? "${_familySurveyItems.length}"
                                : entry.key == l10n.listEligibleCoupleDue
                                    ? "${_eligibleCoupleItems.length}"
                                    : entry.key == l10n.listANC
                                        ? "${_ancItems.length}"
                                        : entry.key == l10n.listHBNC
                                            ? "${_hbncItems.length}"
                                            : "${entry.value.length}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _expandedKey == entry.key
                                  ? Colors.blueAccent
                                  : AppColors.onSurface,
                              fontSize: 15.sp,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: _expandedKey == entry.key ? 0.5 : 0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.keyboard_arrow_down_outlined,
                              color: _expandedKey == entry.key
                                  ? Colors.blueAccent
                                  : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      children: entry.key == l10n.listANC
                          ? (_ancItems.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('No data found'),
                                    ),
                                  ),
                                ]
                              : _getAncListItems())
                          : entry.key == l10n.listFamilySurvey
                          ? (_familySurveyItems.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('No data found'),
                                      ),
                                    ),
                                  ]
                                : _familySurveyItems
                                      .map((item) => _routineCard(item))
                                      .toList())
                          : entry.key == l10n.listEligibleCoupleDue
                          ? (_eligibleCoupleItems.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('No data found'),
                                      ),
                                    ),
                                  ]
                                : _eligibleCoupleItems
                                      .map((item) => _routineCard(item))
                                      .toList())
                          : entry.key == l10n.listHBNC
                          ? (_hbncItems.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('No data found'),
                                      ),
                                    ),
                                  ]
                                : _hbncItems
                                    .map((item) => _routineCard(item))
                                    .toList())
                          : entry.key == l10n.listRoutineImmunization
                          ? _pwList.isEmpty
                              ? [
                                  const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Text('No pregnant women found'),
                                  ),
                                ]
                              : _pwList
                                  .map((item) => _routineCard({
                                        'id': item['id'],
                                        'name': item['name'],
                                        'age': item['age'],
                                        'gender': item['gender'],
                                        'last Visit date': item['last Visit date'],
                                        'mobile': item['mobile'],
                                        'badge': 'RI',
                                        'unique_key': item['unique_key'],
                                        'household_ref_key': item['household_ref_key'],
                                        'lmp': item['lmp'],
                                      }))
                                  .toList()
                          : entry.value
                                .map((item) => ListTile(title: Text(item)))
                                .toList(),
                    ),
                  ),
                  Divider(color: AppColors.divider, thickness: 1, height: 1),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
