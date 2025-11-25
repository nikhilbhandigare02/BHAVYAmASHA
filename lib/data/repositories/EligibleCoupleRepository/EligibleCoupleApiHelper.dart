import 'dart:convert';

import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/repositories/EligibleCoupleRepository/EligibleCoupleRepository.dart';

class EligibleCoupleApiHelper {
  final EligibleCoupleRepository _repo = EligibleCoupleRepository();
  final LocalStorageDao _dao = LocalStorageDao.instance;

  Future<void> syncTrackingDueFromFollowupRow(int formId) async {
    final db = await DatabaseProvider.instance.database;
    final rows = await db.query(
      FollowupFormDataTable.table,
      where: 'id = ?',
      whereArgs: [formId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final saved = Map<String, dynamic>.from(rows.first);
    final String beneficiaryRefKey = (saved['beneficiary_ref_key'] ?? '').toString();
    final String formsRefKey = (saved['forms_ref_key'] ?? '').toString();
    final String nowIso = DateTime.now().toIso8601String();

    Map<String, dynamic> deviceJson = {};
    Map<String, dynamic> appJson = {};
    Map<String, dynamic> geoJson = {};
    try {
      if (saved['device_details'] is String && (saved['device_details'] as String).isNotEmpty) {
        deviceJson = Map<String, dynamic>.from(jsonDecode(saved['device_details']));
      }
    } catch (_) {}
    try {
      if (saved['app_details'] is String && (saved['app_details'] as String).isNotEmpty) {
        appJson = Map<String, dynamic>.from(jsonDecode(saved['app_details']));
      }
    } catch (_) {}
    try {
      if (saved['form_json'] is String && (saved['form_json'] as String).isNotEmpty) {
        final fj = jsonDecode(saved['form_json']);
        if (fj is Map) {
          if (fj['geolocation_details'] is Map) {
            geoJson = Map<String, dynamic>.from(fj['geolocation_details']);
          } else if (fj['form_data'] is Map && (fj['form_data']['geolocation_details'] is Map)) {
            geoJson = Map<String, dynamic>.from(fj['form_data']['geolocation_details']);
          }
        }
      }
    } catch (_) {}

    final String facility = (saved['facility_id'] ?? '').toString();
    final String householdRefKey = (saved['household_ref_key'] ?? '').toString();

    if (householdRefKey.isEmpty || beneficiaryRefKey.isEmpty) {
      return;
    }

    final ecPayloadList = [
      {
        'unique_key': householdRefKey,
        'beneficiaries_registration_ref_key': beneficiaryRefKey,
        'eligible_couple_type': 'tracking_due',
        'facility_id': facility,
        'is_deleted': 0,
        'created_date_time': nowIso,
        'modified_date_time': nowIso,
        'parent_facility_id': int.tryParse(facility) ?? facility,
        'is_guest': 0,
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
      },
    ];

    try {
      final apiResp = await _repo.trackEligibleCouple(ecPayloadList);
      try {
        if (apiResp is Map && apiResp['success'] == true && apiResp['data'] is List) {
          final List data = apiResp['data'];
          Map? tracking = data.cast<Map>().firstWhere(
                (e) => (e['eligible_couple_type']?.toString() ?? '') == 'tracking_due',
            orElse: () => {},
          );
          final serverId = (tracking?['_id'] ?? '').toString();
          if (serverId.isNotEmpty) {
            final updated = await db.update(
              FollowupFormDataTable.table,
              {
                'server_id': serverId,
                'modified_date_time': nowIso,
              },
              where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
              whereArgs: [beneficiaryRefKey, formsRefKey],
            );
            print('EligibleCoupleApiHelper: Updated followup_form_data server_id=$serverId rows=$updated');
          }
        }
      } catch (e) {
        print('EligibleCoupleApiHelper: Error updating followup_form_data with EC server_id: $e');
      }
    } catch (e) {
      print('EligibleCoupleApiHelper: EC API call failed: $e');
    }
  }
}
