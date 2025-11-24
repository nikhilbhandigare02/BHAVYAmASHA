import 'dart:convert';
import 'dart:math';

import 'package:medixcel_new/data/Local_Storage/tables/beneficiaries_table.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/Local_Storage/tables/notification_table.dart';
import 'package:medixcel_new/data/Local_Storage/tables/training_data_table.dart';
import 'package:sqflite/sqflite.dart';

import '../models/guest_beneficiary/guest_beneficiary_model.dart';
import 'database_provider.dart';

class LocalStorageDao {
  LocalStorageDao._();
  static final LocalStorageDao instance = LocalStorageDao._();

  factory LocalStorageDao() => instance;

  Future<Database> get _db async => DatabaseProvider.instance.database;

  dynamic safeJsonDecode(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error decoding JSON: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChildTrackingDueFor16Year() async {
    print('Executing getChildTrackingDueFor16Year query...');
    try {
      final db = await _db;

      // Query to get the latest entry for each beneficiary
      final rows = await db.rawQuery('''
      WITH LatestEntries AS (
        SELECT 
          beneficiary_ref_key,
          MAX(created_date_time) as latest_date
        FROM followup_form_data
        WHERE forms_ref_key = '30bycxe4gv7fqnt6'
          AND form_json LIKE '%"current_tab"%16 YEAR%'
        GROUP BY beneficiary_ref_key
      )
      SELECT f.* 
      FROM followup_form_data f
      INNER JOIN LatestEntries le ON 
        f.beneficiary_ref_key = le.beneficiary_ref_key AND 
        f.created_date_time = le.latest_date
      WHERE f.forms_ref_key = '30bycxe4gv7fqnt6'
        AND f.form_json LIKE '%"current_tab"%16 YEAR%'
      ORDER BY f.created_date_time DESC
    ''');

      print('Found ${rows.length} latest entries for 16 YEAR tracking forms');

      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['form_json'] = safeJsonDecode(mapped['form_json']);
        return mapped;
      }).toList();
    } catch (e) {
      print('Error in getChildTrackingDueFor16Year: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getChildTrackingDueFor9Year() async {
    print('Executing getChildTrackingDueFor9Year query...');
    try {
      final db = await _db;

      // Query to get the latest entry for each beneficiary
      final rows = await db.rawQuery('''
      WITH LatestEntries AS (
        SELECT 
          beneficiary_ref_key,
          MAX(created_date_time) as latest_date
        FROM followup_form_data
        WHERE forms_ref_key = '30bycxe4gv7fqnt6'
          AND form_json LIKE '%"current_tab"%9 MONTHS%' 
        GROUP BY beneficiary_ref_key
      )
      SELECT f.* 
      FROM followup_form_data f
      INNER JOIN LatestEntries le ON 
        f.beneficiary_ref_key = le.beneficiary_ref_key AND 
        f.created_date_time = le.latest_date
      WHERE f.forms_ref_key = '30bycxe4gv7fqnt6'
        AND f.form_json LIKE '%"current_tab"%9 MONTHS%'
      ORDER BY f.created_date_time DESC
    ''');

      print('Found ${rows.length} latest entries for 9 YEAR tracking forms');

      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['form_json'] = safeJsonDecode(mapped['form_json']);
        return mapped;
      }).toList();
    } catch (e) {
      print('Error in getChildTrackingDueFor9Year: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
      rethrow;
    }
  }

  Future<void> debugFormDataFor10Weeks() async {
    try {
      final db = await _db;
      final rows = await db.rawQuery('''
      SELECT id, substr(form_json, 1, 200) as preview 
      FROM followup_form_data 
      WHERE form_json LIKE '%10 WEEK%'
      LIMIT 5
    ''');

      print('Found ${rows.length} rows containing "10 WEEK"');
      for (var row in rows) {
        print('ID: ${row['id']}, Preview: ${row['preview']}');
      }
    } catch (e) {
      print('Error in debugFormDataFor10Weeks: $e');
    }
  }

  // Add these methods to LocalStorageDao class

  Future<List<Map<String, dynamic>>> getChildTrackingForBirthDose() async {
    return _getChildTrackingForAgeGroup('"current_tab"%Birth dose%', 'Birth dose');
  }

  Future<List<Map<String, dynamic>>> getChildTrackingFor6Weeks() async {
    return _getChildTrackingForAgeGroup('"current_tab"%6 WEEK%', '6 WEEK');
  }

  Future<List<Map<String, dynamic>>> getChildTrackingFor10Weeks() async {
    // Try different patterns to match the data
    final patterns = [
      '"current_tab":"10 WEEK"',  // with quotes and colon
      '"current_tab" : "10 WEEK"', // with spaces around colon
      'current_tab":"10 WEEK',    // missing first quote
      '10 WEEK'                   // just the value
    ];

    for (var pattern in patterns) {
      try {
        final result = await _getChildTrackingForAgeGroup(pattern, '10 WEEK');
        if (result.isNotEmpty) {
          print('Found ${result.length} records with pattern: $pattern');
          return result;
        }
      } catch (e) {
        print('Error with pattern $pattern: $e');
      }
    }
    return []; // Return empty if no records found with any pattern
  }

  Future<List<Map<String, dynamic>>> getChildTrackingFor14Weeks() async {
    return _getChildTrackingForAgeGroup('"current_tab"%14 WEEK%', '14 WEEK');
  }

  Future<List<Map<String, dynamic>>> getChildTrackingFor16To24Months() async {
    return _getChildTrackingForAgeGroup('"current_tab"%16-24%', '16-24 MONTHS');
  }

  Future<List<Map<String, dynamic>>> getChildTrackingFor5To6Years() async {
    return _getChildTrackingForAgeGroup('"current_tab"%5-6 YEAR%', '5-6 YEARS');
  }

