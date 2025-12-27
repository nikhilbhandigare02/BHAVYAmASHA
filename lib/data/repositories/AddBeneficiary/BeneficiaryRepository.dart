import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/core/utils/device_info_utils.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';

class BeneficiaryRepository {
  final NetworkServiceApi _api = NetworkServiceApi();

  Future<Map<String, dynamic>> fetchAndStoreBeneficiaries({required String lastId, int pageSize = 20}) async {
    final currentUser = await UserInfo.getCurrentUser();
    final userDetails = currentUser?['details'] is String
        ? jsonDecode(currentUser?['details'] ?? '{}')
        : currentUser?['details'] ?? {};

    String? token = await SecureStorageService.getToken();
    if ((token == null || token.isEmpty) && userDetails is Map) {
      try {
        token = userDetails['token']?.toString();
      } catch (_) {}
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    String effectiveLastId = lastId;
    if (effectiveLastId.isEmpty) {
      effectiveLastId = await LocalStorageDao.instance.getLatestBeneficiaryServerId();
    }

    dynamic response;
    try {
      response = await _api.getApiWithBody(
        Endpoints.getBeneficiary,
        {
          'last_id': effectiveLastId,
        },
        headers: headers,
      );
    } catch (e) {
      try {
        response = await _api.getApi(
          Endpoints.getBeneficiary,
          headers: headers,
          queryParams: {
            'last_id': effectiveLastId,
            'page_size': pageSize.toString(),
          },
        );
      } catch (_) {
        response = await _api.getApi(
          Endpoints.getBeneficiary,
          headers: headers,
          queryParams: {
            'last_id': effectiveLastId,
            'page_size': pageSize.toString(),
          },
        );
      }
    }

    final dataList = (response is Map && response['data'] is List)
        ? List<Map<String, dynamic>>.from(response['data'] as List)
        : <Map<String, dynamic>>[];

    int inserted = 0;
    int updated = 0;
    int skipped = 0;
    for (final rec in dataList) {
      try {
        final serverId = rec['_id']?.toString();
        if (serverId == null || serverId.isEmpty) continue;

        final info = _mapBeneficiaryInfo(rec);

        final hhRefKey = rec['household_ref_key']?.toString();
        final benUniqueKey = rec['unique_key']?.toString();
        if (hhRefKey != null && hhRefKey.isNotEmpty) {
          final existingHh = await LocalStorageDao.instance.getHouseholdByUniqueKey(hhRefKey);
          if (existingHh == null || existingHh.isEmpty) {
            final householdInfo = <String, dynamic>{};
            final beneficiaryInfo = info;

            householdInfo['houseNo'] = beneficiaryInfo['houseNo'];
            householdInfo['headName'] = beneficiaryInfo['headName'] ?? beneficiaryInfo['name'];

            final toInsertHh = <String, dynamic>{
              'server_id': null,
              'unique_key': hhRefKey,
              'address': beneficiaryInfo['address'] ?? {},
              'geo_location': rec['geo_location'] ?? {},
              'head_id': benUniqueKey,
              'household_info': householdInfo,
              'device_details': rec['device_details'] ?? {},
              'app_details': rec['app_details'] ?? {},
              'parent_user': rec['parent_user'] ?? {},
              'current_user_key': rec['current_user_key']?.toString(),
              'facility_id': _toInt(rec['facility_id']),
              'created_date_time': rec['created_date_time']?.toString(),
              'modified_date_time': rec['modified_date_time']?.toString(),
              'is_synced': 1,
              'is_deleted': _toInt(rec['is_deleted']),
            };

            await LocalStorageDao.instance.insertHousehold(toInsertHh);
          }
        }

        final row = <String, dynamic>{
          'server_id': serverId,
          'household_ref_key': rec['household_ref_key']?.toString(),
          'unique_key': rec['unique_key']?.toString(),
          'beneficiary_state': rec['beneficiary_state'],
          'pregnancy_count': rec['pregnancy_count'] ?? 0,
          'beneficiary_info': info,
          'geo_location': rec['geo_location'] ?? {},
          'spouse_key': rec['spouse_key']?.toString(),
          'mother_key': rec['mother_key']?.toString(),
          'father_key': rec['father_key']?.toString(),
          'is_family_planning': _toInt(rec['is_family_planning']),
          'is_adult': _toInt(rec['is_adult']),
          'is_guest': _toInt(rec['is_guest']),
          'is_death': _toInt(rec['is_death']),
          'death_details': rec['death_details'] ?? {},
          'is_migrated': _toInt(rec['is_migrated']),
          'is_separated': _toInt(rec['is_separated']),
          'device_details': rec['device_details'] ?? {},
          'app_details': rec['app_details'] ?? {},
          'parent_user': rec['parent_user'] ?? {},
          'current_user_key': rec['current_user_key']?.toString(),
          'facility_id': _toInt(rec['facility_id']),
          'created_date_time': rec['created_date_time']?.toString(),
          'modified_date_time': rec['modified_date_time']?.toString(),
          'is_synced': 1,
          'is_deleted': _toInt(rec['is_deleted']),
        };

        final uniqueKey = row['unique_key']?.toString();
        if (uniqueKey != null && uniqueKey.isNotEmpty) {
          final existing = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(uniqueKey);
          if (existing != null && existing.isNotEmpty) {
            final existingSynced = (existing['is_synced'] == 1) || (existing['is_synced']?.toString() == '1');
            if (existingSynced) {
              skipped++;
              continue;
            }
            skipped++;
            continue;
          }
        }
        await LocalStorageDao.instance.insertBeneficiary(row);
        
        // Check if this beneficiary is female and pregnant
        try {
          final beneficiaryInfo = _mapBeneficiaryInfo(rec);
          final gender = beneficiaryInfo['gender']?.toString().toLowerCase();
          final isPregnant = (beneficiaryInfo['isPregnant']?.toString().toLowerCase() == 'yes' ||
                            beneficiaryInfo['isPregnant']?.toString().toLowerCase() == 'true');
          
          if (gender == 'female' && isPregnant) {
            final currentUser = await UserInfo.getCurrentUser();
            final userDetails = currentUser?['details'] is String
                ? jsonDecode(currentUser?['details'] ?? '{}')
                : currentUser?['details'] ?? {};
            
            final ashaUniqueKey = userDetails['unique_key']?.toString() ?? '';
            final facilityId = userDetails['facility_id']?.toString() ?? '';
            final uniqueKey = row['unique_key']?.toString() ?? '';
            final householdKey = row['household_ref_key']?.toString() ?? '';
            
            if (uniqueKey.isNotEmpty && householdKey.isNotEmpty) {
              final ts = DateTime.now().toIso8601String();
              
              final motherCareActivityData = {
                'server_id': null,
                'household_ref_key': householdKey,
                'beneficiary_ref_key': uniqueKey,
                'mother_care_state': 'anc_due',
                'device_details': jsonEncode(rec['device_details'] ?? {}),
                'app_details': jsonEncode(rec['app_details'] ?? {}),
                'parent_user': jsonEncode({}),
                'current_user_key': ashaUniqueKey,
                'facility_id': facilityId,
                'created_date_time': ts,
                'modified_date_time': ts,
                'is_synced': 0,
                'is_deleted': 0,
              };

              print('Inserting mother care activity for pregnant beneficiary: ${jsonEncode(motherCareActivityData)}');
              await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
            }
          }
          
          // Check for eligible couple
          final maritalStatus = beneficiaryInfo['maritalStatus']?.toString().toLowerCase() ?? 
                              beneficiaryInfo['marital_status']?.toString().toLowerCase() ?? '';
          final age = _calculateAge(beneficiaryInfo['dob']?.toString() ?? '');
          final isEligibleForCouple = maritalStatus == 'married' && age >= 15 && age <= 49;

          if (isEligibleForCouple) {
            try {
              final currentUser = await UserInfo.getCurrentUser();
              final userDetails = currentUser?['details'] is String
                  ? jsonDecode(currentUser?['details'] ?? '{}')
                  : currentUser?['details'] ?? {};
              
              final ashaUniqueKey = userDetails['unique_key']?.toString() ?? '';
              final facilityId = userDetails['facility_id']?.toString() ?? '';
              final uniqueKey = row['unique_key']?.toString() ?? '';
              final householdKey = row['household_ref_key']?.toString() ?? '';
              final spouseKey = row['spouse_key']?.toString() ?? '';
              
              if (uniqueKey.isNotEmpty && householdKey.isNotEmpty) {
                final ts = DateTime.now().toIso8601String();
                final deviceInfo = await DeviceInfo.getDeviceInfo();
                final deviceDetails = {
                  'id': deviceInfo.deviceId,
                  'platform': deviceInfo.platform,
                  'version': deviceInfo.osVersion,
                  'model': deviceInfo.model,
                };
                
                final eligibleCoupleActivityData = {
                  'server_id': '',
                  'household_ref_key': householdKey,
                  'beneficiary_ref_key': uniqueKey,
                  'eligible_couple_state': 'eligible_couple',
                  'device_details': jsonEncode(deviceDetails),
                  'app_details': jsonEncode({
                    'app_version': deviceInfo.appVersion.split('+').first,
                    'form_data': {
                      'created_at': ts,
                      'updated_at': ts,
                    },
                  }),
                  'parent_user': '',
                  'current_user_key': ashaUniqueKey,
                  'facility_id': facilityId,
                  'created_date_time': ts,
                  'modified_date_time': ts,
                  'is_synced': 0,
                  'is_deleted': 0,
                };

                print('Inserting eligible couple activity for beneficiary: $uniqueKey');
                final db = await DatabaseProvider.instance.database;
                await db.insert(
                  'eligible_couple_activities',
                  eligibleCoupleActivityData,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
            } catch (e) {
              print('Error inserting eligible couple activity: $e');
            }
          }
        } catch (e) {
          print('Error checking/inserting mother care activity or eligible couple: $e');
        }
        
        inserted++;
      } catch (e) {
        print('Error inserting beneficiary: $e');
      }
    }

    return {
      'inserted': inserted,
      'updated': updated,
      'skipped': skipped,
      'fetched': dataList.length,
      'next_cursor': response is Map ? response['next_cursor'] : null,
      'success': response is Map ? response['success'] : null,
      'msg': response is Map ? response['msg'] : null,
    };
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is bool) return v ? 1 : 0;
    return int.tryParse(v.toString()) ?? 0;
  }

  int _calculateAge(String dobString) {
    if (dobString.isEmpty) return 0;
    
    try {
      final dob = DateTime.tryParse(dobString);
      if (dob == null) return 0;
      
      final now = DateTime.now();
      int age = now.year - dob.year;
      
      // Adjust age if birthday hasn't occurred yet this year
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      
      return age < 0 ? 0 : age;
    } catch (e) {
      print('Error calculating age: $e');
      return 0;
    }
  }

  Map<String, dynamic> _mapBeneficiaryInfo(Map<String, dynamic> rec) {


    dynamic rawInfo = rec['beneficiary_info'];
    Map<String, dynamic> info;

    if (rawInfo is String && rawInfo.isNotEmpty) {
      try {
        info = Map<String, dynamic>.from(jsonDecode(rawInfo));
      } catch (_) {
        info = <String, dynamic>{};
      }
    } else if (rawInfo is Map) {
      info = Map<String, dynamic>.from(rawInfo as Map);
    } else {
      info = <String, dynamic>{};
    }

    final looksLikeAppFormat =
        info.containsKey('houseNo') ||
        info.containsKey('headName') ||
        info.containsKey('memberType') ||
        info.containsKey('memberName') ||
        info.containsKey('relation_to_head');
    if (looksLikeAppFormat) {
      return info;
    }



    final nameMap = info['name'] is Map
        ? Map<String, dynamic>.from(info['name'] as Map)
        : <String, dynamic>{};
    final first = (nameMap['first_name'] ?? info['first_name'] ?? '').toString().trim();
    final middle = (nameMap['middle_name'] ?? info['middle_name'] ?? '').toString().trim();
    final last = (nameMap['last_name'] ?? info['last_name'] ?? '').toString().trim();
    final fullNameParts = <String>[first, middle, last].where((s) => s.isNotEmpty).toList();
    String fullName = fullNameParts.join(' ').trim();
    if (fullName.isEmpty) {
      final rawName = info['name'];
      if (rawName is String) fullName = rawName.trim();
    }

    String? _genderText(String? g) {
      if (g == null) return null;
      final s = g.toUpperCase();
      if (s == 'M') return 'Male';
      if (s == 'F') return 'Female';
      if (s == 'O') return 'Other';
      return g;
    }

    String? _titleCase(String? v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty) return s;
      return s[0].toUpperCase() + s.substring(1).toLowerCase();
    }

    final addr = info['address'] is Map
        ? Map<String, dynamic>.from(info['address'] as Map)
        : <String, dynamic>{};

    final mapped = <String, dynamic>{
      'memberType': info['memberType'],
      'relation': info['relation'] ?? info['relation_to_head'] ?? '',
      'name': fullName,

      'houseNo': info['houseNo'],
      'headName': fullName,
      'fatherName': info['father_name'] ?? info['fatherName'],
      'motherName': info['mother_name'] ?? info['motherName'],

      // DOB / age
      'useDob': info['useDob'] ?? true,
      'dob': info['dob']?.toString(),
      'approxAge': info['approxAge'],
      'years': info['years'],
      'months': info['months'],
      'days': info['days'],
      'updateDay': info['updateDay'],
      'updateMonth': info['updateMonth'],
      'updateYear': info['updateYear'],

      // Children summary (for compatibility with children bloc)
      'children': info['children'] ?? [],
      'birthOrder': info['birthOrder'],
      'totalBorn': info['totalBorn'],
      'totalLive': info['totalLive'],
      'totalMale': info['totalMale'],
      'totalFemale': info['totalFemale'],
      'youngestAge': info['youngestAge'],
      'ageUnit': info['ageUnit'],
      'youngestGender': info['youngestGender'],

      // Demographics
      'gender': _genderText(info['gender']?.toString()),
      'occupation': info['occupation'],
      'education': info['education'],
      'religion': info['religion'],
      'category': info['category'],

      // Health / pregnancy
      'hasChildren': info['hasChildren'],
      'isPregnant': info['isPregnant'],
      'lmp': info['lmp']?.toString(),
      'edd': info['edd']?.toString(),
      'beneficiaryType': info['beneficiaryType'],

      // Contact & IDs
      'mobileOwner': info['mobileOwner'],
      'mobileNo': (info['mobileNo'] ?? info['phone'])?.toString(),
      'abhaAddress': info['abhaAddress'],
      'abhaNumber': info['abhaNumber'],
      'voterId': info['voterId'],
      'rationId': info['rationId'],
      'rationCardId': info['rationCardId'],
      'phId': info['phId'],
      'personalHealthId': info['personalHealthId'],
      'bankAcc': info['bankAcc'],
      'bankAccountNumber': info['bankAccountNumber'],
      'ifsc': info['ifsc'],
      'ifscCode': info['ifscCode'],

      // Marital
      'maritalStatus': _titleCase((info['marital_status'] ?? info['maritalStatus'])?.toString()),
      'ageAtMarriage': info['ageAtMarriage'],
      'spouseName': info['spouseName'],

      // Address fields flattened to match local structure
      'village': addr['village'],
      'ward': info['ward'],
      'wardNo': info['wardNo'],
      'mohalla': info['mohalla'],
      'mohallaTola': info['mohallaTola'],

      // Misc fields that may be used in local flows
      'weight': info['weight'],
      'childSchool': info['childSchool'],
      'birthCertificate': info['birthCertificate'],
      'memberStatus': info['memberStatus'],
      'relation_to_head': info['relation_to_head'] ?? info['relationToHead'] ?? '',
    };

    mapped.removeWhere((key, value) => value == null);
    return mapped;
  }
}
