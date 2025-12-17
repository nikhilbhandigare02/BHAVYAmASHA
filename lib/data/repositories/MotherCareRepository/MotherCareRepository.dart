import 'dart:convert';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

import '../../Database/User_Info.dart';
import '../../Database/database_provider.dart';
import '../../Database/tables/mother_care_activities_table.dart';

class MotherCareRepository {
  final NetworkServiceApi _api = NetworkServiceApi();

  Future<dynamic> addMotherCareActivity(List<dynamic> payload) async {
    try {
      final currentUser = await UserInfo.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      final userDetails = currentUser['details'] is String
          ? jsonDecode(currentUser['details'] as String)
          : currentUser['details'] ?? {};

      String? token = await SecureStorageService.getToken();
      if ((token == null || token.isEmpty) && userDetails is Map) {
        try {
          token = userDetails['token']?.toString();
        } catch (e) {
          print('MC: Error getting token from user details: $e');
        }
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('MC: Sending request to ${Endpoints.addMotherCareActivity}');
      print('MC: Headers: $headers');
      print('MC: Payload: $payload');

      final response = await _api.postApi(
        Endpoints.addMotherCareActivity,
        payload,
        headers: headers,
      );

      print('MC: Response received: $response');

      // If the response is a string, try to parse it as JSON
      if (response is String) {
        try {
          return jsonDecode(response);
        } catch (e) {
          return {'success': false, 'msg': 'Invalid response format', 'raw': response};
        }
      }

      return response;
    } catch (e, stackTrace) {
      print('MC: Error in addMotherCareActivity: $e');
      print('MC: Stack trace: $stackTrace');
      rethrow;
    }
  }
  Future<Map<String, dynamic>> fetchAndStoreMotherCareActivities({
    required String facilityId,
    required String ashaId,
    String? lastId,
    int limit = 20,
  }) async {
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

    final effectiveLastId = (lastId != null && lastId.toString().trim().isNotEmpty)
        ? lastId.toString().trim()
        : '0';

    final body = <String, dynamic>{
      'facility_id': facilityId,
      'asha_id': ashaId,
      '_id': effectiveLastId,
      'limit': limit,
    };

    final response = await _api.postApi(
      Endpoints.getMotherCareActivityDataByFal3,
      body,
      headers: headers,
    );

    final dataList = (response is Map && response['data'] is List)
        ? List<Map<String, dynamic>>.from(response['data'] as List)
        : <Map<String, dynamic>>[];

    final db = await DatabaseProvider.instance.database;

    int inserted = 0;
    int updated = 0;

    for (final rec in dataList) {
      final serverId = rec['_id']?.toString();
      if (serverId == null) continue;

      final existing = await db.query(
        MotherCareActivitiesTable.table,
        where: 'server_id = ?',
        whereArgs: [serverId],
        limit: 1,
      );

      final deviceDetails = jsonEncode(rec['device_details'] ?? {});

      final parentUser = <String, dynamic>{
        'app_role_id': rec['app_role_id'],
        'is_guest': rec['is_guest'],
        'pregnancy_count': rec['pregnancy_count'],
        'created_by': rec['created_by'],
        'created_date_time': rec['created_date_time'],
        'modified_by': rec['modified_by'],
        'modified_date_time': rec['modified_date_time'],
        'added_by': rec['added_by'],
        'added_date_time': rec['added_date_time'],
        'modified_by_added_on_server': rec['modified_by_added_on_server'],
        'modified_date_time_added_on_server': rec['modified_date_time_added_on_server'],
        'is_member_details_processed': rec['is_member_details_processed'],
        'is_death': rec['is_death'],
        'is_deleted': rec['is_deleted'],
        'is_disabled': rec['is_disabled'],
        'record_is_deleted': rec['record_is_deleted'],
        'is_processed': rec['is_processed'],
        'is_data_processed': rec['is_data_processed'],
        '__v': rec['__v'],
        'member_name': rec['member_name'],
      };

      final row = {
        'server_id': serverId,
        'household_ref_key': rec['unique_key']?.toString(),
        'beneficiary_ref_key': rec['beneficiaries_registration_ref_key']?.toString(),
        'mother_care_state': rec['mother_care_type']?.toString(),
        'device_details': deviceDetails,
        'app_details': jsonEncode(<String, dynamic>{}),
        'parent_user': jsonEncode(parentUser),
        'current_user_key': ashaId,
        'facility_id': int.tryParse(rec['facility_id']?.toString() ?? facilityId) ?? 0,
        'created_date_time': rec['created_date_time']?.toString(),
        'modified_date_time': rec['modified_date_time']?.toString(),
        'is_synced': 1,
        'is_deleted': rec['is_deleted'] is num ? rec['is_deleted'] : 0,
      };

      if (existing.isEmpty) {
        await db.insert(MotherCareActivitiesTable.table, row);
        inserted++;
      } else {
        await db.update(
          MotherCareActivitiesTable.table,
          row,
          where: 'server_id = ?',
          whereArgs: [serverId],
        );
        updated++;
      }
    }

    return {
      'inserted': inserted,
      'updated': updated,
      'fetched': dataList.length,
    };
  }
}
