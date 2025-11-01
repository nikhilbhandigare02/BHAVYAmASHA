import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserData = 'user_data';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyCurrentUser = 'current_user_id';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Save refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // Save user data
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: _keyUserData, value: userData);
  }

  // Get user data
  static Future<String?> getUserData() async {
    return await _storage.read(key: _keyUserData);
  }

  // Delete all data (logout)
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // Delete specific data
  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all secure storage (for logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Set login flag
  static Future<void> setLoginFlag(int value) async {
    await _storage.write(key: _keyIsLoggedIn, value: value.toString());
  }

  // Get login flag
  static Future<int> getLoginFlag() async {
    final value = await _storage.read(key: _keyIsLoggedIn);
    return int.tryParse(value ?? '0') ?? 0;
  }

  // Save user data with unique key
  static Future<void> saveUserDataWithKey(String uniqueKey, Map<String, dynamic> userData) async {
    try {
      final userDataKey = '${_keyUserData}_$uniqueKey';
      final userDataString = jsonEncode(userData);
      print('Saving user data with key: $userDataKey');
      print('User data to save: $userDataString');
      
      await _storage.write(key: userDataKey, value: userDataString);
      await _storage.write(key: _keyCurrentUser, value: uniqueKey);
      
      // Verify the data was saved
      final savedData = await _storage.read(key: userDataKey);
      print('Data saved successfully. Verification: ${savedData != null}');
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  // Get user data using unique key
  static Future<Map<String, dynamic>?> getUserDataByKey(String uniqueKey) async {
    try {
      final userDataKey = '${_keyUserData}_$uniqueKey';
      print('Fetching user data with key: $userDataKey');
      
      final userDataString = await _storage.read(key: userDataKey);
      print('Retrieved user data string: $userDataString');
      
      if (userDataString != null && userDataString.isNotEmpty) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        print('Successfully parsed user data');
        return userData;
      } else {
        print('No user data found for key: $userDataKey');
      }
    } catch (e) {
      print('Error parsing user data: $e');
    }
    return null;
  }

  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      print('Getting current user data...');
      final currentUser = await _storage.read(key: _keyCurrentUser);
      print('Current user key: $currentUser');
      
      if (currentUser != null) {
        final userData = await getUserDataByKey(currentUser);
        print('Retrieved user data: $userData');
        return userData;
      } else {
        print('No current user found in secure storage');
      }
    } catch (e) {
      print('Error getting current user data: $e');
    }
    return null;
  }

  // Get current user's unique key
  static Future<String?> getCurrentUserKey() async {
    return await _storage.read(key: _keyCurrentUser);
  }

  // Clear all user data including current user
  static Future<void> clearUserData() async {
    final currentUser = await _storage.read(key: _keyCurrentUser);
    if (currentUser != null) {
      await _storage.delete(key: '${_keyUserData}_$currentUser');
      await _storage.delete(key: _keyCurrentUser);
    }
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.write(key: _keyIsLoggedIn, value: '0');
  }
}
