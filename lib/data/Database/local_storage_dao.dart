import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:medixcel_new/data/Database/tables/beneficiaries_table.dart';
import 'package:medixcel_new/data/Database/tables/cluster_meeting_table.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/Database/tables/mother_care_activities_table.dart';
import 'package:medixcel_new/data/Database/tables/notification_table.dart';
import 'package:medixcel_new/data/Database/tables/training_data_table.dart';
import 'package:medixcel_new/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';

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

  Future<Map<String, dynamic>?> getCurrentUserFromDb() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'users',
        where: 'is_deleted = 0',
        orderBy: 'id DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return Map<String, dynamic>.from(rows.first);
    } catch (e) {
      print('Error fetching current user from users table: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getChildTrackingDueFor16Year() async {
    print('Executing getChildTrackingDueFor16Year query...');
    try {
      final db = await _db;

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

  Future<int> getHouseholdTotalCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM households WHERE is_deleted = 0'),
    );
    return count ?? 0;
  }

  Future<int> getHouseholdSyncedCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM households WHERE is_deleted = 0 AND is_synced = 1',
      ),
    );
    return count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getChildTrackingDueFor9Year() async {
    print('Executing getChildTrackingDueFor9Year query...');
    try {
      final db = await _db;

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

  Future<List<Map<String, dynamic>>> getChildTrackingForBirthDose() async {
    return _getChildTrackingForAgeGroup(
      '"current_tab"%Birth dose%',
      'Birth dose',
    );
  }

  Future<List<Map<String, dynamic>>> getChildTrackingFor6Weeks() async {
    return _getChildTrackingForAgeGroup('"current_tab"%6 WEEK%', '6 WEEK');
  }

  Future<List<Map<String, dynamic>>> getChildTrackingFor10Weeks() async {
    final patterns = [
      '"current_tab":"10 WEEK"',
      '"current_tab" : "10 WEEK"', // with spaces around colon
      'current_tab":"10 WEEK', // missing first quote
      '10 WEEK', // just the value
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
    return [];
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

  Future<List<Map<String, dynamic>>> _getChildTrackingForAgeGroup(
    String likePattern,
    String logName,
  ) async {
    print('Executing query for $logName with pattern: $likePattern');
    try {
      final db = await _db;
      final rows = await db.rawQuery(
        '''
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
    ''',
        ['%$likePattern%', '%$likePattern%'],
      );

      print('Found ${rows.length} latest entries for $logName tracking forms');
      if (rows.isNotEmpty) {
        print(
          'First row preview: ${rows.first.toString().substring(0, min(200, rows.first.toString().length))}',
        );
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

  Future<int> setBeneficiaryMigratedByUniqueKey({
    required String uniqueKey,
    required int isMigrated,
  }) async {
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

  Future<List<Map<String, dynamic>>>
  getUnsyncedEligibleCoupleActivities() async {
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

  Future<List<Map<String, dynamic>>> getEligibleCoupleActivities() async {
    final db = await _db;
    final rows = await db.query(
      'eligible_couple_activities',
      where: 'is_deleted = 0',
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

  Future<int> markEligibleCoupleActivitySyncedById(
    int id, {
    String? serverId,
  }) async {
    final db = await _db;
    final values = <String, Object?>{
      'is_synced': 1,
      'modified_date_time': DateTime.now().toIso8601String(),
    };
    if (serverId != null && serverId.isNotEmpty) values['server_id'] = serverId;
    return db.update(
      'eligible_couple_activities',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> getLatestEligibleCoupleActivityServerId() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      final db = await _db;
      final rows = await db.query(
        'eligible_couple_activities',
        columns: [
          'server_id',
          'created_date_time',
          'modified_date_time',
          'id',
          'is_deleted',
        ],
        where:
            "server_id IS NOT NULL AND TRIM(server_id) != '' AND current_user_key = ?",
        whereArgs: [ashaUniqueKey],
        orderBy: "id DESC",
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
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      final db = await _db;
      final rows = await db.query(
        'child_care_activities',
        columns: [
          'server_id',
          'created_date_time',
          'modified_date_time',
          'id',
          'is_deleted',
        ],
        where:
            "server_id IS NOT NULL AND TRIM(server_id) != ''  AND current_user_key = ?",
        whereArgs: [ashaUniqueKey],
        orderBy: "created_date_time DESC",
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
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      final db = await _db;
      final rows = await db.query(
        'mother_care_activities',
        columns: [
          'server_id',
          'created_date_time',
          'modified_date_time',
          'id',
          'is_deleted',
        ],
        where:
            "server_id IS NOT NULL AND TRIM(server_id) != '' AND current_user_key = ?",
        whereArgs: [ashaUniqueKey],
        orderBy: "created_date_time DESC",
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

  Future<Map<String, dynamic>> getANCVisitCount(String beneficiaryId) async {
    try {
      final db = await _db;
      bool isHighRisk = false;
      String? cutoff;

      final cutoffRows = await db.rawQuery(
        '''
      SELECT created_date_time
      FROM ${MotherCareActivitiesTable.table}
      WHERE beneficiary_ref_key = ?
        AND mother_care_state = ?
        AND is_deleted = 0
      ORDER BY created_date_time DESC
      LIMIT 1
    ''',
        [beneficiaryId, 'anc_due'],
      );

      if (cutoffRows.isNotEmpty) {
        final v = cutoffRows.first['created_date_time']?.toString();
        if (v != null && v.isNotEmpty) {
          cutoff = v;
        }
      }

      // Get visit count
      String countSql =
          '''
      SELECT COUNT(*) as count 
      FROM ${FollowupFormDataTable.table} 
      WHERE beneficiary_ref_key = ? 
      AND forms_ref_key = ?
      AND (is_deleted IS NULL OR is_deleted = 0)
    ''';
      final countArgs = <Object?>[
        beneficiaryId,
        FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
            .ancDueRegistration],
      ];
      if (cutoff != null && cutoff.isNotEmpty) {
        countSql += ' AND datetime(created_date_time) >= datetime(?)';
        countArgs.add(cutoff);
      }
      final countResult = await db.rawQuery(countSql, countArgs);

      String riskSql =
          '''
      SELECT form_json
      FROM ${FollowupFormDataTable.table} 
      WHERE beneficiary_ref_key = ? 
      AND forms_ref_key = ?
      AND (is_deleted IS NULL OR is_deleted = 0)
    ''';
      final riskArgs = <Object?>[
        beneficiaryId,
        FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
            .ancDueRegistration],
      ];
      if (cutoff != null && cutoff.isNotEmpty) {
        riskSql += ' AND datetime(created_date_time) >= datetime(?)';
        riskArgs.add(cutoff);
      }
      riskSql += ' ORDER BY created_date_time DESC LIMIT 1';
      final riskResult = await db.rawQuery(riskSql, riskArgs);

      print(
        '🔍 Risk query for $beneficiaryId returned ${riskResult.length} rows',
      );
      if (riskResult.isNotEmpty) {
        final formJson = riskResult.first['form_json'] as String?;
        print('🔍 Form JSON for $beneficiaryId: $formJson');
        if (formJson != null) {
          try {
            final decoded = jsonDecode(formJson) as Map<String, dynamic>;
            print('🔍 Parsed form data: $decoded');

            final data = decoded['form_data'] ?? decoded['anc_form'];
            if (data is Map<String, dynamic>) {
              final hr = data['high_risk'] ?? data['is_high_risk'];
              isHighRisk =
                  hr == true ||
                  hr == 1 ||
                  (hr is String &&
                      ['true', 'yes', '1'].contains(hr.toLowerCase()));
              print('🔍 High risk status from form_data/anc_form: $isHighRisk');
            }

            if (!isHighRisk) {
              final hr = decoded['high_risk'] ?? decoded['is_high_risk'];
              isHighRisk =
                  hr == true ||
                  hr == 1 ||
                  (hr is String &&
                      ['true', 'yes', '1'].contains(hr.toLowerCase()));
              print('🔍 High risk status from top level: $isHighRisk');
            }

            print('🔍 Final high risk status for $beneficiaryId: $isHighRisk');
          } catch (e) {
            print('❌ Error parsing form_json for $beneficiaryId: $e');
          }
        }
      }

      return {
        'count': countResult.first['count'] as int? ?? 0,
        'isHighRisk': isHighRisk,
      };
    } catch (e) {
      print('❌ Error in getANCVisitCount for $beneficiaryId: $e');
      return {'count': 0, 'isHighRisk': false};
    }
  }

  Future<String?> getLastANCVisitDate(String beneficiaryId) async {
    try {
      final db = await _db;

      // Query to get the latest ANC visit record from followup table
      final result = await db.rawQuery(
        '''
        SELECT created_date_time
        FROM ${FollowupFormDataTable.table}
        WHERE beneficiary_ref_key = ? 
        AND forms_ref_key = ?
        AND (is_deleted IS NULL OR is_deleted = 0)
        ORDER BY created_date_time DESC
        LIMIT 1
      ''',
        [
          beneficiaryId,
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .ancDueRegistration],
        ],
      );

      if (result.isNotEmpty) {
        final visitDate = result.first['created_date_time']?.toString();
        if (visitDate != null && visitDate.isNotEmpty) {
          try {
            final dateTime = DateTime.parse(visitDate);
            return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
          } catch (e) {
            print('⚠️ Error parsing visit date: $e');
            return visitDate; // Return raw string if parsing fails
          }
        }
      }

      return null; // No visit found
    } catch (e) {
      print('❌ Error getting last ANC visit date for $beneficiaryId: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAncFormsByBeneficiaryId(
    String beneficiaryId,
  ) async {
    try {
      final db = await _db;
      String? cutoff;
      final cutoffRows = await db.rawQuery(
        '''
      SELECT created_date_time
      FROM ${MotherCareActivitiesTable.table}
      WHERE beneficiary_ref_key = ?
        AND mother_care_state = ?
        AND is_deleted = 0
      ORDER BY created_date_time DESC
      LIMIT 1
    ''',
        [beneficiaryId, 'anc_due'],
      );

      if (cutoffRows.isNotEmpty) {
        final v = cutoffRows.first['created_date_time']?.toString();
        if (v != null && v.isNotEmpty) {
          cutoff = v;
        }
      }

      String where =
          'forms_ref_key = ? AND beneficiary_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)';
      final args = <Object?>[
        FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
            .ancDueRegistration],
        beneficiaryId,
      ];
      if (cutoff != null && cutoff.isNotEmpty) {
        where += ' AND datetime(created_date_time) >= datetime(?)';
        args.add(cutoff);
      }

      final result = await db.query(
        FollowupFormDataTable.table,
        where: where,
        whereArgs: args,
        orderBy: 'created_date_time DESC',
      );

      return result.map((form) {
        final row = Map<String, dynamic>.from(form);
        try {
          if (row['form_json'] != null) {
            final decoded = jsonDecode(row['form_json']);
            if (decoded is Map && decoded['anc_form'] is Map) {
              row['anc_form'] = Map<String, dynamic>.from(decoded['anc_form']);
            } else {
              row['anc_form'] = decoded;
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


  Future<Map<String, dynamic>?> getBeneficiaryByServerKey(
      String serverKey,
      ) async {
    try {

      if(serverKey=='696b76644239d35553728f27' || serverKey == '696b766f99764a6a83a22a21' || serverKey == '696b766f99764a6a83a22a23'){
        print('aa');
      }
      final db = await _db;
      /* final rows = await db.query(
        'beneficiaries_new',
        where:
            'unique_key = ? AND (is_deleted IS NULL OR is_deleted = 0) AND (is_death = 0 OR is_death IS NULL)',
        whereArgs: [uniqueKey],
        limit: 1,
      );*/
      final rows = await db.query(
        'beneficiaries_new',
        where:
        'server_id = ?',
        whereArgs: [serverKey],
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

  Future<Map<String, dynamic>?> getBeneficiaryByUniqueKey(
    String uniqueKey,
  ) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        where:
            'unique_key = ? AND (is_deleted IS NULL OR is_deleted = 0) AND (is_death = 0 OR is_death IS NULL)',
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

  Future<int> updateBeneficiaryServerIdByUniqueKey({
    required String uniqueKey,
    required String serverId,
  }) async {
    try {
      final db = await _db;
      final changes = await db.update(
        'beneficiaries_new',
        {
          'server_id': serverId,
          'is_synced': 1,
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

  Future<int> updateBeneficiaryParentUserByUniqueKey({
    required String uniqueKey,
    required Map<String, dynamic> parentUser,
  }) async {
    try {
      final db = await _db;
      final changes = await db.update(
        'beneficiaries_new',
        {
          'parent_user': jsonEncode(parentUser),
          'modified_date_time': DateTime.now().toIso8601String(),
          'is_synced': 0,
        },
        where: 'unique_key = ?',
        whereArgs: [uniqueKey],
      );
      return changes;
    } catch (e) {
      print('Error updating beneficiary parent_user by unique_key: $e');
      rethrow;
    }
  }

  Future<int> updateBeneficiaryDeathStatus({required String uniqueKey, required int isDeath}) async {
    try {
      final db = await _db;
      final changes = await db.update(
        'beneficiaries_new',
        {
          'is_death': isDeath,
          'modified_date_time': DateTime.now().toIso8601String(),
        },
        where: 'unique_key = ?',
        whereArgs: [uniqueKey],
      );
      return changes;
    } catch (e) {
      print('Error updating beneficiary death status by unique_key: $e');
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
        'address': data['address'] is String
            ? data['address']
            : jsonEncode(data['address'] ?? {}),
        'geo_location': data['geo_location'] is String
            ? data['geo_location']
            : jsonEncode(data['geo_location'] ?? {}),
        'head_id': data['head_id'],
        'household_info': householdInfo is String
            ? householdInfo // Already a JSON string
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
        'address': data['address'] is String
            ? data['address']
            : jsonEncode(data['address'] ?? {}),
        'geo_location': data['geo_location'] is String
            ? data['geo_location']
            : jsonEncode(data['geo_location'] ?? {}),
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
        // Any local update should mark record as needing re-sync
        'is_synced': 0,
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

  Future<int> updateHouseholdServerIdByUniqueKey({
    required String uniqueKey,
    required String serverId,
  }) async {
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

  Future<int> markHouseholdSyncedByUniqueKey({
    required String uniqueKey,
    String? serverId,
  }) async {
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
          : data['beneficiary_state'] is Map
          ? jsonEncode(data['beneficiary_state'])
          : data['beneficiary_state']?.toString() ?? '[]',
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
    return db.insert('beneficiaries_new', row);
  }

  Future<int> getBeneficiaryTotalCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM beneficiaries_new WHERE is_deleted = 0',
      ),
    );
    return count ?? 0;
  }

  Future<int> getBeneficiarySyncedCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM beneficiaries_new WHERE is_deleted = 0 AND is_synced = 1',
      ),
    );
    return count ?? 0;
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

  Future<Map<String, dynamic>?> getEligibleCoupleActivityByBeneficiary(
    String beneficiaryRefKey,
  ) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'eligible_couple_activities',
        where: 'beneficiary_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey],
        limit: 1,
        orderBy: 'created_date_time DESC',
      );
      return rows.isNotEmpty ? Map<String, dynamic>.from(rows.first) : null;
    } catch (e) {
      print('Error getting eligible couple activity by beneficiary: $e');
      return null;
    }
  }

  Future<int> getEligibleCoupleTotalCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM eligible_couple_activities WHERE is_deleted = 0',
      ),
    );
    return count ?? 0;
  }

  Future<int> getEligibleCoupleSyncedCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM eligible_couple_activities WHERE is_deleted = 0 AND is_synced = 1',
      ),
    );
    return count ?? 0;
  }

  Future<int> markEligibleCoupleActivitiesDeletedByBeneficiary(
    String beneficiaryRefKey,
  ) async {
    try {
      final db = await _db;
      final values = <String, Object?>{
        'is_deleted': 1,
        'modified_date_time': DateTime.now().toIso8601String(),
      };
      final changes = await db.update(
        'eligible_couple_activities',
        values,
        where:
            'beneficiary_ref_key = ? AND (is_deleted IS NULL OR is_deleted = 0)',
        whereArgs: [beneficiaryRefKey],
      );
      return changes;
    } catch (e) {
      print(
        'Error marking eligible couple activities deleted for $beneficiaryRefKey: $e',
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loadDeceasedList() async {
    try {
      final db = await _db;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      final List<Map<String, dynamic>> deceasedBeneficiaries = await db
          .rawQuery(
            '''
      SELECT 
  b.*,
  h.household_info AS household_data,
  h.created_date_time AS household_created_date,
  h.household_info AS hh_info
FROM beneficiaries_new b
LEFT JOIN households h 
  ON b.household_ref_key = h.unique_key
WHERE b.is_death = 1
  AND b.is_deleted = 0
  AND b.is_migrated = 0
  AND b.is_adult = 0
  AND (
    b.beneficiary_info LIKE '%"memberType":"child"%' OR
    b.beneficiary_info LIKE '%"memberType":"Child"%'
  )
  AND EXISTS (
    SELECT 1
    FROM child_care_activities cca
    WHERE cca.beneficiary_ref_key = b.unique_key
      AND cca.child_care_state IN ('registration_due', 'tracking_due')
  )
  ${ashaUniqueKey != null && ashaUniqueKey.isNotEmpty ? 'AND b.current_user_key = ?' : ''}
ORDER BY b.created_date_time DESC;
      ''',
            ashaUniqueKey != null && ashaUniqueKey.isNotEmpty
                ? [ashaUniqueKey]
                : [],
          );

      return deceasedBeneficiaries;
    } catch (e) {
      print('Error loading deceased list: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadAllHouseholdData() async {
    try {
      final rows = await getAllBeneficiaries();
      final households = await getAllHouseholds();

      /// Household -> configured head map
      final headKeyByHousehold = <String, String>{};
      for (final hh in households) {
        try {
          final hhRefKey = (hh['unique_key'] ?? '').toString();
          final headId = (hh['head_id'] ?? '').toString();
          if (hhRefKey.isEmpty || headId.isEmpty) continue;
          headKeyByHousehold[hhRefKey] = headId;
        } catch (_) {}
      }

      /// --------- FAMILY HEAD FILTER ----------
      final familyHeads = rows.where((r) {
        try {
          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          final uniqueKey = (r['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;

          // Exclude migrated & death
          if (r['is_death'] == 1 || r['is_migrated'] == 1) return false;

          final rawInfo = r['beneficiary_info'];
          Map<String, dynamic> info;
          if (rawInfo is Map) {
            info = Map<String, dynamic>.from(rawInfo);
          } else if (rawInfo is String && rawInfo.isNotEmpty) {
            info = Map<String, dynamic>.from(jsonDecode(rawInfo));
          } else {
            info = {};
          }

          final configuredHeadKey = headKeyByHousehold[householdRefKey];

          final bool isConfiguredHead =
              configuredHeadKey != null && configuredHeadKey == uniqueKey;

          final relation = (info['relation_to_head'] ?? info['relation'] ?? '')
              .toString()
              .toLowerCase();

          final bool isHeadByRelation =
              relation == 'head' || relation == 'self';

          // ✅ NEW CONDITION
          final bool isFamilyHead =
              info['isFamilyHead'] == true ||
              info['isFamilyHead']?.toString().toLowerCase() == 'true';

          return isConfiguredHead || isHeadByRelation || isFamilyHead;
        } catch (_) {
          return false;
        }
      }).toList();

      return familyHeads;
    } catch (e) {
      print('Error loading all household data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUpdatedEligibleCouplesWithLocalization(
    AppLocalizations? t,
  ) async {
    print('🔍 Starting to fetch updated eligible couples...');

    try {
      final db = await _db;

      // Get current user data
      final currentUser = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUser?['unique_key']?.toString() ?? '';

      String whereClause =
          'eligible_couple_state = ? AND (is_deleted IS NULL OR is_deleted = 0)';
      List<dynamic> whereArgs = ['tracking_due'];

      if (ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
        print('🔑 Filtering by ASHA unique key: $ashaUniqueKey');
      }

      final trackingDueRows = await db.query(
        'eligible_couple_activities',
        columns: ['beneficiary_ref_key', 'current_user_key'],
        where: whereClause,
        whereArgs: whereArgs,
      );

      final trackingDueBeneficiaryKeys = trackingDueRows
          .map((row) => row['beneficiary_ref_key']?.toString())
          .whereType<String>()
          .toSet();

      print(
        '🔑 Tracking due beneficiaries count: ${trackingDueBeneficiaryKeys.length}',
      );

      if (trackingDueBeneficiaryKeys.isEmpty) {
        return [];
      }

      final placeholders = List.filled(
        trackingDueBeneficiaryKeys.length,
        '?',
      ).join(',');
      final rows = await db.query(
        'beneficiaries_new',
        where:
            'unique_key IN ($placeholders) AND (is_deleted IS NULL OR is_deleted = 0) AND (is_migrated IS NULL OR is_migrated = 0)',
        whereArgs: trackingDueBeneficiaryKeys.toList(),
        orderBy: 'created_date_time DESC',
      );

      print(
        '📊 Found ${rows.length} beneficiaries matching tracking_due status',
      );

      final couples = <Map<String, dynamic>>[];
      final households = <String, List<Map<String, dynamic>>>{};

      for (final row in rows) {
        final hhKey = row['household_ref_key']?.toString() ?? '';
        households.putIfAbsent(hhKey, () => []).add(row);
      }
      print('🏠 Households found: ${households.length}');

      for (final household in households.values) {
        Map<String, dynamic>? head;
        Map<String, dynamic>? spouse;

        for (final member in household) {
          try {
            final dynamic infoRaw = member['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});

            // Check if this is the head or spouse
            final relation =
                (info['relation_to_head'] ?? info['relation'] ?? '')
                    .toString()
                    .toLowerCase();
            if (relation.contains('head') || relation == 'self') {
              head = info;
              head!['_row'] = member;
            } else if (relation == 'spouse' ||
                relation == 'wife' ||
                relation == 'husband') {
              spouse = info;
              spouse!['_row'] = member;
            }
          } catch (e) {
            print('❌ Error processing household member: $e');
          }
        }

        for (final member in household) {
          try {
            final dynamic infoRaw = member['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});

            final isFp =
                member['is_family_planning'] == true ||
                member['is_family_planning'] == 1 ||
                member['is_family_planning']?.toString().toLowerCase() == 'yes';

            // Determine if this is the head or spouse to pass the correct counterpart
            final bool isHead = info == head;
            final bool isSpouse = info == spouse;
            final Map<String, dynamic> counterpart = isHead && spouse != null
                ? spouse
                : isSpouse && head != null
                ? head
                : <String, dynamic>{};

            final coupleData = _formatEligibleCoupleData(
              Map<String, dynamic>.from(member),
              info,
              counterpart,
              isFamilyPlanning: isFp,
              t: t,
            );

            couples.add(coupleData);
          } catch (e) {
            print('❌ Error processing EC member: $e');
          }
        }
      }

      print('🏁 Finished processing. Found ${couples.length} eligible couples');
      return couples;
    } catch (e) {
      print('❌ Error in getUpdatedEligibleCouples: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUpdatedEligibleCouples() async {
    print('🔍 Starting to fetch updated eligible couples...');

    try {
      final db = await _db;

      // Get current user data
      final currentUser = await SecureStorageService.getCurrentUserData();
      final ashaUniqueKey = currentUser?['unique_key']?.toString() ?? '';

      String whereClause =
          'eligible_couple_state = ? AND (is_deleted IS NULL OR is_deleted = 0)';
      List<dynamic> whereArgs = ['tracking_due'];

      if (ashaUniqueKey.isNotEmpty) {
        whereClause += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
        print('🔑 Filtering by ASHA unique key: $ashaUniqueKey');
      }

      final trackingDueRows = await db.query(
        'eligible_couple_activities',
        columns: ['beneficiary_ref_key', 'current_user_key'],
        where: whereClause,
        whereArgs: whereArgs,
      );

      final trackingDueBeneficiaryKeys = trackingDueRows
          .map((row) => row['beneficiary_ref_key']?.toString())
          .whereType<String>()
          .toSet();

      print(
        '🔑 Tracking due beneficiaries count: ${trackingDueBeneficiaryKeys.length}',
      );

      if (trackingDueBeneficiaryKeys.isEmpty) {
        return [];
      }

      final placeholders = List.filled(
        trackingDueBeneficiaryKeys.length,
        '?',
      ).join(',');
      final rows = await db.query(
        'beneficiaries_new',
        where:
            'unique_key IN ($placeholders) AND (is_deleted IS NULL OR is_deleted = 0) AND (is_migrated IS NULL OR is_migrated = 0)',
        whereArgs: trackingDueBeneficiaryKeys.toList(),
        orderBy: 'created_date_time DESC',
      );

      print(
        '📊 Found ${rows.length} beneficiaries matching tracking_due status',
      );

      final couples = <Map<String, dynamic>>[];
      final households = <String, List<Map<String, dynamic>>>{};

      for (final row in rows) {
        final hhKey = row['household_ref_key']?.toString() ?? '';
        households.putIfAbsent(hhKey, () => []).add(row);
      }
      print('🏠 Households found: ${households.length}');

      for (final household in households.values) {
        Map<String, dynamic>? head;
        Map<String, dynamic>? spouse;

        for (final member in household) {
          try {
            final dynamic infoRaw = member['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});

            // Check if this is the head or spouse
            final relation =
                (info['relation_to_head'] ?? info['relation'] ?? '')
                    .toString()
                    .toLowerCase();
            if (relation.contains('head') || relation == 'self') {
              head = info;
              head!['_row'] = member;
            } else if (relation == 'spouse' ||
                relation == 'wife' ||
                relation == 'husband') {
              spouse = info;
              spouse!['_row'] = member;
            }
          } catch (e) {
            print('❌ Error processing household member: $e');
          }
        }

        for (final member in household) {
          try {
            final dynamic infoRaw = member['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? jsonDecode(infoRaw)
                : Map<String, dynamic>.from(infoRaw ?? {});

            final isFp =
                member['is_family_planning'] == true ||
                member['is_family_planning'] == 1 ||
                member['is_family_planning']?.toString().toLowerCase() == 'yes';

            // Determine if this is the head or spouse to pass the correct counterpart
            final bool isHead = info == head;
            final bool isSpouse = info == spouse;
            final Map<String, dynamic> counterpart = isHead && spouse != null
                ? spouse
                : isSpouse && head != null
                ? head
                : <String, dynamic>{};

            final coupleData = _formatEligibleCoupleData(
              Map<String, dynamic>.from(member),
              info,
              counterpart,
              isFamilyPlanning: isFp,
            );

            couples.add(coupleData);
          } catch (e) {
            print('❌ Error processing EC member: $e');
          }
        }
      }

      print('🏁 Finished processing. Found ${couples.length} eligible couples');
      return couples;
    } catch (e) {
      print('❌ Error in getUpdatedEligibleCouples: $e');
      return [];
    }
  }

  Map<String, dynamic> _formatEligibleCoupleData(
    Map<String, dynamic> row,
    Map<String, dynamic> female,
    Map<String, dynamic> spouse, {
    bool isFamilyPlanning = false,
    AppLocalizations? t,
  }) {
    final hhId = (row['household_ref_key']?.toString() ?? '');
    final beneficiary_ref = (row['unique_key']?.toString() ?? '');
    final uniqueKey = (row['unique_key']?.toString() ?? '');
    final createdDate = row['created_date_time']?.toString() ?? '';

    final name =
        female['memberName']?.toString() ??
        female['headName']?.toString() ??
        t?.na ??
        'N/A';
    final dob = female['dob']?.toString() ?? '';
    final age = _calculateAge(dob);
    final gender = (female['gender']?.toString().toLowerCase() ?? 'female');
    final mobile = female['mobileNo']?.toString() ?? 'Not Available';
    final richId = female['RichID']?.toString() ?? t?.na ?? 'N/A';

    final spouseName = spouse.isNotEmpty
        ? (spouse['memberName'] ??
                  spouse['headName'] ??
                  spouse['spouseName'] ??
                  t?.na ??
                  'N/A')
              .toString()
        : (female['spouseName']?.toString() ?? t?.na ?? 'N/A');

    String last11(String s) => s.length > 11 ? s.substring(s.length - 11) : s;

    return {
      'hhId': last11(hhId),
      'beneficiary_ref': beneficiary_ref,
      'RegistrationDate': _formatDate(createdDate, t).isNotEmpty
          ? _formatDate(createdDate, t)
          : t?.na ?? 'N/A',
      'RegistrationType': 'General',
      'BeneficiaryID': last11(uniqueKey),
      'Name': name.isNotEmpty ? name : t?.na ?? 'N/A',
      'age': age > 0 ? '$age Y | Female' : t?.na ?? 'N/A',
      'gender': gender,
      'RichID': richId.isNotEmpty ? richId : t?.na ?? 'N/A',
      'mobileno': mobile != 'Not Available' ? mobile : t?.na ?? 'N/A',
      'HusbandName': spouseName.isNotEmpty ? spouseName : 'Not Available',
      'spouseName': spouseName.isNotEmpty ? spouseName : t?.na ?? 'N/A',
      'partnerName': spouseName.isNotEmpty ? spouseName : t?.na ?? 'N/A',
      // For backward compatibility
      'dob': dob,
      'status': isFamilyPlanning ? 'Protected' : 'Unprotected',
      'is_family_planning': isFamilyPlanning,
    };
  }

  int _calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return 0;
    try {
      final dob = DateTime.tryParse(dobString);
      if (dob == null) return 0;

      final now = DateTime.now();
      int age = now.year - dob.year;

      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      return age > 0 ? age : 0;
    } catch (e) {
      print('Error calculating age: $e');
      return 0;
    }
  }

  String _formatDate(String dateStr, AppLocalizations? t) {
    if (dateStr.isEmpty) return t?.na ?? 'N/A';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return t?.na ?? 'N/A';
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return t?.na ?? 'N/A';
    }
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

  Future<int> updateMotherCareActivity(
    String beneficiaryRefKey,
    Map<String, dynamic> data,
  ) async {
    final db = await _db;
    final row = <String, dynamic>{
      'mother_care_state': data['mother_care_state'],
      'device_details': _encodeIfObject(data['device_details']),
      'app_details': _encodeIfObject(data['app_details']),
      'parent_user': _encodeIfObject(data['parent_user']),
      'current_user_key': data['current_user_key'],
      'facility_id': data['facility_id'],
      'modified_date_time': data['modified_date_time'],
      'is_synced': 0, // Reset sync status when updated
    };

    if (data['server_id'] != null) {
      row['server_id'] = data['server_id'];
    }

    return db.update(
      'mother_care_activities',
      row,
      where: 'beneficiary_ref_key = ? AND is_deleted = 0',
      whereArgs: [beneficiaryRefKey],
    );
  }

  Future<int> getMotherCareTotalCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM mother_care_activities WHERE is_deleted = 0',
      ),
    );
    return count ?? 0;
  }

  Future<int> getMotherCareSyncedCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM mother_care_activities WHERE is_deleted = 0 AND is_synced = 1',
      ),
    );
    return count ?? 0;
  }

  Future<Map<String, dynamic>?> getMotherCareActivityByBeneficiary(
    String beneficiaryRefKey,
  ) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'mother_care_activities',
        where: 'beneficiary_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final mapped = Map<String, dynamic>.from(rows.first);
      mapped['device_details'] = safeJsonDecode(mapped['device_details']);
      mapped['app_details'] = safeJsonDecode(mapped['app_details']);
      mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
      return mapped;
    } catch (e) {
      print('Error getting mother care activity by beneficiary: $e');
      return null;
    }
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

  Future<Map<String, dynamic>?> getChildCareActivityByBeneficiary(
    String beneficiaryRefKey,
  ) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'child_care_activities',
        where: 'beneficiary_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey],
        limit: 1,
        orderBy: 'created_date_time DESC',
      );
      return rows.isNotEmpty ? Map<String, dynamic>.from(rows.first) : null;
    } catch (e) {
      print('Error getting child care activity by beneficiary: $e');
      return null;
    }
  }

  Future<int> updateChildCareActivity(
    String beneficiaryRefKey,
    Map<String, dynamic> data,
  ) async {
    final db = await _db;
    final row = <String, dynamic>{
      'child_care_state': data['child_care_state'],
      'device_details': _encodeIfObject(data['device_details']),
      'app_details': _encodeIfObject(data['app_details']),
      'parent_user': _encodeIfObject(data['parent_user']),
      'current_user_key': data['current_user_key'],
      'facility_id': data['facility_id'],
      'modified_date_time': data['modified_date_time'],
      'is_synced': 0, // Reset sync status when updated
    };

    if (data['server_id'] != null) {
      row['server_id'] = data['server_id'];
    }

    return db.update(
      'child_care_activities',
      row,
      where: 'beneficiary_ref_key = ? AND is_deleted = 0',
      whereArgs: [beneficiaryRefKey],
    );
  }

  Future<int> getChildCareTotalCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM child_care_activities WHERE is_deleted = 0',
      ),
    );
    return count ?? 0;
  }

  Future<int> getChildCareSyncedCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM child_care_activities WHERE is_deleted = 0 AND is_synced = 1',
      ),
    );
    return count ?? 0;
  }

  /// Returns the timestamp of the most recent sync operation
  Future<DateTime?> getLastSyncTime() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT MAX(modified_date_time) as last_sync 
        FROM (
          SELECT modified_date_time FROM households WHERE is_synced = 1
          UNION ALL
          SELECT modified_date_time FROM beneficiaries_new WHERE is_synced = 1
          UNION ALL
          SELECT modified_date_time FROM followup_form_data WHERE is_synced = 1
          UNION ALL
          SELECT modified_date_time FROM eligible_couple_activities WHERE is_synced = 1
          UNION ALL
          SELECT modified_date_time FROM mother_care_activities WHERE is_synced = 1
          UNION ALL
          SELECT modified_date_time FROM child_care_activities WHERE is_synced = 1
        ) 
        WHERE modified_date_time IS NOT NULL AND modified_date_time != ''
      ''');

      final dbTime = (result.isNotEmpty && result.first['last_sync'] != null)
          ? DateTime.tryParse(result.first['last_sync'] as String)
          : null;
      final storedTime = await SecureStorageService.getLastSyncTimeStored();
      if (dbTime == null) return storedTime;
      if (storedTime == null) return dbTime;
      return dbTime.isAfter(storedTime) ? dbTime : storedTime;
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMotherCareActivities() async {
    final db = await _db;
    final rows = await db.query(
      'mother_care_activities',
      where: 'is_synced = 0 AND is_deleted = 0',
    );
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  // Future<int> markMotherCareActivitySyncedById(int id) async {
  //   final db = await _db;
  //   return db.update(
  //     'mother_care_activities',
  //     {
  //       'is_synced': 1,
  //       'modified_date_time': DateTime.now().toIso8601String(),
  //     },
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  // }

  Future<int> markMotherCareActivitySyncedById(
    int id, {
    String? serverId,
  }) async {
    final db = await _db;
    final values = <String, Object?>{
      'is_synced': 1,
      'modified_date_time': DateTime.now().toIso8601String(),
    };
    if (serverId != null && serverId.isNotEmpty) values['server_id'] = serverId;
    return db.update(
      'mother_care_activities',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMotherCareAncForms() async {
    try {
      final db = await _db;
      final ancFormsRefKey =
          FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
              .ancDueRegistration] ??
          '';
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

  Future<int> markMotherCareAncFormSyncedById(
    int id, {
    String? serverId,
  }) async {
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
        'mother_care_activities',
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

  Future<int> getFollowupTotalCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM followup_form_data WHERE is_deleted = 0',
      ),
    );
    return count ?? 0;
  }

  Future<int> getFollowupSyncedCountLocal() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM followup_form_data WHERE is_deleted = 0 AND is_synced = 1',
      ),
    );
    return count ?? 0;
  }

  Future<int> getHouseholdCount() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM households WHERE is_deleted = 0'),
    );
    return count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getFollowupFormsWithCaseClosure(
    String formType,
  ) async {
    final db = await _db;

    final forms = await db.query(
      FollowupFormDataTable.table,
      where: 'form_json LIKE ?',
      whereArgs: ['%case_closure%'],
      orderBy: 'created_date_time DESC',
    );

    final List<Map<String, dynamic>> result = [];

    for (final form in forms) {
      try {
        final formJson = form['form_json'] as String?;
        if (formJson == null || formJson.isEmpty) continue;

        final formData = jsonDecode(formJson);

        if (formData is Map && formData['form_data'] is Map) {
          final formDataMap = Map<String, dynamic>.from(
            formData['form_data'] as Map,
          );
          final caseClosure = formDataMap['case_closure'] is Map
              ? Map<String, dynamic>.from(formDataMap['case_closure'] as Map)
              : null;

          if (caseClosure != null && caseClosure['is_case_closure'] == true) {
            final childDetails = formDataMap['child_details'] is Map
                ? Map<String, dynamic>.from(formDataMap['child_details'] as Map)
                : formDataMap;
            final registrationData = formDataMap['registration_data'] is Map
                ? Map<String, dynamic>.from(
                    formDataMap['registration_data'] as Map,
                  )
                : {};

            String beneficiaryRefKey =
                form['beneficiary_ref_key']?.toString() ?? '';
            Map<String, dynamic> beneficiaryData = {};

            if (beneficiaryRefKey.isNotEmpty) {
              try {
                final beneficiaryRows = await db.query(
                  'beneficiaries_new',
                  where: 'unique_key = ?',
                  whereArgs: [beneficiaryRefKey],
                  limit: 1,
                );

                if (beneficiaryRows.isNotEmpty) {
                  beneficiaryData = beneficiaryRows.first;

                  if (beneficiaryData['registration_type_followup'] is String) {
                    try {
                      beneficiaryData['registration_type_followup'] =
                          jsonDecode(
                            beneficiaryData['registration_type_followup'],
                          );
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

            final beneficiaryId =
                formDataMap['beneficiary_id'] ??
                formDataMap['beneficiary_ref_key'] ??
                '';
            final householdId =
                formDataMap['household_id'] ??
                formDataMap['household_ref_key'] ??
                '';

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
              'name':
                  childDetails['name'] ??
                  '${childDetails['first_name'] ?? ''} ${childDetails['last_name'] ?? ''}'
                      .trim(),
              'date_of_death': caseClosure['date_of_death'],
              'cause_of_death':
                  caseClosure['probable_cause_of_death'] ?? 'Not specified',
              'death_place': caseClosure['death_place'] ?? 'Not specified',
              'reason': caseClosure['reason_of_death'] ?? 'Not specified',
              'beneficiary_id': beneficiaryId,
              'rch_id': formDataMap['rch_id'] ?? '',
              'household_id': householdId,
              'mobile_number':
                  formDataMap['mobile_number'] ??
                  formDataMap['contact_number'] ??
                  '',
              'father_name':
                  childDetails['father_name'] ??
                  formDataMap['father_name'] ??
                  '',
              'mother_name':
                  childDetails['mother_name'] ??
                  formDataMap['mother_name'] ??
                  '',
              'age':
                  childDetails['age']?.toString() ??
                  formDataMap['age']?.toString() ??
                  '',
              'gender': childDetails['gender'] ?? formDataMap['gender'] ?? '',
              'registration_date':
                  registrationData['registration_date'] ??
                  formDataMap['registration_date'] ??
                  '',
            });
          }
        }
      } catch (e) {
        print('Error processing form ${form['id']}: $e');
      }
    }

    return result;
  }

  Future<Map<String, dynamic>?> _getCurrentUserData() async {
    try {
      return await SecureStorageService.getCurrentUserData();
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

    Future<List<Map<String, dynamic>>> getHighRiskANCVisits() async {
      final db = await _db;

      final currentUser = await _getCurrentUserData();
      final ashaUniqueKey = currentUser?['unique_key']?.toString() ?? '';

      if (ashaUniqueKey.isEmpty) return [];

      final beneficiaries = await db.rawQuery(
        '''
  SELECT DISTINCT B.*
  FROM beneficiaries_new B
  INNER JOIN mother_care_activities M
    ON M.beneficiary_ref_key = B.unique_key
  WHERE B.is_deleted = 0
    AND B.is_migrated = 0
    AND B.current_user_key = ?
    AND M.is_deleted = 0
    AND M.current_user_key = ?
    AND M.mother_care_state = 'anc_due'
    AND M.created_date_time = (
      SELECT MAX(created_date_time)
      FROM mother_care_activities
      WHERE beneficiary_ref_key = B.unique_key
        AND is_deleted = 0
    )
  ORDER BY datetime(B.created_date_time) DESC
  ''',
        [ashaUniqueKey, ashaUniqueKey],
      );


      final List<Map<String, dynamic>> result = [];
      final Set<String> processedBeneficiaries = {};

      for (final beneficiary in beneficiaries) {
        try {
          final beneficiaryRefKey = beneficiary['unique_key'] as String?;
          if (beneficiaryRefKey == null) continue;

          final forms = await db.query(
            FollowupFormDataTable.table,
            where:
                'is_deleted = 0 AND forms_ref_key = ? AND beneficiary_ref_key = ?',
            whereArgs: [
              FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable
                  .ancDueRegistration],
              beneficiaryRefKey,
            ],
            orderBy: 'created_date_time DESC',
            limit: 1,
          );

          if (forms.isEmpty) continue;

          final form = forms.first;
          final formJson = form['form_json'] as String?;
          if (formJson == null || formJson.isEmpty) continue;

          final decoded = jsonDecode(formJson);
          if (decoded is! Map<String, dynamic>) continue;

          final data = decoded['form_data'] ?? decoded['anc_form'];
          if (data is! Map<String, dynamic>) continue;

          final hr = data['high_risk'] ?? data['is_high_risk'];
          final bool isHighRisk =
              hr == true ||
              hr == 1 ||
              (hr is String && ['true', 'yes', '1'].contains(hr.toLowerCase()));

          if (!isHighRisk) continue;

          final beneficiaryData = Map<String, dynamic>.from(beneficiary);
          if (beneficiaryData['beneficiary_info'] is String) {
            beneficiaryData['beneficiary_info'] = jsonDecode(
              beneficiaryData['beneficiary_info'],
            );
          }

          if (beneficiary.isEmpty) continue;

          processedBeneficiaries.add(beneficiaryRefKey);

          /// Fetch spouse (optional)
          Map<String, dynamic>? spouseData;
          final spouseKey = beneficiaryData['spouse_key'];
          if (spouseKey != null) {
            final spouse = await db.rawQuery(
              '''
            SELECT B.*
            FROM beneficiaries_new B
            WHERE B.unique_key = ?
              AND B.is_deleted = 0
              AND B.is_migrated = 0
              AND B.current_user_key = ?
            LIMIT 1
          ''',
              [spouseKey, ashaUniqueKey],
            );

            if (spouse.isNotEmpty) {
              spouseData = Map<String, dynamic>.from(spouse.first);
              if (spouseData['beneficiary_info'] is String) {
                spouseData['beneficiary_info'] = jsonDecode(
                  spouseData['beneficiary_info'],
                );
              }
            }
          }

          result.add({
            'id': form['id'],
            'forms_ref_key': form['forms_ref_key'],
            'form_type': form['form_type'],
            'beneficiary_ref_key': beneficiaryRefKey,
            'beneficiary_data': beneficiaryData,
            'spouse_data': spouseData,
            'created_date_time': form['created_date_time'],
            'modified_date_time': form['modified_date_time'],
            'form_data': data,
          });
        } catch (e) {
          debugPrint('❌ High-risk ANC error: $e');
        }
      }

      return result;
    }

  Future<List<Map<String, dynamic>>> getAbortionFollowupForms() async {
    final db = await _db;

    final forms = await db.query(
      'followup_form_data',
      where:
          "is_deleted = 0 AND forms_ref_key = 'bt7gs9rl1a5d26mz'  AND form_json LIKE '%\"is_abortion\"%'",
    );

    final List<Map<String, dynamic>> result = [];

    for (final form in forms) {
      try {
        final formJson = form['form_json'] as String?;
        if (formJson == null || formJson.isEmpty) continue;

        final decoded = safeJsonDecode(formJson);
        if (decoded is! Map<String, dynamic>) continue;

        // Structure: {"anc_form": {"is_abortion": "yes", ...}}
        final ancForm = decoded['anc_form'];
        if (ancForm is! Map<String, dynamic>) continue;

        final isAbortion = ancForm['is_abortion']?.toString().toLowerCase();
        // Check for 'yes', 'true', '1'
        if (isAbortion != 'yes' && isAbortion != 'true' && isAbortion != '1')
          continue;

        final beneficiaryRefKey = form['beneficiary_ref_key']?.toString();
        if (beneficiaryRefKey == null) continue;

        // Fetch beneficiary details
        final benRows = await db.query(
          'beneficiaries_new',
          where: 'unique_key = ? AND is_deleted = 0',
          whereArgs: [beneficiaryRefKey],
          limit: 1,
        );

        Map<String, dynamic>? beneficiaryData;
        if (benRows.isNotEmpty) {
          beneficiaryData = Map<String, dynamic>.from(benRows.first);
          if (beneficiaryData['beneficiary_info'] is String) {
            beneficiaryData['beneficiary_info'] = safeJsonDecode(
              beneficiaryData['beneficiary_info'],
            );
          }
        }

        final resultMap = Map<String, dynamic>.from(form);
        resultMap['form_data'] = ancForm;
        resultMap['beneficiary_data'] = beneficiaryData;

        result.add(resultMap);
      } catch (e) {
        print('Error processing abortion form: $e');
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllHouseholds() async {
    try {
      final db = await _db;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      String where = 'is_deleted = ?';
      List<dynamic> whereArgs = [0];

      if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        where += ' AND current_user_key = ?';
        whereArgs.add(ashaUniqueKey);
      }

      final rows = await db.query(
        'households',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_date_time DESC',
      );

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

        householdMap.putIfAbsent(
          hhId,
          () => {'hasHead': false, 'hasSpouse': false, 'childrenCount': 0},
        );

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

  Future<List<Map<String, dynamic>>> getBeneficiariesByHouseholdFamily(
    String householdId,
    String beneficiary_ref_key,
  ) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        where: 'household_ref_key = ? AND is_deleted = ? And unique_key = ?',
        whereArgs: [householdId, 0, beneficiary_ref_key],
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

  Future<List<Map<String, dynamic>>> getBeneficiariesByHousehold(
    String householdId,
  ) async {
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

  // Add this method to the LocalStorageDao class
  Future<Map<String, int>> getEligibleCoupleCounts() async {
    final db = await _db;
    final currentUser = await SecureStorageService.getCurrentUserData();
    final currentUserKey = currentUser?['unique_key']?.toString() ?? '';

    if (currentUserKey.isEmpty) {
      return {'total': 0, 'tracking_due': 0};
    }

    try {
      final totalCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              '''
      SELECT COUNT(DISTINCT b.unique_key)
      FROM beneficiaries_new b
      INNER JOIN eligible_couple_activities e ON b.unique_key = e.beneficiary_ref_key
      WHERE b.is_deleted = 0 
        AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
        AND e.eligible_couple_state = 'eligible_couple'
        AND e.is_deleted = 0
        AND e.current_user_key = ?
        AND (b.beneficiary_info IS NULL OR b.beneficiary_info NOT LIKE '%"gender":"male"%')
    ''',
              [currentUserKey],
            ),
          ) ??
          0;

      // Get tracking due count
      final trackingDueCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              '''
      SELECT COUNT(DISTINCT b.unique_key)
      FROM beneficiaries_new b
      INNER JOIN eligible_couple_activities e ON b.unique_key = e.beneficiary_ref_key
      WHERE b.is_deleted = 0 
        AND (b.is_migrated = 0 OR b.is_migrated IS NULL)
        AND e.eligible_couple_state = 'tracking_due'
        AND e.is_deleted = 0
        AND e.current_user_key = ?
        AND (b.beneficiary_info IS NULL OR b.beneficiary_info NOT LIKE '%"gender":"male"%')
    ''',
              [currentUserKey],
            ),
          ) ??
          0;

      return {'total': totalCount, 'tracking_due': trackingDueCount};
    } catch (e) {
      print('Error getting eligible couple counts: $e');
      return {'total': 0, 'tracking_due': 0};
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

      row['modified_date_time'] = DateTime.now().toIso8601String();
      // Any local update should mark record as needing re-sync
      row['is_synced'] = 0;

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

  // Future<List<Map<String, dynamic>>> getAllBeneficiaries({int? isMigrated}) async {
  //   try {
  //     final db = await _db;
  //     final currentUserData = await SecureStorageService.getCurrentUserData();
  //     String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
  //
  //     String? where;
  //         List<Object?>? whereArgs;
  //         if (isMigrated != null && ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //           where = 'is_migrated = ? AND current_user_key = ?';
  //           whereArgs = [isMigrated, ashaUniqueKey];
  //         } else if (isMigrated != null) {
  //           where = 'is_migrated = ?';
  //           whereArgs = [isMigrated];
  //         } else if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
  //           where = 'current_user_key = ?';
  //           whereArgs = [ashaUniqueKey];
  //         } else {
  //           where = null;
  //           whereArgs = null;
  //         }
  //
  //
  //
  //
  //     final rows = await db.query(
  //         'beneficiaries_new',
  //         where: where,
  //         whereArgs: whereArgs,
  //         orderBy: 'created_date_time DESC'
  //     );
  //     final result = rows.map((row) {
  //       final mapped = Map<String, dynamic>.from(row);
  //       mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
  //       mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
  //       mapped['death_details'] = safeJsonDecode(mapped['death_details']);
  //       mapped['device_details'] = safeJsonDecode(mapped['device_details']);
  //       mapped['app_details'] = safeJsonDecode(mapped['app_details']);
  //       mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
  //       return mapped;
  //     }).toList();
  //     return result;
  //   } catch (e, stackTrace) {
  //     print('Error getting beneficiaries: $e');
  //     print('Stack trace: $stackTrace');
  //     rethrow;
  //   }
  // }

  Future<List<Map<String, dynamic>>> getAllBeneficiaries({
    int? isMigrated,
  }) async {
    try {
      final db = await _db;
      final currentUserData = await SecureStorageService.getCurrentUserData();
      String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      String? where;
      List<Object?>? whereArgs;
      if (isMigrated != null &&
          ashaUniqueKey != null &&
          ashaUniqueKey.isNotEmpty) {
        where = 'is_migrated = ? AND current_user_key = ? AND is_deleted = ?';
        whereArgs = [isMigrated, ashaUniqueKey, 0];
      } else if (isMigrated != null) {
        where = 'is_migrated = ?';
        whereArgs = [isMigrated];
      } else if (ashaUniqueKey != null && ashaUniqueKey.isNotEmpty) {
        where = 'current_user_key = ?';
        whereArgs = [ashaUniqueKey];
      } else {
        where = null;
        whereArgs = null;
      }

      where = '$where AND is_deleted = 0';
      // whereArgs?.add(ashaUniqueKey);

      final rows = await db.query(
        'beneficiaries_new',
        columns: ['DISTINCT unique_key', '*'],
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_date_time DESC',
      );

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
        where: 'is_deleted = 0 AND is_synced = 0',
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

  Future<int> markBeneficiarySyncedByUniqueKey({
    required String uniqueKey,
    String? serverId,
  }) async {
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

      return {'counts': countResult.first, 'sample_records': sampleRecords};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getDeathRecords() async {
    try {
      print('🔍 [getDeathRecords] Querying death records...');
      final db = await _db;

      final currentUser = await _getCurrentUserData();
      final ashaUniqueKey = currentUser?['unique_key']?.toString() ?? '';

      if (ashaUniqueKey.isEmpty) return [];

      final rows = await db.rawQuery(
        '''
          SELECT *
          FROM ${BeneficiariesTable.table}
          WHERE id IN (
            SELECT MAX(id)
            FROM ${BeneficiariesTable.table}
            WHERE is_death = 1
              AND is_deleted = 0
              AND current_user_key = ?
            GROUP BY unique_key
          )
          ORDER BY created_date_time DESC
          ''',
        [ashaUniqueKey],
      );

      print('✅ [getDeathRecords] Found ${rows.length} death records');

      return rows
          .map((row) {
            try {
              final mapped = Map<String, dynamic>.from(row);

              mapped['beneficiary_info'] = safeJsonDecode(
                mapped['beneficiary_info'],
              );
              mapped['death_details'] = safeJsonDecode(mapped['death_details']);
              mapped['device_details'] = safeJsonDecode(
                mapped['device_details'],
              );
              mapped['app_details'] = safeJsonDecode(mapped['app_details']);
              mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);

              return mapped;
            } catch (e) {
              print('❌ Error parsing record $row: $e');
              return <String, dynamic>{};
            }
          })
          .where((map) => map.isNotEmpty)
          .toList();
    } catch (e, stackTrace) {
      print('❌ [getDeathRecords] Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, String?>?> getHeadReligionAndCategory(
    String householdRefKey,
  ) async {
    print(
      '🔍 [getHeadReligionAndCategory] Fetching religion/category for household: $householdRefKey',
    );
    try {
      final db = await _db;

      final beneficiaries = await db.query(
        'beneficiaries_new',
        where: 'household_ref_key = ? AND is_deleted = 0',
        whereArgs: [householdRefKey],
      );

      if (beneficiaries.isEmpty) {
        print(
          '❌ [getHeadReligionAndCategory] No beneficiaries found for household: $householdRefKey',
        );
        return null;
      }

      // 1. Try to find by relation ('self' or 'head')
      for (final beneficiary in beneficiaries) {
        final beneficiaryInfo = beneficiary['beneficiary_info'] as String?;
        if (beneficiaryInfo == null || beneficiaryInfo.isEmpty) continue;

        try {
          final infoMap = jsonDecode(beneficiaryInfo) as Map<String, dynamic>?;
          if (infoMap == null) continue;

          final relation = infoMap['relation']?.toString().toLowerCase();

          // CHECK 1: Relation Condition
          if (relation == 'self' || relation == 'head') {
            // Extract the specific keys you requested
            final religion = infoMap['religion']?.toString();
            final otherReligion = infoMap['other_religion']?.toString();
            final category = infoMap['category']?.toString();
            final otherCategory = infoMap['other_category']?.toString();

            // Condition: Check if at least one of the main fields has data (mirroring your mobile check)
            if ((religion != null && religion.isNotEmpty) ||
                (category != null && category.isNotEmpty) ||
                (otherReligion != null && otherReligion.isNotEmpty) ||
                (otherCategory != null && otherCategory.isNotEmpty)) {
              print(
                '✅ [getHeadReligionAndCategory] Found head data via relation',
              );
              return {
                'religion': religion,
                'other_religion': otherReligion,
                'category': category,
                'other_category': otherCategory,
              };
            }
          }
        } catch (e) {
          print(
            '❌ [getHeadReligionAndCategory] Error parsing beneficiary info: $e',
          );
        }
      }

      // 2. Fallback: Try to find by headName presence
      for (final beneficiary in beneficiaries) {
        final beneficiaryInfo = beneficiary['beneficiary_info'] as String?;
        if (beneficiaryInfo == null || beneficiaryInfo.isEmpty) continue;

        try {
          final infoMap = jsonDecode(beneficiaryInfo) as Map<String, dynamic>?;
          if (infoMap == null) continue;

          if (infoMap['headName'] != null) {
            final religion = infoMap['religion']?.toString();
            final otherReligion = infoMap['other_religion']?.toString();
            final category = infoMap['category']?.toString();
            final otherCategory = infoMap['other_category']?.toString();

            if ((religion != null && religion.isNotEmpty) ||
                (category != null && category.isNotEmpty) ||
                (otherReligion != null && otherReligion.isNotEmpty) ||
                (otherCategory != null && otherCategory.isNotEmpty)) {
              print(
                '✅ [getHeadReligionAndCategory] Found head data via headName',
              );
              return {
                'religion': religion,
                'other_religion': otherReligion,
                'category': category,
                'other_category': otherCategory,
              };
            }
          }
        } catch (e) {
          print(
            '❌ [getHeadReligionAndCategory] Error parsing beneficiary info (fallback): $e',
          );
        }
      }

      print(
        'ℹ️ [getHeadReligionAndCategory] No religion/category found in any beneficiary',
      );
      return null;
    } catch (e) {
      print('❌ [getHeadReligionAndCategory] Error: $e');
      return null;
    }
  }

  Future<String?> getHeadMobileNumber(String householdRefKey) async {
    print(
      '🔍 [getHeadMobileNumber] Fetching head mobile for household: $householdRefKey',
    );
    try {
      final db = await _db;

      final beneficiaries = await db.query(
        'beneficiaries_new',
        where: 'household_ref_key = ? AND is_deleted = 0',
        whereArgs: [householdRefKey],
      );

      if (beneficiaries.isEmpty) {
        print(
          '❌ [getHeadMobileNumber] No beneficiaries found for household: $householdRefKey',
        );
        return null;
      }

      for (final beneficiary in beneficiaries) {
        final beneficiaryInfo = beneficiary['beneficiary_info'] as String?;
        if (beneficiaryInfo == null || beneficiaryInfo.isEmpty) continue;

        try {
          final infoMap = jsonDecode(beneficiaryInfo) as Map<String, dynamic>?;
          if (infoMap == null) continue;

          final relation = infoMap['relation']?.toString().toLowerCase();
          if (relation == 'self' || relation == 'head') {
            final mobile = infoMap['mobileNo']?.toString();
            if (mobile != null && mobile.isNotEmpty) {
              print('✅ [getHeadMobileNumber] Found head mobile: $mobile');
              return mobile;
            }
          }
        } catch (e) {
          print('❌ [getHeadMobileNumber] Error parsing beneficiary info: $e');
        }
      }

      for (final beneficiary in beneficiaries) {
        final beneficiaryInfo = beneficiary['beneficiary_info'] as String?;
        if (beneficiaryInfo == null || beneficiaryInfo.isEmpty) continue;

        try {
          final infoMap = jsonDecode(beneficiaryInfo) as Map<String, dynamic>?;
          if (infoMap == null) continue;

          if (infoMap['headName'] != null) {
            final mobile = infoMap['mobileNo']?.toString();
            if (mobile != null && mobile.isNotEmpty) {
              print(
                '✅ [getHeadMobileNumber] Found head mobile by headName: $mobile',
              );
              return mobile;
            }
          }
        } catch (e) {
          print(
            '❌ [getHeadMobileNumber] Error parsing beneficiary info (fallback): $e',
          );
        }
      }

      print(
        'ℹ️ [getHeadMobileNumber] No head mobile number found in any beneficiary',
      );
      return null;
    } catch (e) {
      print('❌ [getHeadMobileNumber] Error: $e');
      return null;
    }
  }

  Future<String?> getSpouseMobileNumber(String householdRefKey) async {
    print(
      '🔍 [getSpouseMobileNumber] Fetching spouse mobile for household: $householdRefKey',
    );
    try {
      final db = await _db;

      final beneficiaries = await db.query(
        'beneficiaries_new',
        where: 'household_ref_key = ? AND is_deleted = 0',
        whereArgs: [householdRefKey],
      );

      if (beneficiaries.isEmpty) {
        print(
          '❌ [getSpouseMobileNumber] No beneficiaries found for household: $householdRefKey',
        );
        return null;
      }

      // First, try to find a spouse with self-owned mobile
      for (final beneficiary in beneficiaries) {
        final beneficiaryInfo = beneficiary['beneficiary_info'] as String?;
        if (beneficiaryInfo == null || beneficiaryInfo.isEmpty) continue;

        try {
          final infoMap = jsonDecode(beneficiaryInfo) as Map<String, dynamic>?;
          if (infoMap == null) continue;

          final relation = infoMap['relation']?.toString().toLowerCase();
          final mobileOwner = infoMap['mobileOwner']?.toString().toLowerCase();
          final mobile = infoMap['mobileNo']?.toString();

          // Check if this is a spouse/mother with self-owned mobile
          if ((relation == 'mother' ||
                  relation == 'spouse' ||
                  relation == 'wife') &&
              mobileOwner == 'self' &&
              mobile != null &&
              mobile.isNotEmpty) {
            print(
              '✅ [getSpouseMobileNumber] Found spouse with self-owned mobile: $mobile',
            );
            return mobile;
          }
        } catch (e) {
          print('❌ [getSpouseMobileNumber] Error parsing beneficiary info: $e');
        }
      }

      for (final beneficiary in beneficiaries) {
        final beneficiaryInfo = beneficiary['beneficiary_info'] as String?;
        if (beneficiaryInfo == null || beneficiaryInfo.isEmpty) continue;

        try {
          final infoMap = jsonDecode(beneficiaryInfo) as Map<String, dynamic>?;
          if (infoMap == null) continue;

          final relation = infoMap['relation']?.toString().toLowerCase();
          final mobile = infoMap['mobileNo']?.toString();

          if ((relation == 'mother' ||
                  relation == 'spouse' ||
                  relation == 'wife') &&
              mobile != null &&
              mobile.isNotEmpty) {
            print('ℹ️ [getSpouseMobileNumber] Found spouse mobile: $mobile');
            return mobile;
          }
        } catch (e) {
          print(
            '❌ [getSpouseMobileNumber] Error parsing beneficiary info (fallback): $e',
          );
        }
      }

      print('ℹ️ [getSpouseMobileNumber] No mobile number found for spouse');
      return null;
    } catch (e) {
      print('❌ [getSpouseMobileNumber] Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMigratedBeneficiaries() async {
    try {
      print('🔍 [getMigratedRecords] Querying migrated records...');
      final db = await _db;

      // Get current user's unique key
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();

      if (ashaUniqueKey == null) {
        print('⚠️ [getMigratedRecords] No user unique key found');
        return [];
      }

      final debugInfo = await debugDeathRecords();
      print('🔍 [getMigratedRecords] Debug Info: $debugInfo');

      final rows = await db.query(
        BeneficiariesTable.table,
        where: 'is_migrated = 1 AND is_deleted = 0 AND current_user_key = ?',
        whereArgs: [ashaUniqueKey],
        orderBy: 'created_date_time DESC',
      );

      print(
        '✅ [getMigratedRecords] Found ${rows.length} migrated records for user $ashaUniqueKey',
      );

      return rows
          .map((row) {
            try {
              final mapped = Map<String, dynamic>.from(row);
              // Parse JSON fields
              mapped['beneficiary_info'] = safeJsonDecode(
                mapped['beneficiary_info'],
              );
              mapped['death_details'] = safeJsonDecode(mapped['death_details']);
              mapped['device_details'] = safeJsonDecode(
                mapped['device_details'],
              );
              mapped['app_details'] = safeJsonDecode(mapped['app_details']);
              mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
              return mapped;
            } catch (e) {
              print('❌ Error parsing record $row: $e');
              return <String, dynamic>{}; // Return empty map on parse error
            }
          })
          .where((map) => map.isNotEmpty)
          .toList(); // Filter out any empty maps from failed parses
    } catch (e, stackTrace) {
      print('❌ [getMigratedRecords] Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getANCList() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        where: 'is_deleted = ?',
        whereArgs: [0],
        orderBy: 'created_date_time DESC',
      );
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

  Future<String> getLatestHouseholdServerId() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      final db = await _db;
      final rows = await db.query(
        'households',
        columns: [
          'server_id',
          'created_date_time',
          'modified_date_time',
          'id',
          'is_deleted',
        ],
        where:
            "server_id IS NOT NULL AND TRIM(server_id) != '' AND current_user_key = ?",
        whereArgs: [ashaUniqueKey],
        orderBy: "created_date_time DESC",
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

      String ashaUniqueKey = '';
      try {
        final currentUser = await UserInfo.getCurrentUser();
        final userDetails = currentUser?['details'] is String
            ? jsonDecode(currentUser?['details'] ?? '{}')
            : currentUser?['details'] ?? {};
        ashaUniqueKey = userDetails['unique_key']?.toString() ?? '';
      } catch (e) {
        print('⚠️ Unable to fetch ASHA unique key in saveGuestBeneficiary: $e');
      }

      if (!beneficiaryMap.containsKey('current_user_key') ||
          beneficiaryMap['current_user_key'] == null ||
          beneficiaryMap['current_user_key'].toString().trim().isEmpty) {
        beneficiaryMap['current_user_key'] = ashaUniqueKey;
      }
      if (!beneficiaryMap.containsKey('facility_id') ||
          (beneficiaryMap['facility_id'] == null)) {
        beneficiaryMap['facility_id'] = 0;
      }
      if (!beneficiaryMap.containsKey('parent_user') ||
          (beneficiaryMap['parent_user'] == null)) {
        beneficiaryMap['parent_user'] = jsonEncode({});
      }
      if (!beneficiaryMap.containsKey('app_details') ||
          (beneficiaryMap['app_details'] == null)) {
        beneficiaryMap['app_details'] = jsonEncode({
          'app_name': 'BHAVYAmASHA',
          'version': '1.0.0',
        });
      }
      if (!beneficiaryMap.containsKey('device_details') ||
          (beneficiaryMap['device_details'] == null)) {
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
              row['beneficiary_info'] = safeJsonDecode(
                row['beneficiary_info']?.toString(),
              );
              row['death_details'] = safeJsonDecode(
                row['death_details']?.toString(),
              );
              row['device_details'] = safeJsonDecode(
                row['device_details']?.toString(),
              );
              row['app_details'] = safeJsonDecode(
                row['app_details']?.toString(),
              );
              row['parent_user'] = safeJsonDecode(
                row['parent_user']?.toString(),
              );
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
              row['beneficiary_info'] = safeJsonDecode(
                row['beneficiary_info']?.toString(),
              );
              row['death_details'] = safeJsonDecode(
                row['death_details']?.toString(),
              );
              row['device_details'] = safeJsonDecode(
                row['device_details']?.toString(),
              );
              row['app_details'] = safeJsonDecode(
                row['app_details']?.toString(),
              );
              row['parent_user'] = safeJsonDecode(
                row['parent_user']?.toString(),
              );
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

  Future<Map<String, dynamic>?> getHouseholdByUniqueKey(
    String uniqueKey,
  ) async {
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

  Future<int> markChildCareActivitySyncedById(
    int id, {
    String? serverId,
  }) async {
    final db = await _db;
    final values = <String, Object?>{
      'is_synced': 1,
      'modified_date_time': DateTime.now().toIso8601String(),
    };
    if (serverId != null && serverId.isNotEmpty) values['server_id'] = serverId;
    return db.update(
      'child_care_activities',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> getLatestFollowupFormServerId() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      final db = await _db;
      final rows = await db.query(
        FollowupFormDataTable.table,
        columns: [
          'server_id',
          'created_date_time',
          'modified_date_time',
          'id',
          'is_deleted',
        ],
        where:
            "server_id IS NOT NULL AND TRIM(server_id) != '' AND current_user_key = ?",
        whereArgs: [ashaUniqueKey],
        orderBy: "created_date_time DESC",
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
        where:
            'forms_ref_key = ? AND household_ref_key = ? AND beneficiary_ref_key = ?',
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

  Future<List<Map<String, dynamic>>> getPncMotherFormsByBeneficiaryId(
    String beneficiaryId,
  ) async {
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

  Future<int> insertClusterMeeting(Map<String, dynamic> formData) async {
    try {
      final db = await _db;

      final row = <String, dynamic>{
        'unique_key':
            formData['unique_key'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'form_json': jsonEncode(formData['form_json'] ?? {}),
        // your entire form as JSON
        'created_date_time': DateTime.now().toIso8601String(),
        'created_by': formData['created_by'] ?? 'current_user_key',
        'modified_date_time': null,
        'modified_by': null,
        'is_synced': 0,
        'is_deleted': 0,
      };

      final id = await db.insert(ClusterMeetingsTable.table, row);
      print('Cluster meeting saved locally with id: $id');
      return id;
    } catch (e, stack) {
      print('Error inserting cluster meeting: $e');
      print(stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getClusterMeetingById(String uniqueKey) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'cluster_meetings',
      where: 'unique_key = ?',
      whereArgs: [uniqueKey],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> updateClusterMeeting({
    required String uniqueKey,
    required Map<String, dynamic> formJson,
  }) async {
    final db = await _db;

    await db.update(
      ClusterMeetingsTable.table,
      {
        'form_json': jsonEncode(formJson),
        'modified_date_time': DateTime.now().toIso8601String(),
        'modified_by': 'current_user',
      },
      where: 'unique_key = ?',
      whereArgs: [uniqueKey],
    );
  }

  // VIEW: Get all saved cluster meetings (latest first)
  Future<List<Map<String, dynamic>>> getAllClusterMeetings() async {
    try {
      final db = await _db;
      final rows = await db.query(
        ClusterMeetingsTable.table,
        where: 'is_deleted = 0',
        orderBy: 'created_date_time DESC',
      );

      return rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        // Decode form_json back to Map
        try {
          mapped['form_json'] = jsonDecode(mapped['form_json'] as String);
        } catch (e) {
          mapped['form_json'] = {};
        }
        return mapped;
      }).toList();
    } catch (e) {
      print('Error fetching cluster meetings: $e');
      return [];
    }
  }

  Future<String?> getHeadOfFamilyMobileNumber(String householdRefKey) async {
    try {
      final db = await _db;

      final household = await db.query(
        'households',
        where: 'unique_key = ? AND is_deleted = 0',
        whereArgs: [householdRefKey],
        limit: 1,
      );

      if (household.isEmpty) return null;

      final headId = household.first['head_id'] as String?;
      if (headId == null || headId.isEmpty) return null;

      // Now get the beneficiary_info for the head
      final beneficiaries = await db.query(
        'beneficiaries_new',
        where: 'unique_key = ? AND is_deleted = 0',
        whereArgs: [headId],
        limit: 1,
      );

      if (beneficiaries.isEmpty) return null;

      final beneficiaryInfo =
          beneficiaries.first['beneficiary_info'] as String?;
      if (beneficiaryInfo == null) return null;

      // Parse the JSON to get the mobile number
      try {
        final infoMap = jsonDecode(beneficiaryInfo) as Map<String, dynamic>?;
        return infoMap?['mobile_number'] as String?;
      } catch (e) {
        print('Error parsing beneficiary_info JSON: $e');
        return null;
      }
    } catch (e) {
      print('Error in getHeadOfFamilyMobileNumber: $e');
      return null;
    }
  }
}

extension LocalStorageDaoReads on LocalStorageDao {
  /// Get family update count - counts family heads from beneficiaries
  Future<int> getFamilyUpdateCount() async {
    try {
      final rows = await getAllBeneficiaries();
      final households = await getAllHouseholds();

      /// Household -> configured head map
      final headKeyByHousehold = <String, String>{};
      for (final hh in households) {
        try {
          final hhRefKey = (hh['unique_key'] ?? '').toString();
          final headId = (hh['head_id'] ?? '').toString();
          if (hhRefKey.isEmpty || headId.isEmpty) continue;
          headKeyByHousehold[hhRefKey] = headId;
        } catch (_) {}
      }

      /// --------- FAMILY HEAD FILTER ----------
      final familyHeads = rows.where((r) {
        try {
          final householdRefKey = (r['household_ref_key'] ?? '').toString();
          final uniqueKey = (r['unique_key'] ?? '').toString();
          if (householdRefKey.isEmpty || uniqueKey.isEmpty) return false;

          // Exclude migrated & death
          if (r['is_death'] == 1 || r['is_migrated'] == 1) return false;

          final rawInfo = r['beneficiary_info'];
          Map<String, dynamic> info;
          if (rawInfo is Map) {
            info = Map<String, dynamic>.from(rawInfo);
          } else if (rawInfo is String && rawInfo.isNotEmpty) {
            info = Map<String, dynamic>.from(jsonDecode(rawInfo));
          } else {
            info = {};
          }

          final configuredHeadKey = headKeyByHousehold[householdRefKey];

          final bool isConfiguredHead =
              configuredHeadKey != null && configuredHeadKey == uniqueKey;

          final relation = (info['relation_to_head'] ?? info['relation'] ?? '')
              .toString()
              .toLowerCase();

          final bool isHeadByRelation =
              relation == 'head' || relation == 'self';

          // ✅ NEW CONDITION
          final bool isFamilyHead =
              info['isFamilyHead'] == true ||
              info['isFamilyHead']?.toString().toLowerCase() == 'true';

          return isConfiguredHead || isHeadByRelation || isFamilyHead;
        } catch (_) {
          return false;
        }
      }).toList();

      return familyHeads.length;
    } catch (e) {
      print('Error getting family update count: $e');
      return 0;
    }
  }

  Future<String> getLatestBeneficiaryServerId() async {
    try {
      final currentUserData = await SecureStorageService.getCurrentUserData();
      final String? ashaUniqueKey = currentUserData?['unique_key']?.toString();
      final db = await _db;
      final rows = await db.query(
        'beneficiaries_new',
        columns: ['server_id'],
        where:
            "server_id IS NOT NULL AND TRIM(server_id) != '' AND current_user_key = ?",
        whereArgs: [ashaUniqueKey],
        orderBy: "id DESC",
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
