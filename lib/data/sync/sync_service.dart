import 'dart:async';
import 'dart:convert';

import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/repositories/AddBeneficiary/AddBeneficiaryRepository.dart';
import 'package:medixcel_new/data/repositories/HousholdRepository/household_repository.dart';
import 'package:medixcel_new/data/repositories/AddBeneficiary/BeneficiaryRepository.dart';

import 'package:medixcel_new/data/Local_Storage/User_Info.dart';

import '../repositories/ChildCareRepository/ChildCareRepository.dart';
import '../repositories/EligibleCoupleRepository/EligibleCoupleRepository.dart';
import '../repositories/MotherCareRepository/MotherCareRepository.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _dao = LocalStorageDao.instance;
  final _householdRepo = HouseholdRepository();
  final _beneficiaryRepo = AddBeneficiaryRepository();
  final _beneficiaryPullRepo = BeneficiaryRepository();
  final _ecRepo = EligibleCoupleRepository();
  final _ccRepo = ChildCareRepository();
  final _mcRepo = MotherCareRepository();

  Timer? _timer;
  bool _running = false;

  void start({Duration  interval = const Duration(minutes: 5)}) {
    stop();

    print('SyncService: starting with interval ${interval.inMinutes} minute(s)');
    _triggerOnce();
    _timer = Timer.periodic(interval, (_) => _triggerOnce());
  }

  Future<Map<String, String>> _getUserWorkingIds() async {
    final currentUser = await UserInfo.getCurrentUser();
    final userDetails = currentUser?['details'] is String
        ? jsonDecode(currentUser?['details'] ?? '{}')
        : currentUser?['details'] ?? {};
    final working = userDetails['working_location'] ?? {};
    final facilityId = (working['asha_associated_with_facility_id'] ?? working['hsc_id'] ?? userDetails['facility_id'] ?? userDetails['hsc_id'] ?? '').toString();
    final ashaId = (working['asha_id'] ?? userDetails['unique_key'] ?? userDetails['user_id'] ?? '').toString();
    return {
      'facilityId': facilityId,
      'ashaId': ashaId,
    };
  }

  Future<void> fetchEligibleCoupleActivitiesFromServer() async {
    try {
      final ids = await _getUserWorkingIds();
      if (ids['facilityId']!.isEmpty || ids['ashaId']!.isEmpty) return;
      final lastId = await _dao.getLatestEligibleCoupleActivityServerId();
      final useLast = lastId.isEmpty ? '0' : lastId;
      print('EC Pull: Fetching with last_id=$useLast limit=20');
      final result = await _ecRepo.fetchAndStoreEligibleCoupleActivities(
        facilityId: ids['facilityId']!,
        ashaId: ids['ashaId']!,
        lastId: useLast,
        limit: 20,
      );
      print('EC Pull: fetched=${result['fetched']}, inserted=${result['inserted']}, updated=${result['updated']}');
    } catch (e) {
      print('EC Pull: error -> $e');
    }
  }

  Future<void> fetchChildCareActivitiesFromServer() async {
    try {
      final ids = await _getUserWorkingIds();
      if (ids['facilityId']!.isEmpty || ids['ashaId']!.isEmpty) return;
      final lastId = await _dao.getLatestChildCareActivityServerId();
      final useLast = lastId.isEmpty ? '0' : lastId;
      print('ChildCare Pull: Fetching with last_id=$useLast limit=20');
      final result = await _ccRepo.fetchAndStoreChildCareActivities(
        facilityId: ids['facilityId']!,
        ashaId: ids['ashaId']!,
        lastId: useLast,
        limit: 20,
      );
      print('ChildCare Pull: fetched=${result['fetched']}, inserted=${result['inserted']}, updated=${result['updated']}');
    } catch (e) {
      print('ChildCare Pull: error -> $e');
    }
  }

  Future<void> syncUnsyncedEligibleCoupleActivities() async {
    try {
      final ids = await _getUserWorkingIds();
      if (ids['facilityId']!.isEmpty || ids['ashaId']!.isEmpty) return;
      final list = await _dao.getUnsyncedEligibleCoupleActivities();
      if (list.isEmpty) {
        print('EC Push: No unsynced activities');
        return;
      }
      print('EC Push: Found ${list.length} unsynced activity(ies)');
      // Build payload for API
      final payload = list.map((r) => {
            'facility_id': r['facility_id'],
            'asha_id': ids['ashaId'],
            'unique_key': r['household_ref_key'],
            'beneficiaries_registration_ref_key': r['beneficiary_ref_key'],
            'eligible_couple_type': r['eligible_couple_state'],
            'device_details': r['device_details'] ?? {},
            'app_details': r['app_details'] ?? {},
            'parent_user': r['parent_user'] ?? {},
            'created_date_time': r['created_date_time'],
            'modified_date_time': r['modified_date_time'],
          }).toList();
      final resp = await _ecRepo.trackEligibleCouple(payload);
      final success = resp is Map && resp['success'] == true;
      if (success) {
        for (final r in list) {
          await _dao.markEligibleCoupleActivitySyncedById(r['id'] as int? ?? 0);
        }
        print('EC Push: Marked ${list.length} activity(ies) as synced');
      } else {
        print('EC Push: API not successful, will retry later');
      }
    } catch (e) {
      print('EC Push: error -> $e');
    }
  }

  Future<void> syncUnsyncedChildCareActivities() async {
    try {
      final ids = await _getUserWorkingIds();
      if (ids['facilityId']!.isEmpty || ids['ashaId']!.isEmpty) return;
      final list = await _dao.getUnsyncedChildCareActivities();
      if (list.isEmpty) {
        print('ChildCare Push: No unsynced activities');
        return;
      }
      print('ChildCare Push: Found ${list.length} unsynced activity(ies)');
      final payload = list.map((r) => {
            'facility_id': r['facility_id'],
            'asha_id': ids['ashaId'],
            'unique_key': r['household_ref_key'],
            'beneficiaries_registration_ref_key': r['beneficiary_ref_key'],
            'mother_key': r['mother_key'],
            'father_key': r['father_key'],
            'child_care_type': r['child_care_state'],
            'device_details': r['device_details'] ?? {},
            'app_details': r['app_details'] ?? {},
            'parent_user': r['parent_user'] ?? {},
            'created_date_time': r['created_date_time'],
            'modified_date_time': r['modified_date_time'],
          }).toList();
      final resp = await _ccRepo.submitChildCareActivities(payload);
      final success = resp is Map && resp['success'] == true;
      if (success) {
        for (final r in list) {
          await _dao.markChildCareActivitySyncedById(r['id'] as int? ?? 0);
        }
        print('ChildCare Push: Marked ${list.length} activity(ies) as synced');
      } else {
        print('ChildCare Push: API not successful, will retry later');
      }
    } catch (e) {
      print('ChildCare Push: error -> $e');
    }
  }

  Future<void> syncUnsyncedMotherCareAncActivities() async {
    try {
      final list = await _dao.getUnsyncedMotherCareAncForms();
      if (list.isEmpty) {
        print('MotherCare ANC Push: No unsynced forms');
        return;
      }

      print('MotherCare ANC Push: Found ${list.length} unsynced form(s)');

      List<Map<String, dynamic>> payload = [];

      for (final r in list) {
        try {
          Map<String, dynamic> deviceJson = {};
          Map<String, dynamic> appJson = {};
          Map<String, dynamic> geoJson = {};
          Map<String, dynamic> formRoot = {};
          Map<String, dynamic> formDataJson = {};

          final deviceStr = r['device_details']?.toString();
          if (deviceStr != null && deviceStr.isNotEmpty) {
            try {
              final dj = jsonDecode(deviceStr);
              if (dj is Map) deviceJson = Map<String, dynamic>.from(dj);
            } catch (_) {}
          }

          final appStr = r['app_details']?.toString();
          if (appStr != null && appStr.isNotEmpty) {
            try {
              final aj = jsonDecode(appStr);
              if (aj is Map) appJson = Map<String, dynamic>.from(aj);
            } catch (_) {}
          }

          final formStr = r['form_json']?.toString();
          if (formStr != null && formStr.isNotEmpty) {
            try {
              final fj = jsonDecode(formStr);
              if (fj is Map) {
                formRoot = Map<String, dynamic>.from(fj);
                if (fj['form_data'] is Map) {
                  formDataJson = Map<String, dynamic>.from(fj['form_data']);
                }
                if (fj['geolocation_details'] is Map) {
                  geoJson = Map<String, dynamic>.from(fj['geolocation_details']);
                } else if (formDataJson['geolocation_details'] is Map) {
                  geoJson = Map<String, dynamic>.from(formDataJson['geolocation_details']);
                }
              }
            } catch (_) {}
          }

          final String userId = (r['current_user_key'] ?? formRoot['user_id'] ?? formDataJson['user_id'] ?? '').toString();
          final String facility = (r['facility_id']?.toString() ?? formRoot['facility_id']?.toString() ?? formDataJson['facility_id']?.toString() ?? '');
          final String appRoleId = (formRoot['app_role_id'] ?? formDataJson['app_role_id'] ?? '').toString();
          final String createdAt = (r['created_date_time'] ?? formRoot['created_date_time'] ?? formDataJson['created_date_time'] ?? '').toString();
          final String modifiedAt = (r['modified_date_time'] ?? formRoot['modified_date_time'] ?? formDataJson['modified_date_time'] ?? '').toString();

          final String hhRef = (r['household_ref_key'] ?? '').toString();
          final String benRef = (r['beneficiary_ref_key'] ?? '').toString();

          if (hhRef.isEmpty || benRef.isEmpty) {
            continue; // skip invalid rows
          }

          payload.add({
            'unique_key': hhRef,
            'beneficiaries_registration_ref_key': benRef,
            'mother_care_type': 'anc_due',
            'user_id': userId,
            'facility_id': facility,
            'is_deleted': 0,
            'created_by': userId,
            'created_date_time': createdAt,
            'modified_by': userId,
            'modified_date_time': modifiedAt,
            'parent_added_by': userId,
            'parent_facility_id': int.tryParse(facility) ?? facility,
            'app_role_id': appRoleId,
            'is_guest': 0,
            'pregnancy_count': 1,
            'device_details': {
              'device_id': deviceJson['id'] ?? deviceJson['device_id'],
              'device_plateform': deviceJson['platform'] ?? deviceJson['device_plateform'],
              'device_plateform_version': deviceJson['version'] ?? deviceJson['device_plateform_version'],
            },
            'app_details': {
              'app_version': appJson['app_version'],
              'app_name': appJson['app_name'],
            },
            'geolocation_details': {
              'latitude': geoJson['lat']?.toString() ?? '',
              'longitude': geoJson['long']?.toString() ?? '',
            },
          });
        } catch (e) {
          print('MotherCare ANC Push: error building payload for a form -> $e');
        }
      }

      if (payload.isEmpty) {
        print('MotherCare ANC Push: No valid payload items after filtering');
        return;
      }

      final resp = await _mcRepo.addMotherCareActivity(payload);
      final success = resp is Map && resp['success'] == true;

      if (success) {
        for (final r in list) {
          try {
            await _dao.markMotherCareAncFormSyncedById(r['id'] as int? ?? 0);
          } catch (e) {
            print('MotherCare ANC Push: error marking form ${r['id']} as synced -> $e');
          }
        }
        print('MotherCare ANC Push: Marked ${list.length} form(s) as synced');
      } else {
        print('MotherCare ANC Push: API not successful, will retry later');
      }
    } catch (e) {
      print('MotherCare ANC Push: error -> $e');
    }
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
      await fetchHouseholdsFromServer();
      await syncUnsyncedEligibleCoupleActivities();
      await syncUnsyncedChildCareActivities();
      await syncUnsyncedMotherCareAncActivities();
      await fetchEligibleCoupleActivitiesFromServer();
      await fetchChildCareActivitiesFromServer();
    } catch (e) {
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

  Future<void> fetchHouseholdsFromServer() async {
    try {
      final lastId = await _dao.getLatestHouseholdServerId();
      final useLast = (lastId.isEmpty) ? '0' : lastId;
      print('Household Pull: Fetching from server with last_id=$useLast, limit=20');
      final result = await _householdRepo.fetchAndStoreHouseholds(lastId: useLast, limit: 20);
      final inserted = result['inserted'];
      final fetched = result['fetched'];
      print('Household Pull: fetched=$fetched, inserted=$inserted, skipped=${result['skipped']}');
    } catch (e) {
      print('Household Pull: error -> $e');
    }
  }
}
