import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/repositories/AddBeneficiary/AddBeneficiaryRepository.dart';

class AddBeneficiaryApiHelper {
  final AddBeneficiaryRepository _repo = AddBeneficiaryRepository();


  Future<void> syncBeneficiaryByUniqueKey({
    required String uniqueKey,
  }) async {
    // Get current timestamp
    final ts = DateTime.now().toIso8601String();
    // Device info will be extracted from the saved beneficiary data
    try {
      // 1. Fetch beneficiary data from local storage
      final saved = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(uniqueKey);
      if (saved == null) {
        print('Beneficiary with uniqueKey $uniqueKey not found in local database');
        return;
      }

      // 2. Get user and working location details
      final currentUser = await UserInfo.getCurrentUser();
      final userDetails = currentUser?['details'] is String
          ? jsonDecode(currentUser?['details'] ?? '{}')
          : currentUser?['details'] ?? {};
          
      final working = userDetails['working_location'] ?? {};
      final facilityId = working['asha_associated_with_facility_id'] ??
          userDetails['asha_associated_with_facility_id'] ?? 0;
      final ashaUniqueKey = userDetails['unique_key'] ?? '';

      final deviceInfo = {
        'deviceId': saved['device_details']?['deviceId'] ?? '',
        'model': saved['device_details']?['model'] ?? 'Unknown',
        'manufacturer': saved['device_details']?['manufacturer'] ?? 'Unknown',
        'deviceName': saved['device_details']?['deviceName'] ?? 'Unknown',
        'systemName': saved['device_details']?['systemName'] ?? 'Unknown',
        'systemVersion': saved['device_details']?['systemVersion'] ?? 'Unknown',
      };
          
      // 4. Build the API payload
      final payload = _buildBeneficiaryApiPayload(
        Map<String, dynamic>.from(saved),
        Map<String, dynamic>.from(userDetails is Map ? userDetails : {}),
        Map<String, dynamic>.from(working is Map ? working : {}),
        deviceInfo, // Structured device info
        ts,
        ashaUniqueKey,
        facilityId,
      );

      print('Synchronizing beneficiary with payload: ${jsonEncode(payload)}');


      final reqUniqueKey = (saved['unique_key'] ?? '').toString();
      final resp = await _repo.addBeneficiary(payload);


      if (resp is Map && (resp['success'] == true)) {
        String? serverId;
        

        if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
          final first = resp['data'][0];
          if (first is Map) {
            serverId = (first['_id'] ?? first['id'] ?? '').toString();
          }
        } else if (resp['data'] is Map) {
          final map = Map<String, dynamic>.from(resp['data']);
          serverId = (map['_id'] ?? map['id'] ?? '').toString();
        }

        // Update local database with server ID if available
        if (serverId != null && serverId.isNotEmpty && reqUniqueKey.isNotEmpty) {
          final updated = await LocalStorageDao.instance.updateBeneficiaryServerIdByUniqueKey(
            uniqueKey: reqUniqueKey, 
            serverId: serverId,
          );
          print('Successfully updated beneficiary with server_id=$serverId, rows_updated=$updated');
        } else {
          print('Warning: No server ID found in API response for beneficiary $reqUniqueKey');
        }
      } else {
        print('API call was not successful for beneficiary $reqUniqueKey. Response: $resp');
      }
    } catch (e, stackTrace) {
      print('Error syncing beneficiary $uniqueKey: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Re-throw to allow retry logic in the sync service
    }
  }

