import 'dart:async';
import 'dart:convert';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/data/Local_Storage/User_Info.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:sqflite/sqflite.dart';

class ChildCareRepository {
  final NetworkServiceApi _api = NetworkServiceApi();
  Timer? _ccSyncTimer;

  Future<dynamic> submitChildCareActivities(List<dynamic> payload) async {
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

    final response = await _api.postApi(
      Endpoints.addChildCareActivity,
      payload,
      headers: headers,
    );

    return response is String ? jsonDecode(response) : response;
  }

  Future<Map<String, dynamic>> fetchAndStoreChildCareActivities({
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

    final body = {
      'facility_id': facilityId,
      'asha_id': ashaId,
      '_id': lastId,
      'limit': limit,
    };

    final response = await _api.postApi(
      Endpoints.getChildCareActivityDataByFal3,
      body,
      headers: headers,
    );

    final dataList = (response is Map && response['data'] is List)
        ? List<Map<String, dynamic>>.from(response['data'] as List)
        : <Map<String, dynamic>>[];

    final Database db = await DatabaseProvider.instance.database;

    int inserted = 0;
    int updated = 0;

    for (final rec in dataList) {
      final serverId = rec['_id']?.toString();
      if (serverId == null) continue;

      final existing = await db.query(
        'child_care_activities',
        where: 'server_id = ?',
        whereArgs: [serverId],
        limit: 1,
      );

      final deviceDetails = jsonEncode(rec['device_details'] ?? {});
      final appDetails = jsonEncode(rec['app_details'] ?? {});

      final parentUser = <String, dynamic>{
        'app_role_id': rec['app_role_id'],
        'is_guest': rec['is_guest'],
        'parent_added_by': rec['parent_added_by'],
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
        'mother_key': rec['mother_key']?.toString(),
        'father_key': rec['father_key']?.toString(),
        'child_care_state': rec['child_care_type']?.toString(),
        'device_details': deviceDetails,
        'app_details': appDetails,
        'parent_user': jsonEncode(parentUser),
        'current_user_key': ashaId,
        'facility_id': int.tryParse(rec['facility_id']?.toString() ?? facilityId) ?? 0,
        'created_date_time': rec['created_date_time']?.toString(),
        'modified_date_time': rec['modified_date_time']?.toString(),
        'is_synced': 1,
        'is_deleted': rec['is_deleted'] is num ? rec['is_deleted'] : 0,
      };

      if (existing.isEmpty) {
        await db.insert('child_care_activities', row);
        inserted++;
      } else {
        await db.update(
          'child_care_activities',
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

  void startAutoSyncChildCareActivities({
    required String facilityId,
    required String ashaId,
    String? lastId,
    int limit = 20,
  }) {
    _ccSyncTimer?.cancel();
    _ccSyncTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await fetchAndStoreChildCareActivities(
          facilityId: facilityId,
          ashaId: ashaId,
          lastId: lastId,
          limit: limit,
        );
      } catch (e) {
        print('Child care auto-sync error: $e');
      }
    });
  }

  void stopAutoSyncChildCareActivities() {
    _ccSyncTimer?.cancel();
    _ccSyncTimer = null;
  }

  Future<void> startAutoSyncChildCareActivitiesFromCurrentUser({
    String? lastId,
    int limit = 20,
  }) async {
    final currentUser = await UserInfo.getCurrentUser();
    if (currentUser == null) return;

    Map<String, dynamic> details;
    if (currentUser['details'] is String) {
      try {
        details = jsonDecode(currentUser['details']);
      } catch (_) {
        details = {};
      }
    } else if (currentUser['details'] is Map) {
      details = Map<String, dynamic>.from(currentUser['details']);
    } else {
      details = {};
    }

    final working = details['working_location'] ?? {};
    final ashaId = (working['asha_id'] ?? details['unique_key'] ?? details['user_id'] ?? '').toString();
    final facilityId = (working['asha_associated_with_facility_id'] ?? working['hsc_id'] ?? details['facility_id'] ?? details['hsc_id'] ?? '').toString();
    if (ashaId.isEmpty || facilityId.isEmpty) return;

    startAutoSyncChildCareActivities(
      facilityId: facilityId,
      ashaId: ashaId,
      lastId: lastId,
      limit: limit,
    );
  }
}
