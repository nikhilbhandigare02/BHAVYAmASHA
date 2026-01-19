import 'dart:convert';

import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';

import '../../Database/User_Info.dart';

class AddBeneficiaryRepository {
  final NetworkServiceApi _api = NetworkServiceApi();


  Future<dynamic> addBeneficiary(Map<String, dynamic> payload) async {
    try {
      String? token = await _getAuthToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      print('Sending beneficiary data to API...');
      
      final response = await _api.postApi(
        Endpoints.addBeneficiary,
        payload,
        headers: headers,
      );


      final result = response is String ? jsonDecode(response) : response;
      print('API Response: ${result.toString()}');
      
      return result;
    } catch (e, stackTrace) {
      print('Error in addBeneficiary: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Helper method to get authentication token
  Future<String?> _getAuthToken() async {
    try {
      // First try to get from secure storage
      String? token = await SecureStorageService.getToken();
      
      // If not found in secure storage, try to get from user details
      if (token == null || token.isEmpty) {
        final currentUser = await UserInfo.getCurrentUser();
        if (currentUser != null && currentUser['details'] != null) {
          final userDetails = currentUser['details'] is String 
              ? jsonDecode(currentUser['details']) 
              : currentUser['details'];
          token = userDetails['token']?.toString();
        }
      }
      
      return token;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }
}
