import 'dart:convert';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';
import 'package:medixcel_new/core/widgets/AppHeader/AppHeader.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

class Routinescreen extends StatefulWidget {
  const Routinescreen({super.key});

  @override
  State<Routinescreen> createState() => _RoutinescreenState();
}

class _RoutinescreenState extends State<Routinescreen> {
  final Map<String, bool> _expanded = {};
  bool _isLoading = true;

  List<Map<String, dynamic>> _pwList = [];
  final List<Map<String, dynamic>> _child0to1 = [];
  final List<Map<String, dynamic>> _child1to2 = [];
  final List<Map<String, dynamic>> _child2to5 = [];
  final List<Map<String, dynamic>> _poornTikakaran = [];
  final List<Map<String, dynamic>> _sampoornTikakaran = [];

  @override
  void initState() {
    super.initState();
    _loadPregnantWomen();
    _loadSampoornTikakaran();
    _loadPoornTikakaran();
    _loadChild0to1();
    _loadChild1to2();
    _loadChild2to5();
  }
  Future<List<Map<String, dynamic>>> _filterByCurrentUserKey(List<Map<String, dynamic>> rows) async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();
      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) return rows;
      return rows.where((row) => (row['current_user_key'] ?? '').toString() == ashaUniqueKey).toList();
    } catch (_) {
      return rows;
    }
  }

  bool _isMissingValue(dynamic value) {
    if (value == null) return true;
    if (value is String) {
      final v = value.trim();
      return v.isEmpty || v.toLowerCase() == 'null';
    }
    return false;
  }

  int? _parseIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  Future<Map<String, Map<String, dynamic>>> _getLatestAncDueRegistrationFormDataByBeneficiary(
      Set<String> beneficiaryIds,
      ) async {
    try {
      if (beneficiaryIds.isEmpty) return {};

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();
      if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) return {};

      final formKey = FollowupFormDataTable
          .formUniqueKeys[FollowupFormDataTable.ancDueRegistration];
      if (formKey == null || formKey.isEmpty) return {};

      final db = await DatabaseProvider.instance.database;
      final placeholders = List.filled(beneficiaryIds.length, '?').join(',');
      final args = <Object?>[ashaUniqueKey, formKey, ...beneficiaryIds.toList()];

      final rows = await db.rawQuery(
        '''
          WITH Ranked AS (
            SELECT
              f.beneficiary_ref_key,
              f.form_json,
              ROW_NUMBER() OVER (
                PARTITION BY f.beneficiary_ref_key
                ORDER BY f.created_date_time DESC, f.id DESC
              ) AS rn
            FROM followup_form_data f
            WHERE
              f.is_deleted = 0
              AND f.current_user_key = ?
              AND f.forms_ref_key = ?
              AND f.beneficiary_ref_key IN ($placeholders)
          )
          SELECT beneficiary_ref_key, form_json
          FROM Ranked
          WHERE rn = 1;
          ''',
        args,
      );

      final result = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final id = row['beneficiary_ref_key']?.toString() ?? '';
        if (id.isEmpty) continue;

        final formJsonStr = row['form_json']?.toString();
        if (formJsonStr == null || formJsonStr.isEmpty) continue;

        try {
          final root = Map<String, dynamic>.from(jsonDecode(formJsonStr));

          final formData = root['form_data'];
          final ancForm = root['anc_form'];

          if (formData is Map || ancForm is Map) {
            result[id] = Map<String, dynamic>.from(
              (formData is Map) ? formData : ancForm,
            );
          }
        } catch (_) {
          continue;
        }
      }

      return result;
    } catch (_) {
      return {};
    }
  }
  Future<List<Map<String, dynamic>>> _getAncDueRecords() async {
    final db = await DatabaseProvider.instance.database;

    final currentUserData = await SecureStorageService.getCurrentUserData();
    final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

    if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
      return [];
    }

    final rows = await db.rawQuery(
      '''
      WITH RankedMCA AS (
        SELECT DISTINCT
          mca.*,
          ROW_NUMBER() OVER (
            PARTITION BY mca.beneficiary_ref_key
            ORDER BY mca.created_date_time DESC, mca.id DESC
          ) AS rn
        FROM mother_care_activities mca
        WHERE
          mca.is_deleted = 0
          AND mca.current_user_key = ?
      )
      SELECT DISTINCT r.*
      FROM RankedMCA r
      INNER JOIN beneficiaries_new bn
        ON r.beneficiary_ref_key = bn.unique_key
      WHERE
        r.rn = 1
        AND r.mother_care_state = 'anc_due'
        AND bn.is_deleted = 0
        AND bn.is_migrated = 0
        AND bn.is_death = 0
      ORDER BY r.created_date_time DESC; 
      ''',
      [ashaUniqueKey],
    );

    return rows;
  }


  Future<Map<String, dynamic>> _getVisitCount(String beneficiaryId) async {
    try {
      if (beneficiaryId.isEmpty) {
        return {'count': 0, 'isHighRisk': false};
      }

      final result = await LocalStorageDao.instance.getANCVisitCount(beneficiaryId);
      print('✅ Visit details for $beneficiaryId: $result');
      return result;
    } catch (e) {
      print('❌ Error in _getVisitCount for $beneficiaryId: $e');
      return {'count': 0, 'isHighRisk': false};
    }
  }

  String _getNextAncDueDate(DateTime? lmpDate, int visitCount) {
    if (lmpDate == null) return '${AppLocalizations.of(context)!.nextancduedate}: ${AppLocalizations.of(context)!.na}';

    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final ancRanges = _calculateAncDateRanges(lmpDate);

    String? nextAncKey;
    String? nextAncLabel;

    if (visitCount == 0) {
      // First ANC is due
      nextAncKey = '1st_anc_start';
      nextAncLabel = t!.nextancduedate;
    } else if (visitCount == 1) {
      // Second ANC is due
      nextAncKey = '2nd_anc_start';
      nextAncLabel = t!.nextancduedate;
    } else if (visitCount == 2) {
      // Third ANC is due
      nextAncKey = '3rd_anc_start';
      nextAncLabel = t!.nextancduedate;
    } else if (visitCount == 3) {
      // Fourth ANC is due
      nextAncKey = '4th_anc_start';
      nextAncLabel = t!.nextancduedate;
    } else {
      nextAncKey = '4th_anc_start';
      nextAncLabel = t!.nextancduedate;
    }

    if (nextAncKey != null && ancRanges.containsKey(nextAncKey)) {
      final dueDate = ancRanges[nextAncKey];
      if (dueDate != null) {
        return '$nextAncLabel: ${_formatDate(dueDate)}';
      }
    }

    return '${t!.nextancduedate}: ${t!.na}';
  }

  Future<Map<String, dynamic>> _getSyncStatus(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        'mother_care_activities',
        columns: ['is_synced',  'created_date_time'],
        where: 'beneficiary_ref_key = ? AND is_deleted = 0 ',
        whereArgs: [beneficiaryRefKey],
        orderBy: 'created_date_time DESC',
        limit: 1,
      );

      if (rows.isNotEmpty) {
        return {
          'is_synced': rows.first['is_synced'] == 1,
        };
      }

      return {'is_synced': false};
    } catch (e) {
      print('Error fetching sync status: $e');
      return {'is_synced': false,};
    }
  }

  String _getLast11Chars(String? input) {
    if (input == null || input.isEmpty) return '';
    return input.length <= 11 ? input : input.substring(input.length - 11);
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
          (data['_rawRow'] is Map
              ? (data['_rawRow'] as Map)['unique_key']?.toString()
              : null);

      if (benId == null || benId.isEmpty) {
        print('⚠️ Missing beneficiary ID for followup form LMP lookup');
        print('   benId: $benId');
        print('   data keys: ${data.keys}');
        return null;
      }

      print('🔍 Looking for followup forms with benId: $benId');

      final db = await DatabaseProvider.instance.database;
      final formKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue];
      print('🔍 Querying with formKey: $formKey, benId: $benId');

      final result = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND beneficiary_ref_key = ?',
        whereArgs: [formKey, benId],
        orderBy: 'created_date_time DESC',
      );

      print('📋 Found ${result.length} followup forms for beneficiary: $benId');

      if (result.isEmpty) {
        print('ℹ️ No eligible couple tracking due forms found for beneficiary: $benId');

        // Debug: Let's check what forms exist for this beneficiary
        final allForms = await db.query(
          FollowupFormDataTable.table,
          where: 'beneficiary_ref_key = ?',
          whereArgs: [benId],
          orderBy: 'created_date_time DESC',
        );
        print('🔍 DEBUG: All forms for beneficiary $benId:');
        for (int i = 0; i < allForms.length; i++) {
          final form = allForms[i];
          print('   Form ${i + 1}: forms_ref_key=${form['forms_ref_key']}, household_ref_key=${form['household_ref_key']}');
        }

        return null;
      }

      for (int i = 0; i < result.length; i++) {
        final form = result[i];
        final formJsonStr = form['form_json']?.toString();
        final formHouseholdId = form['household_ref_key']?.toString();
        final formBeneficiaryId = form['beneficiary_ref_key']?.toString();

        print('📄 Processing form ${i + 1}/${result.length}: household=$formHouseholdId, beneficiary=$formBeneficiaryId');

        if (formJsonStr == null || formJsonStr.isEmpty) {
          print('⚠️ Empty form_json in form ${i + 1}, skipping');
          continue;
        }

        try {
          final root = Map<String, dynamic>.from(jsonDecode(formJsonStr));
          print('🔍 Parsing followup form JSON ${i + 1}: ${root.keys}');

          String? lmpStr;

          /// ✅ EXISTING CONDITION
          final trackingData = root['eligible_couple_tracking_due_from'];
          if (trackingData is Map) {
            final val = trackingData['lmp_date']?.toString();
            if (val != null && val.isNotEmpty && val != 'null') {
              lmpStr = val;
              print('✅ Found LMP in eligible_couple_tracking_due_from (form ${i + 1}): "$lmpStr"');
            } else {
              print('⚠️ LMP date in eligible_couple_tracking_due_from is empty or null: "$val"');
            }
          } else {
            print('⚠️ No eligible_couple_tracking_due_from found in form ${i + 1}');
          }

          /// ✅ NEW CONDITION
          if ((lmpStr == null || lmpStr.isEmpty || lmpStr == 'null') &&
              root['form_data'] is Map) {
            final formData = root['form_data'] as Map<String, dynamic>;
            final val = formData['lmp_date']?.toString();
            // Check for null, empty, or just empty string
            if (val != null && val.isNotEmpty && val != '""' && val != 'null') {
              lmpStr = val;
              print('✅ Found LMP in form_data (form ${i + 1}): "$lmpStr"');
            } else {
              print('⚠️ LMP date in form_data is empty or invalid (form ${i + 1}): "$val"');
            }
          }

          if (lmpStr != null && lmpStr.isNotEmpty && lmpStr != 'null') {
            try {
              String dateStr = lmpStr;
              if (dateStr.contains('T')) {
                try {
                  final lmpDate = DateTime.parse(dateStr);
                  print('✅ Successfully parsed LMP date (form ${i + 1}): $lmpDate');
                  return lmpDate;
                } catch (e) {
                  dateStr = dateStr.split('T')[0];
                  print('⚠️ Full date parsing failed, trying date part only (form ${i + 1}): "$dateStr"');
                }
              }

              final lmpDate = DateTime.parse(dateStr);
              print('✅ Successfully parsed LMP date (form ${i + 1}): $lmpDate');
              return lmpDate;
            } catch (e) {
              print('⚠️ Error parsing LMP date "$lmpStr" (form ${i + 1}): $e');
            }
          } else {
            print('⚠️ No valid LMP date found in form data (form ${i + 1})');
          }
        } catch (e) {
          print('⚠️ Error parsing followup form JSON (form ${i + 1}): $e');
        }
      }

      print('ℹ️ No LMP date found in any eligible couple tracking due forms for beneficiary: $benId');
      return null;
    } catch (e) {
      print('❌ Error loading LMP from followup form: $e');
      return null;
    }
  }

  Future<void> _loadPregnantWomen() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];
      final Set<String> processedBeneficiaries = {};

      print('ℹ️ Found ${rows.length} beneficiaries');

      final ancDueRecords = await _getAncDueRecords();
      final ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet();

      // ---------------- PROCESS BENEFICIARIES ----------------
      for (final row in rows) {
        try {
          final rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          final Map<String, dynamic> info = rawInfo is String
              ? jsonDecode(rawInfo)
              : Map<String, dynamic>.from(rawInfo);

          final String beneficiaryId =
              row['unique_key']?.toString() ?? '';
          if (beneficiaryId.isEmpty) continue;

          final bool isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';

          final bool isAncDue =
          ancDueBeneficiaryIds.contains(beneficiaryId);

          final String genderRaw =
              info['gender']?.toString().toLowerCase() ?? '';

          if (!(genderRaw == 'f' || genderRaw == 'female')) continue;
          if (!isPregnant && !isAncDue) continue;

          final String ageGender = _formatAgeGenderFromInfo(info);

          // ---------------- MOBILE ----------------
          final String mobileNo =
              info['mobileNo']?.toString().trim() ??
                  info['mobile_no']?.toString().trim() ??
                  '';

          // ---------------- GET NEXT ANC DUE DATE ----------------
          String nextAncDueDate = 'N/A';
          try {
            final visitData = await _getVisitCount(beneficiaryId);
            final visitCount = visitData['count'] ?? 0;

            DateTime? lmpDate;
            final lmpStr = info['lmp']?.toString();
            if (lmpStr != null && lmpStr.isNotEmpty) {
              lmpDate = DateTime.tryParse(lmpStr.split('T')[0]);
            }

            if (lmpDate == null) {
              lmpDate = await _extractLmpDate(row);
            }

            nextAncDueDate = _getNextAncDueDate(lmpDate, visitCount);
          } catch (e) {
            print('Error calculating next ANC due date: $e');
          }

          pregnantWomen.add({
            'BeneficiaryID': beneficiaryId,
            'unique_key': beneficiaryId,
            'Name': info['name'] ?? info['memberName'] ?? 'Unknown',
            'age_gender': ageGender,
            'mobile': mobileNo,
            'gender': genderRaw,
            'isPregnant': isPregnant,
            'isAncDue': isAncDue,
            'RegistrationDate': row['created_date_time'],
            'nextAncDueDate': nextAncDueDate,
            '_rawRow': row,
            'badge': isAncDue ? 'ANC' : 'PW',
          });

          processedBeneficiaries.add(beneficiaryId);
        } catch (e) {
          debugPrint('⚠️ Error processing pregnant woman: $e');
        }
      }

      // ---------------- ADD ANC DUE ONLY ----------------
      for (final ancDue in ancDueRecords) {
        final String beneficiaryId =
            ancDue['beneficiary_ref_key']?.toString() ?? '';

        if (beneficiaryId.isEmpty ||
            processedBeneficiaries.contains(beneficiaryId)) {
          continue;
        }

        String nextAncDueDate = 'N/A';
        try {
          final visitData = await _getVisitCount(beneficiaryId);
          final visitCount = visitData['count'] ?? 0;

          final lmpDate = await _extractLmpDate(ancDue);
          nextAncDueDate = _getNextAncDueDate(lmpDate, visitCount);
        } catch (e) {
          print('Error calculating next ANC due date for ANC due record: $e');
        }

        pregnantWomen.add({
          'BeneficiaryID': beneficiaryId,
          'unique_key': beneficiaryId,
          'Name': 'ANC Due - ${_getLast11Chars(beneficiaryId)}',
          'age_gender': 'N/A',
          'mobile': '',
          'gender': 'female',
          'isPregnant': false,
          'isAncDue': true,
          'RegistrationDate': ancDue['created_date_time'],
          'nextAncDueDate': nextAncDueDate,
          '_rawRow': ancDue,
          'badge': 'ANC',
        });
      }

      // ---------------- DEDUPLICATE ----------------
      final Map<String, Map<String, dynamic>> byId = {};
      for (final item in pregnantWomen) {
        final id = item['BeneficiaryID'];
        if (id != null) {
          byId[id] = item;
        }
      }

      final list = byId.values.toList()
        ..sort((a, b) {
          final DateTime? d1 =
          _safeParseDateTime(a['RegistrationDate']);
          final DateTime? d2 =
          _safeParseDateTime(b['RegistrationDate']);
          return (d2 ?? DateTime(0))
              .compareTo(d1 ?? DateTime(0));
        });

      final latestFormDataByBeneficiary =
      await _getLatestAncDueRegistrationFormDataByBeneficiary(
        list
            .map((e) => e['BeneficiaryID']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet(),
      );

      // ---------------- FILTER PW LIST ----------------
      final filteredList = list.where((item) {
        final beneficiaryId = item['BeneficiaryID']?.toString() ?? '';
        if (beneficiaryId.isEmpty) return false;

        final formData = latestFormDataByBeneficiary[beneficiaryId];
        if (formData == null) return false;

        final weeks =
            _parseIntValue(formData['weeks_of_pregnancy']) ??
                _parseIntValue(formData['week_of_pregnancy']);

        if (weeks == null || weeks > 12) return false;

        final td1Missing =
            _isMissingValue(formData['td1_date']) &&
                _isMissingValue(formData['date_of_td1']);

        final td2Missing =
            _isMissingValue(formData['td2_date']) &&
                _isMissingValue(formData['date_of_td2']);

        final tdBoosterMissing =
            _isMissingValue(formData['td_booster_date']) &&
                _isMissingValue(formData['date_of_td_booster']);

        final tdNotCompleted =
            td1Missing ||
                td2Missing ||
                (tdBoosterMissing && td1Missing && td2Missing);

        return tdNotCompleted;
      }).toList();

      setState(() {
        _pwList = filteredList;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('❌ Load pregnant women error: $e');
      debugPrint('$st');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  DateTime? _safeParseDateTime(dynamic raw) {
    if (raw == null) return null;

    try {
      final dt = DateTime.tryParse(raw.toString());
      if (dt != null) return dt;
    } catch (_) {}

    try {
      final ts = int.tryParse(raw.toString());
      if (ts != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          ts > 1000000000000 ? ts : ts * 1000,
        );
      }
    } catch (_) {}

    return null;
  }

  String _formatAgeGenderFromInfo(Map<String, dynamic> info) {
    String age = 'N/A';

    final years = int.tryParse(info['years']?.toString() ?? '');
    final months = int.tryParse(info['months']?.toString() ?? '');
    final days = int.tryParse(info['days']?.toString() ?? '');

    if (years != null && years > 0) {
      age = '$years Y';
    } else if (months != null && months > 0) {
      age = '$months M';
    } else if (days != null && days > 0) {
      age = '$days D';
    } else {
      final dob = DateTime.tryParse(info['dob']?.toString() ?? '');
      if (dob != null) {
        final now = DateTime.now();
        int y = now.year - dob.year;
        int m = now.month - dob.month;
        if (now.day < dob.day) m--;
        if (m < 0) {
          m += 12;
          y--;
        }
        age = y > 0 ? '$y Y' : '$m M';
      }
    }

    final genderRaw = info['gender']?.toString().toLowerCase() ?? '';
    final gender = (genderRaw == 'f' || genderRaw == 'female')
        ? 'Female'
        : (genderRaw == 'm' || genderRaw == 'male')
        ? 'Male'
        : 'Other';

    return '$age | $gender';
  }

  Future<void> _loadSampoornTikakaran() async {
    print('Starting to load Sampoorn Tikakaran data...');
    try {
      print('Calling getChildTrackingDueFor16Year()...');
      final rows = await LocalStorageDao.instance.getChildTrackingDueFor16Year();
      final scopedRows = await _filterByCurrentUserKey(rows);
      print('Received ${rows.length} rows from database');
      print('Scoped to current user: ${scopedRows.length}');

      setState(() {
        _sampoornTikakaran.clear();
        for (var row in scopedRows) {
          print('Processing row: ${row['id']}');
          final formData = row['form_json'];

          // Check if formData is a Map and contains 'form_data'
          final formDataContent = formData is Map ?
          (formData['form_data'] ?? formData) :
          formData;

          if (formDataContent != null) {
            print('Form data found: ${formDataContent['child_name'] ?? formDataContent['name']}');

            _sampoornTikakaran.add({
              'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
              'age': formDataContent['age'] ?? 'N/A',
              'gender': formDataContent['gender'] ?? 'N/A',
              'father_name': formDataContent['father_name'] ?? 'N/A',
              'mother_name': formDataContent['mother_name'] ?? 'N/A',
              'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
              'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
              'registration_date': formDataContent['registration_date'] ?? 'N/A',
              'household_id': formDataContent['household_id'] ?? 'N/A',
              'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
              'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
            });
          } else {
            print('Warning: form_data is null for row: $row');
          }
        }
        print('Total items in _sampoornTikakaran: ${_sampoornTikakaran.length}');
      });
    } catch (e) {
      print('Error in _loadSampoornTikakaran: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<void> _loadPoornTikakaran() async {
    print('Starting to load Poorn Tikakaran (9-year) data...');
    try {
      print('Calling getChildTrackingDueFor9Year()...');
      final rows = await LocalStorageDao.instance.getChildTrackingDueFor9Year();
      final scopedRows = await _filterByCurrentUserKey(rows);
      print('Received ${rows.length} rows from database');
      print('Scoped to current user: ${scopedRows.length}');

      setState(() {
        _poornTikakaran.clear();
        for (var row in scopedRows) {
          print('Processing row: ${row['id']}');
          final formData = row['form_json'];

          // Check if formData is a Map and contains 'form_data'
          final formDataContent = formData is Map
              ? (formData['form_data'] ?? formData)
              : formData;

          if (formDataContent != null) {
            print('Form data found: ${formDataContent['child_name'] ?? formDataContent['name']}');

            _poornTikakaran.add({
              'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
              'age': formDataContent['age'] ?? 'N/A',
              'gender': formDataContent['gender'] ?? 'N/A',
              'father_name': formDataContent['father_name'] ?? 'N/A',
              'mother_name': formDataContent['mother_name'] ?? 'N/A',
              'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
              'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
              'registration_date': formDataContent['registration_date'] ?? 'N/A',
              'household_id': formDataContent['household_id'] ?? 'N/A',
              'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
              'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
            });
          } else {
            print('Warning: form_data is null for row: $row');
          }
        }
        print('Total items in _poornTikakaran: ${_poornTikakaran.length}');
      });
    } catch (e) {
      print('Error in _loadPoornTikakaran: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  Future<void> _loadChild0to1() async {
    await _loadChildBeneficiariesByAgeGroup('0-1');
  }

  Future<void> _loadChild1to2() async {
    await _loadChildBeneficiariesByAgeGroup('1-2');
  }

  Future<void> _loadChild2to5() async {
    await _loadChildBeneficiariesByAgeGroup('2-5');
  }

  Future<bool> _hasTrackingDueStatus(String beneficiaryRefKey) async {
    try {
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        'child_care_activities',
        where: 'beneficiary_ref_key = ? AND child_care_state = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey, 'tracking_due'],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (e) {
      print('Error checking tracking_due status for $beneficiaryRefKey: $e');
      return false;
    }
  }

  Future<void> _loadChildBeneficiariesByAgeGroup(String ageGroup) async {
    print('Loading children $ageGroup years data...');
    try {
      final db = await DatabaseProvider.instance.database;

      final deceasedChildren = await db.rawQuery('''
          SELECT DISTINCT beneficiary_ref_key, form_json 
          FROM followup_form_data 
          WHERE form_json LIKE '%"reason_of_death":%'
        ''');

      final deceasedIds = <String>{};
      for (var child in deceasedChildren) {
        try {
          final jsonData = jsonDecode(child['form_json'] as String);
          final formData = jsonData['form_data'] as Map<String, dynamic>?;
          final caseClosure = formData?['case_closure'] as Map<String, dynamic>?;

          if (caseClosure?['is_case_closure'] == true &&
              caseClosure?['reason_of_death']?.toString().toLowerCase() == 'death') {
            final beneficiaryId = child['beneficiary_ref_key']?.toString();
            if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
              deceasedIds.add(beneficiaryId);
            }
          }
        } catch (e) {
          print('⚠️ Error processing deceased record: $e');
        }
      }

      // Get current user data
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUserData?['unique_key']?.toString();

      // Get last visit dates from child_care_activities (most recent entry)
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
        if (beneficiaryKey != null && !latestRecordsByBeneficiary.containsKey(beneficiaryKey)) {
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

      // Get all child beneficiaries
      final List<Map<String, dynamic>> rows = await db.rawQuery('''
          SELECT 
            B.*
          FROM beneficiaries_new B
          WHERE 
            B.is_deleted = 0
            AND B.is_adult = 0
            AND B.is_migrated = 0
            AND B.current_user_key = ?
          ORDER BY B.created_date_time DESC
        ''', [ashaUniqueKey]);

      final allChildBeneficiaries = <Map<String, dynamic>>[];

      for (final row in rows) {
        try {
          final rowHhId = row['household_ref_key']?.toString();
          if (rowHhId == null) continue;

          final info = row['beneficiary_info'] is String
              ? jsonDecode(row['beneficiary_info'] as String)
              : row['beneficiary_info'];

          if (info is! Map) continue;

          final memberType = info['memberType']?.toString().toLowerCase() ?? '';
          final relation = info['relation']?.toString().toLowerCase() ?? '';

          if (memberType == 'child' || relation == 'child' ||
              memberType == 'Child' || relation == 'daughter') {

            final name = info['name']?.toString() ??
                info['memberName']?.toString() ??
                info['member_name']?.toString() ??
                '';

            final fatherName = info['fatherName']?.toString() ??
                info['father_name']?.toString() ?? '';

            final motherName = info['motherName']?.toString() ??
                info['mother_name']?.toString() ?? '';

            final mobileNo = info['mobileNo']?.toString() ??
                info['mobile']?.toString() ??
                info['mobile_number']?.toString() ?? '';

            final richId = info['RichIDChanged']?.toString() ??
                info['richIdChanged']?.toString() ??
                info['richId']?.toString() ?? '';

            final dob = info['dob'] ?? info['dateOfBirth'] ?? info['date_of_birth'];
            final gender = info['gender'] ?? info['sex'];

            final beneficiaryId = row['unique_key']?.toString() ?? '';
            final isDeceased = deceasedIds.contains(beneficiaryId);

            // Calculate age in months for filtering
            final ageInMonths = _calculateAgeInMonths(dob);

            // Filter by age group
            bool belongsToAgeGroup = false;
            if (ageGroup == '0-1') {
              belongsToAgeGroup = ageInMonths >= 0 && ageInMonths <= 12;
            } else if (ageGroup == '1-2') {
              belongsToAgeGroup = ageInMonths > 12 && ageInMonths < 24;
            } else if (ageGroup == '2-5') {
              belongsToAgeGroup = ageInMonths >= 24 && ageInMonths <= 60;
            }

            if (!belongsToAgeGroup) continue;

            // Get last visit date from child_care_activities
            String lastVisitDate;
            if (lastVisitDates.containsKey(beneficiaryId)) {
              lastVisitDate = _formatDateFromString(lastVisitDates[beneficiaryId]);
            } else {
              lastVisitDate = 'Not Available';
            }

            // Check if child has tracking_due status in child_care_activities
            final hasTrackingDue = await _hasTrackingDueStatus(beneficiaryId);
            if (!hasTrackingDue) continue;

            final card = <String, dynamic>{
              'hhId': rowHhId,

              'RegitrationType': 'Child',
              'BeneficiaryID': beneficiaryId,
              'RchID': richId,
              'Name': name,
              'Age|Gender': _formatAgeGender(dob, gender),
              'Mobileno.': mobileNo,
              'FatherName': fatherName,
              'MotherName': motherName,
              'is_deceased': isDeceased,
              'is_death': row['is_death'] ?? 0,
              'age_in_months': ageInMonths,
              'LastVisitDate': lastVisitDate,
              '_raw': row,
            };

            allChildBeneficiaries.add(card);
          }
        } catch (e) {
          print('⚠️ Error processing beneficiary record: $e');
        }
      }

      // Update the appropriate list based on age group
      setState(() {
        switch (ageGroup) {
          case '0-1':
            _child0to1.clear();
            _child0to1.addAll(allChildBeneficiaries);
            print('Total items in _child0to1: ${_child0to1.length}');
            break;
          case '1-2':
            _child1to2.clear();
            _child1to2.addAll(allChildBeneficiaries);
            print('Total items in _child1to2: ${_child1to2.length}');
            break;
          case '2-5':
            _child2to5.clear();
            _child2to5.addAll(allChildBeneficiaries);
            print('Total items in _child2to5: ${_child2to5.length}');
            break;
        }
      });
    } catch (e) {
      print('Error in _loadChildBeneficiariesByAgeGroup($ageGroup): $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
    }
  }

  int _calculateAgeInMonths(dynamic dob) {
    if (dob == null) return 0;
    try {
      DateTime? birthDate;
      if (dob is String) {
        birthDate = DateTime.tryParse(dob);
        if (birthDate == null) {
          final timestamp = int.tryParse(dob);
          if (timestamp != null && timestamp > 0) {
            birthDate = DateTime.fromMillisecondsSinceEpoch(
              timestamp > 1000000000000 ? timestamp : timestamp * 1000,
              isUtc: true,
            );
          }
        }
      } else if (dob is DateTime) {
        birthDate = dob;
      }
      if (birthDate == null) return 0;

      final now = DateTime.now();
      int months = (now.year - birthDate.year) * 12 + (now.month - birthDate.month);
      if (now.day < birthDate.day) {
        months--;
      }
      return months;
    } catch (e) {
      return 0;
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

  String _formatDateFromString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not Available';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr;
    }
  }


  void _updateChildList(List<Map<String, dynamic>> targetList, List<Map<String, dynamic>> sourceRows, String logName) {
    setState(() {
      targetList.clear();
      _addFormDataToList(targetList, sourceRows);
      print('Total items in $logName: ${targetList.length}');
    });
  }


  void _addFormDataToList(List<Map<String, dynamic>> targetList, List<Map<String, dynamic>> sourceRows) {
    for (var row in sourceRows) {
      final formData = row['form_json'];
      final formDataContent = formData is Map ? (formData['form_data'] ?? formData) : formData;

      if (formDataContent != null) {
        targetList.add({
          'name': formDataContent['child_name'] ?? formDataContent['name'] ?? 'N/A',
          'age': formDataContent['age'] ?? 'N/A',
          'gender': formDataContent['gender'] ?? 'N/A',
          'father_name': formDataContent['father_name'] ?? 'N/A',
          'mother_name': formDataContent['mother_name'] ?? 'N/A',
          'mobile': formDataContent['mobile_number'] ?? formDataContent['mobile'] ?? 'N/A',
          'rch_id': formDataContent['rch_id_child'] ?? formDataContent['rch_id'] ?? 'N/A',
          'registration_date': formDataContent['registration_date'] ?? 'N/A',
          'household_id': formDataContent['household_id'] ?? 'N/A',
          'beneficiary_id': formDataContent['beneficiary_id'] ?? 'N/A',
          'id': formDataContent['id'] ?? row['id']?.toString() ?? 'N/A',
        });
      }
    }
  }

  int? _calculateAge(dynamic dob) {
    if (dob == null) return null;
    try {
      DateTime? birthDate;
      if (dob is String) {
        birthDate = DateTime.tryParse(dob);
      } else if (dob is DateTime) {
        birthDate = dob;
      }
      if (birthDate == null) return null;

      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
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
    ranges['pmsma_start'] = _dateAfterWeeks(lmp, 40);
    ranges['pmsma_end'] = _dateAfterWeeks(lmp, 44);
    return ranges;
  }

  DateTime _dateAfterWeeks(DateTime startDate, int weeks) {
    return startDate.add(Duration(days: weeks * 7));
  }

  DateTime _calculateEdd(DateTime lmp) {
    return _dateAfterWeeks(lmp, 40);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _getNextVisitDate(Map<String, DateTime> ancDates) {
    final now = DateTime.now();

    final ancWindows = [
      {'key': '1st_anc_start', 'label': '1st ANC'},
      {'key': '2nd_anc_start', 'label': ''},
      {'key': '3rd_anc_start', 'label': '3rd ANC'},
      {'key': '4th_anc_start', 'label': '4th ANC'},
      {'key': 'pmsma_start', 'label': 'PMSMA'},
    ];

    for (var window in ancWindows) {
      final startDate = ancDates[window['key']];
      if (startDate != null && startDate.isAfter(now)) {
        return '${window['label']} (${_formatDate(startDate)})';
      }
    }

    final lastVisit = ancDates['pmsma_end'];
    if (lastVisit != null) {
      return 'Last visit date: ${_formatDate(lastVisit)}';
    }

    return 'No visit scheduled';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleanNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid phone number')),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch phone app';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppHeader(screenTitle: l10n.routine, showBack: true,),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        children: [
          _sectionTile(l10n.routinePwList, _pwList),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList0to1, _child0to1),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList1to2, _child1to2),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineChildList2to5, _child2to5),
          const SizedBox(height: 12),
          _sectionTile(l10n.routinePoornTikakaran, _poornTikakaran),
          const SizedBox(height: 12),
          _sectionTile(l10n.routineSampoornTikakaran, _sampoornTikakaran),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTile(String title, List<Map<String, dynamic>> items) {
    final l10n = AppLocalizations.of(context)!;

    final isOpen = _expanded[title] ?? false;
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expanded[title] = !isOpen;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${items.length}',
                  style:  TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color:AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (isOpen) ...[
          const Divider(height: 1, color: Color(0xFFD3E7FF)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Text(
                  l10n.noRecordFound,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: _routineCard(item),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _routineCard(Map<String, dynamic> item) {
    final primary = Theme.of(context).primaryColor;
    final l10n = AppLocalizations.of(context);
    final ancDates = item['ancDates'] as Map<String, dynamic>?;

    // Handle different data structures
    final mobile = item['mobile']?.toString() ?? item['Mobileno.']?.toString() ?? '';
    final isChildData = item.containsKey('Name') && item.containsKey('BeneficiaryID') && item.containsKey('Age|Gender');
    final isPwData = item.containsKey('age_gender') && item.containsKey('mobile');
    final isSampoornTikakaran = item['age']?.toString().contains('16') ?? false;

    String _last11(String value) {
      if (value.length <= 11) return value;
      return value.substring(value.length - 11);
    }

    // Get appropriate ID based on data structure
    String displayId;
    String displayName;
    String displayAgeGender;
    String displayMobile;
    String badge;

    if (isChildData) {
      displayId = _last11(item['BeneficiaryID']?.toString() ?? '-');
      displayName = item['Name']?.toString() ?? '-';
      displayAgeGender = item['Age|Gender']?.toString() ?? '-';
      displayMobile = item['Mobileno.']?.toString() ?? '-';
      badge = 'Child Tracking';
    } else if (isPwData) {
      // PW (Pregnant Women) data structure
      displayId = _last11(item['BeneficiaryID']?.toString() ?? '-');
      displayName = item['Name']?.toString() ?? '-';
      displayAgeGender = item['age_gender']?.toString() ?? '-';
      displayMobile = item['mobile']?.toString() ?? '';
      badge = item['badge']?.toString() ?? 'PW';
    } else {
      // Old structure or other data
      displayId = _last11((item['beneficiary_ref_key'] ?? item['id'] ?? '-').toString());
      displayName = item['name']?.toString() ?? '-';
      displayAgeGender = '${item['age'] ?? '-'} Y | ${item['gender'] ?? '-'}';
      displayMobile = item['mobile']?.toString() ?? '-';
      badge = item['badge']?.toString() ?? 'Child Tracking';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
                Icon(Icons.home, color: primary, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    displayId,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                // Show deceased badge if applicable
                if (item['is_deceased'] == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Text(
                      'Deceased'.toUpperCase(),
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F7E9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    badge,
                    style:  TextStyle(color: Color(0xFF0E7C3A), fontWeight: FontWeight.w600, fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Container(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic info row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style:  TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16.sp),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayAgeGender,
                            style:  TextStyle(color: Colors.white, fontSize: 14.sp),
                          ),
                          const SizedBox(height: 2),
                          if (isChildData) ...[
                            Text(
                              'Last visit: ${item['LastVisitDate'] ?? '-'}',
                              style:  TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),

                          ] else if (isPwData) ...[
                            Text(
                              item['badge'] == 'ANC'
                                  ? item['nextAncDueDate'] ?? 'N/A'
                                  : item['badge'] == 'PW'
                                  ? 'Pregnant Woman'
                                  : item['nextAncDueDate'] ?? 'N/A',
                              style:  TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),

                          ] else ...[
                            Text(
                              item['badge'] == 'ANC'
                                  ? '${l10n!.antenatal} ${item['nextVisit'] ?? '-'}'
                                  : 'Next Visits: ${item['nextVisit'] ?? '-'}',
                              style:  TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            '${l10n?.mobileLabel} $displayMobile',
                            style:  TextStyle(color: Colors.white, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    Row(
                      children: [
                        if (displayMobile.isNotEmpty)
                          InkWell(
                            onTap: () => _makePhoneCall(displayMobile),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.phone, color: primary, size: 24),
                            ),
                          ),
                        if (displayMobile.isNotEmpty) const SizedBox(width: 12),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: item['badge'] == 'ANC'
                                ? Image.asset('assets/images/hrp.png')
                                : Image.asset('assets/images/capsule2.png'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }


}
