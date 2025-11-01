import 'dart:convert';

import 'package:medixcel_new/core/error/Exception/app_exception.dart';
import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/models/auth/login_request_model.dart';
import 'package:medixcel_new/data/models/auth/login_response_model.dart';

class AuthRepository {
  final NetworkServiceApi _apiService = NetworkServiceApi();

  Future<LoginResponseModel> login(String username, String password) async {
    try {
      // Create the request body
      final requestBody = {
        'username': username.trim(),
        'password': password.trim(),
      };

      print('Login Request: ${Endpoints.login}');
      print('Request Body: ${jsonEncode(requestBody)}');

      // Make the API call using NetworkServiceApi
      final response = await _apiService.postApi(
        Endpoints.login,
        requestBody,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      // Log the raw response
      print('Raw Login Response (Type: ${response.runtimeType}): $response');
      
      // Ensure response is a Map
      final responseData = response is Map<String, dynamic> 
          ? response 
          : (response is String ? jsonDecode(response) : response);
      
      print('Processed Response: $responseData');
      
      // Parse the response
      final loginResponse = LoginResponseModel.fromJson(
        responseData is Map<String, dynamic> 
            ? responseData 
            : {'success': false, 'msg': 'Invalid response format'}
      );
      
      print('Parsed Login Response - Success: ${loginResponse.success}');
      print('Token: ${loginResponse.token}');
      print('User Data: ${loginResponse.data}');
      
      return loginResponse;
      
    } on AppExceptions {
      rethrow; // Re-throw any AppExceptions from NetworkServiceApi
    } catch (e) {
      throw AppExceptions('An error occurred during login. Please try again.');
    }
  }
}
