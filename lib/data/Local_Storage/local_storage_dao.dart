import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'database_provider.dart';

class LocalStorageDao {
  LocalStorageDao._();
  static final LocalStorageDao instance = LocalStorageDao._();

  Future<Database> get _db async => DatabaseProvider.instance.database;

  dynamic _encodeIfObject(dynamic v) {
    if (v == null) return null;
    if (v is Map || v is List) return jsonEncode(v);
    return v;
  }



  Future<int> insertHousehold(Map<String, dynamic> data) async {
    try {
      final db = await _db;
      

      
      final householdInfo = data['household_info'];
      if (householdInfo is String) {
        try {
          final parsed = jsonDecode(householdInfo);
          print('   (JSON String) $parsed');
        } catch (e) {
          print('   (Invalid JSON String) $householdInfo');
        }
      } else if (householdInfo is Map) {
        print('   (Map) $householdInfo');
      } else {
        print('   (${householdInfo.runtimeType}) $householdInfo');
      }
      
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
      
      print('\n Database Row to Insert:');
      row.forEach((key, value) {
        print('   $key: ${value.toString().substring(0, value.toString().length > 100 ? 100 : value.toString().length)}...');
      });
      
      final id = await db.insert('households', row);
      print(' Household inserted with ID: $id\n');
      return id;
    } catch (e, stackTrace) {
      print('Error inserting household:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
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
    return db.insert('beneficiaries', row);
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
      'created_date_time': data['created_date_time'],
      'modified_date_time': data['modified_date_time'],
      'is_synced': data['is_synced'] ?? 0,
      'is_deleted': data['is_deleted'] ?? 0,
    };
    return db.insert('followup_form_data', row);
  }

  Future<int> getHouseholdCount() async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM households WHERE is_deleted = 0')
    );
    return count ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAllHouseholds() async {
    try {
      final db = await _db;
      print('Fetching all households from database...');
      
      final rows = await db.query('households', 
        where: 'is_deleted = ?',
        whereArgs: [0],
        orderBy: 'created_date_time DESC');
      
      print('Found ${rows.length} households');
      
      final result = rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        
        // Helper function to safely decode JSON strings
        dynamic safeJsonDecode(String? jsonString) {
          if (jsonString == null || jsonString.isEmpty) return {};
          try {
            return jsonDecode(jsonString);
          } catch (e) {
            print('Error decoding JSON: $e');
            return {};
          }
        }
        

        mapped['address'] = safeJsonDecode(mapped['address']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['household_info'] = safeJsonDecode(mapped['household_info']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
        
        return mapped;
      }).toList();
      
      print('Successfully decoded ${result.length} households');
      return result;
      
    } catch (e, stackTrace) {
      print('Error getting households: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllBeneficiaries() async {
    try {
      final db = await _db;
      print('Fetching all beneficiaries from database...');
      final rows = await db.query('beneficiaries',
        where: 'is_deleted = ?',
        whereArgs: [0],
        orderBy: 'created_date_time DESC');
      print('Found [1m${rows.length}[0m beneficiaries');
      final result = rows.map((row) {
        final mapped = Map<String, dynamic>.from(row);
        dynamic safeJsonDecode(String? jsonString) {
          if (jsonString == null || jsonString.isEmpty) return {};
          try {
            return jsonDecode(jsonString);
          } catch (e) {
            print('Error decoding JSON: $e');
            return {};
          }
        }
        mapped['beneficiary_info'] = safeJsonDecode(mapped['beneficiary_info']);
        mapped['geo_location'] = safeJsonDecode(mapped['geo_location']);
        mapped['death_details'] = safeJsonDecode(mapped['death_details']);
        mapped['device_details'] = safeJsonDecode(mapped['device_details']);
        mapped['app_details'] = safeJsonDecode(mapped['app_details']);
        mapped['parent_user'] = safeJsonDecode(mapped['parent_user']);
        return mapped;
      }).toList();
      print('Successfully decoded ${result.length} beneficiaries');
      for (final beneficiary in result) {
        print('Beneficiary:');
        beneficiary.forEach((key, value) {
          print('  $key: $value');
        });
        print('---');
      }
      return result;
    } catch (e, stackTrace) {
      print('Error getting beneficiaries: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
