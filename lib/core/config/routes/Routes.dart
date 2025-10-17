
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/presentation/AboutUs/AboutUs.dart';
import 'package:medixcel_new/presentation/AllBeneficiary/AllBeneficiary.dart';
import 'package:medixcel_new/presentation/AllHouseHold/AllHouseHold/AllHouseHold_Screen.dart';
import 'package:medixcel_new/presentation/AllHouseHold/HouseHole_Beneficiery/HouseHold_Beneficiery.dart';
import 'package:medixcel_new/presentation/Incentive_portal/IncentivePortal.dart';
import 'package:medixcel_new/presentation/MISReport/MISReport.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/AddNewFamilyHead.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddNewFamilyMember/AddNewFamilyMember.dart';
import 'package:medixcel_new/presentation/Setting/Setting.dart';
import 'package:medixcel_new/presentation/myBeneficiary/myBeneficiaries.dart';
import 'package:medixcel_new/presentation/profile/Profile_screen.dart';


import '../../../Splash_screen/Splash_screen.dart';
import '../../../presentation/GuestBeneficiarySearch/GuestBeneficiarySearch.dart';
import '../../../presentation/HomeScreen/HomeScreen.dart';
import '../../../presentation/RegisterNewHouseHold/AddFamilyHead/bloc/add_family_head_bloc.dart';
import '../../../presentation/RegisterNewHouseHold/AddNewFamilyMember/bloc/addnewfamilymember_bloc.dart';
import '../../../presentation/RegisterNewHouseHold/RegisterNewHouseHold/RegisterNewHouseHold.dart';
import '../../../presentation/ResetPassword/ResetPassword.dart';
import '../../../presentation/login/Login_Screen.dart';
import 'Route_Name.dart' show Route_Names;

class Routes{
  static Route<dynamic> generateRoute(RouteSettings setting){
    switch (setting.name){
      case Route_Names.splashScreen:
        return MaterialPageRoute(builder: (context) => SplashScreen(),);
      case Route_Names.loginScreen:
        return MaterialPageRoute(builder: (context) => LoginScreen(),);
      case Route_Names.homeScreen:
        return MaterialPageRoute(builder: (context) => HomeScreen(),);
      case Route_Names.profileScreen:
        return MaterialPageRoute(builder: (context) => ProfileScreen(),);
      case Route_Names.MISScreen:
        return MaterialPageRoute(builder: (context) => Misreport(),);
      case Route_Names.Resetpassword:
        return MaterialPageRoute(builder: (context) => Resetpassword(),);
      case Route_Names.setting:
        return MaterialPageRoute(builder: (context) => Setting(),);
      case Route_Names.aboutUs:
        return MaterialPageRoute(builder: (context) => Aboutus(),);
      case Route_Names.incentivePortal:
        return MaterialPageRoute(builder: (context) => IncentivePortal(),);
      case Route_Names.GuestBeneficiarySearch:
        return MaterialPageRoute(builder: (context) => GuestBeneficiarySearch(),);
      case Route_Names.RegisterNewHousehold:
        return MaterialPageRoute(builder: (context) => RegisterNewHouseHoldScreen(),);
      case Route_Names.AllHousehold:
        return MaterialPageRoute(builder: (context) => AllhouseholdScreen(),);
      case Route_Names.houseHoldBeneficiaryScreen:
        return MaterialPageRoute(builder: (context) => HouseHold_BeneficiaryScreen(),);
      case Route_Names.AllBeneficiaryScreen:
        return MaterialPageRoute(builder: (context) => AllBeneficiaryScreen(),);
      case Route_Names.Mybeneficiaries:
        return MaterialPageRoute(builder: (context) => Mybeneficiaries(),);
      case Route_Names.addFamilyHead:
        return MaterialPageRoute(
          settings: setting,
          builder: (_) => BlocProvider(
            create: (_) => AddFamilyHeadBloc(),
            child: const AddNewFamilyHeadScreen(),
          ),
        );
      case Route_Names.addFamilyMember:
        return MaterialPageRoute(
          settings: setting,
          builder: (_) => BlocProvider(
            create: (_) => AddnewfamilymemberBloc(),
            child: const AddNewFamilyMemberScreen(),
          ),
        );
      default :
        return MaterialPageRoute(builder: (context) {
          return Scaffold(
            body: Center(
              child: Text('No Route Found'),
            ),
          );
        },);
    }
  }
}