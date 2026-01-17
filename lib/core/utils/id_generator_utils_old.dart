import 'dart:math';
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
  static Future<String> generateUniqueId(DeviceInfo deviceInfo) async {
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
}
