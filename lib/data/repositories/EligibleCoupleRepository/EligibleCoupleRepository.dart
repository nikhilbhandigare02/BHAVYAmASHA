import 'dart:async';
import 'dart:convert';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../Database/User_Info.dart';


class EligibleCoupleRepository {
  final NetworkServiceApi _api = NetworkServiceApi();
  Timer? _ecSyncTimer;

  Future<dynamic> trackEligibleCouple(List<dynamic> payload) async {
    try {
      print('🔍 Starting trackEligibleCouple with payload: $payload');

      // 1. Get user details
      final currentUser = await UserInfo.getCurrentUser();
      print('👤 Current user: ${currentUser?.toString() ?? 'null'}');

      final userDetails = currentUser?['details'] is String
          ? jsonDecode(currentUser?['details'] ?? '{}')
          : currentUser?['details'] ?? {};
      print('📝 User details: $userDetails');

      // 2. Get token
      String? token = await SecureStorageService.getToken();
      print('🔑 Initial token from storage: $token');

      if ((token == null || token.isEmpty) && userDetails is Map) {
        try {
          token = userDetails['token']?.toString();
          print('🔄 Using token from user details: ${token != null ? 'Token found' : 'No token found'}');
        } catch (e, stackTrace) {
          print('⚠️ Error getting token from user details: $e');
          print('Stack trace: $stackTrace');
        }
      }

      if (token == null || token.isEmpty) {
        print('❌ No authentication token available');
        throw Exception('Authentication token is required');
      }

      // 3. Prepare headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      print('📋 Request headers: $headers');

      // 4. Log the full URL and payload
      final fullUrl = Endpoints.trackEligibleCouple;
      print('🌐 Sending POST request to: $fullUrl');
      print('📤 Request payload: ${jsonEncode(payload)}');

      // 5. Make the API call
      try {
        final response = await _api.postApi(
          fullUrl,
          payload,
          headers: headers,
        );

        print('✅ API Response: $response');
        return response is String ? jsonDecode(response) : response;
      } catch (e, stackTrace) {
        print('❌ Error in API call: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    } catch (e, stackTrace) {
      print('🔥 Error in trackEligibleCouple: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchAndStoreEligibleCoupleActivities({
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
      token = userDetails['token']?.toString();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    final body = {
      'facility_id': facilityId,
      'asha_id': ashaId,
      '_id': lastId,
      'limit': limit,
    };

    final response = await _api.postApi(
      Endpoints.getEligibleCoupleActivityDataByFal3,
      body,
      headers: headers,
    );

    final dataList = (response is Map && response['data'] is List)
        ? List<Map<String, dynamic>>.from(response['data'])
        : <Map<String, dynamic>>[];

    final Database db = await DatabaseProvider.instance.database;

    int inserted = 0;
    int updated = 0;
    int skipped = 0;

    for (final rec in dataList) {
      final serverId = rec['_id']?.toString();
      final beneficiaryRefKey =
      rec['beneficiaries_registration_ref_key']?.toString();

      if (serverId == null || beneficiaryRefKey == null) continue;

      /// 🔴 CHECK: beneficiary_ref_key already exists?
      final existingByBeneficiary = await db.query(
        'eligible_couple_activities',
        where: 'beneficiary_ref_key = ? AND is_deleted = 0',
        whereArgs: [beneficiaryRefKey],
        limit: 1,
      );

      if (existingByBeneficiary.isNotEmpty) {
        skipped++;
        continue; // ❌ EXCLUDE THIS RECORD
      }

      /// Existing check by server_id (normal sync logic)
      final existingByServer = await db.query(
        'eligible_couple_activities',
        where: 'server_id = ?',
        whereArgs: [serverId],
        limit: 1,
      );

      final deviceDetails = jsonEncode(rec['device_details'] ?? {});
      final appDetails = jsonEncode(rec['app_details'] ?? {});

      final parentUser = {
        'app_role_id': rec['app_role_id'],
        'is_guest': rec['is_guest'],
        'parent_added_by': rec['parent_added_by'],
        'created_by': rec['created_by'],
        'created_date_time': rec['created_date_time'],
        'modified_by': rec['modified_by'],
        'modified_date_time': rec['modified_date_time'],
        'added_by': rec['added_by'],
        'added_date_time': rec['added_date_time'],
        'modified_by_added_on_server':
        rec['modified_by_added_on_server'],
        'modified_date_time_added_on_server':
        rec['modified_date_time_added_on_server'],
        'is_member_details_processed':
        rec['is_member_details_processed'],
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
        'beneficiary_ref_key': beneficiaryRefKey,
        'eligible_couple_state':
        rec['eligible_couple_type']?.toString(),
        'device_details': deviceDetails,
        'app_details': appDetails,
        'parent_user': jsonEncode(parentUser),
        'current_user_key': ashaId,
        'facility_id':
        int.tryParse(rec['facility_id']?.toString() ?? facilityId) ??
            0,
        'created_date_time': rec['created_date_time']?.toString(),
        'modified_date_time': rec['modified_date_time']?.toString(),
        'is_synced': 1,
        'is_deleted': rec['is_deleted'] is num ? rec['is_deleted'] : 0,
      };

      if (existingByServer.isEmpty) {
        await db.insert('eligible_couple_activities', row);
        inserted++;
      } else {
        await db.update(
          'eligible_couple_activities',
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
      'skipped_existing_beneficiary': skipped,
      'fetched': dataList.length,
    };
  }


  void startAutoSyncEligibleCoupleActivities({
    required String facilityId,
    required String ashaId,
    String? lastId,
    int limit = 20,
  }) {
    _ecSyncTimer?.cancel();
    _ecSyncTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await fetchAndStoreEligibleCoupleActivities(
          facilityId: facilityId,
          ashaId: ashaId,
          lastId: lastId,
          limit: limit,
        );
      } catch (e) {
        print('EC auto-sync error: $e');
      }
    });
  }

  void stopAutoSyncEligibleCoupleActivities() {
    _ecSyncTimer?.cancel();
    _ecSyncTimer = null;
  }

  Future<void> startAutoSyncEligibleCoupleActivitiesFromCurrentUser({
    String? lastId,
    int limit = 20,
  }) async {
    final currentUser = await UserInfo.getCurrentUser();
    if (currentUser == null) return;

    Map<String, dynamic> details = {};
    try {
      details = currentUser['details'] is String
          ? jsonDecode(currentUser['details'])
          : Map<String, dynamic>.from(currentUser['details']);
    } catch (_) {}

    final working = details['working_location'] ?? {};

    final ashaId = (working['asha_id'] ??
        details['unique_key'] ??
        details['user_id'] ??
        '')
        .toString();

    final facilityId = (working['asha_associated_with_facility_id'] ??
        working['hsc_id'] ??
        details['facility_id'] ??
        details['hsc_id'] ??
        '')
        .toString();

    if (ashaId.isEmpty || facilityId.isEmpty) return;

    startAutoSyncEligibleCoupleActivities(
      facilityId: facilityId,
      ashaId: ashaId,
      lastId: lastId,
      limit: limit,
    );
  }

}
