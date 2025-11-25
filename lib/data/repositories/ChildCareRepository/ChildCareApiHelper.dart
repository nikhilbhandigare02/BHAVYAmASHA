import 'dart:convert';

import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/repositories/ChildCareRepository/ChildCareRepository.dart';

class ChildCareApiHelper {
  final ChildCareRepository _repo = ChildCareRepository();

  Future<void> syncRegistrationDueByFollowupFormId(int formId) async {
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

    final working = <String, dynamic>{};
    final userId = (working['asha_id'] ?? '').toString();
    final facility = (working['asha_associated_with_facility_id'] ?? working['hsc_id'] ?? '').toString();
    final appRoleId = '';

    final nowTs = DateTime.now();
    String fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

    final householdRefKey = (saved['household_ref_key'] ?? '').toString();
    final beneficiaryRefKey = (saved['beneficiary_ref_key'] ?? '').toString();
    if (householdRefKey.isEmpty || beneficiaryRefKey.isEmpty) return;

    final payload = [
      {
        'unique_key': householdRefKey,
        'beneficiaries_registration_ref_key': beneficiaryRefKey,
        'child_care_type': 'registration_due',
        'user_id': userId,
        'facility_id': facility,
        'is_deleted': 0,
        'created_by': userId,
        'created_date_time': fmt(nowTs),
        'modified_by': userId,
        'modified_date_time': fmt(nowTs),
        'parent_added_by': userId,
        'parent_facility_id': int.tryParse(facility) ?? facility,
        'app_role_id': appRoleId,
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
      final apiResp = await _repo.submitChildCareActivities(payload);
      try {
        if (apiResp is Map && apiResp['success'] == true && apiResp['data'] is List) {
          final List data = apiResp['data'];
          Map? item = data.cast<Map>().firstWhere(
            (e) => (e['child_care_type']?.toString() ?? '') == 'registration_due',
            orElse: () => {},
          );
          final serverId = (item?['_id'] ?? '').toString();
          if (serverId.isNotEmpty) {
            int updated = await db.update(
              FollowupFormDataTable.table,
              {
                'server_id': serverId,
                'modified_date_time': saved['modified_date_time'],
              },
              where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
              whereArgs: [beneficiaryRefKey, saved['forms_ref_key']],
            );
            if (updated == 0) {
              updated = await db.update(
                FollowupFormDataTable.table,
                {
                  'server_id': serverId,
                  'modified_date_time': saved['modified_date_time'],
                },
                where: 'household_ref_key = ? AND forms_ref_key = ?',
                whereArgs: [householdRefKey, saved['forms_ref_key']],
              );
            }
            print('ChildCareApiHelper: Updated followup_form_data server_id=$serverId rows=$updated');
          }
        }
      } catch (e) {
        print('ChildCareApiHelper: Error updating followup_form_data with Child Care server_id: $e');
      }
    } catch (e) {
      print('ChildCareApiHelper: Child Care API call failed: $e');
    }
  }
}
