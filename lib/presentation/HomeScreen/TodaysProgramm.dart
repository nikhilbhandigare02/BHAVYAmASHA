import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import 'package:sizer/sizer.dart';
import 'package:sqflite/sqflite.dart' show Database;
import 'package:url_launcher/url_launcher.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/Database/database_provider.dart';
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
    ranges['pmsma_end'] = ranges['2nd_anc_start']!.subtract(const Duration(days: 1));

    return ranges;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
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
      final eligibleCoupleCount = _eligibleCoupleItems.length;
      final ancCount = _ancItems.length;
      final hbncCount = _hbncItems.length;
      final riCount = _riItems.length;

      // Calculate total to-do count (excluding completed visits)
      final totalToDoCount =
          familyCount + eligibleCoupleCount + ancCount + hbncCount + riCount;

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
        final debugQuery = 'SELECT * FROM ${FollowupFormDataTable.table} WHERE DATE(created_date_time) = DATE(?) AND (is_deleted IS NULL OR is_deleted = 0)';
        final debugRows = await db.rawQuery(debugQuery, [todayStr]);
        print('=== DEBUG: All followup_form_data records for today ===');
        print('Total records found: ${debugRows.length}');
        for (final row in debugRows) {
          print('ID: ${row['id']}, forms_ref_key: ${row['forms_ref_key']}, beneficiary_ref_key: ${row['beneficiary_ref_key']}, created_date_time: ${row['created_date_time']}, current_user_key: ${row['current_user_key']}');
        }
        print('================================================');

        // Debug: Check what form keys we're looking for
        print('=== DEBUG: Form Keys We Are Looking For ===');
        final ancFormKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';
        final ecFormKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue] ?? '';
        final hbncFormKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother] ?? '';
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

          List<dynamic> args = [
            ancFormKey,
            todayStr,
            ashaUniqueKey ?? '',
          ];

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
              'Current ANC last due date': 'currentAncLastDueDateText',
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

              final Map<String, dynamic> ecForm = formJson['eligible_couple_tracking_due_from'] ?? {};

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
                'Current ANC last due date': 'currentAncLastDueDateText',
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
              'AND DATE(created_date_time) = DATE(?)';
          List<dynamic> argsHBNC = [...formKeysHBNC, todayStr];

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
            print('HBNC Row: ID=${row['id']}, forms_ref_key=${row['forms_ref_key']}, beneficiary=${row['beneficiary_ref_key']}');
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
              'AND DATE(f.created_date_time) = DATE(?) '
              'AND (b.is_death IS NULL OR b.is_death = 0)';

          List<dynamic> argsRI = ['30bycxe4gv7fqnt6', todayStr];

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
            print('RI Row: ID=${row['id']}, forms_ref_key=${row['forms_ref_key']}, beneficiary=${row['beneficiary_ref_key']}');
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

            final fields = beneficiaryId.isNotEmpty
                ? await _getBeneficiaryFields(beneficiaryId)
                : {
              'name':
              riForm['mother_name']?.toString() ??
                  riForm['woman_name']?.toString() ??
                  '',
              'age':
              riForm['mother_age']?.toString() ??
                  riForm['age']?.toString() ??
                  '',
              'gender': 'Female',
              'mobile': riForm['mobile']?.toString() ?? '-',
            };

            _riCompletedItems.add({
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
              'Current ANC last due date': 'currentAncLastDueDateText',
              'mobile': fields['mobile'],
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
          _saveTodayWorkCountsToStorage();
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
          _saveTodayWorkCountsToStorage();
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
        _saveTodayWorkCountsToStorage();
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

          // Determine if any ANC visit (1st–4th) is currently due
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

          // If no ANC visit is currently due (or all have forms in their windows), skip this beneficiary
          if (!hasDueVisit || dueVisitStartDate == null || dueVisitEndDate == null) {
            continue;
          }

          // For display, use the start and end date of currently due visit window in "TO" format
          DateTime displayEndDate = dueVisitEndDate;

          // Special handling for 4th ANC - show 15 days window from start date
          if (currentAncVisitName == '4th ANC') {
            displayEndDate = dueVisitStartDate!.add(const Duration(days: 15));
          }

          final currentAncLastDueDateText = '${_formatDate(dueVisitStartDate!)} TO ${_formatDate(displayEndDate)}';

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

      // Removed duplicate ANC due items query as we're now handling this in the main query above

      if (mounted) {
        setState(() {
          _ancItems = items; // Use the already filtered items list
        });
        _saveTodayWorkCountsToStorage();
        debugPrint('Updated _ancItems with ${items.length} filtered records');
      }
    } catch (_) {}
  }

  String _formatDateForDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      String s = dateStr;
      if (s.contains('T')) {
        s = s.split('T')[0];
      }
      final date = DateTime.tryParse(s);
      if (date != null) {
        return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      }
    } catch (_) {}
    return '-';
  }

  Future<void> _loadHbncItems() async {
    try {
      setState(() => _isLoading = true);
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
      setState(() => _isLoading = false);
    }
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
        final start = DateTime(
          windowStart.year,
          windowStart.month,
          windowStart.day,
        );
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
        _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
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
        _saveTodayWorkCountsToStorage();
      }
    } catch (_) {}
  }

  Future<String?> _getHbncDeliveryDateForBeneficiary(
      String beneficiaryId,
      ) async {
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
    final totalCount = ancCount + hbncCount + ecCount + riCount;

    print('=== Completed Items Count ===');
    print('ANC Completed Items: $ancCount');
    print('HBNC Completed Items: $hbncCount');
    print('Eligible Couple Completed Items: $ecCount');
    print('RI Completed Items: $riCount');
    print('Total Completed Items: $totalCount');
    print('_completedVisitsCount (State): $_completedVisitsCount');
    print('_toDoVisitsCount (from Storage): $_toDoVisitsCount');
    print('============================');
  }

  int get _totalCount =>
      _ancCompletedItems.length +
          _hbncCompletedItems.length +
          _eligibleCompletedCoupleItems.length +
          _riCompletedItems.length;

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
          if (hhKey.isEmpty) return;

          Map<String, String> initial = {};
          try {
            final households = await LocalStorageDao.instance
                .getAllHouseholds();
            String? headId;
            for (final hh in households) {
              final key = (hh['unique_key'] ?? '').toString();
              if (key == hhKey) {
                headId = (hh['head_id'] ?? '').toString();
                break;
              }
            }

            final members = await LocalStorageDao.instance
                .getBeneficiariesByHousehold(hhKey);

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

              final map = <String, String>{};
              info.forEach((key, value) {
                if (value != null) {
                  map[key] = value.toString();
                }
              });

              map['hh_unique_key'] = hhKey;
              map['head_unique_key'] = headRow['unique_key']?.toString() ?? '';
              if (headRow['id'] != null) {
                map['head_id_pk'] = headRow['id'].toString();
              }

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
                  if (rel == 'spouse' || rel == 'wife' || rel == 'husband') {
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
                  map['spouse_unique_key'] =
                      spouseRow['unique_key']?.toString() ?? '';
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

              map['headName'] ??= item['name']?.toString() ?? '';
              map['mobileNo'] ??= item['mobile']?.toString() ?? '';
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

          if (result == true && mounted) {
            setState(() {
              _completedVisitsCount++;
              _eligibleCoupleItems.removeWhere(
                    (element) =>
                element['id'] == item['id'] &&
                    element['BeneficiaryID'] == item['BeneficiaryID'],
              );
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

          if (result == true && mounted) {
            setState(() {
              _completedVisitsCount++;
              _ancItems.removeWhere(
                    (element) =>
                element['unique_key'] == item['unique_key'] &&
                    element['BeneficiaryID'] == item['BeneficiaryID'],
              );

              // Add the completed item to the completed list immediately
              final completedItem = Map<String, dynamic>.from(item);
              completedItem['last Visit date'] = _formatDateOnly(DateTime.now().toIso8601String());
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
              completedItem['last Visit date'] = _formatDateOnly(DateTime.now().toIso8601String());
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
              completedItem['last Visit date'] = _formatDateOnly(DateTime.now().toIso8601String());
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

                        // spouse_name display removed as requested
                        if (item['next hbnc visit due date'] != null) ...[
                          Text(
                            '${ "Next HBNC due date"}: ${item['next hbnc visit due date']}',
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
                              if (lastVisitDate != null && lastVisitDate.isNotEmpty) {
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
                        ] else if (item['last Visit date'] != null) ...[
                          Text(
                            '${ "Last visit date"}: ${item['last Visit date']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                        if (item['Current ANC last due date'] != null) ...[
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
      return "${_familySurveyItems.length}";
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
      final beneficiaryId = item['BeneficiaryID']?.toString() ??
                           item['unique_key']?.toString() ??
                           item['id']?.toString() ?? '';
      
      if (beneficiaryId.isEmpty) {
        print('⚠️ Empty beneficiary ID provided to _getLastANCVisitDateForItem');
        return null;
      }

      print('🔍 Fetching last ANC visit date for beneficiary: $beneficiaryId');
      final result = await LocalStorageDao.instance.getLastANCVisitDate(beneficiaryId);
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
                                  color: (!todayVisitClick)
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
}