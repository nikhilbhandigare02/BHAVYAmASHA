import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:medixcel_new/core/utils/app_info_utils.dart';

class DeviceInfo {
  final String deviceId;
  final String osVersion;
  final String platform;
  final AppInfo appInfo;

  DeviceInfo({
    required this.deviceId,
    required this.osVersion,
    required this.platform,
    required this.appInfo,
  });

  factory DeviceInfo.fromPackageInfo(PackageInfo packageInfo) {
    String platform = 'unknown';
    String osVersion = 'unknown';
    String deviceId = DateTime.now().millisecondsSinceEpoch.toString();

    if (Platform.isAndroid) {
      platform = 'Android';
      osVersion = Platform.operatingSystemVersion;
    } else if (Platform.isIOS) {
      platform = 'iOS';
      osVersion = Platform.operatingSystemVersion;
    } else if (Platform.isWindows) {
      platform = 'Windows';
      osVersion = Platform.operatingSystemVersion;
    }

    return DeviceInfo(
      deviceId: deviceId,
      osVersion: osVersion,
      platform: platform,
      appInfo: AppInfo.fromPackageInfo(packageInfo),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'os_version': osVersion,
      'platform': platform,
      ...appInfo.toJson(),
    };
  }

  static Future<DeviceInfo> getDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return DeviceInfo.fromPackageInfo(packageInfo);
  }
  
  // Convenience getters for backward compatibility
  String get appVersion => appInfo.appVersion;
  String get appName => appInfo.appName;
  String get buildNumber => appInfo.buildNumber;
  String get packageName => appInfo.packageName;
}
