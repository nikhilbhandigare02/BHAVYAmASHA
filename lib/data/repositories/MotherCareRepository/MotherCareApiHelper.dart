import 'dart:convert';

import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/repositories/MotherCareRepository/MotherCareRepository.dart';

class MotherCareApiHelper {
  final MotherCareRepository _repo = MotherCareRepository();


  Future<void> syncAncByFollowupFormId(int formId) async {
    final db = await DatabaseProvider.instance.database;
    final rows = await db.query(
      FollowupFormDataTable.table,
      where: 'id = ?',
      whereArgs: [formId],
      limit: 1,
    );

    if (rows.isEmpty) return;

    final saved = Map<String, dynamic>.from(rows.first);

    Map<String, dynamic> deviceJson = {};
    Map<String, dynamic> appJson = {};
    Map<String, dynamic> geoJson = {};
    Map<String, dynamic> formRoot = {};
    Map<String, dynamic> formDataJson = {};

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
      }
    } catch (_) {}

    final String userId = (saved['current_user_key'] ?? formRoot['user_id'] ?? formDataJson['user_id'] ?? '').toString();
    final String facility = (saved['facility_id']?.toString() ?? formRoot['facility_id']?.toString() ?? formDataJson['facility_id']?.toString() ?? '');
    final String appRoleId = (formRoot['app_role_id'] ?? formDataJson['app_role_id'] ?? '').toString();
    final String createdAt = (saved['created_date_time'] ?? formRoot['created_date_time'] ?? formDataJson['created_date_time'] ?? '').toString();
    final String modifiedAt = (saved['modified_date_time'] ?? formRoot['modified_date_time'] ?? formDataJson['modified_date_time'] ?? '').toString();

    final dbHouseholdRefKey = (saved['household_ref_key'] ?? '').toString();
    final dbBeneficiaryRefKey = (saved['beneficiary_ref_key'] ?? '').toString();

    if (dbHouseholdRefKey.isEmpty || dbBeneficiaryRefKey.isEmpty) {
      return;
    }

    final motherCarePayload = [
      {
        'unique_key': dbHouseholdRefKey,
        'beneficiaries_registration_ref_key': dbBeneficiaryRefKey,
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
      },
    ];

    try {
      final apiResp = await _repo.addMotherCareActivity(motherCarePayload);
      try {
        if (apiResp is Map && apiResp['success'] == true && apiResp['data'] is List) {
          final List data = apiResp['data'];
          Map? rec = data.cast<Map>().firstWhere(
            (e) => (e['mother_care_type']?.toString() ?? '') == 'anc_due',
            orElse: () => {},
          );
          final serverId = (rec?['_id'] ?? '').toString();
          if (serverId.isNotEmpty) {
            final updated = await db.update(
              FollowupFormDataTable.table,
              {
                'server_id': serverId,
                // keep modified_date_time as stored in DB, no new timestamp
              },
              where: 'id = ?',
              whereArgs: [formId],
            );
            print('MotherCareApiHelper: Updated followup_form_data with mother care server_id=$serverId rows=$updated');
          }
        }
      } catch (e) {
        print('MotherCareApiHelper: Error updating followup_form_data with mother care server_id: $e');
      }
    } catch (e) {
      print('MotherCareApiHelper: Mother care API call failed: $e');
    }
  }
}
