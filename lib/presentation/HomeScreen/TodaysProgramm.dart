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

  String _formatDateOnly(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return '-';
    }
  }

  Future<Map<String, String>> _getBeneficiaryFields(String uniqueKey) async {
    final rec = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(uniqueKey);
    if (rec == null) {
      return {
        'name': '',
        'age': '',
        'gender': '',
        'mobile': '-',
      };

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

    final name = (m['name']?.toString()?.trim().isNotEmpty == true
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
    final mobile = (m['mobileNo'] ?? m['mobile'] ?? m['phone'])?.toString() ?? '-';

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
      await SecureStorageService.saveTodayWorkCounts(
        toDo: toDoCount,
        completed: completedCount,
      );

      if (mounted) {
        // Update the UI with the latest counts
        setState(() {
          // Ensure the UI reflects the same values we saved
          _completedVisitsCount = completedCount;
        });
      }
    } catch (e) {
      // Log error if needed
      debugPrint('Error saving today\'s work counts: $e');
    }
  }

  Future<void> _loadCompletedVisitsCount() async {
    try {
      // First try to load from SecureStorage
      final counts = await SecureStorageService.getTodayWorkCounts();
      if (mounted) {
        setState(() {
          _completedVisitsCount = counts['completed'] ?? 0;
        });
      }

      _eligibleCompletedCoupleItems = [];
      _ancCompletedItems = [];
      _hbncCompletedItems = [];
      _riCompletedItems = [];

      // Get current user key

      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

////////////// Completed ANC Data///////////////////////////
       try {
        final db = await DatabaseProvider.instance.database;


        final ancFormKey =
            FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                .ancDueRegistration] ??
                '';

        final formKeys = <String>[];
        //if (ecFormKey.isNotEmpty) formKeys.add(ecFormKey);
        if (ancFormKey.isNotEmpty) formKeys.add(ancFormKey);

        if (formKeys.isEmpty) return;

        final placeholders = List.filled(formKeys.length, '?').join(',');
        final now = DateTime.now();
        final todayStr =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';


        try {
          String query = 'SELECT * FROM ${FollowupFormDataTable.table} '
              'WHERE forms_ref_key IN ($placeholders) '
              'AND (is_deleted IS NULL OR is_deleted = 0) '
              'AND DATE(created_date_time) = DATE(?) '
              'AND current_user_key = ?';  // Added here

          List<dynamic> args = [...formKeys, todayStr, ashaUniqueKey ?? ''];

          final rows = await db.rawQuery(query, args);

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
              'gender': fields['gender']?.isNotEmpty == true ? fields['gender'] : 'Female',
              'last Visit date': _formatDateOnly(row['created_date_time']?.toString()),
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
          final ecFormKey = FollowupFormDataTable.formUniqueKeys[
          FollowupFormDataTable.eligibleCoupleTrackingDue
          ] ?? '';

          final formKeysEC = <String>[];
          if (ecFormKey.isNotEmpty) formKeysEC.add(ecFormKey);

          if (formKeysEC.isEmpty) return;

          final placeholdersEC = List.filled(formKeysEC.length, '?').join(',');

          String queryEC = 'SELECT * FROM ${FollowupFormDataTable.table} '
              'WHERE forms_ref_key IN ($placeholdersEC) '
              'AND (is_deleted IS NULL OR is_deleted = 0) '
              'AND DATE(created_date_time) = DATE(?) '
              'AND current_user_key = ?';  // Added here

          List<dynamic> argsEC = [...formKeysEC, todayStr, ashaUniqueKey ?? ''];

          final rowsEC = await db.rawQuery(queryEC, argsEC);

          _eligibleCompletedCoupleItems = [];

          for (final row in rowsEC) {
            final beneficiaryId = row['beneficiary_ref_key']?.toString() ?? '';

            // Decode form_json
            final Map<String, dynamic> formJson = row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};

            final Map<String, dynamic> ecForm = formJson['ec_form'] ?? {};

            final fields = beneficiaryId.isNotEmpty
                ? await _getBeneficiaryFields(beneficiaryId)
                : {
              'name': ecForm['woman_name']?.toString() ?? '',
              'age': ecForm['age']?.toString() ?? '',
              'gender': 'Female',
              'mobile': ecForm['mobile']?.toString() ?? '-',
            };

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
              'last Visit date': _formatDateOnly(row['created_date_time']?.toString()),
              'Current ANC last due date': 'currentAncLastDueDateText',
              'mobile': fields['mobile'],
              'badge': 'EligibleCouple',
              '_rawRow': row,
            });
          }
        } catch (e) {
          print('Error in eligible couple query: $e');
        }

        try {
          final hbncFormKey =
              FollowupFormDataTable.formUniqueKeys[
              FollowupFormDataTable.pncMother] ?? '';

          final formKeysHBNC = <String>[];
          if (hbncFormKey.isNotEmpty) formKeysHBNC.add(hbncFormKey);

          if (formKeysHBNC.isEmpty) return;

          final placeholdersHBNC =
          List.filled(formKeysHBNC.length, '?').join(',');

          String queryHBNC = 'SELECT * FROM ${FollowupFormDataTable.table} '
              'WHERE forms_ref_key IN ($placeholdersHBNC) '
              'AND (is_deleted IS NULL OR is_deleted = 0) '
              'AND DATE(created_date_time) = DATE(?)';
          List<dynamic> argsHBNC = [...formKeysHBNC, todayStr];

          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            queryHBNC += ' AND current_user_key = ?';
            argsHBNC.add(ashaUniqueKey);
          }

          final rowsHBNC = await db.rawQuery(queryHBNC, argsHBNC);

          _hbncCompletedItems = [];

          for (final row in rowsHBNC) {
            final beneficiaryId =
                row['beneficiary_ref_key']?.toString() ?? '';

            // 🔹 Decode form_json
            final Map<String, dynamic> formJson =
            row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};


            final Map<String, dynamic> hbncForm =
                formJson['pnc_mother_form'] ?? {};

            final fields = beneficiaryId.isNotEmpty
                ? await _getBeneficiaryFields(beneficiaryId)
                : {
              'name': hbncForm['woman_name']?.toString() ?? '',
              'age': hbncForm['age']?.toString() ?? '',
              'gender': 'Female',
              'mobile': hbncForm['mobile']?.toString() ?? '-',
            };

            _hbncCompletedItems.add({
              'id': row['id'] ?? '',
              'household_ref_key':
              row['household_ref_key']?.toString() ?? '',
              'hhId':
              row['household_ref_key']?.toString() ?? '',
              'unique_key':
              row['beneficiary_ref_key']?.toString() ?? '',
              'BeneficiaryID':
              row['beneficiary_ref_key']?.toString() ?? '',

              'name': fields['name'],
              'age': fields['age'],
              'gender': fields['gender']?.isNotEmpty == true
                  ? fields['gender']
                  : 'Female',
              'last Visit date':
              _formatDateOnly(row['created_date_time']?.toString()),
              'Current ANC last due date':
              'currentAncLastDueDateText',
              'mobile': fields['mobile'],
              'badge': 'HBNC',

              '_rawRow': row,
            });
          }
        } catch (e) {
          debugPrint('HBNC error: $e');
        }


        try {
          String queryRI = 'SELECT * FROM ${FollowupFormDataTable.table} '
              'WHERE (form_json LIKE ? OR forms_ref_key = ?) '
              'AND DATE(created_date_time) = DATE(?)';
          List<dynamic> argsRI = [
              '%child_registration_due%',
              '30bycxe4gv7fqnt6',
              todayStr
            ];
          
          if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
            queryRI += ' AND current_user_key = ?';
            argsRI.add(ashaUniqueKey);
          }
          
          queryRI += ' ORDER BY id DESC';

          final resulrowsRI = await db.rawQuery(queryRI, argsRI);

          _riCompletedItems = [];

          for (final row in resulrowsRI) {
            final beneficiaryId =
                row['beneficiary_ref_key']?.toString() ?? '';

            final Map<String, dynamic> formJson =
            row['form_json'] != null
                ? jsonDecode(row['form_json'] as String)
                : {};

            final Map<String, dynamic> riForm =
                formJson['child_registration_form'] ??
                    formJson['ri_form'] ??
                    {};

            final fields = beneficiaryId.isNotEmpty
                ? await _getBeneficiaryFields(beneficiaryId)
                : {
              'name': riForm['mother_name']?.toString() ??
                  riForm['woman_name']?.toString() ??
                  '',
              'age': riForm['mother_age']?.toString() ??
                  riForm['age']?.toString() ??
                  '',
              'gender': 'Female',
              'mobile': riForm['mobile']?.toString() ?? '-',
            };

            _riCompletedItems.add({
              'id': row['id'] ?? '',
              'household_ref_key':
              row['household_ref_key']?.toString() ?? '',
              'hhId':
              row['household_ref_key']?.toString() ?? '',
              'unique_key':
              row['beneficiary_ref_key']?.toString() ?? '',
              'BeneficiaryID':
              row['beneficiary_ref_key']?.toString() ?? '',

              'name': fields['name'],
              'age': fields['age'],
              'gender': fields['gender']?.isNotEmpty == true
                  ? fields['gender']
                  : 'Female',
              'last Visit date':
              _formatDateOnly(row['created_date_time']?.toString()),
              'Current ANC last due date':
              'currentAncLastDueDateText',
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




        final count = (_ancCompletedItems.length ?? 0) +(_eligibleCompletedCoupleItems.length??0)+(_hbncCompletedItems.length??0)+(_riCompletedItems.length??0);
        if (mounted && count > _completedVisitsCount) {
          setState(() {
            _completedVisitsCount = count;
          });
          await _saveTodayWorkCountsToStorage();
        }


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
          FollowupFormDataTable.formUniqueKeys[
          FollowupFormDataTable.eligibleCoupleTrackingDue] ??
              '';

      if (ecFormKey.isEmpty) return;

      // 1. Get beneficiaries with 'tracking_due' status from eligible_couple_activities
      String whereClause = 'eligible_couple_state = ? AND (is_deleted IS NULL OR is_deleted = 0)';
      List<dynamic> whereArgs = ['tracking_due'];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final trackingDueRows = await db.query(
        'eligible_couple_activities',
        columns: ['beneficiary_ref_key'],
        where: whereClause,
        whereArgs: whereArgs,
      );

      final trackingDueBeneficiaryKeys = trackingDueRows
          .map((row) => row['beneficiary_ref_key']?.toString())
          .whereType<String>()
          .toSet();

      if (trackingDueBeneficiaryKeys.isEmpty) {
        _eligibleCoupleItems.clear();
        if (mounted) {
          setState(() {});
          _saveTodayWorkCountsToStorage();
        }
        return;
      }

      // 2. Filter out those who have been updated in the last 1 month
      // We check for existing forms that are RECENT (>= 1 month ago)
      // If a form exists within the last month, we exclude the beneficiary.
      final placeholders = List.filled(trackingDueBeneficiaryKeys.length, '?').join(',');
      
      final recentForms = await db.rawQuery(
        '''
        SELECT DISTINCT beneficiary_ref_key
        FROM ${FollowupFormDataTable.table}
        WHERE forms_ref_key = ?
        AND beneficiary_ref_key IN ($placeholders)
        AND (is_deleted IS NULL OR is_deleted = 0)
        AND (
          DATE(created_date_time) >= DATE('now', '-1 month')
          OR (modified_date_time IS NOT NULL AND DATE(modified_date_time) >= DATE('now', '-1 month'))
        )
        ''',
        [ecFormKey, ...trackingDueBeneficiaryKeys],
      );

      final recentlyTrackedKeys = recentForms
          .map((row) => row['beneficiary_ref_key']?.toString())
          .whereType<String>()
          .toSet();

      final keysToShow = trackingDueBeneficiaryKeys.difference(recentlyTrackedKeys);

      if (keysToShow.isEmpty) {
        _eligibleCoupleItems.clear();
        if (mounted) {
          setState(() {});
          _saveTodayWorkCountsToStorage();
        }
        return;
      }

      // 3. Load beneficiary details for keysToShow
      final placeholdersShow = List.filled(keysToShow.length, '?').join(',');
      final rows = await db.query(
        'beneficiaries_new',
        where: 'unique_key IN ($placeholdersShow) AND (is_deleted IS NULL OR is_deleted = 0) AND (is_migrated IS NULL OR is_migrated = 0)',
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
            
            final relation = (info['relation_to_head'] ?? info['relation'] ?? '').toString().toLowerCase();
            if (relation.contains('head') || relation == 'self') {
              head = info;
            } else if (relation == 'spouse' || relation == 'wife' || relation == 'husband') {
              spouse = info;
            }
          } catch (_) {}
        }

        // Process members to add to list
        for (final member in household) {
            final dynamic infoRaw = member['beneficiary_info'];
            if (infoRaw == null) continue;
             
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});

            final uniqueKey = member['unique_key']?.toString() ?? '';
            // Only show if this member is in our target list
            if (!keysToShow.contains(uniqueKey)) continue;

            final isHead = info == head;
            final isSpouse = info == spouse;
            final Map<String, dynamic> counterpart = isHead && spouse != null 
                ? spouse! 
                : isSpouse && head != null 
                    ? head! 
                    : <String, dynamic>{};

            final name = info['memberName']?.toString() ?? info['headName']?.toString() ?? info['name']?.toString() ?? '';
            final dob = info['dob']?.toString() ?? '';
            
            // Use _calculateAge if available, or parse manually
            int age = 0;
            try {
               if (dob.isNotEmpty) {
                 final birthDate = DateTime.tryParse(dob.contains('T') ? dob.split('T')[0] : dob);
                 if (birthDate != null) {
                   final now = DateTime.now();
                   age = now.year - birthDate.year;
                   if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
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
              'household_ref_key': member['household_ref_key']?.toString() ?? '',
              'hhId': member['household_ref_key']?.toString() ?? '',
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
                  ? (counterpart['memberName'] ?? counterpart['headName'] ?? counterpart['name']) 
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

      String whereClause = 'forms_ref_key = ? AND is_deleted = 0';
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
          String benWhere = 'unique_key = ? AND (is_deleted = 0 OR is_deleted IS NULL)';
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

  Future<void> _loadRoutineImmunizationItems() async {
    try {
      final db = await DatabaseProvider.instance.database;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      String whereClause = '(form_json LIKE ? OR forms_ref_key = ?)';
      List<dynamic> whereArgs = ['%child_registration_due%', '30bycxe4gv7fqnt6'];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final results = await db.query(
        FollowupFormDataTable.table,
        where: whereClause,
        whereArgs: whereArgs,
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
            String ccWhere = 'beneficiary_ref_key = ? AND form_json LIKE ? AND is_deleted = 0';
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
  Widget _routineCard(Map<String, dynamic> item, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final badge = item['badge']?.toString() ?? '';

    return InkWell(
      onTap: () async {
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
              builder: (context) =>
                  AddNewFamilyHeadScreen(isEdit: true, initial: initial),
            ),
          );
        } else if (badge == 'EligibleCouple') {
          // Align with UpdatedEligibleCoupleListScreen: pass short ID + full ref key
          final displayId = item['id']?.toString() ?? '';
          final beneficiaryRefKey = item['BeneficiaryID']?.toString() ?? item['unique_key']?.toString() ?? '';
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
              // Remove the item from the eligible couple items list
              _eligibleCoupleItems.removeWhere(
                (element) =>
                    element['id'] == item['id'] &&
                    element['BeneficiaryID'] == item['BeneficiaryID'],
              );
            });
            _saveTodayWorkCountsToStorage();
          }
        } else if (badge == 'ANC') {
          // Navigate to ANC Visit Form with full beneficiary data
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
            });
            _saveTodayWorkCountsToStorage();
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
            });
            _saveTodayWorkCountsToStorage();
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
              // Remove the item from the RI items list
              _riItems.removeWhere(
                (element) =>
                    element['id'] == item['id'] &&
                    element['BeneficiaryID'] == item['BeneficiaryID'],
              );
            });
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
                          '${item['name'] ?? (l10n?.na ??'N/A')}',
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

                        if (item['spouse_name'] != null && item['spouse_name'].toString().isNotEmpty) ...[
                          Text(
                            '${l10n?.spouse ?? "Spouse"}: ${item['spouse_name']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],

                        if (item['last Visit date'] != null) ...[
                          Text(
                            '${l10n?.lastVisit ?? "Last Visit"}: ${item['last Visit date']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                        if (item['mobile'] != null) ...[
                          Text(
                            '${l10n?.mobile ?? "Mobile"}: ${item['mobile']}',
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

  // Helper method to get translated title for expansion tiles
  String _getTranslatedTitle(String key, AppLocalizations l10n) {
    // Map English keys to translation keys
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
        return key; // Fallback to original key
    }
  }

  // Helper method to get count for To Do visits
  String _getCountForEntry(String key, AppLocalizations l10n) {
    // Check against English keys first (for backward compatibility)
    if (key == 'Family Survey List' || key == l10n.listFamilySurvey) {
      return "${_familySurveyItems.length}";
    } else if (key == 'Eligible Couple Due List' || key == l10n.listEligibleCoupleDue) {
      return "${_eligibleCoupleItems.length}";
    } else if (key == 'ANC List' || key == l10n.listANC) {
      return "${_ancItems.length}";
    } else if (key == 'HBNC List' || key == l10n.listHBNC) {
      return "${_hbncItems.length}";
    } else if (key == 'Routine Immunization (RI)' || key == l10n.listRoutineImmunization) {
      return "${_riItems.length}";
    } else {
      return "${widget.apiData[key]?.length ?? 0}";
    }
  }

  // Helper method to get count for Completed visits
  String _getCompletedCountForEntry(String key, AppLocalizations l10n) {
    // Check against English keys first (for backward compatibility)
    if (key == 'Family Survey List' || key == l10n.listFamilySurvey) {
      return "${_familySurveyItems.length}";
    } else if (key == 'Eligible Couple Due List' || key == l10n.listEligibleCoupleDue) {
      return "${_eligibleCompletedCoupleItems.length}";
    } else if (key == 'ANC List' || key == l10n.listANC) {
      return "${_ancCompletedItems.length}";
    } else if (key == 'HBNC List' || key == l10n.listHBNC) {
      return "${_hbncCompletedItems.length}";
    } else if (key == 'Routine Immunization (RI)' || key == l10n.listRoutineImmunization) {
      return "${_riCompletedItems.length}";
    } else {
      return "${widget.apiData[key]?.length ?? 0}";
    }
  }

  // Helper method to check entry type for children logic
  bool _isAncList(String key, AppLocalizations l10n) {
    return key == 'ANC List' || key == l10n.listANC;
  }

  bool _isFamilySurveyList(String key, AppLocalizations l10n) {
    return key == 'Family Survey List' || key == l10n.listFamilySurvey;
  }

  bool _isEligibleCoupleList(String key, AppLocalizations l10n) {
    return key == 'Eligible Couple Due List' || key == l10n.listEligibleCoupleDue;
  }

  bool _isHbncList(String key, AppLocalizations l10n) {
    return key == 'HBNC List' || key == l10n.listHBNC;
  }

  bool _isRoutineImmunizationList(String key, AppLocalizations l10n) {
    return key == 'Routine Immunization (RI)' || key == l10n.listRoutineImmunization;
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
        // Grid Boxes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 4,
            children: [
              Expanded(
                flex: 1,
                child:  InkWell(
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
                                "$_completedVisitsCount",
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
        if(todayVisitClick)
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
                                l10n?.noDataFound ?? 'No data found',
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
                                l10n?.noDataFound ?? 'No data found',
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
                                l10n?.noDataFound ?? 'No data found',
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
                                l10n?.noDataFound ?? 'No data found',
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
                                l10n?.noDataFound ?? 'No data found',
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
        if(!todayVisitClick)
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
                                l10n?.noDataFound ?? 'No data found',
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
                                l10n?.noDataFound ?? 'No data found',
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
                                l10n?.noDataFound ?? 'No data found',
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
                                l10n?.noDataFound ?? 'No data found',
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
                                l10n?.noDataFound ?? 'No data found',
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
}
