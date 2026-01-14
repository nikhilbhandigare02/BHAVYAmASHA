import 'dart:convert';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

import '../../Database/User_Info.dart';
import '../../Database/local_storage_dao.dart';

class HouseholdRepository {
  final NetworkServiceApi _api = NetworkServiceApi();

  Future<dynamic> addHousehold(Map<String, dynamic> payload) async {
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
    //print('User token present: ${token != null && token.isNotEmpty}');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await _api.postApi(
      Endpoints.addHousehold,
      payload,
      headers: headers,
    );

    return response is String ? jsonDecode(response) : response;
  }

  Future<Map<String, dynamic>> fetchAndStoreHouseholds({required String lastId, int limit = 20}) async {
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

    // Determine cursor: prefer explicit lastId, otherwise latest from DB
    String effectiveLastId = lastId;
    if (effectiveLastId.isEmpty) {
      effectiveLastId = await LocalStorageDao.instance.getLatestHouseholdServerId();
    }

    dynamic response;
    try {
      response = await _api.getApiWithBody(
        Endpoints.getHousehold,
        {
          'last_id': effectiveLastId,
          'limit': limit,
        },
        headers: headers,
      );
    } catch (e) {
      try {
        response = await _api.getApi(
          Endpoints.getHousehold,
          headers: headers,
          queryParams: {
            'last_id': effectiveLastId,
            'limit': limit.toString(),
          },
        );
      } catch (_) {
        response = await _api.getApi(
          Endpoints.getHousehold,
          headers: headers,
          queryParams: {
            '_id': effectiveLastId,
            'limit': limit.toString(),
          },
        );
      }
    }

    final List<Map<String, dynamic>> dataList =
        (response is Map && response['data'] is List)
            ? List<Map<String, dynamic>>.from(response['data'] as List)
            : <Map<String, dynamic>>[];

    int inserted = 0;
    int skipped = 0;

    for (final rec in dataList) {
      try {
        final serverId = rec['_id']?.toString();
        if (serverId == null || serverId.isEmpty) { skipped++; continue; }

        // Dedup by unique_key or server_id
        final uniqueKey = rec['unique_key']?.toString();
        bool exists = false;
        if (uniqueKey != null && uniqueKey.isNotEmpty) {
          final existingByUk = await LocalStorageDao.instance.getHouseholdByUniqueKey(uniqueKey);
          exists = existingByUk != null && existingByUk.isNotEmpty;
        }
        if (!exists) {
          final existingBySid = await LocalStorageDao.instance.getHouseholdByServerId(serverId);
          exists = existingBySid != null && existingBySid.isNotEmpty;
        }
        if (exists) { skipped++; continue; }
        final Map<String, dynamic> addressMap =
        rec['address'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(rec['address'])
            : <String, dynamic>{};

        final Map<String, dynamic> familyHeadDetails =
        rec['family_head_details'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(rec['family_head_details'])
            : <String, dynamic>{};

// 👇 insert family_head_details inside address
        addressMap['family_head_details'] = familyHeadDetails;

        Map<String, dynamic> toInsert = {
          'server_id': serverId,
          'unique_key': uniqueKey,
          'address': addressMap,
          'geo_location': rec['geo_location'] ?? {},
          'head_id': (rec['family_head_details'] is Map) ? (rec['family_head_details']['unique_key']?.toString()) : null,
          'household_info': rec['household_info'] ?? {},
          'device_details': rec['device_details'] ?? {},
          'app_details': rec['app_details'] ?? {},
          'parent_user': rec['parent_user'] ?? {},
          'current_user_key': rec['current_user_key']?.toString(),
          'facility_id': rec['facility_id'],
          'created_date_time': rec['created_date_time']?.toString(),
          'modified_date_time': (rec['modified_date_time']?.toString().isNotEmpty == true) ? rec['modified_date_time']?.toString() : rec['created_date_time']?.toString(),
          'is_synced': 1,
          'is_deleted': rec['is_deleted'] ?? 0,
        };

        await LocalStorageDao.instance.insertHousehold(toInsert);
        inserted++;
      } catch (e) {
        // skip faulty record
        skipped++;
      }
    }

    return {
      'inserted': inserted,
      'skipped': skipped,
      'fetched': dataList.length,
      'next_cursor': response is Map ? response['next_cursor'] : null,
      'success': response is Map ? response['success'] : null,
      'msg': response is Map ? response['msg'] : null,
    };
  }
}
