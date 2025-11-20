import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:intl/intl.dart';
import 'package:medixcel_new/core/config/themes/CustomColors.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

class Utils {

  static showToastMessage(String message,
      {Toast toastLength = Toast.LENGTH_SHORT}) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: message,
        toastLength: toastLength,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        textColor: Colors.white,
        backgroundColor: Colors.black,
        fontSize: 16.0);
  }

  static Future<bool> isConnected() async {
    try {
      List<InternetAddress> result = await InternetAddress.lookup('google.com') /*.timeout(Duration(seconds: 5))*/;

      //
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      //
      else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  // 🔹 Helper method to show dialog
  static void onLoading(BuildContext context, {String message = "Loading..."}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SmallDotLoader(message: message),
    );
  }
  /*static void onLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: EdgeInsets.all(15),
            child: new Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                new CircularProgressIndicator(),
                SizedBox(
                  width: 10,
                ),
                new Text("Loading"),
              ],
            ),
          ),
        );
      },
    );
  }*/

  static Future<String> selectDate(BuildContext context) async {
    var date = '';
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (pickedDate != null) {
      date = DateFormat('dd-MM-yyyy').format(pickedDate);
    }
    return date;
  }

  static int calculateAge(String dateString) {
    // Define the date format (dd/MM/yyyy)
    DateFormat dateFormat = DateFormat('dd-MM-yyyy');

    // Parse the dateString to DateTime
    DateTime birthDate = dateFormat.parse(dateString);

    // Get the current date
    DateTime currentDate = DateTime.now();

    // Calculate the difference in years
    int age = currentDate.year - birthDate.year;

    // Adjust age if the current date hasn't passed the birthday yet this year
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  static String convertDateFormat(String dateString) {
    // Parse the original date string (yyyy-mm-dd)
    DateTime parsedDate = DateTime.parse(dateString);

    // Format it to dd-mm-yyyy
    String formattedDate = DateFormat('dd-MM-yyyy').format(parsedDate);

    return formattedDate;
  }

  // Regular expression for email validation
  static bool isValidEmail(String input) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(input);
  }

  // Regular expression for mobile phone validation (basic example for 10 digits)
  static bool isValidPhone(String input) {
    String pattern =
        r'^[0-9]{10}$'; // You can adjust this pattern for different formats
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(input);
  }

  // Convert a full name (or any string) to camelCase
  static String toCamelCase(String name) {
    List<String> words =
        name.split(RegExp(r'[\s_]+')); // Split by spaces or underscores

    // Convert the first word to lowercase, and the rest to capitalized
    for (int i = 0; i < words.length; i++) {
      if (words[i].trim().isNotEmpty) {
        words[i] = words[i].capitalize();
      }
    }

    // Join all words back together without spaces
    return words.join(' ');
  }

  static Widget base64ToImage(String base64String) {
    try {
      var bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: 150.0,
        height: 150.0,
        fit: BoxFit.cover,
      );
    } catch (e) {
      print('error in view UPI QR Code : $e');
      return Container(); //Image.asset('assets/img/qr_code.png');
    }
  }

  static Future<void> requestMediaPermissions() async {
    try {
      var statuses = await [
        Permission.storage, // For older Android versions
        Permission.photos, // For media storage access
        Permission.videos,
      ].request();

      if (statuses.values.any((status) => status.isDenied)) {
        throw "Media permission is required to save the file.";
      }

      print("Permissions granted.");
    } catch (e) {
      print("Permission error: $e");
    }
  }

  static Future<String> saveImageToDownloads(String base64, String filename) async {
    List<int> imageBytes = base64Decode(base64);

    Directory downloadsDirectory = Directory('/storage/emulated/0/Download');
    if (!downloadsDirectory.existsSync()) {
      throw "Cannot access Downloads directory.";
    }

    File file = File('${downloadsDirectory.path}/$filename');
    await file.writeAsBytes(imageBytes);

    Utils.showToastMessage("Image downloaded successfully at ${file.path}");
    return file.path; // return the path
  }


  static Future<Directory?> getDownloadDirectory() async {
    try {
      Directory? externalDir;

      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // For all versions: request standard storage permission (only needed for < API 33)
        if (sdkInt < 33) {
          final status = await Permission.storage.request();
          if (status != PermissionStatus.granted) {
            throw Exception('Storage permission not granted');
          }
        }

        // Use app-specific external storage directory
        externalDir = await getExternalStorageDirectory();

        // Optional: Create a custom subdirectory inside app-scoped storage
        if (externalDir != null) {
          final customDir = Directory('${externalDir.path}/MyAppDownloads');
          if (!await customDir.exists()) {
            await customDir.create(recursive: true);
          }
          externalDir = customDir;
        }
      }

      return externalDir;
    } catch (e) {}
  }

  static String generateAbhaTokenUAT() {
    // Define your keys and values

   /* //UAT
    const secretKey = '0e8289d92d75ffb63420210d0f0301ae5f520bec5d26d1dcc29a79ad4c244f14';
    const clientId = '69e40e8ad5a3452a6937';*/

    //UAT
    const secretKey = '81592b837ab12ca0563c66cf4e13517f713391249ab971e2070df0546a14d094';
    const clientId = 'f3e913668614c6b57c2f';

    const clinicId = 10; // Replace with actual clinic ID or keep as zero
    const userId = 0; // Replace with actual staff ID if needed

    // Generate a random integer for the jti
    final jti = Random().nextInt(4294967296); // Max value for jti

    // Define the payload
    final payload = {
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000, // Current time in seconds
      'clinic_id': clinicId,
      'client_id': clientId,
      'user_id': userId,
      'jti': jti,
    };

    // Create the JWT
    final jwt = JWT(payload);

    // Sign the JWT with HS256 algorithm using the secret key
    final token = jwt.sign(SecretKey(secretKey), algorithm: JWTAlgorithm.HS256);


    // Print the token
    print('JWT: $token');
    return token;
  }

  static Future<bool> willPopCallback(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Do you want to exit this application?',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp),
        ),
        //content: Text('We hate to see you leave...'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              print("you choose no");
              Navigator.of(context).pop(false);
            },
            child: Text(
              'No',
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              //SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            },
            child: Text(
              'Yes',
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }

  void showBeautifulDialog(
      BuildContext context, {
        required String title,
        required String message,
        String okText = 'OK',
        VoidCallback? onOk,
      }) {
    showGeneralDialog(
      context: context,
      barrierLabel: "Dialog",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        // The actual widget is built in transitionBuilder; return empty here.
        return SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return Opacity(
          opacity: animation.value,
          child: Transform.scale(
            scale: curved.value,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 28.0),
                  padding: EdgeInsets.only(top: 18, left: 18, right: 18, bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon badge
                        /* Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),*/
                        SizedBox(height: 12),
                        //
                        // Title
                        if(title.isNotEmpty)
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        SizedBox(height: 8),
                        // Message
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            //color: Theme.of(context).textTheme.bodyText2?.color?.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 20),
                        // OK button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (onOk != null) onOk();
                            },
                            child: Text(
                              okText,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  /// Helper if you just need Lat/Lng as a map

  static Future<Map<String, dynamic>?> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        Map<String, dynamic> deviceData = {
          "manufacturer": androidInfo.manufacturer ?? "",
          "model": androidInfo.model ?? "",
          "id": androidInfo.id ?? "",
          "brand": androidInfo.brand ?? "",
          "name": androidInfo.device ?? "",
          "device": androidInfo.device ?? "",
        };

        deviceData.removeWhere((key, value) => value == null || value.toString().isEmpty);
        return deviceData;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

        Map<String, dynamic> deviceData = {
          "manufacturer": "Apple",
          "model": iosInfo.utsname.machine ?? "",
          "id": iosInfo.identifierForVendor ?? "",
          "brand": "Apple",
          "name": iosInfo.name ?? "",
          "device": iosInfo.model ?? "",
        };

        deviceData.removeWhere((key, value) => value == null || value.toString().isEmpty);
        return deviceData;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching device info: $e");
      return null;
    }
  }


  /*static Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        String? deviceId = androidInfo.id;
        print("Device ID: $deviceId");
        return deviceId;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        String? deviceId = iosInfo.identifierForVendor;
        print("Device ID: $deviceId");
        return deviceId;
      } else {
        print("Unsupported platform for device ID");
        return null;
      }
    } catch (e) {
      print("Error fetching device ID: $e");
      //CustomToast.show("Failed to fetch device ID.");
      return null;
    }
  }*/

  static Widget buildButtonCurve({
    required String text,
    VoidCallback? onPressed,
    IconData? prefixIcon,
    Color? color,
    Color? textColor,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // large enough for circular edges
        ),
        padding: padding,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, size: 18, color: textColor ?? Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(color: textColor ?? Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }


}

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
// 🌟 Small Horizontal Dot Loader
class SmallDotLoader extends StatefulWidget {
  final String message;

  const SmallDotLoader({Key? key, this.message = "Loading..."})
      : super(key: key);

  @override
  _SmallDotLoaderState createState() => _SmallDotLoaderState();
}

class _SmallDotLoaderState extends State<SmallDotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(double offset, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        double translateY = sin((_controller.value + offset) * 2 * pi) * 6;
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🌟 Small horizontal animated dots
            _dot(0, primary),
            _dot(0.2, primary),
            _dot(0.4, primary),
            _dot(0.6, primary),
            _dot(0.8, primary),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                widget.message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
