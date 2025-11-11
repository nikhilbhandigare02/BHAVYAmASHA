import 'dart:math';
import 'package:medixcel_new/core/utils/device_info_utils.dart';

class IdGenerator {

  static Future<String> generateUniqueId(DeviceInfo deviceInfo) async {
    final random = Random();
    final now = DateTime.now();

    final milliseconds = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');

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
