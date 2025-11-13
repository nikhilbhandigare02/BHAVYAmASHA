import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import '../../SecureStorage/SecureStorage.dart';
import '../../models/AbhaCreated/AbhaCreated.dart';


class AbhaCreatedRepository {
  final NetworkServiceApi _apiService = NetworkServiceApi();

  Future<AbhaCreated> getAbhaCreated(String userUniqueKey) async {
    print('🟢 [AbhaCreatedRepository] API call started');

    try {
      final token = await SecureStorageService.getToken();
      print('🔐 Retrieved token: $token');
      print('👤 user_unique_key: $userUniqueKey');

      final response = await _apiService.getApi(
        Endpoints.abhaCreated,
        queryParams: {
          'user_unique_key': userUniqueKey,
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('✅ [AbhaCreatedRepository] API Response: $response');
      return AbhaCreated.fromJson(response);
    } catch (e) {
      print('❌ [AbhaCreatedRepository] API Error: $e');
      rethrow;
    }
  }
}
