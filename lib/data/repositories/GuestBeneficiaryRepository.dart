import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';

class GuestBeneficiaryRepository {
  final NetworkServiceApi _api;
  GuestBeneficiaryRepository({NetworkServiceApi? api}) : _api = api ?? NetworkServiceApi();

  Future<Map<String, dynamic>> searchGuestBeneficiaries(Map<String, dynamic> data) async {
    // TODO: replace 'guest/search' with the real endpoint
    final response = await _api.postApi('guest/search', data);
    return response;
  }
}
