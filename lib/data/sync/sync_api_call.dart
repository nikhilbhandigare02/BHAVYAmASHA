import 'dart:convert';

import '../Database/User_Info.dart';
import '../Database/local_storage_dao.dart';
import '../repositories/AddBeneficiary/BeneficiaryRepository.dart';
import '../repositories/ChildCareRepository/ChildCareRepository.dart';
import '../repositories/EligibleCoupleRepository/EligibleCoupleRepository.dart';
import '../repositories/FollowupFormsRepository/FollowupFormsRepository.dart';
import '../repositories/HousholdRepository/household_repository.dart';
import '../repositories/MotherCareRepository/MotherCareRepository.dart';
import '../repositories/NotificationRepository/Notification_Repository.dart';

class SyncApiCall {
  static final _dao = LocalStorageDao.instance;
  static final _householdRepo = HouseholdRepository();
  static final _notificationRepo = NotificationRepository();
  static final _beneficiaryPullRepo = BeneficiaryRepository();
  static final _ecRepo = EligibleCoupleRepository();
  static final _ccRepo = ChildCareRepository();
  static final _followupRepo = FollowupFormsRepository();
  static final _mcRepo = MotherCareRepository();

  static Future<void> allGetApicall() async {
    try {

      print("SyncApiCall - new class call");
      await fetchBeneficiariesFromServer();
      print("SyncApiCall - new class call");
      await fetchHouseholdsFromServer();
      print("SyncApiCall - new class call");
      await fetchEligibleCoupleActivitiesFromServer();
      print("SyncApiCall - new class call");
      await fetchChildCareActivitiesFromServer();
      print("SyncApiCall - new class call");
      await fetchMotherCareActivitiesFromServer();
      print("SyncApiCall - new class call");
      await fetchFollowupFormsFromServer();
      print("SyncApiCall - new class call -  last");
      await fetchNotificationsFromServer();
    } catch (e) {
      print('SyncService periodic error: $e');
    } finally {

    }
  }
  static Future<void> fetchNotificationsFromServer() async {
    try {
      print('Notification Sync: Fetching notifications...');
      await _notificationRepo.fetchAndSaveNotifications();
      print('Notification Sync: Completed');
    } catch (e) {
      print('Notification Sync: Error -> $e');
    }
  }

  static Future<void> fetchBeneficiariesFromServer() async {
    try {
      final lastId = await _dao.getLatestBeneficiaryServerId();
      final useLast = (lastId.isEmpty) ? '' : lastId;
      print('Beneficiary Pull: Fetching from server with last_id=$useLast');
      final result = await _beneficiaryPullRepo.fetchAndStoreBeneficiaries(lastId: useLast);
      final inserted = result['inserted'];
      final fetched = result['fetched'];
      print('Beneficiary Pull: fetched=$fetched, inserted=$inserted, skipped=${result['skipped']}');
    } catch (e) {
      print('Beneficiary Pull: error -> $e');
    }
  }


  static Future<Map<String, String>> _getUserWorkingIds() async {
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


  static Future<void> fetchHouseholdsFromServer() async {
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

  static Future<void> fetchEligibleCoupleActivitiesFromServer() async {
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

  static Future<void> fetchChildCareActivitiesFromServer() async {
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

  static Future<void> fetchMotherCareActivitiesFromServer() async {
    try {
      final ids = await _getUserWorkingIds();
      if (ids['facilityId']!.isEmpty || ids['ashaId']!.isEmpty) return;
      final lastId = await _dao.getLatestMotherCareActivityServerId();
      final useLast = lastId.isEmpty ? '0' : lastId;
      print('MotherCare Pull: Fetching with last_id=${useLast ?? '[default]'} limit=20');
      final result = await _mcRepo.fetchAndStoreMotherCareActivities(
        facilityId: ids['facilityId']!,
        ashaId: ids['ashaId']!,
        lastId: useLast,
        limit: 20,
      );
      print('MotherCare Pull: fetched=${result['fetched']}, inserted=${result['inserted']}, updated=${result['updated']}');
    } catch (e) {
      print('MotherCare Pull: error -> $e');
    }
  }

  static Future<void> fetchFollowupFormsFromServer() async {
    try {
      final ids = await _getUserWorkingIds();
      if (ids['facilityId']!.isEmpty || ids['ashaId']!.isEmpty) return;
      final lastId = await _dao.getLatestFollowupFormServerId();
      final useLast = lastId.isEmpty ? '0' : lastId;
      print('FollowupForms Pull: Fetching with last_id=$useLast limit=20');
      final result = await _followupRepo.fetchAndStoreFollowupForms(
        facilityId: ids['facilityId']!,
        ashaId: ids['ashaId']!,
        lastId: useLast,
        limit: 20,
      );
      print('FollowupForms Pull: fetched=${result['fetched']}, inserted=${result['inserted']}, updated=${result['updated']}');
    } catch (e) {
      print('FollowupForms Pull: error -> $e');
    }
  }
}