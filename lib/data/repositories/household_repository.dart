import 'dart:convert';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

class HouseholdRepository {
  final NetworkServiceApi _api = NetworkServiceApi();

  Future<dynamic> addHousehold(Map<String, dynamic> payload) async {
    final token = await SecureStorageService.getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await _api.postApi(
      Endpoints.addHousehold,
      payload,
      headers: headers,
    );

    // Return parsed JSON/dynamic as-is; caller decides success criteria
    return response is String ? jsonDecode(response) : response;
  }
}
