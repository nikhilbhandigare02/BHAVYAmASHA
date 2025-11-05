import 'dart:math';
import 'package:medixcel_new/core/utils/device_info_utils.dart';

class IdGenerator {
  /// Generates a unique ID in the format: {device_id}_{random_number}{date}{time}{random_suffix}
  /// Example: 0e21f7cd9f8279ea_88120250910171552
  static Future<String> generateUniqueId(DeviceInfo deviceInfo) async {
    final random = Random();
    final now = DateTime.now();
    
    // Get milliseconds (last 3 digits)
    final milliseconds = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    
    // Format: milliseconds(3) + day(2) + month(2) + year(2) + hour(2) + minute(2) + second(2)
    final formattedDate = '$milliseconds'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.year.toString().substring(2)}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
        
    return '${deviceInfo.deviceId}_$formattedDate';
  }
}
