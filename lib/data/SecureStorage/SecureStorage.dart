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

  // Save ANC visit data
  static const String _keyAncVisits = 'anc_visits';

  static Future<void> saveAncVisit(Map<String, dynamic> visitData) async {
    try {
      // Get existing visits
      final existingData = await _storage.read(key: _keyAncVisits);
      List<dynamic> visits = [];

      if (existingData != null) {
        visits = jsonDecode(existingData);
      }

      // Check if we have a beneficiaryId to look for
      final String? beneficiaryId = visitData['beneficiaryId']?.toString();
      bool found = false;

      if (beneficiaryId != null && beneficiaryId.isNotEmpty) {
        // Look for existing entry with the same beneficiaryId
        for (int i = 0; i < visits.length; i++) {
          if (visits[i]['beneficiaryId']?.toString() == beneficiaryId) {
            // Update existing entry
            visits[i] = {
              ...visits[i], // Keep existing data
              ...visitData,  // Update with new data
              'updatedAt': DateTime.now().toIso8601String(), // Add/update timestamp
            };
            found = true;
            break;
          }
        }
      }

      // If no existing entry was found, add as new
      if (!found) {
        visits.add({
          ...visitData,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      // Save back to storage
      await _storage.write(
        key: _keyAncVisits,
        value: jsonEncode(visits),
      );
    } catch (e) {
      print('Error saving ANC visit: $e');
      rethrow;
    }
  }

  // Get all ANC visits
  static Future<List<dynamic>> getAncVisits() async {
    try {
      final data = await _storage.read(key: _keyAncVisits);
      if (data == null) return [];
      return jsonDecode(data);
    } catch (e) {
      print('Error getting ANC visits: $e');
      return [];
    }
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

  // Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      // First try to get the current user's unique key
      final currentUserKey = await _storage.read(key: _keyCurrentUser);
      if (currentUserKey == null || currentUserKey.isEmpty) {
        print('No current user key found');
        return null;
      }
      
      final userDataKey = '${_keyUserData}_$currentUserKey';
      print('Fetching current user data with key: $userDataKey');
      
      final userDataString = await _storage.read(key: userDataKey);
      print('Retrieved current user data string: $userDataString');
      
      if (userDataString == null || userDataString.isEmpty) {
        print('No user data found for key: $userDataKey');
        
        // Fallback to legacy user data format if available
        final legacyUserData = await _storage.read(key: _keyUserData);
        if (legacyUserData != null && legacyUserData.isNotEmpty) {
          print('Falling back to legacy user data format');
          return jsonDecode(legacyUserData) as Map<String, dynamic>;
        }
        
        return null;
      }
      
      try {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        print('Successfully parsed user data');
        return userData;
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
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

  // Get submission count for a beneficiary
  static Future<int> getSubmissionCount(String beneficiaryId) async {
    try {
      final key = 'submission_count_$beneficiaryId';
      final countStr = await _storage.read(key: key);
      if (countStr == null) {
        // If no count exists yet, initialize it to 1
        await _storage.write(key: key, value: '1');
        return 1;
      }
      return int.tryParse(countStr) ?? 1; // Default to 1 if parsing fails
    } catch (e) {
      print('Error getting submission count: $e');
      return 1; // Return 1 as default instead of 0
    }
  }

  // Increment submission count for a beneficiary
  static Future<int> incrementSubmissionCount(String beneficiaryId) async {
    try {
      final key = 'submission_count_$beneficiaryId';
      final currentCount = await getSubmissionCount(beneficiaryId);
      final newCount = currentCount + 1;
      await _storage.write(key: key, value: newCount.toString());
      return newCount;
    } catch (e) {
      print('Error incrementing submission count: $e');
      return 1; // Return 1 as default
    }
  }
}
