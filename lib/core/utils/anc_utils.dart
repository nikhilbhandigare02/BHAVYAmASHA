import 'dart:convert';

import '../../data/Database/database_provider.dart';
import '../../data/Database/local_storage_dao.dart';
import '../../data/Database/tables/followup_form_data_table.dart';
import '../../data/Database/tables/mother_care_activities_table.dart';
import '../../data/SecureStorage/SecureStorage.dart';
import '../config/Constant/constant.dart';

class ANCUtils {

  static Future<Map<String, int>> _loadAncVisitCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final deliveredIds = await _getDeliveredBeneficiaryIds();
      final ancDueIds = await _getAncDueBeneficiaryIds();

      final rows = await LocalStorageDao.instance.getAllBeneficiaries();

      final Set<String> countedIds = {};
      int syncedCount = 0;

      for (final row in rows) {
        final rawInfo = row['beneficiary_info'];
        if (rawInfo == null) continue;

        final info = rawInfo is String
            ? jsonDecode(rawInfo)
            : Map<String, dynamic>.from(rawInfo);

        final beneficiaryId = row['unique_key']?.toString() ?? '';
        if (beneficiaryId.isEmpty) continue;

        // ❌ Exclude delivered
        if (deliveredIds.contains(beneficiaryId)) continue;

        final gender = info['gender']?.toString().toLowerCase() ?? '';
        if (gender != 'f' && gender != 'female') continue;

        final isPregnant =
            info['isPregnant']?.toString().toLowerCase() == 'yes';
        final isAncDue = ancDueIds.contains(beneficiaryId);

        if (isPregnant || isAncDue) {
          countedIds.add(beneficiaryId);

          final syncRows = await db.rawQuery('''
          SELECT 1
          FROM mother_care_activities
          WHERE beneficiary_ref_key = ?
            AND is_synced = 1
          LIMIT 1
        ''', [beneficiaryId]);

          if (syncRows.isNotEmpty) {
            syncedCount++;
          }
        }
      }

      print('✅ ANC total count: ${countedIds.length}');
      print('🔄 Synced ANC count: $syncedCount');

