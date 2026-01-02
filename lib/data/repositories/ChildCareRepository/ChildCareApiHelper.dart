import 'dart:convert';

import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/repositories/ChildCareRepository/ChildCareRepository.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import '../../Database/local_storage_dao.dart';

class ChildCareApiHelper {
  final ChildCareRepository _repo = ChildCareRepository();
  final LocalStorageDao _dao = LocalStorageDao.instance;

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

  Future<void> syncChildCareActivities() async {
    try {
      // Get current user info
      final currentUser = await UserInfo.getCurrentUser();
      if (currentUser == null) {
        print('CC Sync: No current user found');
        return;
      }

      // Get user details
      final userDetails = currentUser['details'] is String
          ? jsonDecode(currentUser['details'] as String)
          : currentUser['details'] ?? {};

      final userId = userDetails['unique_key']?.toString() ?? '';
      final facilityId = userDetails['working_location']?['asha_associated_with_facility_id']?.toString() ??
          userDetails['facility_id']?.toString() ?? '';
      final appRoleId = int.tryParse(userDetails['app_role_id']?.toString() ?? '1') ?? 1;

      if (userId.isEmpty || facilityId.isEmpty) {
        print('CC Sync: Missing required user details (user_id or facility_id)');
        return;
      }

      final unsyncedActivities = await _dao.getUnsyncedChildCareActivities();
      if (unsyncedActivities.isEmpty) {
        print('CC Sync: No unsynced activities found');
        return;
      }

      print('CC Sync: Found ${unsyncedActivities.length} unsynced activities');

      // Build array of payloads for batch processing
      List<Map<String, dynamic>> payloadArray = [];
      List<int> activityIds = [];

      // Format date time properly
      String formatDateTime(dynamic dateTime) {
        if (dateTime == null) {
          final now = DateTime.now();
          return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        }
        
        if (dateTime is String) {
          // Try to parse and reformat to ensure consistency
          try {
            final parsed = DateTime.parse(dateTime);
            return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}:${parsed.second.toString().padLeft(2, '0')}';
          } catch (_) {
            return dateTime; // Return original if parsing fails
          }
        }
        
        return dateTime.toString();
      }

      // Process each activity and build payload array
      for (final activity in unsyncedActivities) {
        try {
          final deviceDetails = activity['device_details'] is String
              ? jsonDecode(activity['device_details'] as String)
              : activity['device_details'] ?? {};

          final appDetails = activity['app_details'] is String
              ? jsonDecode(activity['app_details'] as String)
              : activity['app_details'] ?? {};

          final geoLocation = activity['geo_location'] is Map
              ? Map<String, dynamic>.from(activity['geo_location'] as Map)
              : <String, dynamic>{};

          // Build payload according to the provided structure
          final payload = {
            "unique_key": activity['household_ref_key'] ?? '',
            "beneficiaries_registration_ref_key": activity['beneficiary_ref_key'] ?? '',
            "child_care_type": activity['child_care_state'] ?? 'registration_due',
            "user_id": activity['current_user_key'],
            "facility_id": activity['facility_id'].toString(),
            "is_deleted": 0,
            "created_by": activity['current_user_key'],
            "created_date_time": formatDateTime(activity['created_date_time']),
            "modified_by": activity['current_user_key'],
            "modified_date_time": formatDateTime(activity['modified_date_time']),
            "parent_added_by": activity['current_user_key'],
            "parent_facility_id": int.tryParse(activity['facility_id']?.toString() ?? '0') ?? 0,
            "app_role_id": appRoleId,
            "is_guest": 0,
            "device_details": {
              'device_id': deviceDetails['deviceId'] ?? deviceDetails['device_id'] ?? '',
              'device_plateform': deviceDetails['platform'] ?? deviceDetails['device_plateform'] ?? 'Android',
              'device_plateform_version': deviceDetails['version'] ?? deviceDetails['device_plateform_version'] ?? '',
            },
            "app_details": {
              "app_version": appDetails['app_version'] ?? '1.0.0',
              "app_name": appDetails['app_name'] ?? 'BHAVYA mASHA Training',
            },
            'geolocation_details': {
              'latitude': (geoLocation['latitude'] ?? '').toString(),
              'longitude': (geoLocation['longitude'] ?? '').toString(),
            },
          };

          payloadArray.add(payload);
          activityIds.add(activity['id'] as int? ?? 0);

        } catch (e, stackTrace) {
          print('CC Sync: Error building payload for activity ${activity['id']}: $e');
          print('Stack trace: $stackTrace');
        }
      }

      if (payloadArray.isEmpty) {
        print('CC Sync: No valid payloads to send');
        return;
      }

      // Send batch request with array of payloads
      print('CC Sync: Sending batch payload with ${payloadArray.length} activities');
      print('CC Sync: Payload: ${jsonEncode(payloadArray)}');
      
      final response = await _repo.submitChildCareActivities(payloadArray);

      if (response is Map && response['success'] == true) {
        // Mark all activities as synced
        for (final id in activityIds) {
          if (id > 0) {
            try {
              await _dao.markChildCareActivitySyncedById(id);
              print('CC Sync: Successfully synced activity $id');
            } catch (e) {
              print('CC Sync: Error marking activity $id as synced: $e');
            }
          }
        }
        print('CC Sync: Successfully synced ${activityIds.where((id) => id > 0).length} activities');
      } else {
        print('CC Sync: API call failed for batch request: $response');
      }

    } catch (e, stackTrace) {
      print('CC Sync: Error in syncChildCareActivities: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
