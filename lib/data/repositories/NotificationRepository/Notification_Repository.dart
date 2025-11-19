import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import '../../Local_Storage/local_storage_dao.dart';
import '../../SecureStorage/SecureStorage.dart';
import '../../models/Notification/Notification_anouncement_responce.dart';

class NotificationRepository {
  final NetworkServiceApi _apiService = NetworkServiceApi();

  /// Fetch from API and save to SQLite
  Future<void> fetchAndSaveNotifications() async {
    print('notification API call started');

    try {
      final token = await SecureStorageService.getToken();

      final response = await _apiService.postApi(
        Endpoints.getNotification,
        {},
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('notification API Response: $response');

      final notificationResponse = NotificationAnouncementResponce.fromJson(response);

      if (notificationResponse.data != null && notificationResponse.data!.isNotEmpty) {
        // Get existing unique_keys from the database
        final existingNotifications = await LocalStorageDao.instance.getNotifications();
        final existingUniqueKeys = existingNotifications.map((n) => n['unique_key'] as String).toSet();

        // Filter out notifications that already exist
        final newNotifications = notificationResponse.data!
            .where((notification) => !existingUniqueKeys.contains(notification.uniqueKey))
            .map((e) => e.toMap())
            .toList();

        if (newNotifications.isNotEmpty) {
          // Save only new notifications in DB
          await LocalStorageDao.instance.insertNotifications(newNotifications);
          print("New notifications inserted into SQLite successfully!");
        } else {
          print("No new notifications to insert.");
        }
      }
    } catch (e) {
      print('notification API Error: $e');
      rethrow;
    }
  }
  /// Get notifications from SQLite
  Future<List<Map<String, dynamic>>> getLocalNotifications() async {
    return await LocalStorageDao.instance.getNotifications();
  }
}
