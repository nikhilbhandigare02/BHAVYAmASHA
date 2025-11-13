import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import '../../SecureStorage/SecureStorage.dart';
import '../../models/ExistingAbhaCreated/ExistingAbhaCreated.dart';


class ExistingAbhaCreatedRepository {
  final NetworkServiceApi _apiService = NetworkServiceApi();

  Future<ExistingAbhaCreated> existingAbhaCreated(String userUniqueKey) async {
    try {
      final token = await SecureStorageService.getToken();
      print('🔐 Retrieved token: $token');
      print('🧩 user_unique_key: $userUniqueKey');

      final response = await _apiService.getApi(
        Endpoints.existingAbhaCreated,
        queryParams: {
          'user_unique_key': userUniqueKey,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('✅ [ExistingAbhaCreatedRepository] API Response: $response');
      return ExistingAbhaCreated.fromJson(response);
    } catch (e) {
      print('❌ [ExistingAbhaCreatedRepository] API Error: $e');
      rethrow;
    }
  }
}
