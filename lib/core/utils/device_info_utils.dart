import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:medixcel_new/core/utils/app_info_utils.dart';

class DeviceInfo {
  final String deviceId;
  final String osVersion;
  final String platform;
  final String? model; // e.g. "Redmi Note 12"
  final AppInfo appInfo;

  DeviceInfo({
    required this.deviceId,
    required this.osVersion,
    required this.platform,
    this.model,
    required this.appInfo,
  });

  factory DeviceInfo.fromPackageInfo(
      PackageInfo packageInfo,
      String model,
      String osVersion,
      String platform,
      ) {
    String deviceId = DateTime.now().millisecondsSinceEpoch.toString();

    return DeviceInfo(
      deviceId: deviceId,
      osVersion: osVersion,
      platform: platform,
      model: model,
      appInfo: AppInfo.fromPackageInfo(packageInfo),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'os_version': osVersion,
      'platform': platform,
      'model': model,
      ...appInfo.toJson(),
    };
  }

  static Future<DeviceInfo> getDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfoPlugin = DeviceInfoPlugin();

    String platform = 'unknown';
    String osVersion = 'unknown';
    String model = 'unknown';

    if (Platform.isAndroid) {
      final android = await deviceInfoPlugin.androidInfo;
      platform = 'Android';
      osVersion = android.version.release ?? 'unknown';
      final manufacturer = android.manufacturer ?? '';
      final deviceModel = android.model ?? '';
      model = _formatModelName(manufacturer, deviceModel);
    } else if (Platform.isIOS) {
      final ios = await deviceInfoPlugin.iosInfo;
      platform = 'iOS';
      osVersion = ios.systemVersion ?? 'unknown';
      model = ios.name ?? 'iPhone';
    } else if (Platform.isWindows) {
      final windows = await deviceInfoPlugin.windowsInfo;
      platform = 'Windows';
      osVersion = windows.displayVersion ?? 'unknown';
      model = windows.computerName;
    } else if (Platform.isMacOS) {
      final mac = await deviceInfoPlugin.macOsInfo;
      platform = 'macOS';
      osVersion = mac.osRelease;
      model = mac.model;
    } else if (Platform.isLinux) {
      final linux = await deviceInfoPlugin.linuxInfo;
      platform = 'Linux';
      osVersion = linux.version ?? 'unknown';
      model = linux.prettyName ?? 'Linux';
    }

    return DeviceInfo.fromPackageInfo(packageInfo, model, osVersion, platform);
  }

  static String _formatModelName(String manufacturer, String model) {
    if (model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
      return _capitalize(model);
    } else {
      return '${_capitalize(manufacturer)} ${_capitalize(model)}';
    }
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Convenience getters
  String get appVersion => appInfo.appVersion;
  String get appName => appInfo.appName;
  String get buildNumber => appInfo.buildNumber;
  String get packageName => appInfo.packageName;
}
