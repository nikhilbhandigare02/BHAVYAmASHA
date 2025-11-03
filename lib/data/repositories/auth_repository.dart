import 'dart:convert';

import 'package:medixcel_new/core/error/Exception/app_exception.dart';
import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/models/auth/login_request_model.dart';
import 'package:medixcel_new/data/models/auth/login_response_model.dart';

import '../Local_Storage/User_Info.dart';
import '../SecureStorage/SecureStorage.dart';

class AuthRepository {
  final NetworkServiceApi _apiService = NetworkServiceApi();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final requestBody = {
        'username': username.trim(),
        'password': password.trim(),
      };

      print('Login Request: ${Endpoints.login}');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await _apiService.postApi(
        Endpoints.login,
        requestBody,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
<<<<<<< HEAD
=======

>>>>>>> 9f2a034e02f342ea81ecc20d1a6cbdc2939debdf
      print('Raw Login Response (Type: ${response.runtimeType}): $response');
      
      final responseData = response is Map<String, dynamic>
          ? response 
          : (response is String ? jsonDecode(response) : response);
      
      print('Processed Response: $responseData');
      
      final loginResponse = LoginResponseModel.fromJson(
        responseData is Map<String, dynamic> 
            ? responseData 
            : {'success': false, 'msg': 'Invalid response format'}
      );
      
      print('Parsed Login Response - Success: ${loginResponse.success}');
      print('Token: ${loginResponse.token}');
      print('User Data: ${loginResponse.data}');
      

      if (loginResponse.success && loginResponse.data != null) {
        final userDetails = loginResponse.data!;
        final roleId = userDetails['app_role_id'] is int 
            ? userDetails['app_role_id'] 
            : int.tryParse(userDetails['app_role_id']?.toString() ?? '0') ?? 0;
        
        // Store user data in local database
        final userData = await UserInfo.storeUserData(
          username: username,
          password: password,
          roleId: roleId,
          userDetails: userDetails,
        );
        
        // Save user data to secure storage for drawer access
        try {
          await SecureStorageService.saveUserDataWithKey(
            username, // Using username as unique key
            {
              ...userDetails,
              'username': username,
              'role_id': roleId,
              'token': loginResponse.token,
            },
          );
          
          // Save token separately for auth purposes
          if (loginResponse.token != null) {
            await SecureStorageService.saveToken(loginResponse.token!);
          }
          
          print('User data saved to secure storage');
        } catch (e) {
          print('Error saving to secure storage: $e');
        }
        
        // Print stored user data for verification
        await UserInfo.printUserData();
        
        // Return both login response and user data status
        return {
          'loginResponse': loginResponse,
          'isNewUser': userData['isNewUser'],
          'user': userData['user']
        };
      }
      
      return {
        'loginResponse': loginResponse,
        'isNewUser': true, // Default to true if we can't determine
        'user': null
      };
      
    } on AppExceptions {
      rethrow;
    } catch (e) {
      throw AppExceptions('An error occurred during login. Please try again.');
    }
  }

}
