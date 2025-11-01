import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  static Future<String> getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return 'v${packageInfo.version}';
    } catch (e) {
      // Return a default version if there's an error
      return 'v1.0.0';
    }
  }
}
