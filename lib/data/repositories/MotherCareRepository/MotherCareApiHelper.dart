// In MotherCareApiHelper.dart
import 'dart:convert';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/mother_care_activities_table.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import 'package:medixcel_new/data/repositories/MotherCareRepository/MotherCareRepository.dart';

import '../../Database/local_storage_dao.dart';

class MotherCareApiHelper {
  final MotherCareRepository _repo = MotherCareRepository();
  final LocalStorageDao _dao = LocalStorageDao.instance;


  Future<void> syncMotherCareActivities() async {
    try {
      // Get current user info
      final currentUser = await UserInfo.getCurrentUser();
      if (currentUser == null) {
        print('MC Sync: No current user found');
        return;
      }

      // Get user details
      final userDetails = currentUser['details'] is String
          ? jsonDecode(currentUser['details'] as String)
          : currentUser['details'] ?? {};

      final userId = userDetails['unique_key']?.toString() ?? '';
      final facilityId = userDetails['working_location']?['facility_id']?.toString() ??
          userDetails['facility_id']?.toString() ?? '';
      final appRoleId = int.tryParse(userDetails['app_role_id']?.toString() ?? '1') ?? 1;

      if (userId.isEmpty || facilityId.isEmpty) {
        print('MC Sync: Missing required user details (user_id or facility_id)');
        return;
      }

      final unsyncedActivities = await _dao.getUnsyncedMotherCareActivities();
      if (unsyncedActivities.isEmpty) {
        print('MC Sync: No unsynced activities found');
        return;
      }

      print('MC Sync: Found ${unsyncedActivities.length} unsynced activities');

      // Process each activity
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
            "mother_care_type": activity['mother_care_state'] ?? 'anc_due',
            "user_id": activity['current_user_key'],
            "facility_id": activity['facility_id'],
            "is_deleted": 0,
            "created_by": activity['current_user_key'],
            "created_date_time": activity['created_date_time'] ?? DateTime.now().toIso8601String(),
            "modified_by": activity['current_user_key'],
            "modified_date_time": DateTime.now().toIso8601String(),
            "parent_added_by": '0',
            "parent_facility_id": '0',
            "app_role_id": appRoleId,
            "is_guest": 0,
            "pregnancy_count": activity['pregnancy_count'] ?? 1,
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

          print('MC Sync: Sending payload: ${jsonEncode(payload)}');
          final response = await _repo.addMotherCareActivity([payload]);

          if (response is Map && response['success'] == true) {
            final id = activity['id'] as int?;
            if (id != null) {
              await _dao.markMotherCareActivitySyncedById(id);
              print('MC Sync: Successfully synced activity $id');
            }
          } else {
            print('MC Sync: API call failed for activity ${activity['id']}: $response');
          }
        } catch (e, stackTrace) {
          print('MC Sync: Error processing activity ${activity['id']}: $e');
          print('Stack trace: $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      print('MC Sync: Error in syncMotherCareActivities: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}