      // ✅ ONLY RETURN CHANGED
      return {
        'total': countedIds.length,
        'synced': syncedCount,
      };
    } catch (e, s) {
      return {
        'total': 0,
        'synced': 0,
      };
    }
  }


  static Future<List<Map<String, dynamic>>> _getAncDueRecords() async {
    final db = await DatabaseProvider.instance.database;

    final currentUserData = await SecureStorageService.getCurrentUserData();
    final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

    if (ashaUniqueKey == null || ashaUniqueKey.isEmpty) {
      return [];
    }

    final rows = await db.rawQuery(
      '''
    WITH RankedMCA AS (
      SELECT
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
    SELECT r.*
    FROM RankedMCA r
    INNER JOIN beneficiaries_new bn
      ON r.beneficiary_ref_key = bn.unique_key
    WHERE
      r.rn = 1
      AND r.mother_care_state = 'anc_due'
      AND bn.is_deleted = 0
      AND bn.is_migrated = 0
    ORDER BY r.created_date_time DESC; 
    ''',
      [ashaUniqueKey],
    );

    return rows;
  }

  static Future<void> loadPregnantWomen() async {

    try {
      final rows = await LocalStorageDao.instance.getAllBeneficiaries();
      final pregnantWomen = <Map<String, dynamic>>[];
      final Set<String> processedBeneficiaries = {};

      print('ℹ️ Found ${rows.length} beneficiaries');

      final ancDueRecords = await _getAncDueRecords();
      final ancDueBeneficiaryIds = ancDueRecords
          .map((e) => e['beneficiary_ref_key']?.toString() ?? '')
          .toSet();

      //  final deliveredBeneficiaryIds = await _getDeliveredBeneficiaryIds();
      // print('ℹ️ Delivered: ${deliveredBeneficiaryIds.length}');

      for (final row in rows) {
        try {
          final rawInfo = row['beneficiary_info'];
          if (rawInfo == null) continue;

          final Map<String, dynamic> info = rawInfo is String
              ? jsonDecode(rawInfo)
              : Map<String, dynamic>.from(rawInfo);

          final beneficiaryId = row['unique_key']?.toString() ?? '';
          if (beneficiaryId.isEmpty) continue;

          // if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
          //   continue;
          // }

          final isPregnant =
              info['isPregnant']?.toString().toLowerCase() == 'yes';
          final gender = info['gender']?.toString().toLowerCase() ?? '';
          final isAncDue = ancDueBeneficiaryIds.contains(beneficiaryId);

          if ((isPregnant || isAncDue) &&
              (gender == 'f' || gender == 'female')) {
            final personData =
            _processPerson(row, info, isPregnant: true);

            if (personData != null) {
              personData['isAncDue'] = isAncDue;
              pregnantWomen.add(personData);
              processedBeneficiaries.add(beneficiaryId);
            }
          }
        } catch (_) {}
      }

      // ---------------- ANC-DUE-ONLY RECORDS ----------------
      for (final ancDue in ancDueRecords) {
        final beneficiaryId =
            ancDue['beneficiary_ref_key']?.toString() ?? '';

        if (beneficiaryId.isEmpty ||
            processedBeneficiaries.contains(beneficiaryId)) {
          continue;
        }

        // // ❌ EXCLUDE DELIVERED (IMPORTANT)
        // if (deliveredBeneficiaryIds.contains(beneficiaryId)) {
        //   continue;
        // }

        pregnantWomen.add({
          'BeneficiaryID': beneficiaryId,
          'unique_key': beneficiaryId,
          'Name': 'ANC Due - ${_getLast11Chars(beneficiaryId)}',
          'isAncDue': true,
          'RegistrationDate': ancDue['created_date_time'],
          '_rawRow': ancDue,
          'is_synced': ancDue['is_synced'],
        });
      }

      // ---------------- DEDUP + SORT ----------------
      final Map<String, Map<String, dynamic>> byId = {};
      for (final item in pregnantWomen) {
        final id = item['BeneficiaryID'] ?? item['unique_key'];
        if (id != null) byId[id] = item;
      }

      final list = byId.values.toList()
        ..sort((a, b) {
          final d1 = DateTime.tryParse(
              a['_rawRow']?['created_date_time'] ?? '');
          final d2 = DateTime.tryParse(
              b['_rawRow']?['created_date_time'] ?? '');
          return (d2 ?? DateTime(0))
              .compareTo(d1 ?? DateTime(0));
        });

      final int ancSyncCount = pregnantWomen.where((e) => e['is_synced'] == 1).length;





      final deliveryOutcomeResult = await _getDeliveryOutcomeCount();
      final hbncResult = await _getHBNCCount();

      final deliveryOutcomeCount = deliveryOutcomeResult['total'] ?? 0;
      final hbncCount = hbncResult['total'] ?? 0;

      Constant.motherCareTotal = pregnantWomen.length + deliveryOutcomeCount + hbncCount;
      //Sync
      final deliveryOutcomeResultSync = await _getDeliveryOutcomeCount();
      final hbncResultSync = await _getHBNCCount();

      final deliveryOutcomeSynced = deliveryOutcomeResultSync['synced'] ?? 0;
      final hbncSynced = hbncResultSync['synced'] ?? 0;

      final totalSynced = ancSyncCount + deliveryOutcomeSynced + hbncSynced;
      Constant.motherCareSynced = totalSynced;

      list.length;
    } catch (e) {

    }
  }


  static int? _calculateAge(dynamic dob) {
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
      print('⚠️ Error calculating age: $e');
      return null;
    }
  }


  static String _getLast11Chars(String? input) {
    if (input == null || input.isEmpty) return '';
    return input.length <= 11 ? input : input.substring(input.length - 11);
  }
  static Map<String, dynamic>? _processPerson(
      Map<String, dynamic> row,
      Map<String, dynamic> person, {
        required bool isPregnant,
      }) {
    try {
      final name = person['memberName'] ?? person['headName'] ?? 'Unknown';
      final gender = person['gender']?.toString().toLowerCase() ?? '';
      final dob = person['dob'];
      final age = _calculateAge(dob);
      final spouseName = person['spouseName'] ?? person['headName'] ?? '';

      // Store COMPLETE IDs
      final householdRefKey = row['household_ref_key']?.toString() ?? '';
      final uniqueKey = row['unique_key']?.toString() ?? '';

      // Get TRIMMED versions for display only
      final householdRefKeyDisplay = _getLast11Chars(householdRefKey);
      final uniqueKeyDisplay = _getLast11Chars(uniqueKey);

      final registrationDate = row['created_date_time']?.toString() ?? '';

      if (!isPregnant) return null;

      // Format registration date if available
      String formattedDate = 'N/A';
      if (registrationDate.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(registrationDate);
          // Format day and month to always show two digits
          final day = dateTime.day.toString().padLeft(2, '0');
          final month = dateTime.month.toString().padLeft(2, '0');
          formattedDate = '$day-$month-${dateTime.year}';
        } catch (e) {
          print('⚠️ Error parsing date: $e');
        }
      }

      return {
        'id': row['id']?.toString() ?? '',

        'unique_key': uniqueKey,
        'BeneficiaryID': uniqueKey,
        'hhId': householdRefKey,

        'unique_key_display': uniqueKeyDisplay,
        'BeneficiaryID_display': uniqueKeyDisplay,
        'hhId_display': householdRefKeyDisplay,
        // Other fields
        'Name': name,
        'Age': age?.toString() ?? 'N/A',
        'Gender': 'Female',
        'RCH ID': person['RCH_ID'] ?? person['RichID'] ?? 'N/A',
        'Mobile No': person['mobileNo'] ?? '',
        'Husband': spouseName,
        'RegistrationDate': formattedDate,
        'beneficiary_info': jsonEncode(person),
        '_rawRow': row,
      };
    } catch (e) {
      print('⚠️ Error processing person: $e');
      return null;
    }
  }


  static Future<int> getMotherCareTotalCount() async {
    try {
      final db = await DatabaseProvider.instance.database;

      final deliveredIds = await _getDeliveredBeneficiaryIds();

      final ancResult = await _loadAncVisitCount();
      final deliveryOutcomeResult = await _getDeliveryOutcomeCount();
      final hbncResult = await _getHBNCCount();

      final ancTotal = ancResult['total'] ?? 0;
      final deliveryOutcomeCount = deliveryOutcomeResult['total'] ?? 0;
      final hbncCount = hbncResult['total'] ?? 0;

      final totalCount = ancTotal + deliveryOutcomeCount + hbncCount;

      print('''
Mother Care Counts:
  Pregnant/ANC Due: $ancTotal
  Delivery Outcome: $deliveryOutcomeCount
  HBNC: $hbncCount
  Total: $totalCount
''');

      return totalCount;
    } catch (e) {
      print('Error in getMotherCareTotalCount: $e');
      return 0;
    }
  }

  static Future<Set<String>> _getDeliveredBeneficiaryIds() async {
    final db = await DatabaseProvider.instance.database;

    final rows = await db.query(
      'followup_form_data',
      where: '''
      forms_ref_key = ?
      AND LOWER(form_json) LIKE ?
    ''',
      whereArgs: [
        'bt7gs9rl1a5d26mz',
        '%"gives_birth_to_baby":"yes"%',
      ],
      columns: ['beneficiary_ref_key'],
      distinct: true,
    );

    return rows
        .map((e) => e['beneficiary_ref_key']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  static Future<Set<String>> _getAncDueBeneficiaryIds() async {
    final db = await DatabaseProvider.instance.database;

    final rows = await db.rawQuery('''
     SELECT mca.*
FROM mother_care_activities mca
INNER JOIN (
    SELECT beneficiary_ref_key,
           MAX(created_date_time) AS max_date
    FROM mother_care_activities
    WHERE mother_care_state = 'anc_due'
    GROUP BY beneficiary_ref_key
) latest
  ON mca.beneficiary_ref_key = latest.beneficiary_ref_key
 AND mca.created_date_time = latest.max_date
INNER JOIN beneficiaries_new bn
  ON mca.beneficiary_ref_key = bn.unique_key
WHERE bn.is_deleted = 0;
  ''');

    return rows
        .map((e) => e['beneficiary_ref_key']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();
  }

  static Future<Map<String, int>> _getDeliveryOutcomeCount() async {
    int syncedCount = 0;
    var processedData = <Map<String, dynamic>>[];
    try {

      final db = await DatabaseProvider.instance.database;

      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey =
      currentUserData?['unique_key']?.toString();


      const ancRefKey = 'bt7gs9rl1a5d26mz';

      final results = await db.rawQuery(
        '''
WITH LatestMCA AS (
  SELECT
    mca.*,
    ROW_NUMBER() OVER (
      PARTITION BY mca.beneficiary_ref_key
      ORDER BY mca.created_date_time DESC, mca.id DESC
    ) AS rn
  FROM ${MotherCareActivitiesTable.table} mca
  WHERE mca.is_deleted = 0
),
DeliveryOutcomeOnly AS (
  SELECT *
  FROM LatestMCA
  WHERE rn = 1
    AND mother_care_state = 'delivery_outcome'
),
LatestANC AS (
  SELECT
    f.beneficiary_ref_key,
    f.form_json,
    ROW_NUMBER() OVER (
      PARTITION BY f.beneficiary_ref_key
      ORDER BY f.created_date_time DESC, f.id DESC
    ) AS rn
  FROM ${FollowupFormDataTable.table} f
  WHERE
    f.forms_ref_key = ?
    AND f.is_deleted = 0
    AND f.current_user_key = ?
)
SELECT
  d.beneficiary_ref_key,
  d.household_ref_key,
  d.created_date_time,
  d.id AS form_id,
  COALESCE(a.form_json, '{}') AS form_json
FROM DeliveryOutcomeOnly d
LEFT JOIN LatestANC a
  ON a.beneficiary_ref_key = d.beneficiary_ref_key
 AND a.rn = 1
ORDER BY d.created_date_time DESC
''',
        [
          ancRefKey,
          ashaUniqueKey,
        ],
      );

      if (results.isEmpty) {
        return {
          'total': 0,
          'synced': 0,
        };
      }

      processedData = [];

      for (final row in results) {
        final beneficiaryRefKey =
        row['beneficiary_ref_key']?.toString();

        if (beneficiaryRefKey == null || beneficiaryRefKey.isEmpty) {
          continue;
        }

        Map<String, dynamic>? beneficiaryRow;

        try {
          beneficiaryRow = await LocalStorageDao.instance
              .getBeneficiaryByUniqueKey(beneficiaryRefKey);

          if (beneficiaryRow == null) {
            final fallback = await db.query(
              'beneficiaries_new',
              where:
              'unique_key = ? AND (is_deleted IS NULL OR is_deleted = 0) AND current_user_key = ?',
              whereArgs: [beneficiaryRefKey, ashaUniqueKey],
              limit: 1,
            );

            if (fallback.isNotEmpty) {
              final legacy = Map<String, dynamic>.from(fallback.first);

              Map<String, dynamic> info = {};
              try {
                final formJson = legacy['form_json'];
                if (formJson is String && formJson.isNotEmpty) {
                  final decoded = jsonDecode(formJson);
                  if (decoded is Map) {
                    info = Map<String, dynamic>.from(decoded);
                  }
                }
              } catch (_) {}

              beneficiaryRow = {
                ...legacy,
                'beneficiary_info': info,
                'geo_location': {},
                'death_details': {},
              };
            }
          }
        } catch (_) {}

        final formatted = _formatCoupleData(
          row,
          {},
          {},
          isHead: true,
          beneficiaryRow: beneficiaryRow,
        );

        processedData.add(formatted);
      }

      syncedCount = processedData.where((e) => e['is_synced'] == 1).length;

    } catch (e) {
      print('❌ Error loading pregnancy outcome couples: $e');

    }
    // ✅ ONLY RETURN CHANGED
    return {
      'total': processedData.length,
      'synced': syncedCount,
    };
  }

  static Map<String, dynamic> _formatCoupleData(Map<String, dynamic> row, Map<String, dynamic> female, Map<String, dynamic> headOrSpouse, {required bool isHead, Map<String, dynamic>? beneficiaryRow}) {
    try {
      print('🔄 Formatting couple data for row: $row');

      // Parse form JSON to get the actual form data
      final formJson = row['form_json'] is String
          ? jsonDecode(row['form_json'] as String)
          : (row['form_json'] ?? {}) as Map<String, dynamic>;

      final formData = (formJson['form_data'] ?? formJson) as Map<String, dynamic>;
      print('📋 Form data: $formData');

      // First try to get name from beneficiary info if available
      String womanName = 'Unknown';
      if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
        try {
          final info = beneficiaryRow['beneficiary_info'] is Map
              ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
              : (beneficiaryRow['beneficiary_info'] is String
              ? jsonDecode(beneficiaryRow['beneficiary_info'] as String)
              : <String, dynamic>{});

          womanName = (info['headName'] ?? info['name'] ??info['memberName'] ?? info['spouseName']?? info['woman_name'] ?? 'Unknown').toString();
        } catch (e) {
          print('⚠️ Error parsing beneficiary_info: $e');
        }
      }

      if (womanName == 'Unknown') {
        womanName = (formData['woman_name'] ?? formData['name'] ?? formData['memberName'] ?? formData['headName'] ?? 'Unknown').toString();
      }

      // Try to get husband name from beneficiary info first
      String husbandName = 'N/A';
      if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
        try {
          final info = beneficiaryRow['beneficiary_info'] is Map
              ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
              : (beneficiaryRow['beneficiary_info'] is String
              ? jsonDecode(beneficiaryRow['beneficiary_info'] as String)
              : <String, dynamic>{});

          husbandName = (info['spouseName'] ?? info['spouse_name'] ?? info['husbandName'] ?? info['husband_name'] ?? 'N/A').toString();
        } catch (e) {
          print('⚠️ Error parsing beneficiary_info for spouse name: $e');
        }
      }

      if (husbandName == 'N/A') {
        husbandName = (formData['husband_name'] ?? formData['spouse_name'] ?? formData['spouseName'] ?? formData['husbandName'] ?? 'N/A').toString();
      }
      final rchNumber = (formData['rch_number'] ?? '').toString();
      final lmpDate = (formData['lmp_date'] ?? '').toString();
      final eddDate = (formData['edd_date'] ?? '').toString();
      final weeksOfPregnancy = (formData['weeks_of_pregnancy'] ?? '').toString();
      final createdAt = (formData['created_at'] ?? row['created_date_time'] ?? '').toString();
      final mobileNo = (formData['mobile_no'] ?? formData['phone'] ?? '').toString();
      final houseNumber = (formData['house_number'] ?? '').toString();

      // Get household and beneficiary info
      final hhRefKey = (formData['household_ref_key'] ?? row['household_ref_key'] ?? '').toString();
      final is_synced = (formData['is_synced'] ?? row['is_synced'] ?? '').toString();
      final beneficiaryRefKey = (formData['beneficiary_ref_key'] ?? row['beneficiary_ref_key'] ?? '').toString();

      // Keep full household ID for data passing, will be truncated for display only
      final hhId = hhRefKey;

      int age = 0;
      String displayAge = '';

      if (eddDate.isNotEmpty) {
        final edd = DateTime.tryParse(eddDate);
        if (edd != null) {
          age = (DateTime.now().difference(edd).inDays / 7).round();
          displayAge = '$weeksOfPregnancy weeks (EDD: ${_formatDate(eddDate)})';
        }
      } else if (lmpDate.isNotEmpty) {
        final lmp = DateTime.tryParse(lmpDate);
        if (lmp != null) {
          age = (DateTime.now().difference(lmp).inDays / 7).round();
          displayAge = '$weeksOfPregnancy weeks (LMP: ${_formatDate(lmpDate)})';
        }
      }

      if (displayAge.isEmpty && weeksOfPregnancy.isNotEmpty) {
        displayAge = '$weeksOfPregnancy weeks';
      }

      String registrationDateDisplay = _formatDate(createdAt);
      String mobileFromBeneficiary = mobileNo;
      String gender = '';
      String ageYearsDisplay = '';

      if (beneficiaryRow != null && beneficiaryRow.isNotEmpty) {
        try {
          final createdDt = beneficiaryRow['created_date_time']?.toString() ?? '';
          if (createdDt.isNotEmpty) {
            registrationDateDisplay = _formatDate(createdDt);
          }

          final info = beneficiaryRow['beneficiary_info'] is Map
              ? Map<String, dynamic>.from(beneficiaryRow['beneficiary_info'] as Map)
              : <String, dynamic>{};

          final dob = info['dob']?.toString();
          int ageYears = _calculateAgeDelivery(dob);

          if (ageYears == 0) {
            final updateYearStr = info['updateYear']?.toString() ?? '';
            final approxAgeStr = info['approxAge']?.toString() ?? '';
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
          ageYearsDisplay = ageYears > 0 ? ageYears.toString() : '';

          gender = 'F';

          final m = (info['mobileNo']?.toString() ?? info['mobile']?.toString() ?? info['phone']?.toString() ?? '').trim();
          if (m.isNotEmpty) {
            mobileFromBeneficiary = m;
          }
        } catch (e) {
          print('⚠️ Error extracting beneficiary_info for $beneficiaryRefKey: $e');
        }
      }

      final ageGenderCombined = (ageYearsDisplay.isNotEmpty || gender.isNotEmpty)
          ? '${ageYearsDisplay.isNotEmpty ? ageYearsDisplay : 'N/A'} | ${gender.isNotEmpty ? gender : 'N/A'}'
          : 'N/A';

      final formattedData = {
        'hhId': hhId.isNotEmpty ? hhId : 'N/A',
        'household_id': hhRefKey,
        'RegistrationDate': registrationDateDisplay.isNotEmpty ? registrationDateDisplay : 'N/A',
        'BeneficiaryID': beneficiaryRefKey,
        'Name': womanName,
        'ageGender': ageGenderCombined,
        'RichID': rchNumber.isNotEmpty ? rchNumber : 'N/A',
        'mobileno': mobileFromBeneficiary.isNotEmpty ? mobileFromBeneficiary : 'N/A',
        'HusbandName': husbandName,
        'weeksOfPregnancy': weeksOfPregnancy.isNotEmpty ? weeksOfPregnancy : 'N/A',
        'eddDate': _formatDate(eddDate).isNotEmpty ? _formatDate(eddDate) : 'N/A',
        'lmpDate': _formatDate(lmpDate).isNotEmpty ? _formatDate(lmpDate) : 'N/A',
        'houseNumber': houseNumber.isNotEmpty ? houseNumber : 'N/A',
        'is_synced': is_synced,
        '_rawRow': row,
      };

      print('✅ Formatted data for $womanName:');
      print('   - Household ID: ${formattedData['hhId']}');
      print('   - Registration Date: ${formattedData['RegistrationDate']}');
      print('   - Beneficiary ID: $beneficiaryRefKey');
      print('   - Name: $womanName');
      print('   - Mobile: ${formattedData['mobileno']}');

      return formattedData;
    } catch (e) {
      print('❌ Error formatting   couple data: $e');
      return {
        'hhId': 'N/A',
        'RegistrationDate': 'N/A',
        'RegistrationType': 'Error',
        'BeneficiaryID': '',
        'Name': 'Error loading data',
        'age': 'N/A',
        'RichID': 'N/A',
        'mobileno': 'N/A',
        'HusbandName': 'N/A',
        'weeksOfPregnancy': 'N/A',
        'eddDate': 'N/A',
        'lmpDate': 'N/A',
        '_rawRow': row,
      };
    }
  }
  static String _formatDate(String dateStr) {
    if (dateStr.isEmpty || dateStr == 'null') return '';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return '';
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return '';
    }
  }

  static int _calculateAgeDelivery(dynamic dobRaw) {
    if (dobRaw == null || dobRaw.toString().isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobRaw.toString());
      if (dob == null) return 0;
      return DateTime.now().difference(dob).inDays ~/ 365;
    } catch (_) {
      return 0;
    }
  }

  static Future<Map<String, int>> _getHBNCCount() async {
    final db = await DatabaseProvider.instance.database;
    const deliveryOutcomeKey = '4r7twnycml3ej1vg';

    try {
      // First, get all beneficiary_ref_keys that have either pnc_mother or hbnc_visit state
      final validBeneficiaries = await db.rawQuery('''
    SELECT DISTINCT mca.beneficiary_ref_key,
           MAX(CASE WHEN mca.is_synced = 1 THEN 1 ELSE 0 END) as has_synced
    FROM mother_care_activities mca
    WHERE mca.mother_care_state IN ('pnc_mother', 'pnc_mother')
    AND mca.is_deleted = 0
    GROUP BY mca.beneficiary_ref_key
  ''');

      if (validBeneficiaries.isEmpty) {
        print('ℹ️ No beneficiaries found with pnc_mother or pnc_mother state');
        return {'total': 0, 'synced': 0};
      }

      final beneficiaryKeys = validBeneficiaries.map((e) => e['beneficiary_ref_key'] as String).toList();
      final placeholders = List.filled(beneficiaryKeys.length, '?').join(',');

      // Get delivery outcome records only for valid beneficiaries
      final deliveryOutcomeBeneficiaries = await db.rawQuery('''
    SELECT DISTINCT beneficiary_ref_key 
    FROM followup_form_data ffd
    INNER JOIN beneficiaries_new bn
      ON bn.unique_key = ffd.beneficiary_ref_key
    WHERE ffd.forms_ref_key = ? 
    AND ffd.is_deleted = 0
    AND ffd.beneficiary_ref_key IN ($placeholders)
  ''', [deliveryOutcomeKey, ...beneficiaryKeys]);

      // Create a set of beneficiaries with delivery outcomes
      final deliveryOutcomeBeneficiarySet = {
        for (var e in deliveryOutcomeBeneficiaries)
          e['beneficiary_ref_key'] as String
      };

      // Count synced records from the valid beneficiaries that also have delivery outcomes
      int syncedCount = 0;
      for (final beneficiary in validBeneficiaries) {
        final beneficiaryRefKey = beneficiary['beneficiary_ref_key'] as String;
        final hasSynced = (beneficiary['has_synced'] as int) == 1;

        if (deliveryOutcomeBeneficiarySet.contains(beneficiaryRefKey) && hasSynced) {
          syncedCount++;
        }
      }

      final totalCount = deliveryOutcomeBeneficiarySet.length;
      print('✅ HBNC total processed count: $totalCount');
      print('🔄 HBNC synced count: $syncedCount');

      return {
        'total': totalCount,
        'synced': syncedCount,
      };
    } catch (e) {
      print('❌ Error in _getHBNCCount: $e');
      return {'total': 0, 'synced': 0};
    }
  }

  static Future<int> getMotherCareSyncedTotalCount() async {
    try {
      final ancResult = await _loadAncVisitCount();
      final deliveryOutcomeResult = await _getDeliveryOutcomeCount();
      final hbncResult = await _getHBNCCount();

      final ancSynced = ancResult['synced'] ?? 0;
      final deliveryOutcomeSynced = deliveryOutcomeResult['synced'] ?? 0;
      final hbncSynced = hbncResult['synced'] ?? 0;

      final totalSynced =
          ancSynced + deliveryOutcomeSynced + hbncSynced;

      print('''
Mother Care Synced Counts:
  ANC Synced: $ancSynced
  Delivery Outcome Synced: $deliveryOutcomeSynced
  HBNC Synced: $hbncSynced
  Total Synced: $totalSynced
''');

      return totalSynced;
    } catch (e) {
      print('Error in getMotherCareSyncedTotalCount: $e');
      return 0;
    }
  }


}
