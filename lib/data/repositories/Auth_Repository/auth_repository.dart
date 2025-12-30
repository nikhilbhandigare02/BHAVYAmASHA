import 'dart:convert';

import 'package:medixcel_new/core/error/Exception/app_exception.dart';
import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/models/auth/login_request_model.dart';
import 'package:medixcel_new/data/models/auth/login_response_model.dart';

import '../../Database/User_Info.dart';
import '../../SecureStorage/SecureStorage.dart';

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

        final userData = await UserInfo.storeUserData(
          username: username,
          password: password,
          roleId: roleId,
          userDetails: userDetails,
        );

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

          if (loginResponse.token != null) {
            await SecureStorageService.saveToken(loginResponse.token!);
          }
          
          print('User data saved to secure storage');
        } catch (e) {
          print('Error saving to secure storage: $e');
        }
        

        await UserInfo.printUserData();

        return {
          'loginResponse': loginResponse,
          'isNewUser': userData['isNewUser'],
          'user': userData['user']
        };
      }
      
      return {
        'loginResponse': loginResponse,
        'isNewUser': true,
        'user': null
      };
      
    } on AppExceptions {
      rethrow;
    } catch (e) {
      throw AppExceptions('An error occurred during login. Please try again.');
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String username,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
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

      final requestBody = {
        'username': username.trim(),
        'password': currentPassword.trim(),
        'change_password': newPassword.trim(),
        'confirm_new_password': confirmNewPassword.trim(),
      };

      print('Change Password Request: ${Endpoints.changePassword}');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await _apiService.postApi(
        Endpoints.changePassword,
        requestBody,
        headers: headers,
      );

      print('Raw Change Password Response (Type: ${response.runtimeType}): $response');

      final responseData = response is Map<String, dynamic>
          ? response
          : (response is String ? jsonDecode(response) : <String, dynamic>{});

      print('Processed Change Password Response: $responseData');

      return responseData is Map<String, dynamic>
          ? responseData
          : <String, dynamic>{};
    } on AppExceptions {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

}
