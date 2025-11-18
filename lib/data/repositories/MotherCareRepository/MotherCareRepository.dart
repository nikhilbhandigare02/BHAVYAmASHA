import 'dart:convert';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

import '../../Local_Storage/User_Info.dart';

class MotherCareRepository {
  final NetworkServiceApi _api = NetworkServiceApi();

  Future<dynamic> addMotherCareActivity(List<dynamic> payload) async {
    final currentUser = await UserInfo.getCurrentUser();
    final userDetails = currentUser?['details'] is String
        ? jsonDecode(currentUser?['details'] ?? '{}')
        : currentUser?['details'] ?? {};

    String? token = await SecureStorageService.getToken();
    if ((token == null || token.isEmpty) && userDetails is Map) {
      try {
        token = userDetails['token']?.toString();
      } catch (_) {}
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await _api.postApi(
      Endpoints.addMotherCareActivity,
      payload,
      headers: headers,
    );

    return response is String ? jsonDecode(response) : response;
  }
}
