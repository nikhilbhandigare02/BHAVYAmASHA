
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
import 'package:medixcel_new/presentation/Training/TrainingHome.dart';
import 'package:medixcel_new/presentation/WorkProgress/TodayWork.dart';
import 'package:medixcel_new/presentation/myBeneficiary/myBeneficiaries.dart';
import 'package:medixcel_new/presentation/profile/Profile_screen.dart';
import 'package:medixcel_new/presentation/EligibleCouple/EligibleCoupleHome/EligibleCoupleIdentifiedScreen.dart';


import '../../../Splash_screen/Splash_screen.dart';
import '../../../presentation/ABHALink/AbhaLinkScreen.dart' show Abhalinkscreen;
import '../../../presentation/CBACForm/CBACForm.dart';
import '../../../presentation/ChildCare/ChildCareHomeScreen.dart';
import '../../../presentation/ChildCare/ChildTrackingDueList/ChildTrackingDueList.dart' show CHildTrackingDueList;
import '../../../presentation/ChildCare/HBYCList/HBYCList.dart' show HBYCList;
import '../../../presentation/ChildCare/HBYC_Child_Care_Form/HBYCChildCareForm.dart';
import '../../../presentation/ChildCare/RegisterChildBeneficieryList/RegisterChildListScreen.dart' show RegisterChildScreen;
import '../../../presentation/ChildCare/RegisterChildDueList/RegisterChildDueList.dart' show RegisterChildDueList;
import '../../../presentation/ChildCare/RegisterChildDueListForm/RegisterChildDueListForm.dart';
import '../../../presentation/EligibleCouple/EligibleCoupleHome/EligibleCoupleHomeScreen.dart' show EligibleCoupleHomeScreen;
import '../../../presentation/EligibleCouple/EligibleCoupleUpdate/EligibleCoupleUpdateScreen.dart' show EligibleCoupleUpdateScreen;
import '../../../presentation/EligibleCouple/TrackEligibleCouple/TrackEligibleCoupleScreen.dart' show TrackEligibleCoupleScreen;
import '../../../presentation/EligibleCouple/UpdtedEligibleCoupleList/UpdatedEligibleCoupleListScreen.dart' show UpdatedEligibleCoupleListScreen;
import '../../../presentation/GuestBeneficiarySearch/GuestBeneficiarySearch.dart';
import '../../../presentation/Help/HelpScreen.dart';
import '../../../presentation/HomeScreen/HomeScreen.dart';
import '../../../presentation/MotherCare/ANCVisit/PreviousVisits/PreviousVisit.dart' show Previousvisit;
import '../../../presentation/MotherCare/DeliveryOutcome/Deliver_outcome_screen.dart';
import '../../../presentation/MotherCare/HBNCScreen/HBNCList.dart' show HBNCListScreen;
import '../../../presentation/MotherCare/HBNCVisitForm/HBNCVisitScreen.dart';
import '../../../presentation/MotherCare/MotherCareHomeScreen.dart' show Mothercarehomescreen;
import '../../../presentation/MotherCare/OutcomeForm/OutcomeForm.dart';
import '../../../presentation/NCD/NCDHome.dart';
import '../../../presentation/RegisterNewHouseHold/AddFamilyHead/HeadDetails/bloc/add_family_head_bloc.dart';
import '../../../presentation/RegisterNewHouseHold/AddNewFamilyMember/bloc/addnewfamilymember_bloc.dart';
import '../../../presentation/RegisterNewHouseHold/RegisterNewHouseHold/RegisterNewHouseHold.dart';
import '../../../presentation/ResetPassword/ResetPassword.dart';
import '../../../presentation/Routine/RoutineScreen.dart' show Routinescreen;
import '../../../presentation/Training/ReceivedTraining/RecievedTraining.dart' show TrainingReceived;
import '../../../presentation/Training/Training_Form/TrainingForm.dart' show Trainingform;
import '../../../presentation/Training/Training_Provided/ProvidedTraining.dart';
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
      case Route_Names.RegisterChildScreen:
        return MaterialPageRoute(builder: (context) => RegisterChildScreen(),);
      case Route_Names.RegisterChildDueList:
        return MaterialPageRoute(builder: (context) => RegisterChildDueList(),);
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
      case Route_Names.TrainingHomeScreen:
        return MaterialPageRoute(builder: (context) => const TrainingHomeScreen(),);
      case Route_Names.Routinescreen:
        return MaterialPageRoute(builder: (context) => const Routinescreen(),);
      case Route_Names.Trainingform:
        return MaterialPageRoute(builder: (context) => const Trainingform(),);
      case Route_Names.HelpScreen:
        return MaterialPageRoute(builder: (context) => const HelpScreen(),);
      case Route_Names.NCDHome:
        return MaterialPageRoute(builder: (context) => const NCDHome(),);
      case Route_Names.TrackEligibleCoupleScreen:
        return MaterialPageRoute(builder: (context) => const TrackEligibleCoupleScreen(),);
      case Route_Names.cbacScreen:
        return MaterialPageRoute(builder: (context) => const Cbacform(),);
      case Route_Names.Abhalinkscreen:
        return MaterialPageRoute(builder: (context) => const Abhalinkscreen(),);
      case Route_Names.TrainingReceived:
        return MaterialPageRoute(builder: (context) => const TrainingReceived(),);
      case Route_Names.TrainingProvided:
        return MaterialPageRoute(builder: (context) => const TrainingProvided(),);
      case Route_Names.DeliveryOutcomeScreen:
        return MaterialPageRoute(builder: (context) => const DeliveryOutcomeScreen(),);
      case Route_Names.OutcomeFormScreen:
        return MaterialPageRoute(builder: (context) => const OutcomeFormPage(),);
      case Route_Names.HBNCScreen:
        return MaterialPageRoute(builder: (context) => const HBNCListScreen(),);
      case Route_Names.HbncVisitFormScreen:
        return MaterialPageRoute(builder: (context) => const HbncVisitScreen(),);
      case Route_Names.CHildTrackingDueList:
        return MaterialPageRoute(builder: (context) => const CHildTrackingDueList(),);
      case Route_Names.HBYCList:
        return MaterialPageRoute(builder: (context) => const HBYCList(),);
      case Route_Names.HBYCChildCareForm:
        return MaterialPageRoute(builder: (context) => const HBYCChildCareFormScreen(),);
      case Route_Names.RegisterChildDueListFormScreen:
        return MaterialPageRoute(builder: (context) => const RegisterChildDueListFormScreen(),);
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