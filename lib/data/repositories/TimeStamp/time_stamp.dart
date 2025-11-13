import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';

import '../../../data/SecureStorage/SecureStorage.dart';

class TimeStampRepository {
  final NetworkServiceApi _apiService = NetworkServiceApi();

  Future<Map<String, dynamic>> getTimeStamp() async {
    print('🟢 [TimeStampRepository] getTimeStamp() called');

    try {
      final token = await SecureStorageService.getToken();
      print('🔐 Retrieved token from SecureStorage: $token');

      final response = await _apiService.getApi(
        Endpoints.getTimeStamp,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('✅ [TimeStampRepository] API hit successful');
      print('📦 Response: $response');

      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('❌ [TimeStampRepository] API call failed: $e');
      rethrow;
    }
  }
}
