import 'dart:convert';

import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';
import 'package:sqflite/sqflite.dart';

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

  Future<Map<String, dynamic>?> getBeneficiaryByUniqueKey(String uniqueKey) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries',
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

  Future<int> updateBeneficiaryServerIdByUniqueKey({required String uniqueKey, required String serverId}) async {
    try {
      final db = await _db;
      final changes = await db.update(
        'beneficiaries',
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
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM households WHERE is_deleted = 0')
    );
    return count ?? 0;
  }


  Future<List<Map<String, dynamic>>> getFollowupFormsWithCaseClosure(String formType) async {
    final db = await _db;

    final forms = await db.query(
      FollowupFormDataTable.table,
      where: 'is_deleted = 0 AND form_json LIKE ?',
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
                  'beneficiaries',
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

  Future<List<Map<String, dynamic>>> getBeneficiariesByHousehold(String householdId) async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries',
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
        'beneficiaries',
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
      final rows = await db.query('beneficiaries',
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

  Future<List<Map<String, dynamic>>> getDeathRecords() async {
    try {
      final db = await _db;
      final rows = await db.query(
        'beneficiaries',
        where: 'is_death = ? AND is_deleted = ?',
        whereArgs: [1, 0],
        orderBy: 'created_date_time DESC',
      );
      final result = <Map<String, dynamic>>[];
      
      for (final row in rows) {
        try {
          final mapped = Map<String, dynamic>.from(row);

          final beneficiaryInfo = safeJsonDecode(mapped['beneficiary_info']);
          final deathDetails = safeJsonDecode(mapped['death_details']);

          final headDetails = beneficiaryInfo is Map 
              ? (beneficiaryInfo['head_details'] ?? {}) 
              : {};
          
          // Format the death record
          final deathRecord = {
            'id': mapped['id'],
            'hhId': mapped['household_ref_key'],
            'name': headDetails['headName'] ?? headDetails['memberName'] ?? 'Unknown',
            'age/gender': _getAgeGender(headDetails),
            'date': _formatDeathDate(deathDetails),
            'place': deathDetails['placeOfDeath'] ?? 'Not specified',
            'status': headDetails['maritalStatus'] ?? 'Unknown',
            'beneficiary_info': beneficiaryInfo,
            'death_details': deathDetails,
          };
          
          result.add(deathRecord);
          
        } catch (e) {
          print('Error processing death record: $e');
        }
      }
      return result;
      
    } catch (e, stackTrace) {
      print('Error getting death records: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  String _getAgeGender(Map<String, dynamic> headDetails) {
    final dob = headDetails['dob'];
    if (dob == null) return 'Unknown';
    
    try {
      final birthDate = DateTime.tryParse(dob);
      if (birthDate == null) return 'Unknown';
      
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      
      // Adjust age if birthday hasn't occurred yet this year
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      final gender = (headDetails['gender'] ?? '').toString().toLowerCase();
      final genderDisplay = gender == 'm' ? 'Male' : gender == 'f' ? 'Female' : 'Unknown';
      
      return '$age Y / $genderDisplay';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  String _formatDeathDate(Map<String, dynamic> deathDetails) {
    final dateStr = deathDetails['dateOfDeath'];
    if (dateStr == null) return 'Date not available';
    
    try {
      final date = DateTime.tryParse(dateStr);
      if (date == null) return dateStr; // Return original string if parsing fails
      
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr; // Return original string if any error occurs
    }
  }
}
