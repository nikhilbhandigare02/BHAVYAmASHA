
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medixcel_new/presentation/Abha_Generation/ABHA_Generationscreen.dart';
import 'package:medixcel_new/presentation/AboutUs/AboutUs.dart';
import 'package:medixcel_new/presentation/AllBeneficiary/AllBeneficiary.dart';
import 'package:medixcel_new/presentation/AllHouseHold/AllHouseHold/AllHouseHold_Screen.dart';
import 'package:medixcel_new/presentation/AllHouseHold/HouseHole_Beneficiery/HouseHold_Beneficiery.dart';
import 'package:medixcel_new/presentation/Annoucement/Annoucement_scree.dart';
import 'package:medixcel_new/presentation/Incentive_portal/IncentivePortal.dart';
import 'package:medixcel_new/presentation/MISReport/MISReport.dart';
import 'package:medixcel_new/presentation/MotherCare/ANCVisit/ANCVisitForm/ANCVisitForm.dart';
import 'package:medixcel_new/presentation/MotherCare/ANCVisit/ANVVisitList/ANCVisitListScreen.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/AddNewFamilyHead.dart';
import 'package:medixcel_new/presentation/RegisterNewHouseHold/AddNewFamilyMember/AddNewFamilyMember.dart';
import 'package:medixcel_new/presentation/Setting/Setting.dart';
import 'package:medixcel_new/presentation/WorkProgress/TodayWork.dart';
import 'package:medixcel_new/presentation/myBeneficiary/myBeneficiaries.dart';
import 'package:medixcel_new/presentation/profile/Profile_screen.dart';
import 'package:medixcel_new/presentation/EligibleCouple/EligibleCoupleHome/EligibleCoupleIdentifiedScreen.dart';


import '../../../Splash_screen/Splash_screen.dart';
import '../../../presentation/ChildCare/ChildCareHomeScreen.dart';
import '../../../presentation/EligibleCouple/EligibleCoupleHome/EligibleCoupleHomeScreen.dart' show EligibleCoupleHomeScreen;
import '../../../presentation/EligibleCouple/EligibleCoupleUpdate/EligibleCoupleUpdateScreen.dart' show EligibleCoupleUpdateScreen;
import '../../../presentation/EligibleCouple/UpdtedEligibleCoupleList/UpdatedEligibleCoupleListScreen.dart' show UpdatedEligibleCoupleListScreen;
import '../../../presentation/GuestBeneficiarySearch/GuestBeneficiarySearch.dart';
import '../../../presentation/HomeScreen/HomeScreen.dart';
import '../../../presentation/MotherCare/ANCVisit/PreviousVisits/PreviousVisit.dart' show Previousvisit;
import '../../../presentation/MotherCare/MotherCareHomeScreen.dart' show Mothercarehomescreen;
import '../../../presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/bloc/add_family_head_bloc.dart';
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
      case Route_Names.ABHAGeneration:
        return MaterialPageRoute(builder: (context) => AbhaGenerationscreen(),);
      case Route_Names.WorkProgress:
        return MaterialPageRoute(builder: (context) => Todaywork(),);
      case Route_Names.Annoucement:
        return MaterialPageRoute(builder: (context) => AnnoucementScree(),);
      case Route_Names.EligibleCoupleIdentified:
        return MaterialPageRoute(builder: (context) => const EligibleCoupleIdentifiedScreen(),);
      case Route_Names.UpdatedEligibleCoupleList:
        return MaterialPageRoute(builder: (context) => const EligibleCoupleUpdateScreen(),);
      case Route_Names.EligibleCoupleHomeScreen:
        return MaterialPageRoute(builder: (context) => const EligibleCoupleHomeScreen(),);
      case Route_Names.UpdatedEligibleCoupleScreen:
        return MaterialPageRoute(builder: (context) => const UpdatedEligibleCoupleListScreen(),);
      case Route_Names.Mothercarehomescreen:
        return MaterialPageRoute(builder: (context) => const Mothercarehomescreen(),);
      case Route_Names.Ancvisitlistscreen:
        return MaterialPageRoute(builder: (context) => const Ancvisitlistscreen(),);
      case Route_Names.Ancvisitform:
        return MaterialPageRoute(builder: (context) => const Ancvisitform(),);
      case Route_Names.Previousvisit:
        return MaterialPageRoute(builder: (context) => const Previousvisit(),);
      case Route_Names.ChildCareHomeScreen:
        return MaterialPageRoute(builder: (context) => const ChildCareHomeScreen(),);
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