  Map<String, dynamic> _buildBeneficiaryApiPayload(
    Map<String, dynamic> row,
    Map<String, dynamic> userDetails,
    Map<String, dynamic> working,
    dynamic deviceInfo,
    String ts,
    dynamic ashaUniqueKey,
    dynamic facilityId,
  ) {
    final rawInfo = row['beneficiary_info'];
    final info = (rawInfo is Map)
        ? Map<String, dynamic>.from(rawInfo)
        : (rawInfo is String && rawInfo.isNotEmpty)
            ? Map<String, dynamic>.from(jsonDecode(rawInfo))
            : <String, dynamic>{};

    String? _genderCode(String? g) {
      if (g == null) return null;
      final s = g.toLowerCase();
      if (s.startsWith('m')) return 'M';
      if (s.startsWith('f')) return 'F';
      if (s.startsWith('o')) return 'O';
      return null;
    }

    String? _yyyyMMdd(String? iso) {
      if (iso == null || iso.isEmpty) return null;
      try {
        final d = DateTime.tryParse(iso);
        if (d == null) return null;
        return DateFormat('yyyy-MM-dd').format(d);
      } catch (_) {
        return null;
      }
    }

    Map<String, dynamic> _apiGeo(dynamic g) {
      try {
        if (g is String && g.isNotEmpty) g = jsonDecode(g);
        if (g is Map) {
          final m = Map<String, dynamic>.from(g);
          final lat = m['lat'] ?? m['latitude'] ?? m['Lat'] ?? m['Latitude'];
          final lng = m['lng'] ?? m['long'] ?? m['longitude'] ?? m['Lng'];
          final acc = m['accuracy_m'] ?? m['accuracy'] ?? m['Accuracy'];
          final tsCap = m['captured_at'] ?? m['captured_datetime'] ?? m['timestamp'];
          return {
            'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}'),
            'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}'),
            'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}'),
            'captured_at': tsCap?.toString() ??
                DateTime.now().toUtc().toIso8601String(),
          }
            ..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
        }
      } catch (_) {}
      return {
        'lat': null,
        'lng': null,
        'accuracy_m': null,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    }

    final beneficiaryInfoApi = {
      'house_no': (info['houseNo']),
      'name': {
        'first_name': (info['headName'] ?? info['memberName'] ?? info['name'] ?? '').toString(),
        'middle_name': '',
        'last_name': '',
      },
      'gender': _genderCode(info['gender']?.toString()),
      'dob': _yyyyMMdd(info['dob']?.toString()),
      'marital_status': (info['maritalStatus'] ?? 'married').toString().toLowerCase(),
      'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
      'phone': (info['mobileNo'] ?? '').toString(),
      'address': {
        'state': working['state'] ?? userDetails['stateName'],
        'district': working['district'] ?? userDetails['districtName'],
        'block': working['block'] ?? userDetails['blockName'],
        'village': info['village'] ?? working['village'] ?? userDetails['villageName'],
        'pincode': working['pincode'] ?? userDetails['pincode'],
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
      'is_abha_verified': info['is_abha_verified'] ?? false,
      'is_rch_id_verified': info['is_rch_id_verified'] ?? false,
      'is_fetched_from_abha': info['is_fetched_from_abha'] ?? false,
      'is_fetched_from_rch': info['is_fetched_from_rch'] ?? false,
      'ben_type': info['ben_type'] ?? (info['memberType'] ?? 'adult'),
      'mother_ben_ref_key': info['mother_ben_ref_key'] ?? row['mother_key']?.toString() ?? '',
      'father_ben_ref_key': info['father_ben_ref_key'] ?? row['father_key']?.toString() ?? '',
      'relaton_with_family_head':
          info['relaton_with_family_head'] ?? info['relation_to_head'] ?? 'self',
      'member_status': info['member_status'] ?? 'alive',
      'member_name': info['member_name'] ?? info['headName'] ?? info['memberName'] ?? info['name'],
      'father_or_spouse_name':
          info['father_or_spouse_name'] ?? info['fatherName'] ?? info['spouseName'] ?? '',
      'have_children': info['have_children'] ?? info['hasChildren'],
      'is_family_planning': info['is_family_planning'] ?? row['is_family_planning'] ?? 0,
      'total_children': info['total_children'] ?? info['totalBorn'],
      'total_live_children': info['total_live_children'] ?? info['totalLive'],
      'total_male_children': info['total_male_children'] ?? info['totalMale'],
      'age_of_youngest_child': info['age_of_youngest_child'] ?? info['youngestAge'],
      'gender_of_younget_child': info['gender_of_younget_child'] ?? info['youngestGender'],
      'whose_mob_no': info['whose_mob_no'] ?? info['mobileOwner'],
      'mobile_no': info['mobile_no'] ?? info['mobileNo'],
      'dob_day': info['dob_day'],
      'dob_month': info['dob_month'],
      'dob_year': info['dob_year'],
      'age_by': info['age_by'],
      'date_of_birth': info['date_of_birth'] ?? info['dob'],
      'age': info['age'] ?? info['approxAge'],
      'village_name': info['village_name'] ?? info['village'],
      'is_new_member': info['is_new_member'] ?? true,
      'isFamilyhead': info['isFamilyhead'] ?? true,
      'isFamilyheadWife': info['isFamilyheadWife'] ?? false,
      'age_of_youngest_child_unit':
          info['age_of_youngest_child_unit'] ?? info['ageUnit'],
      'type_of_beneficiary':
          info['type_of_beneficiary'] ?? info['beneficiaryType'] ?? 'staying_in_house',
      'name_of_spouse': info['name_of_spouse'] ?? info['spouseName'] ?? '',
    }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

    return {
      'unique_key': row['unique_key'],
      'id': row['id'],
      'household_ref_key': row['household_ref_key'],
      'beneficiary_state': [
        {
          'state': 'registered',
          'at': DateTime.now().toUtc().toIso8601String(),
        },
        {
          'state': (row['beneficiary_state'] ?? 'active').toString(),
          'at': DateTime.now().toUtc().toIso8601String(),
        },
      ],
      'pregnancy_count': row['pregnancy_count'] ?? 0,
      'beneficiary_info':beneficiaryInfoApi,
      'geo_location': _apiGeo(row['geo_location']),
      'spouse_key': row['spouse_key'],
      'mother_key': row['mother_key'],
      'father_key': row['father_key'],
      'is_family_planning': row['is_family_planning'] ?? 0,
      'is_adult': row['is_adult'] ?? 1,
      'is_guest': row['is_guest'] ?? 0,
      'is_death': row['is_death'] ?? 0,
      'death_details': row['death_details'] is Map ? row['death_details'] : {},
      'is_migrated': row['is_migrated'] ?? 0,
      'is_separated': row['is_separated'] ?? 0,
      'device_details': row['device_details'] is Map
          ? Map<String, dynamic>.from(row['device_details'])
          : {
        'device_id': deviceInfo['deviceId'] ?? '',
        'model': deviceInfo['model'] ?? 'Unknown',
        'os': '${deviceInfo['systemName'] ?? 'Unknown'} ${deviceInfo['systemVersion'] ?? ''}'.trim(),
        'app_version': '1.0.0',
      },
      'app_details': {
        'captured_by_user': userDetails['user_identifier'] ?? '',
        'captured_role_id': userDetails['role_id'] ?? userDetails['role'] ?? 0,
        'source': 'mobile',
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
      'parent_user': {
        'user_key': userDetails['supervisor_user_key'] ?? '',
        'name': userDetails['supervisor_name'] ?? '',
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
      'current_user_key': row['current_user_key'] ?? ashaUniqueKey,
      'facility_id': row['facility_id'] ?? facilityId,
      'created_date_time': row['created_date_time'] ?? ts,
      'modified_date_time': row['modified_date_time'] ?? ts,
    };

  }
}
