import 'dart:convert';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/data/Local_Storage/User_Info.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';

class BeneficiaryRepository {
  final NetworkServiceApi _api = NetworkServiceApi();

  Future<Map<String, dynamic>> fetchAndStoreBeneficiaries({required String lastId, int pageSize = 50}) async {
    final currentUser = await UserInfo.getCurrentUser();
    final userDetails = currentUser?['details'] is String
        ? jsonDecode(currentUser?['details'] ?? '{}')
        :  currentUser?['details'] ?? {};

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

    dynamic response;
    try {
      response = await _api.getApiWithBody(
        Endpoints.getBeneficiary,
        {
          'last_id': lastId,
        },
        headers: headers,
      );
    } catch (e) {
      try {
        response = await _api.getApi(
          Endpoints.getBeneficiary,
          headers: headers,
          queryParams: {
            'last_id': lastId,
            'page_size': pageSize.toString(),
          },
        );
      } catch (_) {
        // Fallback 2: GET with query param _id
        response = await _api.getApi(
          Endpoints.getBeneficiary,
          headers: headers,
          queryParams: {
            '_id': lastId,
            'page_size': pageSize.toString(),
          },
        );
      }
    }

    final dataList = (response is Map && response['data'] is List)
        ? List<Map<String, dynamic>>.from(response['data'] as List)
        : <Map<String, dynamic>>[];

    int inserted = 0;
    int updated = 0; // kept for compatibility, but we won't perform updates per request
    int skipped = 0;
    for (final rec in dataList) {
      try {
        final serverId = rec['_id']?.toString();
        if (serverId == null || serverId.isEmpty) continue;

        final info = _mapBeneficiaryInfo(rec);

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
            // Even if not synced, per requirement do not insert duplicates and do not update
            skipped++;
            continue;
          }
        }
        await LocalStorageDao.instance.insertBeneficiary(row);
        inserted++;
      } catch (e) {
        // Skip faulty record
        // print('Error inserting beneficiary: $e');
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

  Map<String, dynamic> _mapBeneficiaryInfo(Map<String, dynamic> rec) {
    final info = rec['beneficiary_info'] is Map
        ? Map<String, dynamic>.from(rec['beneficiary_info'] as Map)
        : <String, dynamic>{};

    final nameMap = info['name'] is Map ? Map<String, dynamic>.from(info['name']) : <String, dynamic>{};
    final first = (nameMap['first_name'] ?? info['first_name'] ?? '').toString().trim();
    final middle = (nameMap['middle_name'] ?? info['middle_name'] ?? '').toString().trim();
    final last = (nameMap['last_name'] ?? info['last_name'] ?? '').toString().trim();
    final fullNameParts = <String>[first, middle, last].where((s) => s.isNotEmpty).toList();
    String fullName = fullNameParts.join(' ').trim();
    if (fullName.isEmpty) {
      // Fallback to any provided single name string
      final rawName = info['name'];
      if (rawName is String) fullName = rawName.trim();
    }

    return {
      'memberType': '',
      'relation': '',
      'name': fullName,
      'fatherName': info['father_name'] ?? '',
      'motherName': info['mother_name'] ?? '',
      'useDob': true,
      'dob': info['dob']?.toString(),
      'approxAge': null,
      'updateDay': null,
      'updateMonth': null,
      'updateYear': null,
      'children': null,
      'birthOrder': null,
      'gender': info['gender']?.toString(),
      'bankAcc': null,
      'ifsc': null,
      'occupation': null,
      'education': null,
      'religion': info['religion'] ?? '',
      'category': info['category'] ?? '',
      'weight': null,
      'childSchool': null,
      'birthCertificate': null,
      'abhaAddress': null,
      'mobileOwner': null,
      'mobileNo': info['phone']?.toString(),
      'voterId': null,
      'rationId': null,
      'phId': null,
      'beneficiaryType': null,
      'maritalStatus': info['marital_status'] ?? '',
      'ageAtMarriage': null,
      'spouseName': null,
      'hasChildren': null,
      'isPregnant': null,
      'memberStatus': null,
      'relation_to_head': '',
      'address': info['address'] ?? {},
    };
  }
}
