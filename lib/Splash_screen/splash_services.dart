import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../core/config/routes/Route_Name.dart';
import '../data/SecureStorage/SecureStorage.dart';

class SplashServices {
  Future<void> isLogin(BuildContext context) async {
    final loginFlag = await SecureStorageService.getLoginFlag();
    
    Timer(
      const Duration(seconds: 3),
      () => Navigator.pushNamedAndRemoveUntil(
        context,
         loginFlag == 1 ? Route_Names.homeScreen : Route_Names.loginScreen,
          // Route_Names.homeScreen,
        (route) => false,
      ),
    );
  }
}
