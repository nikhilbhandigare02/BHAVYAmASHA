import '../../NetworkAPIServices/APIs_Urls/Endpoints.dart';
import '../../NetworkAPIServices/api_services/network_services_API.dart';
import '../../SecureStorage/SecureStorage.dart';

class RegisterNewHouseHold {
  final NetworkServiceApi _apiService = NetworkServiceApi();

  Future<Map<String, dynamic>> getRCHData({
    required int requestFor,
    required int rchId,
  }) async {
    try {
      final token = await SecureStorageService.getToken();

      final requestBody = {
        "request_for": requestFor,
        "rch_id": rchId,
      };

      final response = await _apiService.postApi(
        Endpoints.getRCHDataForID,   // 1st positional argument
        requestBody,                 // 2nd positional argument → data
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
