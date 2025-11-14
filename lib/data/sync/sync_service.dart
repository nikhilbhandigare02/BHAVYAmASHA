import 'dart:async';
import 'dart:convert';

import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/repositories/AddBeneficiaryRepository.dart';
import 'package:medixcel_new/data/repositories/household_repository.dart';
import 'package:medixcel_new/data/repositories/BeneficiaryRepository.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _dao = LocalStorageDao.instance;
  final _householdRepo = HouseholdRepository();
  final _beneficiaryRepo = AddBeneficiaryRepository();
  final _beneficiaryPullRepo = BeneficiaryRepository();

  Timer? _timer;
  bool _running = false;

  void start({Duration  interval = const Duration(minutes: 5)}) {
    stop();

    print('SyncService: starting with interval ${interval.inMinutes} minute(s)');
    _triggerOnce();
    _timer = Timer.periodic(interval, (_) => _triggerOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _triggerOnce() async {
    if (_running) {
      print('SyncService: previous run still in progress, skipping this tick');
      return;
    }
    _running = true;
    try {
      await syncUnsyncedHouseholds();
      await syncUnsyncedBeneficiaries();
      await fetchBeneficiariesFromServer();
    } catch (e) {
      // ignore but log
      print('SyncService periodic error: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> syncUnsyncedHouseholds() async {
    try {
      final unsynced = await _dao.getUnsyncedHouseholds();
      final count = unsynced.length;
      if (count == 0) {
        print('Household Sync: No unsynced records found');
        return;
      }
      print('Household Sync: Found $count unsynced record(s)');
      for (final h in unsynced) {
        try {
          // Prepare payload by ensuring nested JSON are Maps
          Map<String, dynamic> _asMap(dynamic v) {
            if (v is Map<String, dynamic>) return v;
            if (v is String && v.isNotEmpty) {
              try { return Map<String, dynamic>.from(jsonDecode(v)); } catch (_) {}
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

          if ((payload['unique_key'] as String).isEmpty) continue;
          final uniqueKey = payload['unique_key'] as String;
          print('Household Sync: syncing unique_key=$uniqueKey');
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
            print('Household Sync: response parse error for unique_key=$uniqueKey -> $e');
          }

          if (success) {
            final updated = await _dao.markHouseholdSyncedByUniqueKey(
              uniqueKey: uniqueKey,
              serverId: serverIdFromResp,
            );
            print(
              'Household Sync: SYNCED unique_key=$uniqueKey (rows=$updated) ' 
              '+ server_id ${serverIdFromResp == null || serverIdFromResp.isEmpty ? 'NOT set' : 'set to '+serverIdFromResp!}'
            );
          } else {
            print('Household Sync: NOT SYNCED unique_key=$uniqueKey (API not successful), will retry later');
          }
        } catch (e) {
          // skip item, keep unsynced
          print('Household Sync: failed for a record -> $e');
        }
      }
    } catch (e) {
      // ignore
      print('Household Sync: error during batch -> $e');
    }
  }

  Future<void> syncUnsyncedBeneficiaries() async {
    try {
      final unsynced = await _dao.getUnsyncedBeneficiaries();
      final count = unsynced.length;
      if (count == 0) {
        print('Beneficiary Sync: No unsynced records found');
        return;
      }
      print('Beneficiary Sync: Found $count unsynced record(s)');
      for (final b in unsynced) {
        try {
          Map<String, dynamic> _asMap(dynamic v) {
            if (v is Map<String, dynamic>) return v;
            if (v is String && v.isNotEmpty) {
              try { return Map<String, dynamic>.from(jsonDecode(v)); } catch (_) {}
            }
            return <String, dynamic>{};
          }

          final payload = <String, dynamic>{
            'unique_key': (b['unique_key'] ?? '').toString(),
            'household_ref_key': b['household_ref_key'],
            'beneficiary_info': _asMap(b['beneficiary_info']),
            'geo_location': _asMap(b['geo_location']),
            'death_details': _asMap(b['death_details']),
            'device_details': _asMap(b['device_details']),
            'app_details': _asMap(b['app_details']),
            'parent_user': _asMap(b['parent_user']),
            'current_user_key': b['current_user_key'],
            'facility_id': b['facility_id'],
          }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

          if ((payload['unique_key'] as String).isEmpty) continue;
          final uniqueKey = payload['unique_key'] as String;
          print('Beneficiary Sync: syncing unique_key=$uniqueKey');
          final resp = await _beneficiaryRepo.addBeneficiary(payload);

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
            print('Beneficiary Sync: response parse error for unique_key=$uniqueKey -> $e');
          }

          if (success) {
            final updated = await _dao.markBeneficiarySyncedByUniqueKey(
              uniqueKey: uniqueKey,
              serverId: serverIdFromResp,
            );
            print(
              'Beneficiary Sync: SYNCED unique_key=$uniqueKey (rows=$updated) '
              '+ server_id ${serverIdFromResp == null || serverIdFromResp.isEmpty ? 'NOT set' : 'set to '+serverIdFromResp!}'
            );
          } else {
            print('Beneficiary Sync: NOT SYNCED unique_key=$uniqueKey (API not successful), will retry later');
          }
        } catch (e) {
          // keep unsynced on failure
          print('Beneficiary Sync: failed for a record -> $e');
        }
      }
    } catch (e) {
      // ignore
      print('Beneficiary Sync: error during batch -> $e');
    }
  }

  Future<void> fetchBeneficiariesFromServer() async {
    try {
      final lastId = await _dao.getLatestBeneficiaryServerId();
      final useLast = (lastId.isEmpty) ? '0' : lastId;
      print('Beneficiary Pull: Fetching from server with last_id=$useLast');
      final result = await _beneficiaryPullRepo.fetchAndStoreBeneficiaries(lastId: useLast);
      final inserted = result['inserted'];
      final fetched = result['fetched'];
      print('Beneficiary Pull: fetched=$fetched, inserted=$inserted, skipped=${result['skipped']}');
    } catch (e) {
      print('Beneficiary Pull: error -> $e');
    }
  }
}
