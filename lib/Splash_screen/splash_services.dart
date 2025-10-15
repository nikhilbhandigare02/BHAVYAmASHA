import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/config/routes/Route_Name.dart';

class SplashServices {
  void isLogin(BuildContext context) {
    Timer(
      Duration(seconds: 3),
      () => Navigator.pushNamedAndRemoveUntil(
        context,
        Route_Names.loginScreen,
        (route) => false,
      ),
    );
  }
}
