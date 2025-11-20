import 'dart:convert';
import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/models/guest_beneficiary/search_beneficiary_request.dart';
import 'package:medixcel_new/data/models/guest_beneficiary/search_beneficiary_response.dart';

class GuestBeneficiaryRepository {
  final NetworkServiceApi _api;
  GuestBeneficiaryRepository({NetworkServiceApi? api}) : _api = api ?? NetworkServiceApi();

  Future<SearchBeneficiaryResponse> searchBeneficiary(String beneficiaryNumber) async {
    try {
      print('🔍 Searching beneficiary with number: $beneficiaryNumber');
      
      final request = SearchBeneficiaryRequest(
        beneficiaryNumber: beneficiaryNumber,
      );
      
      print('📤 Request: ${jsonEncode(request.toJson())}');
      
      final response = await _api.postApi(
        Endpoints.searchBeneficiary,
        request.toJson(),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('📥 Response: $response');
      
      if (response is Map<String, dynamic>) {
        return SearchBeneficiaryResponse.fromJson(response);
      } else if (response is String) {
        return SearchBeneficiaryResponse.fromJson(jsonDecode(response));
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print('❌ Error in searchBeneficiary: $e');
      return SearchBeneficiaryResponse(
        success: false,
        message: e.toString(),
      );
    }
  }


  Future<Map<String, dynamic>> searchGuestBeneficiaries(Map<String, dynamic> data) async {
    final response = await _api.postApi('guest/search', data);
    return response;
  }
}
