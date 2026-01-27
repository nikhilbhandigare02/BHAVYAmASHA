import 'dart:math';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:medixcel_new/core/utils/device_info_utils.dart';

class IdGenerator {
  static int _counter = 0;
  static DateTime? _lastTimestamp;
  
  /// Generates a unique ID in the format: {device_id}_{milliseconds}{year}{month}{day}{second}{microseconds}{counter}
  /// Example: 0e21f7cd9f8279ea_123202511100530123456001
  /// Format breakdown:
  /// - milliseconds (3 digits)
  /// - year (4 digits)
  /// - month (2 digits)
  /// - day (2 digits)
  /// - second (2 digits)
  /// - microseconds (6 digits)
  /// - counter (3 digits) - increments for IDs generated in the same microsecond
 /* static Future<String> generateUniqueId(DeviceInfo deviceInfo) async {
    final now = DateTime.now();
    
    // Reset counter if timestamp changed
    if (_lastTimestamp == null || 
        now.microsecondsSinceEpoch != _lastTimestamp!.microsecondsSinceEpoch) {
      _counter = 0;
      _lastTimestamp = now;
    } else {
      _counter++;
    }
    
    // Get milliseconds (last 3 digits of millisecondsSinceEpoch)
    final milliseconds = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    
    // Get microseconds (last 6 digits)
    final microseconds = (now.microsecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    
    // Format: milliseconds(3) + year(4) + month(2) + day(2) + second(2) + microseconds(6) + counter(3)
    final formattedDate = '$milliseconds'
        '${now.year.toString()}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}'
        '$microseconds'
        '${_counter.toString().padLeft(3, '0')}';
        
    return '${deviceInfo.deviceId}_$formattedDate';
  }
}*/

  static Future<String> generateUniqueId(DeviceInfo deviceInfo) async {

    try{
      // Add 1-second delay to ensure unique timestamps for sequential calls
      await Future.delayed(Duration(seconds: 1));
      
      final DateTime now = DateTime.now();
      String deviceId = await _getAndroidId();
      final String formattedDate =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString ().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      return '${deviceId}_$formattedDate';
    }
    catch(e){
      return '';
    }
  }

  /// Gets the Android ID using Settings.Secure.ANDROID_ID
  static Future<String> _getAndroidId() async {
    try {
      if (Platform.isAndroid) {
        print('=== Attempting to get Android ID via MethodChannel ===');
        
        // Use the proper method to get Android ID from Settings.Secure
        const MethodChannel channel = MethodChannel('medixcel/device_id');
        
        try {
          final String? deviceId = await channel.invokeMethod<String>('getAndroidId');
          
          print('MethodChannel result: $deviceId');
          
          if (deviceId != null && deviceId.isNotEmpty && deviceId != 'Unknown' && !deviceId.startsWith('Error:')) {
            // Debug logging
            print('=== IdGenerator Android Info ===');
            print('Proper Android ID: $deviceId');
            print('Android ID length: ${deviceId.length}');
            print('Is Android ID empty: ${deviceId.isEmpty}');
            print('===============================');
            return deviceId;
          } else {
            print('MethodChannel returned invalid result: $deviceId');
          }
        } catch (e) {
          print('MethodChannel failed: $e');
        }
        
        // Fallback to device_info_plus
        print('=== Falling back to device_info_plus ===');
        final deviceInfoPlugin = DeviceInfoPlugin();
        final androidInfo = await deviceInfoPlugin.androidInfo;
        final fallbackId = androidInfo.id;
        
        print('=== IdGenerator Fallback Info ===');
        print('Fallback Android ID: $fallbackId');
        print('Fallback ID length: ${fallbackId.length}');
        print('===============================');
        
        return fallbackId;
      } else {
        // For non-Android platforms, return a fallback ID
        return 'non_android_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      // Fallback if Android ID cannot be retrieved
      print('Error getting Android ID: $e');
      return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

}
