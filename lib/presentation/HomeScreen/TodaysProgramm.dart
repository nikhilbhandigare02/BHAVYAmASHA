import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart' show Database;
import 'package:url_launcher/url_launcher.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/Database/database_provider.dart';
import '../../data/Database/tables/eligible_couple_activities_table.dart';
import '../../data/Database/tables/followup_form_data_table.dart';
import '../../data/SecureStorage/SecureStorage.dart';
import '../../core/widgets/ConfirmationDialogue/ConfirmationDialogue.dart';
import '../../l10n/app_localizations.dart';
import '../AllHouseHold/HouseHole_Beneficiery/HouseHold_Beneficiery.dart';
import '../EligibleCouple/TrackEligibleCouple/TrackEligibleCoupleScreen.dart';
import '../MotherCare/ANCVisit/ANCVisitForm/ANCVisitForm.dart';
import '../MotherCare/HBNCVisitForm/HBNCVisitScreen.dart';
import '../ChildCare/ChildTrackingDueList/ChildTrackingDueListForm.dart';
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
  List<Map<String, dynamic>> _familySurveyCompletedItems = [];
  List<Map<String, dynamic>> _eligibleCoupleItems = [];
  List<Map<String, dynamic>> _eligibleCompletedCoupleItems = [];
  List<Map<String, dynamic>> _ancItems = [];
  List<Map<String, dynamic>> _ancCompletedItems = [];
  List<Map<String, dynamic>> _hbncItems = [];
  List<Map<String, dynamic>> _hbncCompletedItems = [];
  List<Map<String, dynamic>> _riItems = [];
  List<Map<String, dynamic>> _riCompletedItems = [];
  int _completedVisitsCount = 0;
  int _toDoVisitsCount = 0;
  bool todayVisitClick = true;
  String? ashaUniqueKey;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onGridTap(0);
      _loadData();
    });
  }

  Future<Map<String, dynamic>> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiary ID provided to _getVisitCount');
        return {'count': 0, 'isHighRisk': false};
      }

      print(
        '🔍 Fetching visit count and high-risk status for beneficiary: $beneficiaryId',
      );
      final result = await LocalStorageDao.instance.getANCVisitCount(
        beneficiaryId,
      );
      print('✅ Visit details for $beneficiaryId: $result');
      return result;
    } catch (e) {
      print('❌ Error in _getVisitCount for $beneficiaryId: $e');
      return {'count': 0, 'isHighRisk': false};
    }
  }

  Future<DateTime?> _extractLmpDate(Map<String, dynamic> data) async {
    try {
      // First try to get LMP from beneficiary_info (beneficiaries_new table)
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
          print(
            '✅ Found LMP date from beneficiaries_new: ${_formatDate(lmpDate)}',
          );
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
        print(
          '✅ Found LMP date from followup form: ${_formatDate(lmpFromFollowup)}',
        );
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
          (data['_rawRow'] is Map
              ? (data['_rawRow'] as Map)['unique_key']?.toString()
              : null);

      final hhId = data['hhId']?.toString() ??
          data['household_ref_key']?.toString() ??
          (data['_rawRow'] is Map
              ? (data['_rawRow'] as Map)['household_ref_key']?.toString()
              : null);

      if (benId == null || benId.isEmpty || hhId == null || hhId.isEmpty) {
        print('⚠️ Missing beneficiary ID or household ID for followup form LMP lookup');
        print('   benId: $benId');
        print('   hhId: $hhId');
        print('   data keys: ${data.keys}');
        return null;
      }

      print('🔍 Looking for followup forms with benId: $benId, hhId: $hhId');

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

      print('📋 Found ${forms.length} followup forms to process');

      for (final form in forms) {
        final formJsonStr = form['form_json']?.toString();
        final formHouseholdId = form['household_ref_key']?.toString();
        final formBeneficiaryId = form['beneficiary_ref_key']?.toString();

        print('📄 Processing form: household=$formHouseholdId, beneficiary=$formBeneficiaryId');

        if (formJsonStr == null || formJsonStr.isEmpty) {
          print('⚠️ Empty form_json, skipping');
          continue;
        }

        try {
          final root = Map<String, dynamic>.from(jsonDecode(formJsonStr));
          print('🔍 Parsing followup form JSON: ${root.keys}');

          String? lmpStr;

          /// ✅ EXISTING CONDITION (DO NOT REMOVE)
          final trackingData = root['eligible_couple_tracking_due_from'];
          if (trackingData is Map) {
            final val = trackingData['lmp_date']?.toString();
            if (val != null && val.isNotEmpty) {
              lmpStr = val;
              print('✅ Found LMP in eligible_couple_tracking_due_from: $lmpStr');
            }
          }

          /// ✅ NEW CONDITION (ADDED SAFELY)
          if ((lmpStr == null || lmpStr.isEmpty) &&
              root['form_data'] is Map) {
            final formData = root['form_data'] as Map<String, dynamic>;
            final val = formData['lmp_date']?.toString();
            // Check for null, empty, or just empty string
            if (val != null && val.isNotEmpty && val != '""') {
              lmpStr = val;
              print('✅ Found LMP in form_data: $lmpStr');
            } else {
              print('⚠️ LMP date in form_data is empty or invalid: $val');
            }
          }

          if (lmpStr != null && lmpStr.isNotEmpty) {
            try {
              // Handle different date formats
              String dateStr = lmpStr;
              if (dateStr.contains('T')) {
                // For ISO 8601 format, extract just the date part or parse as-is
                try {
                  final lmpDate = DateTime.parse(dateStr);
                  print('✅ Successfully parsed LMP date: $lmpDate');
                  return lmpDate;
                } catch (e) {
                  // If full parsing fails, try date part only
                  dateStr = dateStr.split('T')[0];
                  print('⚠️ Full date parsing failed, trying date part only: $dateStr');
                }
              }

              final lmpDate = DateTime.parse(dateStr);
              print('✅ Successfully parsed LMP date: $lmpDate');
              return lmpDate;
            } catch (e) {
              print('⚠️ Error parsing LMP date "$lmpStr": $e');
            }
          } else {
            print('⚠️ No LMP date found in form data');
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

  String _getNextAncDueDate(DateTime? lmpDate, int visitCount) {
    if (lmpDate == null) return AppLocalizations.of(context)!.na;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ancRanges = _calculateAncDateRanges(lmpDate);

    if (ancRanges['4th_anc_start'] != null && ancRanges['4th_anc_end'] != null) {
      final windowStart = DateTime(ancRanges['4th_anc_start']!.year, ancRanges['4th_anc_start']!.month, ancRanges['4th_anc_start']!.day);
      final windowEnd = DateTime(ancRanges['4th_anc_end']!.year, ancRanges['4th_anc_end']!.month, ancRanges['4th_anc_end']!.day);

      if ((today.isAtSameMomentAs(windowStart) || today.isAfter(windowStart)) &&
          (today.isAtSameMomentAs(windowEnd) || today.isBefore(windowEnd))) {
        return _formatDate(windowEnd);
      }
    }

    // Check 3rd ANC window (26-34 weeks)
    if (ancRanges['3rd_anc_start'] != null && ancRanges['3rd_anc_end'] != null) {
      final windowStart = DateTime(ancRanges['3rd_anc_start']!.year, ancRanges['3rd_anc_start']!.month, ancRanges['3rd_anc_start']!.day);
      final windowEnd = DateTime(ancRanges['3rd_anc_end']!.year, ancRanges['3rd_anc_end']!.month, ancRanges['3rd_anc_end']!.day);

      if ((today.isAtSameMomentAs(windowStart) || today.isAfter(windowStart)) &&
          (today.isAtSameMomentAs(windowEnd) || today.isBefore(windowEnd))) {
        return _formatDate(windowEnd);
      }
    }

    if (ancRanges['2nd_anc_start'] != null && ancRanges['2nd_anc_end'] != null) {
      final windowStart = DateTime(ancRanges['2nd_anc_start']!.year, ancRanges['2nd_anc_start']!.month, ancRanges['2nd_anc_start']!.day);
      final windowEnd = DateTime(ancRanges['2nd_anc_end']!.year, ancRanges['2nd_anc_end']!.month, ancRanges['2nd_anc_end']!.day);

      if ((today.isAtSameMomentAs(windowStart) || today.isAfter(windowStart)) &&
          (today.isAtSameMomentAs(windowEnd) || today.isBefore(windowEnd))) {
        return _formatDate(windowEnd);
      }
    }

    // Check 1st ANC window (0-12 weeks)
    if (ancRanges['1st_anc_start'] != null && ancRanges['1st_anc_end'] != null) {
      final windowStart = DateTime(ancRanges['1st_anc_start']!.year, ancRanges['1st_anc_start']!.month, ancRanges['1st_anc_start']!.day);
      final windowEnd = DateTime(ancRanges['1st_anc_end']!.year, ancRanges['1st_anc_end']!.month, ancRanges['1st_anc_end']!.day);

      if ((today.isAtSameMomentAs(windowStart) || today.isAfter(windowStart)) &&
          (today.isAtSameMomentAs(windowEnd) || today.isBefore(windowEnd))) {
        return _formatDate(windowEnd);
      }
    }

    // If today doesn't fall within any ANC window, return NA
    return AppLocalizations.of(context)!.na;
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      // Load all the data from the database
      await _loadFamilySurveyItems();
      if (!mounted) return;

      await _loadFamilySurveyCompletedItems();
      if (!mounted) return;

      await _loadEligibleCoupleItems();
      if (!mounted) return;

      await _loadAncItems();
      if (!mounted) return;

      await _loadHbncItems();
      if (!mounted) return;

      // Load completed visits before routine immunization to avoid duplicates
      await _loadCompletedVisitsCount();
      if (!mounted) return;

      await _loadRoutineImmunizationItems();
      if (!mounted) return;

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

  String _last11(String? input) {
    if (input == null || input.isEmpty) return '-';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }

  DateTime _dateAfterWeeks(DateTime startDate, int noOfWeeks) {
    final days = noOfWeeks * 7;
    return startDate.add(Duration(days: days));
  }

  DateTime _calculateEdd(DateTime lmp) {
    return _dateAfterWeeks(lmp, 40);
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
    ranges['pmsma_end'] = ranges['2nd_anc_start']!.subtract(
      const Duration(days: 1),
    );

    return ranges;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  var _isLoading = true;

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

  String _formatAgeWithSuffix(int age) {
    if (age <= 0) return '0 Y';

    final now = DateTime.now();
    // We need to calculate more precise age, so let's use the same logic as _formatAgeGender
    // But since we only have years, we'll just show years with Y suffix
    return '$age Y';
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

  String _formatAncDateOnly(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return '-';
    }
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

  void _launchPhoneDialer(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty || phoneNumber == '-') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
      return;
    }

    // Clean the phone number - remove all spaces and any non-digit characters
    final raw = phoneNumber
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: raw);

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open dialer on this device.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open dialer on this device.'),
          ),
        );
      }
    }
  }

  bool _isExpanded(String key) {
    return _expandedKey == key;
  }

  Future<void> _saveTodayWorkCountsToStorage() async {
    try {
      if (!mounted) return;

      final familyCount = _familySurveyItems.length;
      final familyCompletedCount = _familySurveyCompletedItems.length;
      final eligibleCoupleCount = _eligibleCoupleItems.length;
      final ancCount = _ancItems.length;
      final hbncCount = _hbncItems.length;
      final riCount = _riItems.length;

      // Calculate total to-do count (excluding completed visits)
      final totalToDoCount =
          familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;

      // Calculate total completed count (including family survey completed)
      final totalCompletedCount = _completedVisitsCount + familyCompletedCount;

      // Ensure we don't have negative counts
      final toDoCount = totalToDoCount >= 0 ? totalToDoCount : 0;
      final completedCount = totalCompletedCount >= 0
          ? totalCompletedCount
          : 0;

      // Save to secure storage
      print('=== TodaysProgramm Saving to Storage ===');
      print('Family To-Do Count: $familyCount');
      print('Family Completed Count: $familyCompletedCount');
      print('To-Do Count: $toDoCount');
      print('Completed Count: $completedCount');
      print('====================================');

      await SecureStorageService.saveTodayWorkCounts(
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
      }
    } catch (e) {
      // Log error if needed
      debugPrint('Error saving today\'s work counts: $e');
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

  String _getLocalizedBadge(String badge, AppLocalizations l10n) {
    switch (badge) {
      case 'Family':
        return l10n.badgeFamily;
      case 'EligibleCouple':
        return l10n.badgeEligibleCouple;
      case 'ANC':
        return l10n.anc;
      case 'HBNC':
        return l10n.hbnc;
      case 'RI':
        return l10n.categoryRI;
      default:
        return badge;
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

            print('=== DEBUG: EC Form Rows Found ===');
            print('Total EC Form Rows: ${formRows.length}');
            for (final row in formRows) {
              print('  - ID: ${row['id']}, Beneficiary: ${row['beneficiary_ref_key']}, Created: ${row['created_date_time']}');
            }
            print('================================');

            final processedBeneficiaries = <String>{};

            for (final row in formRows) {
              final beneficiaryId =
                  row['beneficiary_ref_key']?.toString() ?? '';
              if (beneficiaryId.isEmpty ||
                  processedBeneficiaries.contains(beneficiaryId)) {
                if (processedBeneficiaries.contains(beneficiaryId)) {
                  print('⚠️ SKIPPED: Beneficiary $beneficiaryId already processed');
                }
                continue;
              }

              print('=== DEBUG: Processing EC Form ===');
              print('Beneficiary ID: $beneficiaryId');
              print('Form Row ID: ${row['id']}');
              print('Created: ${row['created_date_time']}');
              print('================================');

              // Check if pregnant from form data
              final Map<String, dynamic> formJson = row['form_json'] != null
                  ? jsonDecode(row['form_json'] as String)
                  : {};

              final Map<String, dynamic> formData = formJson['form_data'] ?? {};
              final isPregnant = formData['is_pregnant']?.toString().toLowerCase() == 'yes';

              print('=== DEBUG: Pregnancy Check ===');
              print('Form Data: $formData');
              print('Is Pregnant: $isPregnant');
              print('================================');

              // Include all submitted forms (regardless of activity state) but only for today
              // The fact that it was submitted today means it should be in completed list
              // But only show for current day, not permanently

              // Check if form was created today (not just any time today)
              bool isCreatedToday = false;
              try {
                final createdDate = DateTime.parse(row['created_date_time'].toString());
                final now = DateTime.now();
                isCreatedToday = createdDate.year == now.year &&
                    createdDate.month == now.month &&
                    createdDate.day == now.day;
              } catch (e) {
                print('Error parsing created date: $e');
              }

              print('=== DEBUG: Date Check ===');
              print('Created Date: ${row['created_date_time']}');
              print('Is Created Today: $isCreatedToday');
              print('================================');

              // Only include if created today
              if (!isCreatedToday) {
                print('❌ SKIPPED: Form not created today');
                continue;
              }

              // Mark beneficiary as processed BEFORE adding to list
              processedBeneficiaries.add(beneficiaryId);

              if (isPregnant) {
                print('✅ INCLUDING: Pregnant woman found in completed forms (today only)');
              } else {
                print('✅ INCLUDING: Non-pregnant woman found in completed forms (today only)');
              }

              final fields = await _getBeneficiaryFields(beneficiaryId);

              // Check if this beneficiary is already in the completed list
              final alreadyInCompletedList = _eligibleCompletedCoupleItems
                  .any((item) => item['BeneficiaryID'] == beneficiaryId);

              if (alreadyInCompletedList) {
                print('⚠️ SKIPPED: Beneficiary $beneficiaryId already in completed list');
                continue;
              }

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

          print('=== DEBUG: Final EC Completed List ===');
          print('Total EC Completed Items: ${_eligibleCompletedCoupleItems.length}');
          for (final item in _eligibleCompletedCoupleItems) {
            print('  - ID: ${item['id']}, BeneficiaryID: ${item['BeneficiaryID']}, Name: ${item['name']}');
          }
          print('==================================');
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
                (_riCompletedItems.length ?? 0) +
                (_familySurveyCompletedItems.length ?? 0);
        if (mounted && count > _completedVisitsCount) {
          setState(() {
            _completedVisitsCount = count;
          });
          await _saveTodayWorkCountsToStorage();
        }

        // Print completed items count to console
        _printCompletedItemsCount();
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

  Future<String> _getLastVisitDate({
    required String beneficiaryId,
    required String formRefKey,
  }) async {
    try {
      final db = await DatabaseProvider.instance.database;

      final result = await db.rawQuery(
        '''
      SELECT MAX(created_date_time) AS last_visit
      FROM ${FollowupFormDataTable.table}
      WHERE beneficiary_ref_key = ?
        AND forms_ref_key = ?
        AND (is_deleted IS NULL OR is_deleted = 0)
      ''',
        [beneficiaryId, formRefKey],
      );

      final String? rawDate =
      result.first['last_visit']?.toString();

      if (rawDate == null || rawDate.isEmpty) {
        return '-';
      }

      return _formatDateOnly(rawDate);
    } catch (e) {
      debugPrint('Last visit error: $e');
      return '-';
    }
  }



  Future<void> _loadEligibleCoupleItems() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) return;

      final DateTime oneMonthAgo =
      DateTime.now().subtract(const Duration(days: 30));

      final ecRows = await db.query(
        EligibleCoupleActivitiesTable.table,
        columns: [
          'beneficiary_ref_key',
          'created_date_time',
          'modified_date_time',
        ],
        where: '''
        eligible_couple_state = ?
        AND current_user_key = ?
        AND (is_deleted IS NULL OR is_deleted = 0)
      ''',
        whereArgs: ['tracking_due', ashaUniqueKey],
      );

      // ------------------ STEP 2: FILTER 1 MONTH OLD ------------------
      final Set<String> eligibleBeneficiaryKeys = {};

      for (final row in ecRows) {
        final String? beneficiaryKey =
        row['beneficiary_ref_key']?.toString();
        if (beneficiaryKey == null || beneficiaryKey.isEmpty) continue;

        DateTime? createdDate;
        DateTime? modifiedDate;

        try {
          if (row['created_date_time'] != null &&
              row['created_date_time'].toString().isNotEmpty) {
            createdDate =
                DateTime.parse(row['created_date_time'].toString());
          }

          if (row['modified_date_time'] != null &&
              row['modified_date_time'].toString().isNotEmpty) {
            modifiedDate =
                DateTime.parse(row['modified_date_time'].toString());
          }
        } catch (_) {
          continue;
        }

        final bool isValid =
            createdDate != null &&
                createdDate.isBefore(oneMonthAgo) &&
                (modifiedDate == null ||
                    modifiedDate.isBefore(oneMonthAgo));

        if (isValid) {
          eligibleBeneficiaryKeys.add(beneficiaryKey);
        }
      }

      if (eligibleBeneficiaryKeys.isEmpty) {
        _eligibleCoupleItems.clear();
        if (mounted) setState(() {});
        _saveTodayWorkCountsToStorage();
        return;
      }

      // ------------------ STEP 3: FILTER OUT COMPLETED TODAY ------------------
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final ecFormKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .eligibleCoupleTrackingDue] ?? '';

      if (ecFormKey.isNotEmpty) {
        final completedTodayQuery = '''
          SELECT DISTINCT beneficiary_ref_key 
          FROM ${FollowupFormDataTable.table} 
          WHERE forms_ref_key LIKE ? 
          AND DATE(created_date_time) = DATE(?)
          AND (is_deleted IS NULL OR is_deleted = 0)
        ''';

        final completedTodayRows = await db.rawQuery(
          completedTodayQuery,
          [ecFormKey, todayStr],
        );

        print('=== DEBUG: EC Completed Today Filter ===');
        print('Form Key: $ecFormKey');
        print('Today String: $todayStr');
        print('Completed Today Query: $completedTodayQuery');
        print('Completed Today Rows: ${completedTodayRows.length}');
        for (final row in completedTodayRows) {
          print('  - Beneficiary: ${row['beneficiary_ref_key']}, Form Key: ${row['forms_ref_key']}, Created: ${row['created_date_time']}');
        }
        print('=====================================');

        final Set<String> completedTodayBeneficiaries = completedTodayRows
            .map((row) => row['beneficiary_ref_key']?.toString() ?? '')
            .where((key) => key.isNotEmpty)
            .toSet();

        print('Completed Today Beneficiaries: $completedTodayBeneficiaries');
        print('Before Filter - Eligible Beneficiary Keys: $eligibleBeneficiaryKeys');

        // Remove completed beneficiaries from eligible list
        eligibleBeneficiaryKeys.removeAll(completedTodayBeneficiaries);

        print('After Filter - Eligible Beneficiary Keys: $eligibleBeneficiaryKeys');
        print('Removed ${completedTodayBeneficiaries.length} beneficiaries from eligible list');
        print('=====================================');
      }

      // ------------------ STEP 4: FETCH BENEFICIARIES ------------------
      final placeholders =
      List.filled(eligibleBeneficiaryKeys.length, '?').join(',');

      final beneficiaryRows = await db.query(
        'beneficiaries_new',
        where: '''
        unique_key IN ($placeholders)
        AND (is_deleted IS NULL OR is_deleted = 0)
        AND (is_migrated IS NULL OR is_migrated = 0)
      ''',
        whereArgs: eligibleBeneficiaryKeys.toList(),
      );

      _eligibleCoupleItems.clear();

      // ------------------ STEP 4: BUILD FINAL LIST ------------------
      for (final member in beneficiaryRows) {
        final dynamic infoRaw = member['beneficiary_info'];
        if (infoRaw == null) continue;

        Map<String, dynamic> info = {};
        try {
          info = infoRaw is String
              ? jsonDecode(infoRaw)
              : Map<String, dynamic>.from(infoRaw);
        } catch (_) {}

        final String beneficiaryId =
            member['unique_key']?.toString() ?? '';

        // -------- AGE --------
        String ageText = '-';
        final String dob = info['dob']?.toString() ?? '';

        if (dob.isNotEmpty) {
          final int age = _calculateAgeFromDob(dob);
          if (age > 0) ageText = age.toString();
        } else if (info['age'] != null &&
            info['age'].toString().isNotEmpty) {
          ageText = info['age'].toString();
        }

        // -------- LAST VISIT FROM FOLLOWUP --------
        final String lastVisitDate =
        await _getLastVisitDate(
          beneficiaryId: beneficiaryId,
          formRefKey: '0g5au2h46icwjlvr',
        );

        _eligibleCoupleItems.add({
          'id': member['id'],
          'unique_key': beneficiaryId,

          'beneficiary_id': beneficiaryId,
          'beneficiaryId': beneficiaryId,
          'BeneficiaryID': beneficiaryId,

          'household_ref_key': member['household_ref_key'],
          'name': info['memberName'] ??
              info['headName'] ??
              info['name'] ??
              '',
          'gender':
          info['gender']?.toString().toLowerCase() ?? 'female',
          'age': ageText,
          'mobile':
          info['mobileNo']?.toString() ?? 'Not Available',
          'badge': 'EligibleCouple',

          // ✅ CORRECT LAST VISIT DATE
          'last Visit date': lastVisitDate,

          '_rawRow': member,
        });
      }

      if (mounted) {
        setState(() {});
        _saveTodayWorkCountsToStorage();
      }
    } catch (e) {
      debugPrint('Eligible Couple load error: $e');
    }
  }

  int _calculateAgeFromDob(String dob) {
    try {
      final DateTime birthDate = DateTime.parse(
        dob.contains('T') ? dob.split('T')[0] : dob,
      );

      final DateTime today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month &&
              today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _loadAncItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      final List<Map<String, dynamic>> items = [];
      final Set<String> processedBeneficiaries = {};

      // ---------- Fetch ANC due beneficiaries ----------
      String query = '''
      SELECT 
        mca.*,
        bn.*,
        bn.household_ref_key
      FROM mother_care_activities mca
      INNER JOIN beneficiaries_new bn
        ON mca.beneficiary_ref_key = bn.unique_key
      WHERE mca.mother_care_state = 'anc_due'
        AND bn.is_deleted = 0
    ''';

      final List<dynamic> args = [];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        query += ' AND bn.current_user_key = ?';
        args.add(ashaUniqueKey);
      }

      query += ' ORDER BY mca.created_date_time DESC';

      final List<Map<String, Object?>> rows =
      await db.rawQuery(query, args);

      final DateTime today = DateTime.now();
      final DateTime todayDate =
      DateTime(today.year, today.month, today.day);

      bool isTodayInsideWindow(DateTime start, DateTime end) {
        final s = DateTime(start.year, start.month, start.day);
        final e = DateTime(end.year, end.month, end.day);
        return (todayDate.isAtSameMomentAs(s) ||
            todayDate.isAfter(s)) &&
            (todayDate.isAtSameMomentAs(e) ||
                todayDate.isBefore(e));
      }

      // ---------- Process each row ----------
      for (final row in rows) {
        final String beneficiaryKey =
            row['beneficiary_ref_key']?.toString() ?? '';

        if (beneficiaryKey.isEmpty ||
            processedBeneficiaries.contains(beneficiaryKey)) {
          continue;
        }
        processedBeneficiaries.add(beneficiaryKey);

        // Skip death / migrated
        if (row['is_death'] == 1 || row['is_migrated'] == 1) continue;

        // ---------- Parse beneficiary info ----------
        final Object? infoRaw = row['beneficiary_info'];
        if (infoRaw == null) continue;

        late Map<String, dynamic> info;
        try {
          info = infoRaw is String
              ? jsonDecode(infoRaw) as Map<String, dynamic>
              : Map<String, dynamic>.from(infoRaw as Map);
        } catch (_) {
          continue;
        }

        final bool isPregnant =
            info['isPregnant']?.toString().toLowerCase() == 'yes';
        final String gender =
            info['gender']?.toString().toLowerCase() ?? '';

        if (!isPregnant && gender != 'f' && gender != 'female') continue;

        // ---------- Extract LMP ----------
        DateTime? lmpDate = await _extractLmpDate(row);
        lmpDate ??= info['lmp'] != null
            ? DateTime.tryParse(info['lmp'].toString().split('T')[0])
            : null;

        if (lmpDate == null) continue;

        // ---------- Calculate ANC windows ----------
        final Map<String, DateTime?> ancRanges =
        _calculateAncDateRanges(lmpDate);

        DateTime? activeWindowStart;
        DateTime? activeWindowEnd;

        final DateTime? firstStart =
        ancRanges['1st_anc_start'];
        final DateTime? firstEnd =
        ancRanges['1st_anc_end'];

        final DateTime? secondStart =
        ancRanges['2nd_anc_start'];
        final DateTime? secondEnd =
        ancRanges['2nd_anc_end'];

        final DateTime? thirdStart =
        ancRanges['3rd_anc_start'];
        final DateTime? thirdEnd =
        ancRanges['3rd_anc_end'];

        final DateTime? fourthStart =
        ancRanges['4th_anc_start'];
        final DateTime? fourthEnd =
        ancRanges['4th_anc_end'];

        if (firstStart != null &&
            firstEnd != null &&
            isTodayInsideWindow(firstStart, firstEnd)) {
          activeWindowStart = firstStart;
          activeWindowEnd = firstEnd;
        } else if (secondStart != null &&
            secondEnd != null &&
            isTodayInsideWindow(secondStart, secondEnd)) {
          activeWindowStart = secondStart;
          activeWindowEnd = secondEnd;
        } else if (thirdStart != null &&
            thirdEnd != null &&
            isTodayInsideWindow(thirdStart, thirdEnd)) {
          activeWindowStart = thirdStart;
          activeWindowEnd = thirdEnd;
        } else if (fourthStart != null &&
            fourthEnd != null &&
            isTodayInsideWindow(fourthStart, fourthEnd)) {
          activeWindowStart = fourthStart;
          activeWindowEnd = fourthEnd;
        }

        // ❌ Today is not in ANY ANC window
        if (activeWindowStart == null || activeWindowEnd == null) {
          continue;
        }

        // ---------- Age ----------
        String ageText = '-';
        if (info['dob'] != null) {
          final DateTime? dob =
          DateTime.tryParse(info['dob'].toString().split('T')[0]);
          if (dob != null) {
            ageText = '${today.year - dob.year} Y';
          }
        }

        final String uniqueKey =
            row['unique_key']?.toString() ?? '';
        final String householdRefKey =
            row['household_ref_key']?.toString() ?? '';

        // ---------- Add record ----------
        items.add({
          'id': uniqueKey.length > 11
              ? uniqueKey.substring(uniqueKey.length - 11)
              : uniqueKey,
          'unique_key': uniqueKey,
          'household_ref_key': householdRefKey,
          'name':
          info['memberName'] ?? info['name'] ?? 'Unknown',
          'age': ageText,
          'gender': 'Female',
          'last Visit date':
          _formatAncDateOnly(activeWindowStart.toIso8601String()),
          'Current ANC last due date':
          _formatAncDateOnly(activeWindowEnd.toIso8601String()),
          'mobile': info['mobileNo'] ?? '-',
          'badge': 'ANC',
          'beneficiary_info': jsonEncode(info),
          '_rawRow': row,
        });
      }

      if (mounted) {
        setState(() => _ancItems = items);
        _saveTodayWorkCountsToStorage();
      }
    } catch (e) {
      debugPrint('ANC load error: $e');
    }
  }


  Future<void> _loadHbncItems() async {
    try {
      setState(() => _isLoading = true);
      _hbncItems = [];

      final Set<String> processedBeneficiaries = <String>{};

      final db = await DatabaseProvider.instance.database;
      final deliveryOutcomeKey =
          '4r7twnycml3ej1vg';
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

          // Get registration date from mother_care_activities table for pnc_mother state
          String registrationDate = beneficiary['created_date_time']?.toString() ?? '';
          try {
            final mcaResult = await db.query(
              'mother_care_activities',
              where: 'beneficiary_ref_key = ? AND mother_care_state = ? AND is_deleted = 0',
              whereArgs: [beneficiaryRefKey, 'pnc_mother'],
              orderBy: 'created_date_time DESC',
              limit: 1,
            );

            if (mcaResult.isNotEmpty) {
              final mcaCreatedDate = mcaResult.first['created_date_time']?.toString() ?? '';
              if (mcaCreatedDate.isNotEmpty) {
                registrationDate = mcaCreatedDate;
              }
            }
          } catch (e) {
            print('⚠️ Error fetching registration date from mother_care_activities: $e');
            // Fallback to beneficiary created date
          }

          // Use HBNCList logic for visit count and dates
          final visitCount = await _getHbncVisitCountFromHBNCList(beneficiaryRefKey);
          final previousHBNCDate = await _getHbncLastVisitDateFromHBNCList(beneficiaryRefKey);
          final deliveryDate = formData['delivery_date']?.toString();
          print('📅 Passing delivery date to _getHbncNextVisitDateFromHBNCList: $deliveryDate');
          print('📊 Passing visit count to _getHbncNextVisitDateFromHBNCList: $visitCount');
          final nextHBNCDate = await _getHbncNextVisitDateFromHBNCList(
            beneficiaryRefKey,
            deliveryDate,
            visitCount,
            registrationDate,
          );

          print('📊 Final values for beneficiary $beneficiaryRefKey:');
          print('  - Visit Count: $visitCount');
          print('  - Previous HBNC Date: $previousHBNCDate');
          print('  - Next HBNC Date: $nextHBNCDate');

          // Get visit number for filtering logic (keep existing logic)
          final visitNumber = await _getHbncVisitNumber(beneficiaryRefKey);

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
              if (nextHBNCDate != null && nextHBNCDate.isNotEmpty) {
                final nextDate = _parseDate(nextHBNCDate);
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
                      '🗑️ Skipping HBNC record for $beneficiaryRefKey - next visit date $nextHBNCDate is in the future',
                    );
                    continue;
                  }

                  // If next visit date is today or in the past, show the record
                  if (nextDateOnly.isBefore(today) ||
                      nextDateOnly.isAtSameMomentAs(today)) {
                    debugPrint(
                      '✅ Including HBNC record for $beneficiaryRefKey - next visit date $nextHBNCDate is today or in the past',
                    );
                  } else {
                    debugPrint(
                      '🗑️ Skipping HBNC record for $beneficiaryRefKey - next visit date $nextHBNCDate is in the future',
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
            'last_visit_date': previousHBNCDate ?? '-',
            'next_visit_date': nextHBNCDate ?? '-',
            'visit_count': visitCount,
            'is_hbnc': true,
            'beneficiary_info': jsonEncode(beneficiaryInfo),
            'form_data': formData,
            'badge': 'HBNC', // Add this line to ensure the badge shows "HBNC"
            'last Visit date':
            previousHBNCDate ??
                '-', // Ensure this matches the card's expected field name
            'next hbnc visit due date':
            nextHBNCDate ??
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
      setState(() => _isLoading = false);
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

  Future<String?> _getHbncLastVisitDateFromHBNCList(String beneficiaryId) async {
    try {
      print('🔍 Fetching last visit date for beneficiary: $beneficiaryId');
      final db = await DatabaseProvider.instance.database;

      final hbncVisitKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];
      print('🔑 Using form reference key: $hbncVisitKey');

      final results = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? ',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      print('📋 Found ${results.length} HBNC visit records');

      if (results.isNotEmpty) {
        final result = results.first;
        print('📋 Found HBNC visit record with ID: ${result['id']}');

        // Directly use created_date_time as the previous HBNC date
        final createdDate = result['created_date_time'];
        if (createdDate != null && createdDate.toString().isNotEmpty) {
          print('⏰ Using created_date_time as previous HBNC date: $createdDate');
          final formattedDate = _formatDateFromString(createdDate.toString());
          print('✅ Previous HBNC date: $formattedDate');
          return formattedDate;
        } else {
          print('⚠️ created_date_time is null or empty');
          return null;
        }
      } else {
        print('ℹ️ No HBNC visit records found for beneficiary');
      }
    } catch (e) {
      print('❌ Error in _getHbncLastVisitDateFromHBNCList: $e');
    }
    return null;
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

  Future<int> _getHbncVisitCountFromHBNCList(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiaryId provided to _getHbncVisitCountFromHBNCList');
        return 0;
      }

      final db = await DatabaseProvider.instance.database;
      final hbncVisitKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother];

      // Get the latest visit record to extract visit number
      final latestVisitRows = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? ',
        whereArgs: [beneficiaryId, hbncVisitKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (latestVisitRows.isNotEmpty) {
        final result = latestVisitRows.first;
        try {
          final formJson = jsonDecode(result['form_json'] as String? ?? '{}');

          if (formJson.containsKey('hbyc_form')) {
            final hbycForm = formJson['hbyc_form'] as Map<String, dynamic>? ?? {};

            if (hbycForm.containsKey('visitDetails')) {
              final visitDetails = hbycForm['visitDetails'] as Map<String, dynamic>? ?? {};
              final visitNumber = visitDetails['visitNumber']?.toString();

              if (visitNumber != null) {
                final number = int.tryParse(visitNumber);
                if (number != null) {
                  print('🔢 Found visit number from hbyc_form.visitDetails: $number for beneficiary $beneficiaryId');
                  return number;
                }
              }
            }
          }

          final formData = formJson['form_data'] as Map<String, dynamic>? ?? {};

          if (formData.containsKey('visitDetails')) {
            final visitDetails = formData['visitDetails'] as Map<String, dynamic>? ?? {};
            final visitNumber = visitDetails['visitNumber']?.toString() ??
                visitDetails['visit_number']?.toString();

            if (visitNumber != null) {
              final number = int.tryParse(visitNumber);
              if (number != null) {
                print('🔢 Found visit number from form_data.visitDetails: $number for beneficiary $beneficiaryId');
                return number;
              }
            }
          }
        } catch (e) {
          print('❌ Error parsing visit number: $e');
        }
      }

      // Fallback 1: Check home_visit_day from pnc_infant_form
      if (latestVisitRows.isNotEmpty) {
        final result = latestVisitRows.first;
        try {
          final formJson = jsonDecode(result['form_json'] as String? ?? '{}');
          print('🔍 Full form JSON keys: ${formJson.keys.toList()}');

          // Check for both pnc_mother_form and pnc_infant_form structures
          List<String> formKeysToCheck = ['pnc_mother_form', 'pnc_infant_form'];

          for (final formKey in formKeysToCheck) {
            if (formJson.containsKey(formKey)) {
              final formData = formJson[formKey] as Map<String, dynamic>? ?? {};
              print('🔍 Found $formKey structure');
              print('🔍 $formKey keys: ${formData.keys.toList()}');

              final homeVisitDay = formData['home_visit_day']?.toString();
              print('📊 Extracted home_visit_day from $formKey: $homeVisitDay');
              print('📊 home_visit_day type: ${homeVisitDay.runtimeType}');

              if (homeVisitDay != null && homeVisitDay.isNotEmpty) {
                final number = int.tryParse(homeVisitDay);
                print('🔢 Parsed home_visit_day as integer: $number');
                if (number != null && number > 0) {
                  print('🔢 Found visit number from $formKey.home_visit_day: $number for beneficiary $beneficiaryId');
                  return number;
                } else {
                  print('⚠️ home_visit_day is null or <= 0: $number');
                }
              } else {
                print('⚠️ home_visit_day is null or empty in $formKey: $homeVisitDay');
              }
            }
          }
        } catch (e) {
          print('❌ Error parsing pnc_infant_form: $e');
          print('🔍 Raw form_json: ${result['form_json']}');
        }
      } else {
        print('⚠️ No latest visit rows found for pnc_infant_form check');
      }

      // Fallback 2: Counting total records
      final countRows = await db.query(
        FollowupFormDataTable.table,
        where: 'beneficiary_ref_key = ? AND forms_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryId, hbncVisitKey],
        columns: ['id'],
      );
      final count = countRows.length;
      print('🔢 HBNC visit record count for $beneficiaryId: $count');
      return count;
    } catch (e) {
      print('❌ Error in _getHbncVisitCountFromHBNCList for $beneficiaryId: $e');
      return 0;
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

  /// HBNC helper: get next visit date formatted as dd-MM-yyyy, same logic as
  /// HBNCList._getNextVisitDate
  Future<String?> _getHbncNextVisitDateForDisplay(
      String beneficiaryId,
      String? deliveryDate,
      ) async {
    try {
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

  DateTime? _calculateNextVisitDate(int currentVisitNumber, DateTime currentVisitDate) {
    switch (currentVisitNumber) {
      case 0: // Day 0 → Day 1 (within 24 hours of birth)
      case 1: // Day 1 → Day 3 (after 2 days)
        return currentVisitDate.add(const Duration(days: 2));
      case 3: // Day 3 → Day 7 (after 4 days)
        return currentVisitDate.add(const Duration(days: 4));
      case 7: // Day 7 → Day 14 (after 7 days)
        return currentVisitDate.add(const Duration(days: 7));
      case 14: // Day 14 → Day 21 (after 7 days)
        return currentVisitDate.add(const Duration(days: 7));
      case 21: // Day 21 → Day 28 (after 7 days)
        return currentVisitDate.add(const Duration(days: 7));
      case 28: // Day 28 → Day 42 (after 14 days)
        return currentVisitDate.add(const Duration(days: 14));
      default:
      // For any other visit number, add 7 days as default
        return currentVisitDate.add(const Duration(days: 7));
    }
  }

  Future<String?> _getHbncNextVisitDateFromHBNCList(
      String beneficiaryId,
      String? deliveryDate,
      int visitCount,
      String registrationDate,
      ) async {
    try {
      print('🔍 Calculating next visit date for beneficiary: $beneficiaryId');
      print('📊 Visit count: $visitCount');
      print('📅 Registration date: $registrationDate');

      /// 🔹 CASE 1: No HBNC visits done yet
      /// → Show registration date
      if (visitCount == 0) {
        if (registrationDate.isNotEmpty) {
          final parsedRegDate = DateTime.tryParse(registrationDate);
          if (parsedRegDate != null) {
            final formatted = _formatDateFromString(parsedRegDate.toString());
            print('📅 Visit count 0 → Next HBNC = Registration Date: $formatted');
            return formatted;
          }
        }

        // Fallback safety
        print('⚠️ Invalid registration date, using today');
        return _formatDateFromString(DateTime.now().toString());
      }

      /// 🔹 CASE 2: Visit count >= 1
      final db = await DatabaseProvider.instance.database;

      final possibleFormKeys = [
        FollowupFormDataTable.formUniqueKeys[
        FollowupFormDataTable.pncMother],
        '4r7twnycml3ej1vg',
        '695fdc026276645a01e9c800',
      ];

      final latestVisitRows = await db.query(
        FollowupFormDataTable.table,
        where:
        'beneficiary_ref_key = ? AND (forms_ref_key = ? OR forms_ref_key = ? OR forms_ref_key = ?)',
        whereArgs: [beneficiaryId, ...possibleFormKeys],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      DateTime baseDate;

      if (latestVisitRows.isNotEmpty) {
        final createdDateTime =
        latestVisitRows.first['created_date_time']?.toString();
        baseDate =
            DateTime.tryParse(createdDateTime ?? '') ?? DateTime.now();
        print('📅 Base date from last visit: $baseDate');
      } else {
        baseDate = DateTime.now();
        print('⚠️ No visit found, using today as base date');
      }

      /// Visit 1 → +2 days
      if (visitCount == 1) {
        final nextVisit = baseDate.add(const Duration(days: 2));
        return _formatDateFromString(nextVisit.toString());
      }

      /// Visit 2+ → use your existing rule
      final nextVisitDate =
      _calculateNextVisitDate(visitCount, baseDate);

      return nextVisitDate != null
          ? _formatDateFromString(nextVisitDate.toString())
          : null;
    } catch (e) {
      print('❌ Error calculating next visit date: $e');
      return null;
    }
  }

  /// Check if HBNC record should be removed due to visit count changes
  /// between current date and next HBNC visit date
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

  Future<bool> _hasTrackingDueStatus(String beneficiaryKey) async {
    final db = await DatabaseProvider.instance.database;

    final result = await db.rawQuery(
      '''
    SELECT 1
    FROM child_care_activities
    WHERE beneficiary_ref_key = ?
      AND child_care_state = 'tracking_due'
      AND is_deleted = 0
    LIMIT 1
    ''',
      [beneficiaryKey],
    );

    return result.isNotEmpty;
  }

  Future<bool> _hasFollowupWithinSixMonths({
    required String beneficiaryKey,
    required DateTime trackingDueDate,
  }) async {
    final db = await DatabaseProvider.instance.database;

    final sixMonthEnd = DateTime(
      trackingDueDate.year,
      trackingDueDate.month + 6,
      trackingDueDate.day,
    );

    print('🟢 ENTERED _hasFollowupWithinSixMonths for $beneficiaryKey');
    print('📅 Window: $trackingDueDate → $sixMonthEnd');

    final result = await db.rawQuery(
      '''
    SELECT 1
    FROM followup_form_data
    WHERE forms_ref_key = ?
      AND beneficiary_ref_key = ?
      AND is_deleted = 0
      AND datetime(created_date_time)
          BETWEEN datetime(?) AND datetime(?)
    LIMIT 1
    ''',
      [
        FollowupFormDataTable
            .formUniqueKeys[FollowupFormDataTable.childTrackingDue],
        beneficiaryKey,
        trackingDueDate.toIso8601String(),
        sixMonthEnd.toIso8601String(),
      ],
    );

    return result.isNotEmpty;
  }

  Future<DateTime?> _getLatestTrackingDueDate(
      String beneficiaryKey,
      ) async {
    final db = await DatabaseProvider.instance.database;

    final result = await db.rawQuery(
      '''
    SELECT created_date_time
    FROM child_care
    WHERE beneficiaries_registration_ref_key = ?
      AND child_care_type = 'tracking_due'
      AND is_deleted = 0
    ORDER BY datetime(created_date_time) DESC
    LIMIT 1
    ''',
      [beneficiaryKey],
    );

    if (result.isEmpty) {
      print('❌ No tracking_due for $beneficiaryKey');
      return null;
    }

    print('✅ tracking_due found for $beneficiaryKey → ${result.first['created_date_time']}');

    return DateTime.parse(result.first['created_date_time'] as String);
  }


  Future<void> _loadRoutineImmunizationItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();

      final rows = await db.rawQuery(
        '''
      SELECT *
      FROM beneficiaries_new
      WHERE is_deleted = 0
        AND is_adult = 0
        AND is_migrated = 0
        AND current_user_key = ?
      ORDER BY created_date_time DESC
      ''',
        [ashaUniqueKey],
      );

      final List<Map<String, dynamic>> items = [];
      final Set<String> seenBeneficiaries = {};

      for (final row in rows) {
        try {
          final beneficiaryRefKey = row['unique_key']?.toString() ?? '';
          if (beneficiaryRefKey.isEmpty) continue;
          if (!seenBeneficiaries.add(beneficiaryRefKey)) continue;

          final Map<String, dynamic>? info =
          row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
          as Map<String, dynamic>?
              : row['beneficiary_info'] as Map<String, dynamic>?;


          if (info == null) continue;

          final memberType =
              info['memberType']?.toString().toLowerCase() ?? '';
          final relation =
              info['relation']?.toString().toLowerCase() ?? '';

          if (!(memberType == 'child' ||
              relation == 'child' ||
              relation == 'daughter')) {
            continue;
          }

          // 🔹 Must have tracking_due
          final hasTrackingDue =
          await _hasTrackingDueStatus(beneficiaryRefKey);
          if (!hasTrackingDue) continue;

          // 🔹 6 MONTH EXCLUSION LOGIC
          final trackingDueDate =
          await _getLatestTrackingDueDate(beneficiaryRefKey);

          if (trackingDueDate != null) {
            final hasFollowupIn6Months =
            await _hasFollowupWithinSixMonths(
              beneficiaryKey: beneficiaryRefKey,
              trackingDueDate: trackingDueDate,
            );

            if (hasFollowupIn6Months) {
              print('❌ Excluding $beneficiaryRefKey → RI done within 6 months');
              continue;
            }
          }


          // 🔹 Extract display data
          final name =
              info['name'] ??
                  info['memberName'] ??
                  info['member_name'] ??
                  '';

          final mobile =
              info['mobileNo'] ??
                  info['mobile'] ??
                  info['mobile_number'] ??
                  '-';

          final dob =
              info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];

          final genderRaw =
              info['gender']?.toString().toLowerCase() ?? '';

          final gender = genderRaw == 'male' || genderRaw == 'm'
              ? 'Male'
              : genderRaw == 'female' || genderRaw == 'f'
              ? 'Female'
              : 'Other';

          final age = _formatAgeOnly(dob);

          final hhId = row['household_ref_key']?.toString() ?? '';

          items.add({
            'id': _last11(beneficiaryRefKey),
            'household_ref_key': hhId,
            'hhId': hhId,
            'BeneficiaryID': beneficiaryRefKey,
            'name': name,
            'age': age,
            'gender': gender,
            'mobile': mobile,
            'badge': 'RI',
          });
        } catch (e) {
          print('⚠️ Beneficiary error: $e');
        }
      }

      if (mounted) {
        setState(() => _riItems = items);
        _saveTodayWorkCountsToStorage();
      }
    } catch (e) {
      print('❌ RI load error: $e');
    }
  }

  Future<void> _loadFamilySurveyItems() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final List<Map<String, dynamic>> items = [];

      final Map<String, String> headKeyByHousehold = {};
      for (final hh in households) {
        final hhRefKey = (hh['unique_key'] ?? '').toString();
        final headId = (hh['head_id'] ?? '').toString();
        if (hhRefKey.isNotEmpty && headId.isNotEmpty) {
          headKeyByHousehold[hhRefKey] = headId;
        }
      }

      final DateTime now = DateTime.now();
      final DateTime sixMonthsAgo = now.subtract(const Duration(days: 180));
      final String todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      for (final row in rows) {
        try {
          if (ashaUniqueKey != null &&
              ashaUniqueKey.isNotEmpty &&
              row['current_user_key']?.toString() != ashaUniqueKey) {
            continue;
          }

          if (row['is_death'] == 1 ||
              row['is_migrated'] == 1 ||
              row['is_deleted'] == 1) continue;

          final String householdRefKey =
              row['household_ref_key']?.toString() ?? '';
          final String uniqueKey =
              row['unique_key']?.toString() ?? '';

          if (householdRefKey.isEmpty || uniqueKey.isEmpty) continue;

          // ------------------ BENEFICIARY INFO ------------------
          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info =
          infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw);

          final bool isFamilyHeadFromInfo =
              info['isFamilyhead'] == true ||
                  info['isFamilyHead']?.toString() == 'true';

          final String? configuredHeadKey =
          headKeyByHousehold[householdRefKey];

          final bool isHouseholdHead =
              configuredHeadKey != null &&
                  configuredHeadKey == uniqueKey;

          // ❌ If neither condition matches → skip
          if (!isHouseholdHead && !isFamilyHeadFromInfo) continue;

          DateTime? createdDt;
          DateTime? modifiedDt;

          try {
            // if (row['created_date_time'] != null &&
            //     row['created_date_time'].toString().isNotEmpty) {
            //   String dateStr = row['created_date_time'].toString();
            //   // Handle both "YYYY-MM-DD HH:MM:SS" and "YYYY-MM-DDTHH:MM:SS" formats
            //   if (dateStr.contains(' ')) {
            //     dateStr = dateStr.split(' ')[0];
            //   } else if (dateStr.contains('T')) {
            //     dateStr = dateStr.split('T')[0];
            //   }
            //   createdDt = DateTime.parse(dateStr);
            // }

            if (row['modified_date_time'] != null &&
                row['modified_date_time'].toString().isNotEmpty) {
              String dateStr = row['modified_date_time'].toString();
              // Handle both "YYYY-MM-DD HH:MM:SS" and "YYYY-MM-DDTHH:MM:SS" formats
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              modifiedDt = DateTime.parse(dateStr);
            }
          } catch (_) {}

          final bool isEligible =
              modifiedDt != null && modifiedDt.isBefore(sixMonthsAgo);

          if (!isEligible) continue;

          // ------------------ CHECK IF MODIFIED TODAY ------------------
          bool isModifiedToday = false;
          final String? rawModifiedDate = row['modified_date_time']?.toString();

          if (rawModifiedDate != null && rawModifiedDate.isNotEmpty) {
            try {
              String dateStr = rawModifiedDate;
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              if (dateStr == todayStr) {
                isModifiedToday = true;
                print('📋 Record was modified today - excluding from to-do list');
              }
            } catch (e) {
              // If parsing fails, try to extract date part
              if (rawModifiedDate.contains(' ')) {
                final datePart = rawModifiedDate.split(' ')[0];
                if (datePart == todayStr) {
                  isModifiedToday = true;
                  print('📋 Record was modified today (fallback) - excluding from to-do list');
                }
              } else if (rawModifiedDate.contains('T')) {
                final datePart = rawModifiedDate.split('T')[0];
                if (datePart == todayStr) {
                  isModifiedToday = true;
                  print('📋 Record was modified today (fallback) - excluding from to-do list');
                }
              }
            }
          }

          // Skip if modified today (these go to completed tab)
          if (isModifiedToday) continue;

          // ------------------ LAST SURVEY DATE ------------------
          final String lastSurveyDate = modifiedDt != null
              ? '${modifiedDt.day}-${modifiedDt.month}-${modifiedDt.year}'
              : '-';

          // ------------------ DISPLAY DATA ------------------
          final String name =
              (info['headName'])
                  ?.toString()
                  .trim() ??
                  '';
          if (name.isEmpty) continue;

          final String gender = (info['gender']?.toString() ?? '-')
              .toLowerCase()
              .replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase());

          String ageText = '-';
          final String? dobRaw = info['dob']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            final dob = DateTime.tryParse(dobRaw.split('T')[0]);
            if (dob != null) {
              int age = now.year - dob.year;
              if (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)) {
                age--;
              }
              if (age >= 0) ageText = '${age}Y';
            }
          } else if (info['age'] != null) {
            ageText = '${info['age']}y';
          }

          final String mobile =
              info['mobileNo']?.toString() ??
                  info['phone']?.toString() ??
                  '-';

          String displayId = uniqueKey;
          if (displayId.length > 11) {
            displayId = displayId.substring(displayId.length - 11);
          }

          final rawCreatedDate = row['created_date_time']?.toString();

          print('=== DEBUG: Adding Family Survey Item ===');
          print('Name: $name');
          print('Raw Modified Date: $rawModifiedDate');
          print('Last Survey Date (based on modified date): $lastSurveyDate');
          print('Note: Only modified date is checked for 6+ month eligibility');
          print('=====================================');

          items.add({
            'id': displayId,
            'beneficiary_ref_key': uniqueKey,
            'household_ref_key': householdRefKey,
            'name': name,
            'age': ageText,
            'gender': gender,
            'last survey date': lastSurveyDate,
            'lastSurveyDate': lastSurveyDate, // Add this field for UI display
            'Next HBNC due date': '-',
            'mobile': mobile,
            'badge': 'Family',
            // Add raw date fields for completed tab filtering
            'created_date': rawCreatedDate,
            'modified_date': rawModifiedDate,
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
    } catch (e) {
      debugPrint('Family survey load error: $e');
    }
  }

  Future<void> _loadFamilySurveyCompletedItems() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final households = await LocalStorageDao.instance.getAllHouseholds();

      final List<Map<String, dynamic>> items = [];

      final Map<String, String> headKeyByHousehold = {};
      for (final hh in households) {
        final hhRefKey = (hh['unique_key'] ?? '').toString();
        final headId = (hh['head_id'] ?? '').toString();
        if (hhRefKey.isNotEmpty && headId.isNotEmpty) {
          headKeyByHousehold[hhRefKey] = headId;
        }
      }

      final DateTime now = DateTime.now();
      final String todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      print('=== DEBUG: Loading Family Survey Completed Items ===');
      print('Today String: $todayStr');

      for (final row in rows) {
        try {
          if (ashaUniqueKey != null &&
              ashaUniqueKey.isNotEmpty &&
              row['current_user_key']?.toString() != ashaUniqueKey) {
            continue;
          }

          if (row['is_death'] == 1 ||
              row['is_migrated'] == 1 ||
              row['is_deleted'] == 1) continue;

          final String householdRefKey =
              row['household_ref_key']?.toString() ?? '';
          final String uniqueKey =
              row['unique_key']?.toString() ?? '';

          if (householdRefKey.isEmpty || uniqueKey.isEmpty) continue;

          // ------------------ BENEFICIARY INFO ------------------
          final infoRaw = row['beneficiary_info'];
          if (infoRaw == null) continue;

          final Map<String, dynamic> info =
          infoRaw is Map<String, dynamic>
              ? infoRaw
              : Map<String, dynamic>.from(infoRaw);

          final bool isFamilyHeadFromInfo =
              info['isFamilyhead'] == true ||
                  info['isFamilyHead']?.toString() == 'true';

          final String? configuredHeadKey =
          headKeyByHousehold[householdRefKey];

          final bool isHouseholdHead =
              configuredHeadKey != null &&
                  configuredHeadKey == uniqueKey;

          // ❌ If neither condition matches → skip
          if (!isHouseholdHead && !isFamilyHeadFromInfo) continue;

          // ------------------ CHECK IF MODIFIED TODAY ------------------
          bool isModifiedToday = false;
          final String? rawModifiedDate = row['modified_date_time']?.toString();

          if (rawModifiedDate != null && rawModifiedDate.isNotEmpty) {
            try {
              String dateStr = rawModifiedDate;
              // Handle both "YYYY-MM-DD HH:MM:SS" and "YYYY-MM-DDTHH:MM:SS" formats
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              if (dateStr == todayStr) {
                isModifiedToday = true;
                print('📋 Record modified today - including in completed list');
              }
            } catch (e) {
              // If parsing fails, try to extract date part
              if (rawModifiedDate.contains(' ')) {
                final datePart = rawModifiedDate.split(' ')[0];
                if (datePart == todayStr) {
                  isModifiedToday = true;
                  print('📋 Record modified today (fallback) - including in completed list');
                }
              } else if (rawModifiedDate.contains('T')) {
                final datePart = rawModifiedDate.split('T')[0];
                if (datePart == todayStr) {
                  isModifiedToday = true;
                  print('📋 Record modified today (fallback) - including in completed list');
                }
              }
            }
          }

          // Only include if modified today
          if (!isModifiedToday) continue;

          // ------------------ DATE PARSING ------------------
          DateTime? createdDt;
          DateTime? modifiedDt;

          try {
            if (row['created_date_time'] != null &&
                row['created_date_time'].toString().isNotEmpty) {
              String dateStr = row['created_date_time'].toString();
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              createdDt = DateTime.parse(dateStr);
            }

            if (row['modified_date_time'] != null &&
                row['modified_date_time'].toString().isNotEmpty) {
              String dateStr = row['modified_date_time'].toString();
              if (dateStr.contains(' ')) {
                dateStr = dateStr.split(' ')[0];
              } else if (dateStr.contains('T')) {
                dateStr = dateStr.split('T')[0];
              }
              modifiedDt = DateTime.parse(dateStr);
            }
          } catch (_) {}

          // ------------------ LAST SURVEY DATE ------------------
          final String lastSurveyDate = modifiedDt != null
              ? '${modifiedDt.day}-${modifiedDt.month}-${modifiedDt.year}'
              : '-';

          // ------------------ DISPLAY DATA ------------------
          final String name =
              (info['headName'])
                  ?.toString()
                  .trim() ??
                  '';
          if (name.isEmpty) continue;

          final String gender = (info['gender']?.toString() ?? '-')
              .toLowerCase()
              .replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase());

          String ageText = '-';
          final String? dobRaw = info['dob']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            final dob = DateTime.tryParse(dobRaw.split('T')[0]);
            if (dob != null) {
              int age = now.year - dob.year;
              if (now.month < dob.month ||
                  (now.month == dob.month && now.day < dob.day)) {
                age--;
              }
              if (age >= 0) ageText = '${age}Y';
            }
          } else if (info['age'] != null) {
            ageText = '${info['age']}y';
          }

          final String mobile =
              info['mobileNo']?.toString() ??
                  info['phone']?.toString() ??
                  '-';

          String displayId = uniqueKey;
          if (displayId.length > 11) {
            displayId = displayId.substring(displayId.length - 11);
          }

          // ------------------ ADD ITEM ------------------
          final rawCreatedDate = row['created_date_time']?.toString();

          print('=== DEBUG: Adding Family Survey Completed Item ===');
          print('Name: $name');
          print('Raw Created Date: $rawCreatedDate');
          print('Raw Modified Date: $rawModifiedDate');
          print('Last Survey Date: $lastSurveyDate');
          print('=============================================');

          items.add({
            'id': displayId,
            'household_ref_key': householdRefKey,
            'name': name,
            'age': ageText,
            'gender': gender,
            'last survey date': lastSurveyDate,
            'lastSurveyDate': lastSurveyDate,
            'Next HBNC due date': '-',
            'mobile': mobile,
            'badge': 'Family',
            'created_date': rawCreatedDate,
            'modified_date': rawModifiedDate,
          });
        } catch (_) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _familySurveyCompletedItems = items;
        });
        print('=== DEBUG: Family Survey Completed Items Loaded ===');
        print('Total Completed Items: ${items.length}');
        print('===============================================');
      }
    } catch (e) {
      debugPrint('Family survey completed load error: $e');
    }
  }

  List<Map<String, dynamic>> _getFamilySurveyItemsForCompletedTab() {
    if (todayVisitClick) {
      // For to-do visits tab, show all items (excluding today's modified)
      return _familySurveyItems;
    } else {
      // For completed visits tab, show today's modified items
      print('=== DEBUG: Family Survey Completed Tab ===');
      print('Returning ${_familySurveyCompletedItems.length} completed items');
      print('========================================');
      return _familySurveyCompletedItems;
    }
  }

  List<Widget> _getAncListItems() {
    final List<Map<String, dynamic>> ancItems = _ancItems;

    return ancItems.map((item) => _routineCard(item, context)).toList();
  }

  List<Widget> _getAncListCompletedItems() {
    final List<Map<String, dynamic>> ancItems = _ancCompletedItems;

    return ancItems.map((item) => _routineCard(item, context)).toList();
  }

  List<Widget> _getHBNCListCompletedItems() {
    final List<Map<String, dynamic>> ancItems = _hbncCompletedItems;

    return ancItems.map((item) => _routineCard(item, context)).toList();
  }

  List<Widget> _getECListCompletedItems() {
    final List<Map<String, dynamic>> ancItems = _eligibleCompletedCoupleItems;

    return ancItems.map((item) => _routineCard(item, context)).toList();
  }

  List<Widget> _getRIListCompletedItems() {
    final List<Map<String, dynamic>> ancItems = _riCompletedItems;

    return ancItems.map((item) => _routineCard(item, context)).toList();
  }

  void _printCompletedItemsCount() {
    final ancCount = _ancCompletedItems.length;
    final hbncCount = _hbncCompletedItems.length;
    final ecCount = _eligibleCompletedCoupleItems.length;
    final riCount = _riCompletedItems.length;
    final familySurveyCount = _familySurveyCompletedItems.length;
    final totalCount = ancCount + hbncCount + ecCount + riCount + familySurveyCount;

    print('=== Completed Items Count ===');
    print('ANC Completed Items: $ancCount');
    print('HBNC Completed Items: $hbncCount');
    print('Eligible Couple Completed Items: $ecCount');
    print('RI Completed Items: $riCount');
    print('Family Survey Completed Items: $familySurveyCount');
    print('Total Completed Items: $totalCount');
    print('_completedVisitsCount (State): $_completedVisitsCount');
    print('_toDoVisitsCount (from Storage): $_toDoVisitsCount');
    print('============================');
  }

  int get _totalCount =>
      _ancCompletedItems.length +
          _hbncCompletedItems.length +
          _eligibleCompletedCoupleItems.length +
          _riCompletedItems.length +
          _familySurveyCompletedItems.length;

  Widget _routineCard(Map<String, dynamic> item, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final badge = item['badge']?.toString() ?? '';

    return InkWell(
      onTap: () async {
        // Hide confirmation dialog for completed visits tab
        if (!todayVisitClick) {
          return;
        }

        final confirmed = await showConfirmationDialog(
          context: context,
          message: l10n?.moveForward ?? 'Move forward?',
          yesText: l10n?.yes ?? 'Yes',
          noButtonColor: AppColors.primary,
          yesButtonColor: AppColors.primary,
          noText: l10n?.no ?? 'No',
        );

        if (confirmed != true) {
          return;
        }

        if (badge == 'Family') {
          final hhKey = item['household_ref_key']?.toString() ?? '';
          final beneficiaryKey = item['id']?.toString() ?? '';
          final beneficiary_ref_key = item['beneficiary_ref_key']?.toString() ?? '';
          if (hhKey.isEmpty && beneficiaryKey.isEmpty) {
            print('⚠️ Both household_ref_key and id are empty for family survey navigation');
            return;
          }

          Map<String, String> initial = {};
          try {
            final households = await LocalStorageDao.instance
                .getAllHouseholds();
            String? headId;
            String? foundHhKey;

            // First try to find household using household_ref_key
            if (hhKey.isNotEmpty) {
              for (final hh in households) {
                final key = (hh['unique_key'] ?? '').toString();
                if (key == hhKey) {
                  headId = (hh['head_id'] ?? '').toString();
                  foundHhKey = key;
                  break;
                }
              }
            }

            //If not found with household_ref_key, try using beneficiary key as fallback
            if (foundHhKey == null && beneficiaryKey.isNotEmpty) {
              for (final hh in households) {
                final key = (hh['unique_key'] ?? '').toString();
                if (key == beneficiaryKey) {
                  headId = (hh['head_id'] ?? '').toString();
                  foundHhKey = key;
                  print('✅ Found household using beneficiary key: $beneficiaryKey');
                  break;
                }
              }
            }

            if (foundHhKey == null) {
              print('⚠️ No household found for keys - hhKey: $hhKey, beneficiaryKey: $beneficiaryKey');
              return;
            }

            final members = await LocalStorageDao.instance
                .getBeneficiariesByHouseholdFamily(foundHhKey, beneficiary_ref_key);

            Map<String, dynamic>? headRow;
            // Use beneficiary_ref_key as the configured head key (same logic as AllHouseHold)
            final configuredHeadKey = beneficiary_ref_key;
            if (configuredHeadKey != null && configuredHeadKey.isNotEmpty) {
              for (final m in members) {
                if ((m['unique_key'] ?? '').toString() == configuredHeadKey) {
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

              final map = <String, String>{};
              info.forEach((key, value) {
                if (value != null) {
                  map[key] = value.toString();
                }
              });

              map['hh_unique_key'] = foundHhKey;
              map['head_unique_key'] = headRow['unique_key']?.toString() ?? '';
              if (headRow['id'] != null) {
                map['head_id_pk'] = headRow['id'].toString();
              }

              // Check if the current beneficiary is actually a spouse (not the head)
              // If so, we should prefill the spouse details with their own data
              final relationToHead = info['relation_to_head']?.toString().toLowerCase() ?? '';
              final relation = info['relation']?.toString().toLowerCase() ?? '';
              final isCurrentBeneficiarySpouse = relationToHead == 'wife' ||
                  relationToHead == 'husband' ||
                  relation == 'wife' ||
                  relation == 'husband';

              print('🔍 [Family Survey] Relation Detection:');
              print('   relation_to_head: "$relationToHead"');
              print('   relation: "$relation"');
              print('   isCurrentBeneficiarySpouse: $isCurrentBeneficiarySpouse');
              print('   Current beneficiary name: ${info['name']}');

              if (!isCurrentBeneficiarySpouse) {
                print('👤 [Family Survey] Current beneficiary is HEAD, looking for spouse in members...');
                // Try to find spouse in the members list
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
                  if (rel == 'spouse' || rel == 'wife' || rel == 'husband') {
                    spouseRow = m;
                    break;
                  }
                }

                if (spouseRow != null) {
                  // Use the found spouse row data
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

                  // Specific mappings for SpousState fields
                  map['sp_relation'] = spInfo['relation_to_head']?.toString() ??
                      spInfo['relation']?.toString() ?? 'spouse';
                  map['sp_memberName'] = spInfo['name']?.toString() ??
                      spInfo['memberName']?.toString() ?? '';
                  map['sp_spouseName'] = spInfo['spouseName']?.toString() ??
                      spInfo['headName']?.toString() ?? '';
                  map['sp_fatherName'] = spInfo['father_name']?.toString() ??
                      spInfo['fatherName']?.toString() ?? '';
                  map['sp_ageAtMarriage'] = spInfo['ageAtMarriage']?.toString() ?? '';
                  map['sp_gender'] = spInfo['gender']?.toString() ?? '';
                  map['sp_occupation'] = spInfo['occupation']?.toString() ?? '';
                  map['sp_otherOccupation'] = spInfo['other_occupation']?.toString() ?? '';
                  map['sp_education'] = spInfo['education']?.toString() ?? '';
                  map['sp_religion'] = spInfo['religion']?.toString() ?? '';
                  map['sp_otherReligion'] = spInfo['other_religion']?.toString() ?? '';
                  map['sp_category'] = spInfo['category']?.toString() ?? '';
                  map['sp_otherCategory'] = spInfo['other_category']?.toString() ?? '';
                  map['sp_abhaAddress'] = spInfo['abhaAddress']?.toString() ?? '';
                  map['sp_mobileOwner'] = spInfo['mobileOwner']?.toString() ?? '';
                  map['sp_mobileOwnerOtherRelation'] = spInfo['mobile_owner_relation']?.toString() ??
                      spInfo['mobileOwnerOtherRelation']?.toString() ?? '';
                  map['sp_mobileNo'] = spInfo['mobileNo']?.toString() ??
                      spInfo['mobile']?.toString() ?? '';
                  map['sp_bankAcc'] = spInfo['bankAcc']?.toString() ??
                      spInfo['bankAccountNumber']?.toString() ??
                      spInfo['account_number']?.toString() ?? '';
                  map['sp_ifsc'] = spInfo['ifsc']?.toString() ??
                      spInfo['ifscCode']?.toString() ??
                      spInfo['ifsc_code']?.toString() ?? '';
                  map['sp_voterId'] = spInfo['voterId']?.toString() ?? '';
                  map['sp_rationId'] = spInfo['rationId']?.toString() ?? '';
                  map['sp_phId'] = spInfo['phId']?.toString() ?? '';
                  map['sp_beneficiaryType'] = spInfo['beneficiaryType']?.toString() ??
                      spInfo['type_of_beneficiary']?.toString() ?? 'staying_in_house';
                  map['sp_isPregnant'] = spInfo['isPregnant']?.toString() ?? '';

                  // Age-related fields
                  map['sp_useDob'] = spInfo['useDob']?.toString() ?? 'true';
                  map['sp_dob'] = spInfo['dob']?.toString() ?? '';
                  map['sp_approxAge'] = spInfo['approxAge']?.toString() ?? '';
                  map['sp_UpdateYears'] = spInfo['years']?.toString() ?? '';
                  map['sp_UpdateMonths'] = spInfo['months']?.toString() ?? '';
                  map['sp_UpdateDays'] = spInfo['days']?.toString() ?? '';

                  // ID fields
                  map['sp_RichIDChanged'] = spInfo['RichIDChanged']?.toString() ??
                      spInfo['rch_id']?.toString() ??
                      spInfo['abhaNumber']?.toString() ?? '';

                  // Family planning fields
                  map['sp_familyPlanningCounseling'] = spInfo['is_family_planning']?.toString() ?? '';
                  map['sp_fpMethod'] = spInfo['fpMethod']?.toString() ?? '';
                }
              } else {
                // Current beneficiary is the spouse, so prefill spouse details with their own data
                info.forEach((key, value) {
                  if (value != null) {
                    // Add spouse data with sp_ prefix for general use
                    map['sp_$key'] = value.toString();
                  }
                });

                // Specific mappings for SpousState fields when current beneficiary is spouse
                map['sp_relation'] = info['relation_to_head']?.toString() ??
                    info['relation']?.toString() ?? 'spouse';
                map['sp_memberName'] = info['name']?.toString() ??
                    info['memberName']?.toString() ?? '';
                map['sp_spouseName'] = info['spouseName']?.toString() ??
                    info['headName']?.toString() ?? '';
                map['sp_fatherName'] = info['father_name']?.toString() ??
                    info['fatherName']?.toString() ?? '';
                map['sp_ageAtMarriage'] = info['ageAtMarriage']?.toString() ?? '';
                map['sp_gender'] = info['gender']?.toString() ?? '';
                map['sp_occupation'] = info['occupation']?.toString() ?? '';
                map['sp_otherOccupation'] = info['other_occupation']?.toString() ?? '';
                map['sp_education'] = info['education']?.toString() ?? '';
                map['sp_religion'] = info['religion']?.toString() ?? '';
                map['sp_otherReligion'] = info['other_religion']?.toString() ?? '';
                map['sp_category'] = info['category']?.toString() ?? '';
                map['sp_otherCategory'] = info['other_category']?.toString() ?? '';
                map['sp_abhaAddress'] = info['abhaAddress']?.toString() ?? '';
                map['sp_mobileOwner'] = info['mobileOwner']?.toString() ?? '';
                map['sp_mobileOwnerOtherRelation'] = info['mobile_owner_relation']?.toString() ??
                    info['mobileOwnerOtherRelation']?.toString() ?? '';
                map['sp_mobileNo'] = info['mobileNo']?.toString() ??
                    info['mobile']?.toString() ?? '';
                map['sp_bankAcc'] = info['bankAcc']?.toString() ??
                    info['bankAccountNumber']?.toString() ??
                    info['account_number']?.toString() ?? '';
                map['sp_ifsc'] = info['ifsc']?.toString() ??
                    info['ifscCode']?.toString() ??
                    info['ifsc_code']?.toString() ?? '';
                map['sp_voterId'] = info['voterId']?.toString() ?? '';
                map['sp_rationId'] = info['rationId']?.toString() ?? '';
                map['sp_phId'] = info['phId']?.toString() ?? '';
                map['sp_beneficiaryType'] = info['beneficiaryType']?.toString() ??
                    info['type_of_beneficiary']?.toString() ?? 'staying_in_house';
                map['sp_isPregnant'] = info['isPregnant']?.toString() ?? '';

                // Age-related fields
                map['sp_useDob'] = info['useDob']?.toString() ?? 'true';
                map['sp_dob'] = info['dob']?.toString() ?? '';
                map['sp_approxAge'] = info['approxAge']?.toString() ?? '';
                map['sp_UpdateYears'] = info['years']?.toString() ?? '';
                map['sp_UpdateMonths'] = info['months']?.toString() ?? '';
                map['sp_UpdateDays'] = info['days']?.toString() ?? '';

                // ID fields
                map['sp_RichIDChanged'] = info['RichIDChanged']?.toString() ??
                    info['rch_id']?.toString() ??
                    info['abhaNumber']?.toString() ?? '';

                // Family planning fields
                map['sp_familyPlanningCounseling'] = info['is_family_planning']?.toString() ?? '';
                map['sp_fpMethod'] = info['fpMethod']?.toString() ?? '';

                // Also add technical identifiers for spouse
                map['spouse_unique_key'] = headRow['unique_key']?.toString() ?? '';
                if (headRow['id'] != null) {
                  map['spouse_id_pk'] = headRow['id'].toString();
                }
              }

              map['headName'] ??= item['name']?.toString() ?? '';
              map['mobileNo'] ??= item['mobile']?.toString() ?? '';

              map['memberType'] ??= info['memberType']?.toString() ?? 'adult';
              map['relation'] ??= info['relation']?.toString() ?? info['relation_to_head']?.toString() ?? '';
              map['name'] ??= info['name']?.toString() ?? '';
              map['memberName'] ??= info['memberName']?.toString() ?? info['name']?.toString() ?? '';
              map['headName'] ??= info['headName']?.toString() ?? item['name']?.toString() ?? '';
              map['father_name'] ??= info['father_name']?.toString() ?? info['fatherName']?.toString() ?? '';
              map['fatherName'] ??= info['fatherName']?.toString() ?? info['father_name']?.toString() ?? '';
              map['motherName'] ??= info['motherName']?.toString() ?? '';
              map['houseNo'] ??= info['houseNo']?.toString() ?? '';

              map['age_by'] ??= info['age_by']?.toString() ?? 'by_dob';
              map['useDob'] ??= info['useDob']?.toString() ?? info['age_by']?.toString() ?? 'by_dob';
              map['dob'] ??= info['dob']?.toString() ?? '';
              map['approxAge'] ??= info['approxAge']?.toString() ?? '';
              map['years'] ??= info['years']?.toString() ?? '';
              map['months'] ??= info['months']?.toString() ?? '';
              map['days'] ??= info['days']?.toString() ?? '';
              map['updateDay'] ??= info['updateDay']?.toString() ?? '';
              map['updateMonth'] ??= info['updateMonth']?.toString() ?? '';
              map['updateYear'] ??= info['updateYear']?.toString() ?? '';

              map['children'] ??= info['children']?.toString() ?? '';
              map['birthOrder'] ??= info['birthOrder']?.toString() ?? '';
              map['totalBorn'] ??= info['totalBorn']?.toString() ?? '';
              map['totalLive'] ??= info['totalLive']?.toString() ?? '';
              map['totalMale'] ??= info['totalMale']?.toString() ?? '';
              map['totalFemale'] ??= info['totalFemale']?.toString() ?? '';
              map['youngestAge'] ??= info['youngestAge']?.toString() ?? '';
              map['ageUnit'] ??= info['ageUnit']?.toString() ?? 'year';
              map['youngestGender'] ??= info['youngestGender']?.toString() ?? '';
              map['hasChildren'] ??= info['hasChildren']?.toString() ?? '';
              map['isPregnant'] ??= info['isPregnant']?.toString() ?? '';

              map['gender'] ??= info['gender']?.toString() ?? '';
              map['occupation'] ??= info['occupation']?.toString() ?? '';
              map['education'] ??= info['education']?.toString() ?? '';
              map['religion'] ??= info['religion']?.toString() ?? '';
              map['category'] ??= info['category']?.toString() ?? '';
              map['maritalStatus'] ??= info['maritalStatus']?.toString() ?? '';
              map['ageAtMarriage'] ??= info['ageAtMarriage']?.toString() ?? '';
              map['spouseName'] ??= info['spouseName']?.toString() ?? '';

              map['beneficiaryType'] ??= info['beneficiaryType']?.toString() ?? info['type_of_beneficiary']?.toString() ?? 'staying_in_house';
              map['mobileOwner'] ??= info['mobileOwner']?.toString() ?? '';
              map['mobileNo'] ??= info['mobileNo']?.toString() ?? info['mobile']?.toString() ?? item['mobile']?.toString() ?? '';
              map['abhaAddress'] ??= info['abhaAddress']?.toString() ?? '';
              map['abhaNumber'] ??= info['abhaNumber']?.toString() ?? info['abha_no']?.toString() ?? '';

              map['bankAcc'] ??= info['bankAcc']?.toString() ?? info['bankAccountNumber']?.toString() ?? info['account_number']?.toString() ?? '';
              map['bankAccountNumber'] ??= info['bankAccountNumber']?.toString() ?? info['account_number']?.toString() ?? '';
              map['ifsc'] ??= info['ifsc']?.toString() ?? info['ifscCode']?.toString() ?? info['ifsc_code']?.toString() ?? '';
              map['ifscCode'] ??= info['ifscCode']?.toString() ?? info['ifsc_code']?.toString() ?? '';
              map['bankName'] ??= info['bankName']?.toString() ?? '';
              map['branchName'] ??= info['branchName']?.toString() ?? '';

              map['village'] ??= info['village']?.toString() ?? info['village_name']?.toString() ?? '';
              map['ward'] ??= info['ward']?.toString() ?? '';
              map['wardNo'] ??= info['wardNo']?.toString() ?? info['ward_no']?.toString() ?? '';
              map['mohalla'] ??= info['mohalla']?.toString() ?? info['mohalla_name']?.toString() ?? '';
              map['mohallaTola'] ??= info['mohallaTola']?.toString() ?? '';
              map['state'] ??= info['state']?.toString() ?? '';
              map['district'] ??= info['district']?.toString() ?? '';
              map['block'] ??= info['block']?.toString() ?? '';

              map['memberStatus'] ??= info['memberStatus']?.toString() ?? info['member_status']?.toString() ?? 'alive';
              map['relation_to_head'] ??= info['relation_to_head']?.toString() ?? info['relation']?.toString() ?? '';
              map['ben_type'] ??= info['ben_type']?.toString() ?? info['memberType']?.toString() ?? 'adult';
              map['is_new_member'] ??= info['is_new_member']?.toString() ?? 'false';
              map['isFamilyhead'] ??= info['isFamilyhead']?.toString() ?? info['isFamilyhead']?.toString() ?? 'false';
              map['isFamilyheadWife'] ??= info['isFamilyheadWife']?.toString() ?? 'false';
              map['type_of_beneficiary'] ??= info['type_of_beneficiary']?.toString() ?? 'staying_in_house';
              map['is_family_planning'] ??= info['is_family_planning']?.toString() ?? '';

              // Verification Status
              map['is_abha_verified'] ??= info['is_abha_verified']?.toString() ?? 'false';
              map['is_rch_id_verified'] ??= info['is_rch_id_verified']?.toString() ?? 'false';
              map['is_fetched_from_abha'] ??= info['is_fetched_from_abha']?.toString() ?? 'false';
              map['is_fetched_from_rch'] ??= info['is_fetched_from_rch']?.toString() ?? 'false';

              // ID Information
              map['adhar_no'] ??= info['adhar_no']?.toString() ?? '';
              map['abha_no'] ??= info['abha_no']?.toString() ?? '';
              map['rch_id'] ??= info['rch_id']?.toString() ?? '';
              map['sr_no'] ??= info['sr_no']?.toString() ?? '';

              // Additional Fields for Child Members
              map['relaton_with_family_head'] ??= info['relaton_with_family_head']?.toString() ?? '';
              map['other_relation'] ??= info['other_relation']?.toString() ?? '';
              map['whose_mob_no'] ??= info['whose_mob_no']?.toString() ?? '';
              map['other_whose_mob_no'] ??= info['other_whose_mob_no']?.toString() ?? '';
              map['mobile_no'] ??= info['mobile_no']?.toString() ?? '';
              map['dob_day'] ??= info['dob_day']?.toString() ?? '';
              map['dob_month'] ??= info['dob_month']?.toString() ?? '';
              map['dob_year'] ??= info['dob_year']?.toString() ?? '';
              map['date_of_birth'] ??= info['date_of_birth']?.toString() ?? '';
              map['age'] ??= info['age']?.toString() ?? '';
              map['estimate_age'] ??= info['estimate_age']?.toString() ?? '';
              map['weight'] ??= info['weight']?.toString() ?? '';
              map['weight_at_birth'] ??= info['weight_at_birth']?.toString() ?? '';
              map['is_birth_certificate_issued'] ??= info['is_birth_certificate_issued']?.toString() ?? '';
              map['is_school_going_child'] ??= info['is_school_going_child']?.toString() ?? '';
              map['type_of_school'] ??= info['type_of_school']?.toString() ?? '';
              map['other_category'] ??= info['other_category']?.toString() ?? '';
              map['ward_name'] ??= info['ward_name']?.toString() ?? '';
              map['mohalla_name'] ??= info['mohalla_name']?.toString() ?? '';
              map['is_existing_father'] ??= info['is_existing_father']?.toString() ?? 'true';
              map['is_existing_mother'] ??= info['is_existing_mother']?.toString() ?? 'true';
              map['mother_ben_ref_key'] ??= info['mother_ben_ref_key']?.toString() ?? '';
              map['father_ben_ref_key'] ??= info['father_ben_ref_key']?.toString() ?? '';
              map['father_or_spouse_name'] ??= info['father_or_spouse_name']?.toString() ?? '';
              map['mother_name'] ??= info['mother_name']?.toString() ?? '';
              map['formated_age'] ??= info['formated_age']?.toString() ?? '';
              map['beneficiary_key'] ??= info['beneficiary_key']?.toString() ?? '';
              map['reason_of_closer'] ??= info['reason_of_closer']?.toString() ?? '';

              initial = map;
            }
          } catch (_) {
            initial = {
              'headName': item['name']?.toString() ?? '',
              'mobileNo': item['mobile']?.toString() ?? '',
            };
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddNewFamilyHeadScreen(isEdit: true, initial: initial),
            ),
          );

          if (result != null && mounted) {
            await _loadData();
          }
        } else if (badge == 'EligibleCouple') {
          final displayId = item['id']?.toString() ?? '';
          final beneficiaryRefKey =
              item['BeneficiaryID']?.toString() ??
                  item['unique_key']?.toString() ??
                  '';
          if (displayId.isEmpty || beneficiaryRefKey.isEmpty) return;

          final result = await Navigator.push(
            context,
            TrackEligibleCoupleScreen.route(
              beneficiaryId: displayId,
              beneficiaryRefKey: beneficiaryRefKey,
            ),
          );

          bool saved = false;
          if (result == true) saved = true;
          if (result is Map && result['saved'] == true) saved = true;

          if (saved && mounted) {
            setState(() {
              _completedVisitsCount++;
              _eligibleCoupleItems.removeWhere(
                    (element) =>
                element['BeneficiaryID'] == item['BeneficiaryID'],
              );

              final completedItem = Map<String, dynamic>.from(item);
              completedItem['last Visit date'] = _formatDateOnly(
                DateTime.now().toIso8601String(),
              );
              completedItem['_rawRow'] = {};
              _eligibleCompletedCoupleItems.insert(0, completedItem);
            });
            await _loadData();
          }
        } else if (badge == 'ANC') {
          final hhId =
              item['hhId']?.toString() ??
                  item['household_ref_key']?.toString() ??
                  '';
          final beneficiaryId =
              item['BeneficiaryID']?.toString() ??
                  item['unique_key']?.toString() ??
                  '';
          if (hhId.isEmpty || beneficiaryId.isEmpty) return;

          final formData = Map<String, dynamic>.from(item);
          formData['hhId'] = hhId;
          formData['BeneficiaryID'] = beneficiaryId;
          formData['unique_key'] =
              item['unique_key']?.toString() ?? beneficiaryId;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Ancvisitform(beneficiaryData: formData),
            ),
          );

          bool saved = false;
          if (result == true) saved = true;
          if (result is Map && result['saved'] == true) saved = true;

          if (saved && mounted) {
            setState(() {
              _completedVisitsCount++;
              _ancItems.removeWhere(
                    (element) =>
                element['unique_key'] == item['unique_key'] &&
                    element['BeneficiaryID'] == item['BeneficiaryID'],
              );

              // Add the completed item to the completed list immediately
              final completedItem = Map<String, dynamic>.from(item);
              completedItem['last Visit date'] = _formatDateOnly(
                DateTime.now().toIso8601String(),
              );
              completedItem['_rawRow'] = {};
              _ancCompletedItems.insert(0, completedItem);
            });
            await _loadData();
          }
        } else if (badge == 'HBNC') {
          final fullBeneficiaryId = item['fullBeneficiaryId']?.toString() ?? '';
          final fullHhId = item['fullHhId']?.toString() ?? '';
          if (fullBeneficiaryId.isEmpty || fullHhId.isEmpty) return;

          final beneficiaryData = <String, dynamic>{
            'unique_key': fullBeneficiaryId,
            'household_ref_key': fullHhId,
            'name': item['name']?.toString() ?? '-',
            'returnToPrevious': true,
          };

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HbncVisitScreen(beneficiaryData: beneficiaryData),
            ),
          );

          if (result == true && mounted) {
            setState(() {
              _completedVisitsCount++;
              _hbncItems.removeWhere(
                    (element) =>
                element['fullBeneficiaryId'] == item['fullBeneficiaryId'],
              );

              // Add the completed item to the completed list immediately
              final completedItem = Map<String, dynamic>.from(item);
              completedItem['last Visit date'] = _formatDateOnly(
                DateTime.now().toIso8601String(),
              );
              completedItem['_rawRow'] = {};
              _hbncCompletedItems.insert(0, completedItem);
            });
            await _loadData();
          }
        } else if (badge == 'RI') {
          final hhKey =
              item['household_ref_key']?.toString() ??
                  item['hhId']?.toString() ??
                  '';
          final beneficiaryRefKey =
              item['BeneficiaryID']?.toString() ?? item['id']?.toString() ?? '';
          if (beneficiaryRefKey.isEmpty) return;

          final formData = <String, dynamic>{
            'household_ref_key': hhKey,
            'beneficiary_ref_key': beneficiaryRefKey,
            'hhId': hhKey,
            'BeneficiaryID': beneficiaryRefKey,
            'beneficiary_id': beneficiaryRefKey,
            'household_id': hhKey,
            'child_name': item['name']?.toString() ?? '',
            'age': item['age']?.toString() ?? '',
            'gender': item['gender']?.toString() ?? '',
            'mobile_number': item['mobile']?.toString() ?? '',
          };

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChildTrackingDueListForm(),
              settings: RouteSettings(arguments: {'formData': formData}),
            ),
          );

          if (result == true && mounted) {
            setState(() {
              _completedVisitsCount++;
              _riItems.removeWhere(
                    (element) =>
                element['id'] == item['id'] &&
                    element['BeneficiaryID'] == item['BeneficiaryID'],
              );

              // Add the completed item to the completed list immediately
              final completedItem = Map<String, dynamic>.from(item);
              completedItem['last Visit date'] = _formatDateOnly(
                DateTime.now().toIso8601String(),
              );
              completedItem['_rawRow'] = {};
              _riCompletedItems.insert(0, completedItem);
            });
            await _loadData();
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
                          return _last11(item['BeneficiaryID']?.toString());
                        }

                        // For RI (Routine Immunization), show household reference key
                        if (badge == 'RI') {
                          final householdRefKey =
                              item['household_ref_key']?.toString() ??
                                  item['hhId']?.toString();
                          if (householdRefKey != null &&
                              householdRefKey.isNotEmpty) {
                            return _last11(householdRefKey);
                          }
                        }

                        // Prefer beneficiary/unique identifiers over household_ref_key for other badges
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
                        _getLocalizedBadge(badge, l10n!),
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
                          '${item['name'] ?? (l10n?.na ?? 'N/A')}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (item['age'] != null || item['gender'] != null) ...[
                          Text(
                            '${item['age'] ?? '-'} - ${item['gender'] ?? '-'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],

                        // Show last survey list for Family items
                        if (badge == 'Family') ...[
                          Text(
                            '${l10n?.lastSurveyList ?? "Last Survey date"}: ${item['lastSurveyDate'] ?? item['last_survey_date'] ?? "Not Available"}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],

                        // spouse_name display removed as requested
                        if (item['next hbnc visit due date'] != null) ...[
                          Text(
                            '${"Next HBNC due date"}: ${item['next hbnc visit due date']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],

                        // Show last visit date for ANC items
                        if (badge == 'ANC') ...[
                          FutureBuilder<String?>(
                            future: _getLastANCVisitDateForItem(item),
                            builder: (context, snapshot) {
                              final lastVisitDate = snapshot.data;
                              if (lastVisitDate != null &&
                                  lastVisitDate.isNotEmpty) {
                                return Text(
                                  'Last visit date: $lastVisitDate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                );
                              } else {
                                return Text(
                                  'Last visit date: No visit Yet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                );
                              }
                            },
                          ),
                        ] else if (badge == 'RI') ...[
                          // For RI items, show different labels based on whether it's in completed list or to-do list
                          if (!todayVisitClick) ...[
                            // Completed visits tab - show completion date
                            Text(
                              'Completion date: ${item['last Visit date'] ?? 'Not Available'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ] else ...[
                            // To-do visits tab - show last historical visit date
                            Text(
                              'Last visit date: ${item['last Visit date'] ?? 'Not Available'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ] else if (badge != 'HBNC' &&
                            item['last Visit date'] != null) ...[
                          Text(
                            '${"Last visit date"}: ${item['last Visit date']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                        if (item['Current ANC last due date'] != null && badge != 'EligibleCouple') ...[
                          Text(
                            '${"Current ANC last due date"}: ${item['Current ANC last due date']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                        if (item['mobile'] != null) ...[
                          Text(
                            '${l10n?.mobileNo ?? "Mobile"}: ${item['mobile']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _launchPhoneDialer(item['mobile']?.toString()),
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

  String _getTranslatedTitle(String key, AppLocalizations l10n) {
    switch (key) {
      case 'Family Survey List':
        return l10n.listFamilySurvey;
      case 'Eligible Couple Due List':
        return l10n.listEligibleCoupleDue;
      case 'ANC List':
        return l10n.listANC;
      case 'HBNC List':
        return l10n.listHBNC;
      case 'Routine Immunization (RI)':
        return l10n.listRoutineImmunization;
      default:
        if (key == l10n.listFamilySurvey ||
            key == l10n.listEligibleCoupleDue ||
            key == l10n.listANC ||
            key == l10n.listHBNC ||
            key == l10n.listRoutineImmunization) {
          return key;
        }
        return key;
    }
  }

  String _getCountForEntry(String key, AppLocalizations l10n) {
    // Check against English keys first (for backward compatibility)
    if (key == 'Family Survey List' || key == l10n.listFamilySurvey) {
      return "${_familySurveyItems.length}";
    } else if (key == 'Eligible Couple Due List' ||
        key == l10n.listEligibleCoupleDue) {
      return "${_eligibleCoupleItems.length}";
    } else if (key == 'ANC List' || key == l10n.listANC) {
      return "${_ancItems.length}";
    } else if (key == 'HBNC List' || key == l10n.listHBNC) {
      return "${_hbncItems.length}";
    } else if (key == 'Routine Immunization (RI)' ||
        key == l10n.listRoutineImmunization) {
      return "${_riItems.length}";
    } else {
      return "${widget.apiData[key]?.length ?? 0}";
    }
  }

  String _getCompletedCountForEntry(String key, AppLocalizations l10n) {
    if (key == 'Family Survey List' || key == l10n.listFamilySurvey) {
      return "${_getFamilySurveyItemsForCompletedTab().length}";
    } else if (key == 'Eligible Couple Due List' ||
        key == l10n.listEligibleCoupleDue) {
      return "${_eligibleCompletedCoupleItems.length}";
    } else if (key == 'ANC List' || key == l10n.listANC) {
      return "${_ancCompletedItems.length}";
    } else if (key == 'HBNC List' || key == l10n.listHBNC) {
      return "${_hbncCompletedItems.length}";
    } else if (key == 'Routine Immunization (RI)' ||
        key == l10n.listRoutineImmunization) {
      return "${_riCompletedItems.length}";
    } else {
      return "${widget.apiData[key]?.length ?? 0}";
    }
  }

  bool _isAncList(String key, AppLocalizations l10n) {
    return key == 'ANC List' || key == l10n.listANC;
  }

  bool _isFamilySurveyList(String key, AppLocalizations l10n) {
    return key == 'Family Survey List' || key == l10n.listFamilySurvey;
  }

  bool _isEligibleCoupleList(String key, AppLocalizations l10n) {
    return key == 'Eligible Couple Due List' ||
        key == l10n.listEligibleCoupleDue;
  }

  bool _isHbncList(String key, AppLocalizations l10n) {
    return key == 'HBNC List' || key == l10n.listHBNC;
  }

  bool _isRoutineImmunizationList(String key, AppLocalizations l10n) {
    return key == 'Routine Immunization (RI)' ||
        key == l10n.listRoutineImmunization;
  }

  Future<String?> _getLastANCVisitDateForItem(Map<String, dynamic> item) async {
    try {
      final beneficiaryId =
          item['BeneficiaryID']?.toString() ??
              item['unique_key']?.toString() ??
              item['id']?.toString() ??
              '';

      if (beneficiaryId.isEmpty) {
        print(
          '⚠️ Empty beneficiary ID provided to _getLastANCVisitDateForItem',
        );
        return null;
      }

      print('🔍 Fetching last ANC visit date for beneficiary: $beneficiaryId');
      final result = await LocalStorageDao.instance.getLastANCVisitDate(
        beneficiaryId,
      );
      print('✅ Last visit date for $beneficiaryId: $result');
      return result;
    } catch (e) {
      print('❌ Error in _getLastANCVisitDateForItem: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final familyCount = _familySurveyItems.length;
    final eligibleCoupleCount = _eligibleCoupleItems.length;
    final ancCount = _ancItems.length;
    final hbncCount = _hbncItems.length;
    final riCount = _riItems.length;
    final totalToDoCount =
        familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 4,
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      todayVisitClick = true;
                      _expandedKey = null;
                    });
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Card(
                    elevation: 3,
                    color: todayVisitClick
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
                                  color: todayVisitClick
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
                              color: todayVisitClick
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
                  onTap: () {
                    setState(() {
                      todayVisitClick = false;
                      _expandedKey = null;
                    });
                  },

                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Card(
                    elevation: 3,
                    color: (!todayVisitClick)
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
                                "$_totalCount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _totalCount > 0 ? Colors.green : Colors.green,
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
                              color: (!todayVisitClick)
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
        if (todayVisitClick)
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
                          _getTranslatedTitle(entry.key, l10n),
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
                              _getCountForEntry(entry.key, l10n),
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
                        children: _isAncList(entry.key, l10n)
                            ? (_ancItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _getAncListItems())
                            : _isFamilySurveyList(entry.key, l10n)
                            ? (_familySurveyItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _familySurveyItems
                            .map(
                              (item) => _routineCard(item, context),
                        )
                            .toList())
                            : _isEligibleCoupleList(entry.key, l10n)
                            ? (_eligibleCoupleItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _eligibleCoupleItems
                            .map(
                              (item) => _routineCard(item, context),
                        )
                            .toList())
                            : _isHbncList(entry.key, l10n)
                            ? (_hbncItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _hbncItems
                            .map(
                              (item) => _routineCard(item, context),
                        )
                            .toList())
                            : _isRoutineImmunizationList(entry.key, l10n)
                            ? _riItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _riItems
                            .map(
                              (item) => _routineCard(item, context),
                        )
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

        // ExpansionTile list Competed
        if (!todayVisitClick)
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
                          _getTranslatedTitle(entry.key, l10n),
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
                              _getCompletedCountForEntry(entry.key, l10n),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getCompletedCountForEntry(entry.key, l10n) != "0" ? Colors.green : Colors.black,
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
                        children: _isAncList(entry.key, l10n)
                            ? (_ancCompletedItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _getAncListCompletedItems())
                            : _isFamilySurveyList(entry.key, l10n)
                            ? (_getFamilySurveyItemsForCompletedTab().isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _getFamilySurveyItemsForCompletedTab()
                            .map(
                              (item) => _routineCard(item, context),
                        )
                            .toList())
                            : _isEligibleCoupleList(entry.key, l10n)
                            ? (_eligibleCompletedCoupleItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _getECListCompletedItems())
                            : _isHbncList(entry.key, l10n)
                            ? (_hbncCompletedItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _getHBNCListCompletedItems())
                            : _isRoutineImmunizationList(entry.key, l10n)
                            ? _riCompletedItems.isEmpty
                            ? [
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  l10n?.noDataFound ??
                                      'No data found',
                                ),
                              ),
                            ),
                          ),
                        ]
                            : _getRIListCompletedItems()
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

      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      String whereClause =
          'forms_ref_key = ? AND beneficiary_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0) AND created_date_time LIKE ?';
      List<dynamic> whereArgs = [hbncFormKey, beneficiaryRefKey, '$todayStr%'];

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
}
