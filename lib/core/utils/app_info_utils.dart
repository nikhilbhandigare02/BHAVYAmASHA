import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  final String appVersion;
  final String appName;
  final String buildNumber;
  final String packageName;

  AppInfo({
    required this.appVersion,
    required this.appName,
    required this.buildNumber,
    required this.packageName,
  });

  factory AppInfo.fromPackageInfo(PackageInfo packageInfo) {
    return AppInfo(
      appVersion: packageInfo.version,
      appName: packageInfo.appName,
      buildNumber: packageInfo.buildNumber,
      packageName: packageInfo.packageName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app_version': appVersion.split('+').first,
      'app_name': appName,
      'build_number': buildNumber,
      'package_name': packageName,
    };
  }

  static Future<AppInfo> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppInfo.fromPackageInfo(packageInfo);
  }
}
