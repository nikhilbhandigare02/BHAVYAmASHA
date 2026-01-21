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

  Future<Map<String, dynamic>> fetchAndStoreBeneficiaries({required String lastId, int pageSize = 100}) async {

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
          "limit": 20
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
            "limit": 20
          },
        );
      } catch (_) {
        response = await _api.getApi(
          Endpoints.getBeneficiary,
          headers: headers,
          queryParams: {
            'last_id': effectiveLastId,
            "limit": 20
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
        if (serverId == null || serverId.isEmpty) {
          print('Skipping record with missing server_id');
          continue;
        }

        final hhRefKey = rec['household_ref_key']?.toString();
        final benUniqueKey = rec['unique_key']?.toString();
        
        if (benUniqueKey == null || benUniqueKey.isEmpty) {
          print('Skipping record with missing unique_key: $serverId');
          continue;
        }

        final info = _mapBeneficiaryInfo(rec);
        // if (hhRefKey != null && hhRefKey.isNotEmpty) {
        //   final existingHh = await LocalStorageDao.instance.getHouseholdByUniqueKey(hhRefKey);
        //   if (existingHh == null || existingHh.isEmpty) {
        //     final householdInfo = <String, dynamic>{};
        //     final beneficiaryInfo = info;
        //
        //     householdInfo['houseNo'] = beneficiaryInfo['houseNo'];
        //     householdInfo['headName'] = beneficiaryInfo['headName'] ?? beneficiaryInfo['name'];
        //
        //     final toInsertHh = <String, dynamic>{
        //       'server_id': null,
        //       'unique_key': hhRefKey,
        //       'address': beneficiaryInfo['address'] ?? {},
        //       'geo_location': rec['geo_location'] ?? {},
        //       'head_id': benUniqueKey,
        //       'household_info': householdInfo,
        //       'device_details': rec['device_details'] ?? {},
        //       'app_details': rec['app_details'] ?? {},
        //       'parent_user': rec['parent_user'] ?? {},
        //       'current_user_key': rec['current_user_key']?.toString(),
        //       'facility_id': _toInt(rec['facility_id']),
        //       'created_date_time': rec['created_date_time']?.toString(),
        //       'modified_date_time': rec['modified_date_time']?.toString(),
        //       'is_synced': 1,
        //       'is_deleted': _toInt(rec['is_deleted']),
        //     };
        //
        //     await LocalStorageDao.instance.insertHousehold(toInsertHh);
        //   }
        // }

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
          'is_adult': (info['memberType']?.toString() == 'adult') ? 1 : 0,
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

        final uniqueKey = row['server_id']?.toString();
        if (uniqueKey != null && uniqueKey.isNotEmpty) {
          if(uniqueKey=='696b76644239d35553728f27' || uniqueKey == '696b766f99764a6a83a22a21' || uniqueKey == '696b766f99764a6a83a22a23'){
            print('aa');
          }
          final existing = await LocalStorageDao.instance.getBeneficiaryByServerKey(uniqueKey);
         /* if (existing != null && existing.isNotEmpty) {
            final existingSynced = (existing['is_synced'] == 1) || (existing['is_synced']?.toString() == '1');
            if (existingSynced) {
              print('Skipping already synced beneficiary: $uniqueKey');
              skipped++;
              continue;
            }
            print('Skipping beneficiary with existing record: $uniqueKey');
            skipped++;
            continue;
          }*/

          if (existing == null || existing.isEmpty) {
            print('Inserting beneficiary: server_id=$serverId, unique_key=$uniqueKey');
            try {
              await LocalStorageDao.instance.insertBeneficiary(row);
              print('Inserted beneficiary: server_id=$serverId, unique_key=$uniqueKey');
            }
                catch(e){

              print('Failed inserted');
                }
          }
          else {
            print("BenifSkip db else ${uniqueKey}");
          }
        }
        else {
          print("BenifSkip uniqueKey else ${uniqueKey}");
        }

        //print('Successfully inserted beneficiary: $uniqueKey');
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

  String _resolveFullName(Map<String, dynamic> info) {
    // API scenario
    final apiName = info['member_name']?.toString().trim();
    if (apiName != null && apiName.isNotEmpty) return apiName;

    // App name map
    if (info['name'] is Map) {
      final map = Map<String, dynamic>.from(info['name']);
      final parts = [
        map['first_name'],
        map['middle_name'],
        map['last_name']
      ]
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .map((e) => e.toString().trim())
          .toList();
      if (parts.isNotEmpty) return parts.join(' ');
    }

    // Flat fields
    final first = info['first_name']?.toString().trim() ?? '';
    final last = info['last_name']?.toString().trim() ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();

    // Raw fallback
    if (info['name'] is String && info['name'].toString().trim().isNotEmpty) {
      return info['name'].toString().trim();
    }

    return 'Unknown Member';
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
    final fullName = _resolveFullName(info);


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
    String? _resolveFatherName(Map<String, dynamic> info) {
      final primary = info['father_or_spouse_name']?.toString().trim();
      if (primary != null && primary.isNotEmpty) {
        return primary;
      }

      final fallback = info['father_name']?.toString().trim();
      if (fallback != null && fallback.isNotEmpty) {
        return fallback;
      }

      return null;
    }


    String? _normalizeDob(dynamic dob) {
      if (dob == null) return null;

      try {
        String dobString = dob.toString().trim();
        if (dobString.isEmpty) return null;
        
        // Try ISO format first
        DateTime? parsed = DateTime.tryParse(dobString);
        
        // If ISO parsing fails, try common formats
        if (parsed == null) {
          // Try DD/MM/YYYY or DD-MM-YYYY
          final regex1 = RegExp(r'^(\d{2})[/-](\d{2})[/-](\d{4})$');
          final match1 = regex1.firstMatch(dobString);
          if (match1 != null) {
            final day = int.parse(match1.group(1)!);
            final month = int.parse(match1.group(2)!);
            final year = int.parse(match1.group(3)!);
            parsed = DateTime(year, month, day);
          }
          
          // Try YYYY/MM/DD or YYYY-MM-DD
          if (parsed == null) {
            final regex2 = RegExp(r'^(\d{4})[/-](\d{2})[/-](\d{2})$');
            final match2 = regex2.firstMatch(dobString);
            if (match2 != null) {
              final year = int.parse(match2.group(1)!);
              final month = int.parse(match2.group(2)!);
              final day = int.parse(match2.group(3)!);
              parsed = DateTime(year, month, day);
            }
          }
        }
        
        if (parsed == null) return null;
        return DateFormat('yyyy-MM-dd').format(parsed);
      } catch (e) {
        print('Error normalizing DOB: $e');
        return null;
      }
    }

    final mapped = <String, dynamic>{
      'memberType': info['ben_type'] == 'child' ? 'child' : 'adult',
      'relation': info['relaton_with_family_head'] ?? info['relation_to_head'] ?? '',
      'name': fullName,
      'headName': fullName,
      'memberName': info['member_name'],
      'father_name': info['father_name'] ?? '',
      'houseNo': info['house_no'] ?? '',
      'fatherName': info['father_or_spouse_name'],
      'motherName': info['mother_name'] ?? '',
      'age_by': info['age_by'],
      'useDob': info['age_by'],
      'dob': _normalizeDob(info['dob'] ?? info['date_of_birth']),
      'approxAge': info['age'],
      'years': info['dob_year'],
      'months': info['dob_month'],
      'days': info['dob_day'],
      'updateDay': DateTime.now().day,
      'updateMonth': DateTime.now().month,
      'updateYear': DateTime.now().year,

      'children': info['total_children'],
      'birthOrder': info['birth_order'],
      'totalBorn': info['total_children'] ?? (info['have_children'] == 'yes' ? 1 : 0),
      'totalLive': info['total_live_children'] ?? (info['have_children'] == 'yes' ? 1 : 0),
      'totalLiveChildren': info['total_live_children'] ?? (info['have_children'] == 'yes' ? 1 : 0),
      'totalMale': info['total_male_children'] ?? 0,
      'totalFemale': info['total_female_children'] ?? 0,
      'youngestAge': info['age_of_youngest_child'],
      'ageUnit': info['age_of_youngest_child_unit'] ?? '',
      'youngestGender': info['gender_of_younget_child'],

      'gender': _genderText(info['gender']?.toString()),
      'occupation': info['occupation'],
      'education': info['education'],
      'religion': info['religion'],
      'category': info['category'],

      'hasChildren': info['have_children'],
      'isPregnant': info['is_women_pregenant'] ?? '',
      'lmp': info['lmp_date']?.toString(),
      'edd': info['edd_date']?.toString(),
      'beneficiaryType': info['type_of_beneficiary'],

      'mobileOwner': info['whose_mob_no'] ?? '',
      'mobileNo': (info['mobile_no'] ?? info['phone'])?.toString(),
      'abhaAddress': info['abha_no'],
      'abhaNumber': info['abha_no'],
      'voterId': info['voter_id'],
      'rationId': info['ration_id'],
      'rationCardId': info['ration_card_id'],
      'phId': info['ph_id'],
      'personalHealthId': info['personal_health_id'],
      'bankAcc': info['account_number'],
      'bankAccountNumber': info['account_number'],
      'ifsc': info['ifsc_code'],
      'ifscCode': info['ifsc_code'],

      'maritalStatus': _titleCase(info['marital_status']?.toString()),
      'ageAtMarriage': info['age_at_marrige'],
      'spouseName': info['name_of_spouse'] ?? info['father_or_spouse_name'],

      'village': info['village_name'] ?? addr['village'] ?? '',
      'ward': info['ward_name'] ?? '',
      'wardNo': info['ward_no'] ?? '',
      'mohalla': info['mohalla_name'] ?? '',
      'mohallaTola': info['mohalla_name'] ?? '',
      'state': addr['state'] ?? '',
      'district': addr['district'] ?? '',
      'block': addr['block'] ?? '',

      'weight': info['weight'],
      'birthWeight': info['weight_at_birth'],
      'childSchool': info['is_school_going_child'],
      'birthCertificate': info['is_birth_certificate_issued'],
      'memberStatus': info['member_status'] ?? '',
      'relation_to_head': info['relaton_with_family_head'] ?? info['relationToHead'] ?? '',
      
      'is_abha_verified': info['is_abha_verified'] ?? false,
      'is_rch_id_verified': info['is_rch_id_verified'] ?? false,
      'is_fetched_from_abha': info['is_fetched_from_abha'] ?? false,
      'is_fetched_from_rch': info['is_fetched_from_rch'] ?? false,
      'ben_type': info['ben_type'] ?? '',
      'is_new_member': info['is_new_member'] ?? false,
      'isFamilyhead': info['isFamilyhead'] ?? false,
      'isFamilyheadWife': info['isFamilyheadWife'] ?? false,
      'type_of_beneficiary': info['type_of_beneficiary'] ?? '',
      
      // Family planning fields
      'fp_adopting': info['is_family_planning'] ?? 0,
      'fp_method': info['method_of_contraception'],
      
      // Bank details
      'bankName': info['bank_name'],
      'branchName': info['branch_name'],
      
      // Disease/health conditions
      'suffering_from_a_serious_illness': info['suffering_from_a_serious_illness'],
      'non_communicable_diseases': info['non_communicable_diseases'],
      'communicable_diseases': info['communicable_diseases'],
      'ncd_registration_id': info['ncd_registration_id'],
      'nikshay_id': info['nikshay_id'],
      'any_other_communicable_diseases': info['any_other_communicable_diseases'],
      
      // Death related fields
      'date_of_death': info['date_of_death'],
      'death_place': info['death_place'],
      'reason_of_death': info['reason_of_death'],
      'other_reason_for_death': info['other_reason_for_death'],
      
      // Aadhaar details
      'adhar_no': info['adhar_no'],
      'family_head_adhar_no': info['family_head_adhar_no'],
      
      'poverty_line': info['poverty_line'],
      
      // Migration status
      'is_migrated': info['is_migrated'],
      
      // Contraception quantities
      'condom_quantity': info['quantity_of_condoms'],
      'mala_quantity': info['quantity_of_mala_n_daily'],
      'chhaya_quantity': info['quantity_of_chhaya_weekly'],
      'ecp_quantity': info['quantity_of_ecp'],
      
      // Family planning dates
      'antra_injection_date': info['date_of_antra'],
      'removal_date': info['removal_date'],
      'removal_reason': info['reason'],
    };

    mapped.removeWhere((key, value) => value == null);
    return mapped;
  }
}
