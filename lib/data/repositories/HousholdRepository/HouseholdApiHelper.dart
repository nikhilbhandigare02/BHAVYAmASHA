import 'dart:convert';

import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/repositories/HousholdRepository/household_repository.dart';

class HouseholdApiHelper {
  final HouseholdRepository _householdRepo = HouseholdRepository();
  final LocalStorageDao _dao = LocalStorageDao.instance;

  Future<void> syncHouseholdRecord(Map<String, dynamic> h) async {
    Map<String, dynamic> _asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is String && v.isNotEmpty) {
        try {
          return Map<String, dynamic>.from(jsonDecode(v));
        } catch (_) {}
      }
      return <String, dynamic>{};
    }

    final payload = <String, dynamic>{
      'unique_key': (h['unique_key'] ?? '').toString(),
      'address': _asMap(h['address']),
      'geo_location': _asMap(h['geo_location']),
      'household_info': _asMap(h['household_info']),
      'device_details': _asMap(h['device_details']),
      'app_details': _asMap(h['app_details']),
      'parent_user': _asMap(h['parent_user']),
      'current_user_key': h['current_user_key'],
      'facility_id': h['facility_id'],
    }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

    if ((payload['unique_key'] as String).isEmpty) return;
    final uniqueKey = payload['unique_key'] as String;

    try {
      final resp = await _householdRepo.addHousehold(payload);

      String? serverIdFromResp;
      bool success = false;
      try {
        if (resp is Map && resp['success'] == true) {
          success = true;
          if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
            final first = (resp['data'] as List).first;
            if (first is Map) {
              serverIdFromResp = (first['_id'] ?? first['id'])?.toString();
            }
          } else if (resp['data'] is Map) {
            final d = resp['data'] as Map;
            serverIdFromResp = (d['_id'] ?? d['id'])?.toString();
          }
        }
      } catch (e) {
        print('HouseholdApiHelper: response parse error for unique_key=$uniqueKey -> $e');
      }

      if (success) {
        final updated = await _dao.markHouseholdSyncedByUniqueKey(
          uniqueKey: uniqueKey,
          serverId: serverIdFromResp,
        );
        print('HouseholdApiHelper: SYNCED unique_key=$uniqueKey (rows=$updated)');
      } else {
        print('HouseholdApiHelper: NOT SYNCED unique_key=$uniqueKey (API not successful)');
      }
    } catch (e) {
      print('HouseholdApiHelper: error syncing unique_key=$uniqueKey -> $e');
    }
  }
}