  // Helper method to avoid code duplication
  Future<List<Map<String, dynamic>>> _getChildTrackingForAgeGroup(String likePattern, String logName) async {
    print('Executing query for $logName with pattern: $likePattern');
    try {
      final db = await _db;
      final rows = await db.rawQuery('''
      WITH LatestEntries AS (
        SELECT 
          beneficiary_ref_key,
          MAX(created_date_time) as latest_date
        FROM followup_form_data
        WHERE forms_ref_key = '30bycxe4gv7fqnt6'
          AND form_json LIKE ?
        GROUP BY beneficiary_ref_key
      )
      SELECT f.* 
      FROM followup_form_data f
      INNER JOIN LatestEntries le ON 
        f.beneficiary_ref_key = le.beneficiary_ref_key AND 
        f.created_date_time = le.latest_date
      WHERE f.forms_ref_key = '30bycxe4gv7fqnt6'
        AND f.form_json LIKE ?
      ORDER BY f.created_date_time DESC
    ''', ['%$likePattern%', '%$likePattern%']);  // Added % around the pattern

      print('Found ${rows.length} latest entries for $logName tracking forms');
      if (rows.isNotEmpty) {
        print('First row preview: ${rows.first.toString().substring(0, min(200, rows.first.toString().length))}');
      }

      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['form_json'] = safeJsonDecode(mapped['form_json']);
        return mapped;
      }).toList();
    } catch (e) {
      print('Error in getChildTrackingFor$logName: $e');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
      rethrow;
    }
  }

  Future<void> debugFormData() async {
    try {
      final db = await _db;
      final rows = await db.rawQuery('''
      SELECT id, substr(form_json, 1, 500) as preview 
      FROM followup_form_data 
      WHERE form_json LIKE '%16 YEAR%' 
      LIMIT 5
    ''');

      print('Found ${rows.length} rows with "16 YEAR" in form_json');
      for (var row in rows) {
        print('ID: ${row['id']}, Preview: ${row['preview']}');
      }
    } catch (e) {
      print('Error in debugFormData: $e');
    }
  }

  Future<int> setBeneficiaryMigratedByUniqueKey({required String uniqueKey, required int isMigrated}) async {
    try {
      final db = await _db;
      final values = <String, Object?>{
        'is_migrated': isMigrated,
        'modified_date_time': DateTime.now().toIso8601String(),
      };
      final changes = await db.update(
        'beneficiaries_new',
        values,
        where: 'unique_key = ?',
        whereArgs: [uniqueKey],
      );
      return changes;
    } catch (e) {
      print('Error updating is_migrated for beneficiary: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedEligibleCoupleActivities() async {
    final db = await _db;
    final rows = await db.query(
      'eligible_couple_activities',
      where: 'is_deleted = 0 AND (is_synced IS NULL OR is_synced = 0)',
      orderBy: 'created_date_time ASC',
    );
    return rows.map((row) {
      final mapped = Map<String, dynamic>.from(row);
      mapped['device_details'] = safeJsonDecode(mapped['device_details']);
      mapped['app_details'] = safeJsonDecode(mapped['app_details']);
      mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
      return mapped;
    }).toList();
  }

  Future<int> markEligibleCoupleActivitySyncedById(int id, {String? serverId}) async {
    final db = await _db;
    final values = <String, Object?>{
      'is_synced': 1,
      'modified_date_time': DateTime.now().toIso8601String(),
    };
    if (serverId != null && serverId.isNotEmpty) values['server_id'] = serverId;
    return db.update('eligible_couple_activities', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getLatestEligibleCoupleActivityServerId() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'eligible_couple_activities',
        columns: ['server_id', 'created_date_time', 'modified_date_time', 'id', 'is_deleted'],
        where:
              "server_id IS NOT NULL AND TRIM(server_id) != '' AND COALESCE(modified_date_time, created_date_time) <= datetime('now','-5 minutes')",

        orderBy: "COALESCE(modified_date_time, created_date_time) DESC, id DESC",
        limit: 1,
      );
      if (rows.isEmpty) return '';
      final sid = rows.first['server_id'];
      return sid?.toString() ?? '';
    } catch (e) {
      print('Error getting latest EC activity server_id: $e');
      return '';
    }
  }

  Future<String> getLatestChildCareActivityServerId() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'child_care_activities',
        columns: ['server_id', 'created_date_time', 'modified_date_time', 'id', 'is_deleted'],
        where:
              "server_id IS NOT NULL AND TRIM(server_id) != '' AND COALESCE(modified_date_time, created_date_time) <= datetime('now','-5 minutes')",

        orderBy: "COALESCE(modified_date_time, created_date_time) DESC, id DESC",
        limit: 1,
      );
      if (rows.isEmpty) return '';
      final sid = rows.first['server_id'];
      return sid?.toString() ?? '';
    } catch (e) {
      print('Error getting latest child care activity server_id: $e');
      return '';
    }
  }

  Future<String> getLatestMotherCareActivityServerId() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'mother_care_activities',
        columns: ['server_id', 'created_date_time', 'modified_date_time', 'id', 'is_deleted'],
        where:
                "server_id IS NOT NULL AND TRIM(server_id) != '' AND COALESCE(modified_date_time, created_date_time) <= datetime('now','-5 minutes')",

        orderBy: "COALESCE(modified_date_time, created_date_time) DESC, id DESC",
        limit: 1,
      );
      if (rows.isEmpty) return '';
      final sid = rows.first['server_id'];
      return sid?.toString() ?? '';
    } catch (e) {
      print('Error getting latest mother care activity server_id: $e');
      return '';
    }
  }

  Future<int> getANCVisitCount(String beneficiaryId) async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM ${FollowupFormDataTable.table} 
        WHERE beneficiary_ref_key = ? 
        AND forms_ref_key = ?
      ''', [beneficiaryId, FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration]]);

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      print('Error getting ANC visit count: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAncFormsByBeneficiaryId(String beneficiaryId) async {
    try {
      final db = await _db;
      final result = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND beneficiary_ref_key = ?',
        whereArgs: [
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration],
          beneficiaryId,
        ],
        orderBy: 'created_date_time DESC',
      );

      return result.map((form) {
        final row = Map<String, dynamic>.from(form);
        try {
          if (row['form_json'] != null) {
            final decoded = jsonDecode(row['form_json']);
            if (decoded is Map && decoded['form_data'] is Map) {
              row['form_data'] = Map<String, dynamic>.from(decoded['form_data']);
            } else {
              row['form_data'] = decoded;
            }
          }
        } catch (_) {}
        return row;
      }).toList();
    } catch (e) {
      print('Error getting ANC forms: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBeneficiaryByUniqueKey(String uniqueKey) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        where: 'unique_key = ? AND is_deleted = 0',
        whereArgs: [uniqueKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final mapped = Map<String, dynamic>.from(rows.first);
      mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
      mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
      mapped['death_details'] = safeJsonDecode(mapped['death_details']);
      mapped['device_details'] = safeJsonDecode(mapped['device_details']);
      mapped['app_details'] = safeJsonDecode(mapped['app_details']);
      mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
      return mapped;
    } catch (e) {
      print('Error getting beneficiary by unique_key: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedFollowupForms() async {
    try {
      final db = await _db;
      final rows = await db.query(
        FollowupFormDataTable.table,
        where:
        '(is_deleted IS NULL OR is_deleted = 0) AND (is_synced IS NULL OR is_synced = 0)',
        orderBy: 'created_date_time ASC',
      );

      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      print('Error getting unsynced followup forms: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTrainingList() async {
    try {
      final db = await _db;
      final rows = await db.query(
        TrainingDataTable.table,
        where: 'is_deleted = 0',
        orderBy: 'created_date_time DESC',
      );

      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        final formJson = mapped['form_json']?.toString();
        if (formJson != null && formJson.isNotEmpty) {
          try {
            mapped['form_json'] = jsonDecode(formJson);
          } catch (_) {}
        }
        return mapped;
      }).toList();
    } catch (e) {
      print('Error fetching training list: $e');
      rethrow;
    }
  }

  Future<int> updateBeneficiaryServerIdByUniqueKey({required String uniqueKey, required String serverId}) async {
    try {
      final db = await _db;
      final changes = await db.update(
        'beneficiaries_new',
        {
          'server_id': serverId,
          // 'is_synced': 1,
          'modified_date_time': DateTime.now().toIso8601String(),
        },
        where: 'unique_key = ?',
        whereArgs: [uniqueKey],
      );
      return changes;
    } catch (e) {
      print('Error updating beneficiary server_id by unique_key: $e');
      rethrow;
    }
  }

  dynamic _encodeIfObject(dynamic v) {
    if (v == null) return null;
    if (v is Map || v is List) return jsonEncode(v);
    return v;
  }

  Future<int> insertHousehold(Map<String, dynamic> data) async {
    try {
      final db = await _db;
      final householdInfo = data['household_info'];

      final row = <String, dynamic>{
        'server_id': data['server_id'],
        'unique_key': data['unique_key'],
        'address': data['address'] is String ? data['address'] : jsonEncode(data['address'] ?? {}),
        'geo_location': data['geo_location'] is String ? data['geo_location'] : jsonEncode(data['geo_location'] ?? {}),
        'head_id': data['head_id'],
        'household_info': householdInfo is String
            ? householdInfo  // Already a JSON string
            : jsonEncode(householdInfo ?? {}),
        'device_details': data['device_details'] is String
            ? data['device_details']
            : jsonEncode(data['device_details'] ?? {}),
        'app_details': data['app_details'] is String
            ? data['app_details']
            : jsonEncode(data['app_details'] ?? {}),
        'parent_user': data['parent_user'] is String
            ? data['parent_user']
            : jsonEncode(data['parent_user'] ?? {}),
        'current_user_key': data['current_user_key'],
        'facility_id': data['facility_id'],
        'created_date_time': data['created_date_time'],
        'modified_date_time': data['modified_date_time'],
        'is_synced': data['is_synced'] ?? 0,
        'is_deleted': data['is_deleted'] ?? 0,
      };

      final id = await db.insert('households', row);
      return id;
    } catch (e, stackTrace) {
      print('Error inserting household:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> updateHouseholdByUniqueKey(Map<String, dynamic> data) async {
    try {
      final db = await _db;
      final householdInfo = data['household_info'];

      final row = <String, dynamic>{
        'server_id': data['server_id'],
        'address': data['address'] is String ? data['address'] : jsonEncode(data['address'] ?? {}),
        'geo_location': data['geo_location'] is String ? data['geo_location'] : jsonEncode(data['geo_location'] ?? {}),
        'head_id': data['head_id'],
        'household_info': householdInfo is String
            ? householdInfo
            : jsonEncode(householdInfo ?? {}),
        'device_details': data['device_details'] is String
            ? data['device_details']
            : jsonEncode(data['device_details'] ?? {}),
        'app_details': data['app_details'] is String
            ? data['app_details']
            : jsonEncode(data['app_details'] ?? {}),
        'parent_user': data['parent_user'] is String
            ? data['parent_user']
            : jsonEncode(data['parent_user'] ?? {}),
        'current_user_key': data['current_user_key'],
        'facility_id': data['facility_id'],
        // Keep original created_date_time in DB; only update modified_date_time
        'modified_date_time': data['modified_date_time'],
        'is_synced': data['is_synced'] ?? 0,
        'is_deleted': data['is_deleted'] ?? 0,
      };

      final changes = await db.update(
        'households',
        row,
        where: 'unique_key = ?',
        whereArgs: [data['unique_key']],
      );
      return changes;
    } catch (e, stackTrace) {
      print('Error updating household by unique_key:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> updateHouseholdServerIdByUniqueKey({required String uniqueKey, required String serverId}) async {
    try {
      final db = await _db;
      final changes = await db.update(
        'households',
        {
          'server_id': serverId,
          // 'is_synced': 1,
          'modified_date_time': DateTime.now().toIso8601String(),
        },
        where: 'unique_key = ?',
        whereArgs: [uniqueKey],
      );
      return changes;
    } catch (e) {
      print('Error updating household server_id by unique_key: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedHouseholds() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'households',
        where: 'is_deleted = 0 AND (is_synced IS NULL OR is_synced = 0)',
        orderBy: 'created_date_time ASC',
      );
      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['address'] = safeJsonDecode(mapped['address']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['household_info'] = safeJsonDecode(mapped['household_info']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
        return mapped;
      }).toList();
    } catch (e) {
      print('Error getting unsynced households: $e');
      rethrow;
    }
  }

  Future<int> markHouseholdSyncedByUniqueKey({required String uniqueKey, String? serverId}) async {
    try {
      final db = await _db;
      final values = <String, Object?>{
        'is_synced': 1,
        'modified_date_time': DateTime.now().toIso8601String(),
      };
      if (serverId != null && serverId.isNotEmpty) {
        values['server_id'] = serverId;
      }
      final changes = await db.update(
        'households',
        values,
        where: 'unique_key = ?',
        whereArgs: [uniqueKey],
      );
      return changes;
    } catch (e) {
      print('Error marking household as synced: $e');
      rethrow;
    }
  }

  Future<int> insertBeneficiary(Map<String, dynamic> data) async {
    final db = await _db;
    final row = <String, dynamic>{
      'server_id': data['server_id'],
      'household_ref_key': data['household_ref_key'],
      'unique_key': data['unique_key'],
      'beneficiary_state': data['beneficiary_state'] is List
          ? jsonEncode(data['beneficiary_state'])
          : data['beneficiary_state'],
      'pregnancy_count': data['pregnancy_count'],
      'beneficiary_info': _encodeIfObject(data['beneficiary_info']),
      'geo_location': _encodeIfObject(data['geo_location']),
      'spouse_key': data['spouse_key'],
      'mother_key': data['mother_key'],
      'father_key': data['father_key'],
      'is_family_planning': data['is_family_planning'] ?? 0,
      'is_adult': data['is_adult'] ?? 0,
      'is_guest': data['is_guest'] ?? 0,
      'is_death': data['is_death'] ?? 0,
      'death_details': _encodeIfObject(data['death_details']),
      'is_migrated': data['is_migrated'] ?? 0,
      'is_separated': data['is_separated'] ?? 0,
      'device_details': _encodeIfObject(data['device_details']),
      'app_details': _encodeIfObject(data['app_details']),
      'parent_user': _encodeIfObject(data['parent_user']),
      'current_user_key': data['current_user_key'],
      'facility_id': data['facility_id'],
      'created_date_time': data['created_date_time'],
      'modified_date_time': data['modified_date_time'],
      'is_synced': data['is_synced'] ?? 0,
      'is_deleted': data['is_deleted'] ?? 0,
    };
    return db.insert('beneficiaries_new', row);
  }

  Future<int> insertEligibleCoupleActivity(Map<String, dynamic> data) async {
    final db = await _db;
    final row = <String, dynamic>{
      'server_id': data['server_id'],
      'household_ref_key': data['household_ref_key'],
      'beneficiary_ref_key': data['beneficiary_ref_key'],
      'eligible_couple_state': data['eligible_couple_state'],
      'device_details': _encodeIfObject(data['device_details']),
      'app_details': _encodeIfObject(data['app_details']),
      'parent_user': _encodeIfObject(data['parent_user']),
      'current_user_key': data['current_user_key'],
      'facility_id': data['facility_id'],
      'created_date_time': data['created_date_time'],
      'modified_date_time': data['modified_date_time'],
      'is_synced': data['is_synced'] ?? 0,
      'is_deleted': data['is_deleted'] ?? 0,
    };
    return db.insert('eligible_couple_activities', row);
  }

  Future<int> insertMotherCareActivity(Map<String, dynamic> data) async {
    final db = await _db;
    final row = <String, dynamic>{
      'server_id': data['server_id'],
      'household_ref_key': data['household_ref_key'],
      'beneficiary_ref_key': data['beneficiary_ref_key'],
      'mother_care_state': data['mother_care_state'],
      'device_details': _encodeIfObject(data['device_details']),
      'app_details': _encodeIfObject(data['app_details']),
      'parent_user': _encodeIfObject(data['parent_user']),
      'current_user_key': data['current_user_key'],
      'facility_id': data['facility_id'],
      'created_date_time': data['created_date_time'],
      'modified_date_time': data['modified_date_time'],
      'is_synced': data['is_synced'] ?? 0,
      'is_deleted': data['is_deleted'] ?? 0,
    };
    return db.insert('mother_care_activities', row);
  }

  Future<int> insertChildCareActivity(Map<String, dynamic> data) async {
    final db = await _db;
    final row = <String, dynamic>{
      'server_id': data['server_id'],
      'household_ref_key': data['household_ref_key'],
      'beneficiary_ref_key': data['beneficiary_ref_key'],
      'mother_key': data['mother_key'],
      'father_key': data['father_key'],
      'child_care_state': data['child_care_state'],
      'device_details': _encodeIfObject(data['device_details']),
      'app_details': _encodeIfObject(data['app_details']),
      'parent_user': _encodeIfObject(data['parent_user']),
      'current_user_key': data['current_user_key'],
      'facility_id': data['facility_id'],
      'created_date_time': data['created_date_time'],
      'modified_date_time': data['modified_date_time'],
      'is_synced': data['is_synced'] ?? 0,
      'is_deleted': data['is_deleted'] ?? 0,
    };
    return db.insert('child_care_activities', row);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMotherCareAncForms() async {
    try {
      final db = await _db;
      final ancFormsRefKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration] ?? '';
      if (ancFormsRefKey.isEmpty) return [];

      final rows = await db.query(
        FollowupFormDataTable.table,
        where:
        '(is_deleted IS NULL OR is_deleted = 0) AND (is_synced IS NULL OR is_synced = 0) AND (server_id IS NULL OR TRIM(server_id) = "") AND forms_ref_key = ?',
        whereArgs: [ancFormsRefKey],
        orderBy: 'created_date_time ASC',
      );

      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    } catch (e) {
      print('Error getting unsynced mother care ANC forms: $e');
      return [];
    }
  }

  Future<int> markMotherCareAncFormSyncedById(int id, {String? serverId}) async {
    try {
      final db = await _db;
      final values = <String, Object?>{
        'is_synced': 1,
        'modified_date_time': DateTime.now().toIso8601String(),
      };
      if (serverId != null && serverId.isNotEmpty) {
        values['server_id'] = serverId;
      }
      return await db.update(
        FollowupFormDataTable.table,
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error marking mother care ANC form as synced: $e');
      rethrow;
    }
  }

  Future<int> insertFollowupFormData(Map<String, dynamic> data) async {
    final db = await _db;

    final row = <String, dynamic>{
      'server_id': data['server_id'],
      'forms_ref_key': data['forms_ref_key'],
      'household_ref_key': data['household_ref_key'],
      'beneficiary_ref_key': data['beneficiary_ref_key'],
      'mother_key': data['mother_key'],
      'father_key': data['father_key'],
      'child_care_state': data['child_care_state'],
      'device_details': _encodeIfObject(data['device_details']),
      'app_details': _encodeIfObject(data['app_details']),
      'parent_user': _encodeIfObject(data['parent_user']),
      'current_user_key': data['current_user_key'],
      'facility_id': data['facility_id'],
      'form_json': data['form_json'],
      'created_date_time': data['created_date_time'],
      'modified_date_time': data['modified_date_time'],
      'is_synced': data['is_synced'] ?? 0,
      'is_deleted': data['is_deleted'] ?? 0,
    };

    final id = await db.insert('followup_form_data', row);
    return id;
  }

  Future<int> getHouseholdCount() async {
    final db = await _db;


    final count = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(DISTINCT h.unique_key) AS household_count
      FROM households h
      INNER JOIN beneficiaries_new b
        ON b.household_ref_key = h.unique_key
      WHERE h.is_deleted = 0
        AND b.is_deleted = 0
        AND b.is_migrated = 0
        AND b.is_death = 0
    '''));

    return count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getFollowupFormsWithCaseClosure(String formType) async {
    final db = await _db;

    final forms = await db.query(
      FollowupFormDataTable.table,
      where: ' form_json LIKE ?',
      whereArgs: ['%case_closure%'],
    );

    final List<Map<String, dynamic>> result = [];

    for (final form in forms) {
      try {
        final formJson = form['form_json'] as String?;
        if (formJson == null || formJson.isEmpty) continue;

        final formData = jsonDecode(formJson);

        if (formData is Map && formData['form_data'] is Map) {
          final formDataMap = Map<String, dynamic>.from(formData['form_data'] as Map);
          final caseClosure = formDataMap['case_closure'] is Map
              ? Map<String, dynamic>.from(formDataMap['case_closure'] as Map)
              : null;

          if (caseClosure != null &&
              caseClosure['is_case_closure'] == true &&
              caseClosure['date_of_death'] != null) {

            final childDetails = formDataMap['child_details'] is Map
                ? Map<String, dynamic>.from(formDataMap['child_details'] as Map)
                : formDataMap;
            final registrationData = formDataMap['registration_data'] is Map
                ? Map<String, dynamic>.from(formDataMap['registration_data'] as Map)
                : {};

            String beneficiaryRefKey = form['beneficiary_ref_key']?.toString() ?? '';
            Map<String, dynamic> beneficiaryData = {};

            if (beneficiaryRefKey.isNotEmpty) {
              try {
                final beneficiaryRows = await db.query(
                  'beneficiaries_new',
                  where: 'beneficiary_ref_key = ?',
                  whereArgs: [beneficiaryRefKey],
                  limit: 1,
                );

                if (beneficiaryRows.isNotEmpty) {
                  beneficiaryData = beneficiaryRows.first;

                  if (beneficiaryData['registration_type_followup'] is String) {
                    try {
                      beneficiaryData['registration_type_followup'] =
                          jsonDecode(beneficiaryData['registration_type_followup']);
                    } catch (e) {
                      print('Error parsing registration_type_followup: $e');
                    }
                  }

                  print('Found beneficiary data for key: $beneficiaryRefKey');
                  print('Beneficiary data: $beneficiaryData');
                }
              } catch (e) {
                print('Error fetching beneficiary data: $e');
              }
            }

            final beneficiaryId = formDataMap['beneficiary_id'] ?? formDataMap['beneficiary_ref_key'] ?? '';
            final householdId = formDataMap['household_id'] ?? formDataMap['household_ref_key'] ?? '';

            print(' Extracted from formDataMap:');
            print('  beneficiary_id: $beneficiaryId');
            print('  household_id: $householdId');
            print('  All formDataMap keys: ${formDataMap.keys.toList()}');

            result.add({
              'id': form['id'],
              'form_data': formDataMap,
              'registration_data': registrationData,
              'child_details': childDetails,
              'case_closure': caseClosure,
              'beneficiary_data': beneficiaryData,
              'name': childDetails['name'] ??
                  '${childDetails['first_name'] ?? ''} ${childDetails['last_name'] ?? ''}'.trim(),
              'date_of_death': caseClosure['date_of_death'],
              'cause_of_death': caseClosure['probable_cause_of_death'] ?? 'Not specified',
              'death_place': caseClosure['death_place'] ?? 'Not specified',
              'reason': caseClosure['reason_of_death'] ?? 'Not specified',
              'beneficiary_id': beneficiaryId,
              'rch_id': formDataMap['rch_id'] ?? '',
              'household_id': householdId,
              'mobile_number': formDataMap['mobile_number'] ?? formDataMap['contact_number'] ?? '',
              'father_name': childDetails['father_name'] ?? formDataMap['father_name'] ?? '',
              'mother_name': childDetails['mother_name'] ?? formDataMap['mother_name'] ?? '',
              'age': childDetails['age']?.toString() ?? formDataMap['age']?.toString() ?? '',
              'gender': childDetails['gender'] ?? formDataMap['gender'] ?? '',
              'registration_date': registrationData['registration_date'] ?? formDataMap['registration_date'] ?? '',
            });
          }
        }
      } catch (e) {
        print('Error processing form ${form['id']}: $e');
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getHighRiskANCVisits() async {
    final db = await _db;

    final forms = await db.query(
      FollowupFormDataTable.table,
      where: 'is_deleted = 0 AND forms_ref_key = ?',
      whereArgs: [
        FollowupFormDataTable.formUniqueKeys[
        FollowupFormDataTable.ancDueRegistration
        ],
      ],
      orderBy: 'created_date_time DESC',
    );

    final List<Map<String, dynamic>> result = [];

    for (final form in forms) {
      try {
        final formJson = form['form_json'] as String?;
        if (formJson == null || formJson.isEmpty) continue;

        final decoded = jsonDecode(formJson);
        if (decoded is! Map || decoded['form_data'] is! Map) continue;

        final formData = Map<String, dynamic>.from(decoded['form_data'] as Map);

        final hr = formData['high_risk'];
        final bool isHighRisk =
            hr == true ||
                hr == 1 ||
                (hr is String &&
                    (hr.toLowerCase() == 'true' || hr.toLowerCase() == 'yes' || hr == '1'));

        if (!isHighRisk) continue;

        result.add({
          'id': form['id'],
          'forms_ref_key': form['forms_ref_key'],
          'household_ref_key': form['household_ref_key'],
          'beneficiary_ref_key': form['beneficiary_ref_key'],
          'created_date_time': form['created_date_time'],
          'modified_date_time': form['modified_date_time'],
          'form_data': formData,
        });
      } catch (e) {
        print('Error processing high-risk ANC form ${form['id']}: $e');
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllHouseholds() async {
    try {
      final db = await _db;

      final rows = await db.query('households',
          where: 'is_deleted = ?',
          whereArgs: [0],
          orderBy: 'created_date_time DESC');

      final result = rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);

        mapped['address'] = safeJsonDecode(mapped['address']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['household_info'] = safeJsonDecode(mapped['household_info']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);

        return mapped;
      }).toList();
      return result;

    } catch (e, stackTrace) {
      print('Error getting households: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> getBeneficiariesDashboardCount() async {
    try {
      final rows = await getAllBeneficiaries();

      final householdMap = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final hhId = row['household_ref_key']?.toString() ?? '';
        if (hhId.isEmpty) continue;

        final info = (row['beneficiary_info'] as Map?) ?? <String, dynamic>{};
        String relationToHead =
            (info['relation_to_head']?.toString().toLowerCase().trim() ?? '');

        householdMap.putIfAbsent(hhId, () => {
              'hasHead': false,
              'hasSpouse': false,
              'childrenCount': 0,
            });

        final bucket = householdMap[hhId]!;

        if (relationToHead == 'self' || relationToHead.isEmpty) {
          bucket['hasHead'] = true;
        } else if (relationToHead == 'spouse') {
          bucket['hasSpouse'] = true;
        } else if (relationToHead == 'child' ||
            info['memberType']?.toString().toLowerCase() == 'child') {
          bucket['childrenCount'] = (bucket['childrenCount'] as int) + 1;
        }
      }

      int total = 0;
      for (final entry in householdMap.values) {
        if (entry['hasHead'] == true) total++;
        if (entry['hasSpouse'] == true) total++;
        total += (entry['childrenCount'] as int);
      }

      return total;
    } catch (e) {
      print('Error computing beneficiaries dashboard count: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBeneficiariesByHousehold(String householdId) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        where: 'household_ref_key = ? AND is_deleted = ?',
        whereArgs: [householdId, 0],
      );

      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['death_details'] = safeJsonDecode(mapped['death_details']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
        return mapped;
      }).toList();
    } catch (e) {
      print('Error getting beneficiaries by household: $e');
      rethrow;
    }
  }

  Future<int> updateBeneficiary(Map<String, dynamic> data) async {
    try {
      final db = await _db;
      final id = data['id'];
      if (id == null) throw Exception('Beneficiary ID is required for update');

      final row = Map<String, dynamic>.from(data);
      row.remove('id');

      // Convert nested objects to JSON strings
      if (row['beneficiary_info'] is Map) {
        row['beneficiary_info'] = jsonEncode(row['beneficiary_info']);
      }
      if (row['geo_location'] is Map) {
        row['geo_location'] = jsonEncode(row['geo_location']);
      }
      if (row['death_details'] is Map) {
        row['death_details'] = jsonEncode(row['death_details']);
      }
      if (row['device_details'] is Map) {
        row['device_details'] = jsonEncode(row['device_details']);
      }
      if (row['app_details'] is Map) {
        row['app_details'] = jsonEncode(row['app_details']);
      }
      if (row['parent_user'] is Map) {
        row['parent_user'] = jsonEncode(row['parent_user']);
      }

      row['modified_date_time'] = DateTime.now().toIso8601String();

      return await db.update(
        'beneficiaries_new',
        row,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error updating beneficiary: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllBeneficiaries() async {
    try {
      final db = await _db;
      final rows = await db.query('beneficiaries_new',
          // where: 'is_deleted = ?',
          // whereArgs: [0],
          orderBy: 'created_date_time DESC');
      final result = rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['death_details'] = safeJsonDecode(mapped['death_details']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
        return mapped;
      }).toList();
      return result;
    } catch (e, stackTrace) {
      print('Error getting beneficiaries: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedBeneficiaries() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        where: 'is_deleted = 0 AND (is_synced IS NULL OR is_synced = 0)',
        orderBy: 'created_date_time ASC',
      );
      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['death_details'] = safeJsonDecode(mapped['death_details']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
        return mapped;
      }).toList();
    } catch (e) {
      print('Error getting unsynced beneficiaries: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHbncListTodaysProgram() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        orderBy: 'created_date_time ASC',
      );
      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['death_details'] = safeJsonDecode(mapped['death_details']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
        return mapped;
      }).toList();
    } catch (e) {
      print('Error getting unsynced beneficiaries: $e');
      rethrow;
    }
  }


  Future<int> markBeneficiarySyncedByUniqueKey({required String uniqueKey, String? serverId}) async {
    try {
      final db = await _db;
      final values = <String, Object?>{
        'is_synced': 1,
        'modified_date_time': DateTime.now().toIso8601String(),
      };
      if (serverId != null && serverId.isNotEmpty) {
        values['server_id'] = serverId;
      }
      final changes = await db.update(
        'beneficiaries_new',
        values,
        where: 'unique_key = ?',
        whereArgs: [uniqueKey],
      );
      return changes;
    } catch (e) {
      print('Error marking beneficiary as synced: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> debugDeathRecords() async {
    try {
      final db = await _db;

      // Check total records count
      final countResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN is_death = 1 THEN 1 ELSE 0 END) as death_count,
          SUM(CASE WHEN is_death = 1 AND is_deleted = 0 THEN 1 ELSE 0 END) as valid_death_count
        FROM ${BeneficiariesTable.table}
      ''');

      // Get sample death records
      final sampleRecords = await db.query(
        BeneficiariesTable.table,
        where: 'is_death = 1 AND is_deleted = 0',
        limit: 5,
      );

      return {
        'counts': countResult.first,
        'sample_records': sampleRecords,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getDeathRecords() async {
    try {
      print('🔍 [getDeathRecords] Querying death records...');
      final db = await _db;

      // First, run debug query
      final debugInfo = await debugDeathRecords();
      print('🔍 [getDeathRecords] Debug Info: $debugInfo');

      final rows = await db.query(
        BeneficiariesTable.table,
        where: 'is_death = 1 AND is_deleted = 0',
        orderBy: 'created_date_time DESC',
      );

      print('✅ [getDeathRecords] Found ${rows.length} death records');

      return rows.map((row) {
        try {
          final mapped = Map<String, dynamic>.from(row);
          // Parse JSON fields
          mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
          mapped['death_details'] = safeJsonDecode(mapped['death_details']);
          mapped['device_details'] = safeJsonDecode(mapped['device_details']);
          mapped['app_details'] = safeJsonDecode(mapped['app_details']);
          mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
          return mapped;
        } catch (e) {
          print('❌ Error parsing record $row: $e');
          return <String, dynamic>{}; // Return empty map on parse error
        }
      }).where((map) => map.isNotEmpty).toList(); // Filter out any empty maps from failed parses
    } catch (e, stackTrace) {
      print('❌ [getDeathRecords] Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMigratedBeneficiaries() async {
    try {
      print('🔍 [getMIGRecords] Querying  mig records...');
      final db = await _db;

      final debugInfo = await debugDeathRecords();
      print('🔍 [getMIGRecords] Debug Info: $debugInfo');

      final rows = await db.query(
        BeneficiariesTable.table,
        where: 'is_migrated = 1 AND is_deleted = 0',
        orderBy: 'created_date_time DESC',
      );

      print('✅ [getDeathRecords] Found ${rows.length} death records');

      return rows.map((row) {
        try {
          final mapped = Map<String, dynamic>.from(row);
          // Parse JSON fields
          mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
          mapped['death_details'] = safeJsonDecode(mapped['death_details']);
          mapped['device_details'] = safeJsonDecode(mapped['device_details']);
          mapped['app_details'] = safeJsonDecode(mapped['app_details']);
          mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
          return mapped;
        } catch (e) {
          print('❌ Error parsing record $row: $e');
          return <String, dynamic>{}; // Return empty map on parse error
        }
      }).where((map) => map.isNotEmpty).toList(); // Filter out any empty maps from failed parses
    } catch (e, stackTrace) {
      print('❌ [getDeathRecords] Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  Future<List<Map<String, dynamic>>> getANCList() async {
    try {
      final db = await _db;
      final rows = await db.query('beneficiaries_new',
          where: 'is_deleted = ?',
          whereArgs: [0],
          orderBy: 'created_date_time DESC');
      final result = rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['death_details'] = safeJsonDecode(mapped['death_details']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
        return mapped;
      }).toList();
      return result;
    } catch (e, stackTrace) {
      print('Error getting beneficiaries: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  Future<int> updateBeneficiaryDeleteAndSyncFlagByUniqueKey({
    required String uniqueKey,
    required int isDeleted,
  }) async {
    try {
      final db = await _db;
      final changes = await db.update(
        'beneficiaries_new',
        {
          'is_deleted': isDeleted,
          'is_synced': 0,
          'modified_date_time': DateTime.now().toIso8601String(),
        },
        where: 'unique_key = ?',
        whereArgs: [uniqueKey],
      );
      return changes;
    } catch (e) {
      print('Error updating beneficiary delete/sync flags by unique_key: $e');
      rethrow;
    }
  }

  Future<String> getLatestHouseholdServerId() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'households',
        columns: ['server_id', 'created_date_time', 'modified_date_time', 'id', 'is_deleted'],
        where:
              "server_id IS NOT NULL AND TRIM(server_id) != '' AND COALESCE(modified_date_time, created_date_time) <= datetime('now','-2 minutes')",

        orderBy: "COALESCE(modified_date_time, created_date_time) DESC, id DESC",
        limit: 1,
      );
      if (rows.isEmpty) return '';
      final sid = rows.first['server_id'];
      return sid?.toString() ?? '';
    } catch (e) {
      print('Error getting latest household server_id: $e');
      return '';
    }
  }

  Future<int> saveGuestBeneficiary(GuestBeneficiary beneficiary) async {
    try {
      final db = await _db;
      final Map<String, dynamic> beneficiaryMap = beneficiary.toMap();

      if (!beneficiaryMap.containsKey('current_user_key') || (beneficiaryMap['current_user_key'] == null)) {
        beneficiaryMap['current_user_key'] = '';
      }
      if (!beneficiaryMap.containsKey('facility_id') || (beneficiaryMap['facility_id'] == null)) {
        beneficiaryMap['facility_id'] = 0;
      }
      if (!beneficiaryMap.containsKey('parent_user') || (beneficiaryMap['parent_user'] == null)) {
        beneficiaryMap['parent_user'] = jsonEncode({});
      }
      if (!beneficiaryMap.containsKey('app_details') || (beneficiaryMap['app_details'] == null)) {
        beneficiaryMap['app_details'] = jsonEncode({
          'app_name': 'BHAVYAmASHA',
          'version': '1.0.0',
        });
      }
      if (!beneficiaryMap.containsKey('device_details') || (beneficiaryMap['device_details'] == null)) {
        beneficiaryMap['device_details'] = jsonEncode({
          'platform': 'mobile',
          'os': 'android',
        });
      }
      beneficiaryMap['is_guest'] = 1;

      final existing = await db.query(
        BeneficiariesTable.table,
        where: 'unique_key = ?',
        whereArgs: [beneficiary.uniqueKey],
      );

      if (existing.isNotEmpty) {
        // Update existing record
        final affected = await db.update(
          BeneficiariesTable.table,
          beneficiaryMap,
          where: 'unique_key = ?',
          whereArgs: [beneficiary.uniqueKey],
        );
        try {
          final savedRows = await db.query(
            BeneficiariesTable.table,
            where: 'unique_key = ?',
            whereArgs: [beneficiary.uniqueKey],
            limit: 1,
          );
          if (savedRows.isNotEmpty) {
            final row = Map<String, dynamic>.from(savedRows.first);
            try {
              row['beneficiary_info'] = safeJsonDecode(row['beneficiary_info']?.toString());
              row['death_details'] = safeJsonDecode(row['death_details']?.toString());
              row['device_details'] = safeJsonDecode(row['device_details']?.toString());
              row['app_details'] = safeJsonDecode(row['app_details']?.toString());
              row['parent_user'] = safeJsonDecode(row['parent_user']?.toString());
            } catch (_) {}
            print('Saved beneficiary row (update): ${jsonEncode(row)}');
          }
        } catch (_) {}
        return affected;
      } else {
        // Insert new record
        final insertedId = await db.insert(
          BeneficiariesTable.table,
          beneficiaryMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        try {
          final savedRows = await db.query(
            BeneficiariesTable.table,
            where: 'unique_key = ?',
            whereArgs: [beneficiary.uniqueKey],
            limit: 1,
          );
          if (savedRows.isNotEmpty) {
            final row = Map<String, dynamic>.from(savedRows.first);
            try {
              row['beneficiary_info'] = safeJsonDecode(row['beneficiary_info']?.toString());
              row['death_details'] = safeJsonDecode(row['death_details']?.toString());
              row['device_details'] = safeJsonDecode(row['device_details']?.toString());
              row['app_details'] = safeJsonDecode(row['app_details']?.toString());
              row['parent_user'] = safeJsonDecode(row['parent_user']?.toString());
            } catch (_) {}
            print('Saved beneficiary row (insert): ${jsonEncode(row)}');
          }
        } catch (_) {}
        return insertedId;
      }
    } catch (e) {
      print('Error saving guest beneficiary: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getHouseholdByUniqueKey(String uniqueKey) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'households',
        where: 'unique_key = ? AND is_deleted = 0',
        whereArgs: [uniqueKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final mapped = Map<String, dynamic>.from(rows.first);
      mapped['address'] = safeJsonDecode(mapped['address']);
      mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
      mapped['household_info'] = safeJsonDecode(mapped['household_info']);
      mapped['device_details'] = safeJsonDecode(mapped['device_details']);
      mapped['app_details'] = safeJsonDecode(mapped['app_details']);
      mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
      return mapped;
    } catch (e) {
      print('Error getting household by unique_key: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getHouseholdByServerId(String serverId) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'households',
        where: 'server_id = ? AND is_deleted = 0',
        whereArgs: [serverId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final mapped = Map<String, dynamic>.from(rows.first);
      mapped['address'] = safeJsonDecode(mapped['address']);
      mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
      mapped['household_info'] = safeJsonDecode(mapped['household_info']);
      mapped['device_details'] = safeJsonDecode(mapped['device_details']);
      mapped['app_details'] = safeJsonDecode(mapped['app_details']);
      mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
      return mapped;
    } catch (e) {
      print('Error getting household by server_id: $e');
      return null;
    }
  }

  Future<int> insertTrainingData(Map<String, dynamic> data) async {
    try {
      final db = await _db;
      final row = Map<String, dynamic>.from(data);
      return await db.insert(TrainingDataTable.table, row);
    } catch (e) {
      print('Error inserting training data: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedChildCareActivities() async {
    final db = await _db;
    final rows = await db.query(
      'child_care_activities',
      where: 'is_deleted = 0 AND (is_synced IS NULL OR is_synced = 0)',
      orderBy: 'created_date_time ASC',
    );
    return rows.map((row) {
      final mapped = Map<String, dynamic>.from(row);
      mapped['device_details'] = safeJsonDecode(mapped['device_details']);
      mapped['app_details'] = safeJsonDecode(mapped['app_details']);
      mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
      return mapped;
    }).toList();
  }

  Future<int> markChildCareActivitySyncedById(int id, {String? serverId}) async {
    final db = await _db;
    final values = <String, Object?>{
      'is_synced': 1,
      'modified_date_time': DateTime.now().toIso8601String(),
    };
    if (serverId != null && serverId.isNotEmpty) values['server_id'] = serverId;
    return db.update('child_care_activities', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getLatestFollowupFormServerId() async {
    try {
      final db = await _db;
      final rows = await db.query(
        FollowupFormDataTable.table,
        columns: ['server_id', 'created_date_time', 'modified_date_time', 'id', 'is_deleted'],
        where:
              "server_id IS NOT NULL AND TRIM(server_id) != '' AND COALESCE(modified_date_time, created_date_time) <= datetime('now','-5 minutes')",

        orderBy: "COALESCE(modified_date_time, created_date_time) DESC, id DESC",
        limit: 1,
      );

      if (rows.isEmpty) return '';
      final sid = rows.first['server_id'];
      return sid?.toString() ?? '';
    } catch (e) {
      print('Error getting latest followup form server_id: $e');
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> getFollowupFormsByHouseholdAndBeneficiary({
    required String formType,
    required String householdId,
    required String beneficiaryId,
  }) async {
    try {
      final db = await _db;
      final result = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND household_ref_key = ? AND beneficiary_ref_key = ?',
        whereArgs: [
          FollowupFormDataTable.formUniqueKeys[formType],
          householdId,
          beneficiaryId,
        ],
        orderBy: 'created_date_time DESC',
      );

      return result;
    } catch (e) {
      print('Error getting followup forms: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPncMotherFormsByBeneficiaryId(String beneficiaryId) async {
    try {
      final db = await _db;
      final result = await db.query(
        FollowupFormDataTable.table,
        where: 'forms_ref_key = ? AND beneficiary_ref_key = ?',
        whereArgs: [
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.pncMother],
          beneficiaryId,
        ],
        orderBy: 'created_date_time DESC',
      );

      // Parse form_json for each result
      return result.map((form) {
        final formData = Map<String, dynamic>.from(form);
        try {
          if (formData['form_json'] != null) {
            formData['form_data'] = jsonDecode(formData['form_json']);
          }
        } catch (e) {
          print('Error parsing form_json: $e');
        }
        return formData;
      }).toList();
    } catch (e) {
      print('Error getting PNC Mother forms: $e');
      return [];
    }
  }

  Future<void> insertNotifications(List<Map<String, dynamic>> list) async {
    try {
      final db = await _db;
      final batch = db.batch();

      for (var data in list) {
        // Check if a record with the same unique_key exists
        final existingRecords = await db.query(
          NotificationDetailsTable.table,
          where: 'unique_key = ?',
          whereArgs: [data['unique_key']],
        );

        if (existingRecords.isEmpty) {
          // Insert new record if it doesn't exist
          batch.insert(
            NotificationDetailsTable.table,
            {
              '_id': data['_id'],
              'unique_key': data['unique_key'],
              'added_date_time': data['added_date_time'],
              'announcement_end_period': data['announcement_end_period'],
              'announcement_for': data['announcement_for'],
              'announcement_start_period': data['announcement_start_period'],
              'announcement_type': data['announcement_type'],
              'block_id': data['block_id'],
              'block_name': data['block_name'],
              'content_en': data['content_en'],
              'content_hi': data['content_hi'],
              'district_id': data['district_id'],
              'district_name': data['district_name'],
              'state_id': data['state_id'],
              'state_name': data['state_name'],
              'title_en': data['title_en'],
              'title_hi': data['title_hi'],
              'modified_date_time': data['modified_date_time'],
              'option': data['option'],
              'is_deleted': data['is_deleted'] ?? 0,
              'is_published': data['is_published'] ?? 1,
              '__v': data['__v'],
              'is_read': 0,
              'is_synced': 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          // Optionally update the existing record
          batch.update(
            NotificationDetailsTable.table,
            {
              'added_date_time': data['added_date_time'],
              'announcement_end_period': data['announcement_end_period'],
              'announcement_for': data['announcement_for'],
              'announcement_start_period': data['announcement_start_period'],
              'announcement_type': data['announcement_type'],
              'block_id': data['block_id'],
              'block_name': data['block_name'],
              'content_en': data['content_en'],
              'content_hi': data['content_hi'],
              'district_id': data['district_id'],
              'district_name': data['district_name'],
              'state_id': data['state_id'],
              'state_name': data['state_name'],
              'title_en': data['title_en'],
              'title_hi': data['title_hi'],
              'modified_date_time': data['modified_date_time'],
              'option': data['option'],
              'is_deleted': data['is_deleted'] ?? 0,
              'is_published': data['is_published'] ?? 1,
              '__v': data['__v'],
              'is_synced': 0,
            },
            where: 'unique_key = ?',
            whereArgs: [data['unique_key']],
          );
        }
      }

      await batch.commit(noResult: true);
    } catch (e, s) {
      print("Error inserting notifications batch: $e\n$s");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final db = await _db;
      return await db.query(
        NotificationDetailsTable.table,
        where: "is_deleted = 0",
        orderBy: "added_date_time DESC",
      );
    } catch (e) {
      print("Error fetching notifications: $e");
      rethrow;
    }
  }
}

   extension LocalStorageDaoReads on LocalStorageDao {
  Future<String> getLatestBeneficiaryServerId() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        columns: ['server_id'],
        where:
            "server_id IS NOT NULL AND TRIM(server_id) != '' AND COALESCE(modified_date_time, created_date_time) <= datetime('now','-2 minutes')",

        orderBy: "CAST(server_id AS INTEGER) DESC",
        limit: 1,
      );
      if (rows.isEmpty) return '';
      final sid = rows.first['server_id'];
      return sid?.toString() ?? '';
    } catch (e) {
      print('Error getting latest beneficiary server_id: $e');
      return '';
    }
  }
}