import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Medixcel'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'BHAVYA mASHA Home'**
  String get homeTitle;

  /// No description provided for @tabTodaysProgram.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PROGRAM'**
  String get tabTodaysProgram;

  /// No description provided for @tabAshaDashboard.
  ///
  /// In en, this message translates to:
  /// **'ASHA DASHBOARD'**
  String get tabAshaDashboard;

  /// No description provided for @gridRegisterNewHousehold.
  ///
  /// In en, this message translates to:
  /// **'Register New Household'**
  String get gridRegisterNewHousehold;

  /// No description provided for @gridAllHousehold.
  ///
  /// In en, this message translates to:
  /// **'All Household'**
  String get gridAllHousehold;

  /// No description provided for @gridAllBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'All Beneficiaries'**
  String get gridAllBeneficiaries;

  /// No description provided for @gridMyBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'My Beneficiaries'**
  String get gridMyBeneficiaries;

  /// No description provided for @gridAbhaGeneration.
  ///
  /// In en, this message translates to:
  /// **'Abha Generation'**
  String get gridAbhaGeneration;

  /// No description provided for @gridWorkProgress.
  ///
  /// In en, this message translates to:
  /// **'Work Progress'**
  String get gridWorkProgress;

  /// No description provided for @gridEligibleCouple.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple'**
  String get gridEligibleCouple;

  /// No description provided for @gridMotherCare.
  ///
  /// In en, this message translates to:
  /// **'Mother Care'**
  String get gridMotherCare;

  /// No description provided for @gridChildCare.
  ///
  /// In en, this message translates to:
  /// **'Child Care'**
  String get gridChildCare;

  /// No description provided for @gridHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High-Risk'**
  String get gridHighRisk;

  /// No description provided for @gridAshaKiDuniya.
  ///
  /// In en, this message translates to:
  /// **'Asha ki Duniya'**
  String get gridAshaKiDuniya;

  /// No description provided for @gridTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get gridTraining;

  /// No description provided for @toDoVisits.
  ///
  /// In en, this message translates to:
  /// **'To do visits'**
  String get toDoVisits;

  /// No description provided for @completedVisits.
  ///
  /// In en, this message translates to:
  /// **'Completed visits'**
  String get completedVisits;

  /// No description provided for @listFamilySurvey.
  ///
  /// In en, this message translates to:
  /// **'Family Survey List'**
  String get listFamilySurvey;

  /// No description provided for @listEligibleCoupleDue.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple Due List'**
  String get listEligibleCoupleDue;

  /// No description provided for @listANC.
  ///
  /// In en, this message translates to:
  /// **'ANC List'**
  String get listANC;

  /// No description provided for @listHBNC.
  ///
  /// In en, this message translates to:
  /// **'HBNC List'**
  String get listHBNC;

  /// No description provided for @listRoutineImmunization.
  ///
  /// In en, this message translates to:
  /// **'Routine Immunization (RI)'**
  String get listRoutineImmunization;

  /// No description provided for @routine.
  ///
  /// In en, this message translates to:
  /// **'Routine Immunization (RI)'**
  String get routine;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @ncd.
  ///
  /// In en, this message translates to:
  /// **'NCD'**
  String get ncd;

  /// No description provided for @trainingTitle.
  ///
  /// In en, this message translates to:
  /// **'BHAVYA mASHA Training'**
  String get trainingTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Login to continue'**
  String get loginToContinue;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Username'**
  String get usernameHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'LogIn'**
  String get loginButton;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered By Medixcel Lite © 2025'**
  String get poweredBy;

  /// No description provided for @ashaProfile.
  ///
  /// In en, this message translates to:
  /// **'ASHA Profile'**
  String get ashaProfile;

  /// No description provided for @areaOfWorking.
  ///
  /// In en, this message translates to:
  /// **'Area of working'**
  String get areaOfWorking;

  /// No description provided for @selectArea.
  ///
  /// In en, this message translates to:
  /// **'Select area'**
  String get selectArea;

  /// No description provided for @ashaIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ASHA ID'**
  String get ashaIdLabel;

  /// No description provided for @ashaIdHint.
  ///
  /// In en, this message translates to:
  /// **'A10000555'**
  String get ashaIdHint;

  /// No description provided for @ashaNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA'**
  String get ashaNameLabel;

  /// No description provided for @ashaNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA'**
  String get ashaNameHint;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dobLabel;

  /// No description provided for @dateHint.
  ///
  /// In en, this message translates to:
  /// **'dd-mm-yyyy'**
  String get dateHint;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @yearsSuffix.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get yearsSuffix;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get mobileLabel;

  /// No description provided for @mobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get mobileHint;

  /// No description provided for @altMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Alternate mobile no.'**
  String get altMobileLabel;

  /// No description provided for @altMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Alternate mobile no.'**
  String get altMobileHint;

  /// No description provided for @fatherSpouseLabel.
  ///
  /// In en, this message translates to:
  /// **'Father/Spouse Name'**
  String get fatherSpouseLabel;

  /// No description provided for @fatherSpouseHint.
  ///
  /// In en, this message translates to:
  /// **'Father/Spouse Name'**
  String get fatherSpouseHint;

  /// No description provided for @dojLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Joining'**
  String get dojLabel;

  /// No description provided for @bankDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank details'**
  String get bankDetailsTitle;

  /// No description provided for @accountNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountNumberLabel;

  /// No description provided for @accountNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountNumberHint;

  /// No description provided for @ifscLabel.
  ///
  /// In en, this message translates to:
  /// **'IFSC code'**
  String get ifscLabel;

  /// No description provided for @ifscHint.
  ///
  /// In en, this message translates to:
  /// **'IFSC code'**
  String get ifscHint;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// No description provided for @stateHint.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateHint;

  /// No description provided for @divisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get divisionLabel;

  /// No description provided for @divisionHint.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get divisionHint;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @districtHint.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtHint;

  /// No description provided for @blockLabel.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockLabel;

  /// No description provided for @blockHint.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockHint;

  /// No description provided for @panchayatLabel.
  ///
  /// In en, this message translates to:
  /// **'Panchayat'**
  String get panchayatLabel;

  /// No description provided for @panchayatHint.
  ///
  /// In en, this message translates to:
  /// **'Panchayat'**
  String get panchayatHint;

  /// No description provided for @villageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get villageLabel;

  /// No description provided for @villageHint.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get villageHint;

  /// No description provided for @tolaLabel.
  ///
  /// In en, this message translates to:
  /// **'Tola'**
  String get tolaLabel;

  /// No description provided for @tolaHint.
  ///
  /// In en, this message translates to:
  /// **'Tola'**
  String get tolaHint;

  /// No description provided for @mukhiyaNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Village mukhiya name'**
  String get mukhiyaNameLabel;

  /// No description provided for @mukhiyaNameHint.
  ///
  /// In en, this message translates to:
  /// **'Village mukhiya name'**
  String get mukhiyaNameHint;

  /// No description provided for @mukhiyaMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of mukhiya'**
  String get mukhiyaMobileLabel;

  /// No description provided for @mukhiyaMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of mukhiya'**
  String get mukhiyaMobileHint;

  /// No description provided for @hwcNameLabel.
  ///
  /// In en, this message translates to:
  /// **'HWC Name'**
  String get hwcNameLabel;

  /// No description provided for @hwcNameHint.
  ///
  /// In en, this message translates to:
  /// **'HWC Name'**
  String get hwcNameHint;

  /// No description provided for @hscNameLabel.
  ///
  /// In en, this message translates to:
  /// **'HSC Name'**
  String get hscNameLabel;

  /// No description provided for @hscNameHint.
  ///
  /// In en, this message translates to:
  /// **'HSC Name'**
  String get hscNameHint;

  /// No description provided for @fruNameLabel.
  ///
  /// In en, this message translates to:
  /// **'FRU name'**
  String get fruNameLabel;

  /// No description provided for @fruNameHint.
  ///
  /// In en, this message translates to:
  /// **'FRU name'**
  String get fruNameHint;

  /// No description provided for @phcChcLabel.
  ///
  /// In en, this message translates to:
  /// **'PHC/CHC'**
  String get phcChcLabel;

  /// No description provided for @phcChcHint.
  ///
  /// In en, this message translates to:
  /// **'PHC/CHC'**
  String get phcChcHint;

  /// No description provided for @rhSdhDhLabel.
  ///
  /// In en, this message translates to:
  /// **'RH/SDH/DH/SADAR Hospital'**
  String get rhSdhDhLabel;

  /// No description provided for @rhSdhDhHint.
  ///
  /// In en, this message translates to:
  /// **'RH/SDH/DH/SADAR Hospital'**
  String get rhSdhDhHint;

  /// No description provided for @populationCoveredLabel.
  ///
  /// In en, this message translates to:
  /// **'Population covered under ASHA'**
  String get populationCoveredLabel;

  /// No description provided for @populationCoveredHint.
  ///
  /// In en, this message translates to:
  /// **'Population covered under ASHA'**
  String get populationCoveredHint;

  /// No description provided for @ashaFacilitatorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA Facilitator'**
  String get ashaFacilitatorNameLabel;

  /// No description provided for @ashaFacilitatorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA Facilitator'**
  String get ashaFacilitatorNameHint;

  /// No description provided for @ashaFacilitatorMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ASHA Facilitator'**
  String get ashaFacilitatorMobileLabel;

  /// No description provided for @ashaFacilitatorMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ASHA Facilitator'**
  String get ashaFacilitatorMobileHint;

  /// No description provided for @choNameLabel.
  ///
  /// In en, this message translates to:
  /// **'CHO Name'**
  String get choNameLabel;

  /// No description provided for @choNameHint.
  ///
  /// In en, this message translates to:
  /// **'CHO Name'**
  String get choNameHint;

  /// No description provided for @choMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of CHO'**
  String get choMobileLabel;

  /// No description provided for @choMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of CHO'**
  String get choMobileHint;

  /// No description provided for @awwNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of AWW'**
  String get awwNameLabel;

  /// No description provided for @awwNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of AWW'**
  String get awwNameHint;

  /// No description provided for @awwMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of AWW'**
  String get awwMobileLabel;

  /// No description provided for @awwMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of AWW'**
  String get awwMobileHint;

  /// No description provided for @anganwadiCenterNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Anganwadi Center no.'**
  String get anganwadiCenterNoLabel;

  /// No description provided for @anganwadiCenterNoHint.
  ///
  /// In en, this message translates to:
  /// **'Anganwadi Center no.'**
  String get anganwadiCenterNoHint;

  /// No description provided for @anm1NameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of ANM1'**
  String get anm1NameLabel;

  /// No description provided for @anm1NameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of ANM1'**
  String get anm1NameHint;

  /// No description provided for @anm1MobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ANM1'**
  String get anm1MobileLabel;

  /// No description provided for @anm1MobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ANM1'**
  String get anm1MobileHint;

  /// No description provided for @anm2NameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of ANM2'**
  String get anm2NameLabel;

  /// No description provided for @anm2NameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of ANM2'**
  String get anm2NameHint;

  /// No description provided for @anm2MobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ANM2'**
  String get anm2MobileLabel;

  /// No description provided for @anm2MobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ANM2'**
  String get anm2MobileHint;

  /// No description provided for @bcmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Block Community Mobilizer name'**
  String get bcmNameLabel;

  /// No description provided for @bcmNameHint.
  ///
  /// In en, this message translates to:
  /// **'Block Community Mobilizer name'**
  String get bcmNameHint;

  /// No description provided for @bcmMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of Block Community Mobilizer'**
  String get bcmMobileLabel;

  /// No description provided for @bcmMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get bcmMobileHint;

  /// No description provided for @dcmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'District Community Mobilizer name'**
  String get dcmNameLabel;

  /// No description provided for @dcmNameHint.
  ///
  /// In en, this message translates to:
  /// **'District Community Mobilizer name'**
  String get dcmNameHint;

  /// No description provided for @dcmMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of District Community Mobilizer'**
  String get dcmMobileLabel;

  /// No description provided for @dcmMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get dcmMobileHint;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateButton;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @drawerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// No description provided for @drawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get drawerProfile;

  /// No description provided for @drawerMisReport.
  ///
  /// In en, this message translates to:
  /// **'MIS Report'**
  String get drawerMisReport;

  /// No description provided for @drawerIncentivePortal.
  ///
  /// In en, this message translates to:
  /// **'Incentive Portal'**
  String get drawerIncentivePortal;

  /// No description provided for @drawerFetchData.
  ///
  /// In en, this message translates to:
  /// **'Fetch Data'**
  String get drawerFetchData;

  /// No description provided for @drawerSyncedData.
  ///
  /// In en, this message translates to:
  /// **'Synced Data'**
  String get drawerSyncedData;

  /// No description provided for @drawerResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get drawerResetPassword;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerAboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get drawerAboutUs;

  /// No description provided for @drawerLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get drawerLogout;

  /// No description provided for @userNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get userNameLabel;

  /// No description provided for @userRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get userRoleLabel;

  /// No description provided for @userVillageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village:'**
  String get userVillageLabel;

  /// No description provided for @userHscLabel.
  ///
  /// In en, this message translates to:
  /// **'HSC:'**
  String get userHscLabel;

  /// No description provided for @userHfrIdLabel.
  ///
  /// In en, this message translates to:
  /// **'HFR ID:'**
  String get userHfrIdLabel;

  /// No description provided for @resetCreateNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get resetCreateNewPasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get currentPasswordHint;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get newPasswordHint;

  /// No description provided for @reenterPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Re-Enter Password'**
  String get reenterPasswordLabel;

  /// No description provided for @reenterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reenterPasswordHint;

  /// No description provided for @misMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month : '**
  String get misMonthLabel;

  /// No description provided for @misStatPregnantWomen.
  ///
  /// In en, this message translates to:
  /// **'Number of total Pregnant Women :'**
  String get misStatPregnantWomen;

  /// No description provided for @misStatNewborns.
  ///
  /// In en, this message translates to:
  /// **'Total number of newborns :'**
  String get misStatNewborns;

  /// No description provided for @misStatAbhaGenerated.
  ///
  /// In en, this message translates to:
  /// **'Total number of ABHA generated by user :'**
  String get misStatAbhaGenerated;

  /// No description provided for @misStatAbhaFetched.
  ///
  /// In en, this message translates to:
  /// **'Total number of Exisiting ABHA fetched by user :'**
  String get misStatAbhaFetched;

  /// No description provided for @monthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// No description provided for @monthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// No description provided for @monthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// No description provided for @monthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// No description provided for @monthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// No description provided for @monthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// No description provided for @monthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// No description provided for @monthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// No description provided for @monthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// No description provided for @monthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckForUpdates;

  /// No description provided for @settingsCheck.
  ///
  /// In en, this message translates to:
  /// **'CHECK'**
  String get settingsCheck;

  /// No description provided for @aboutUsP1Title.
  ///
  /// In en, this message translates to:
  /// **'ASHA (ACCREDITED SOCIAL HEALTH ACTIVIST) App, is an application to help ASHA front-line workers to do their everyday work related the population immunization, eligible couple tracking, mother and child care, and different more programs run by the health society.'**
  String get aboutUsP1Title;

  /// No description provided for @aboutUsP2.
  ///
  /// In en, this message translates to:
  /// **'The ASHA can do the family immunization, and from there, the beneficiary can be added. Once the family members get added, tracking of the eligible couple and family planning can be done. This app aims to support offline functionality for remote villages where a stable network is a challenge.'**
  String get aboutUsP2;

  /// No description provided for @aboutUsP3.
  ///
  /// In en, this message translates to:
  /// **'The ASHA can do the ABHA generation, this app has ABDM compliance for the M1 process of ABDM, and this can boost create many of the ABHA and beneficiaries going forward with the health treatments use their ABHA in any private or government facilities, when needed.'**
  String get aboutUsP3;

  /// No description provided for @aboutUsP4.
  ///
  /// In en, this message translates to:
  /// **'The app allows the ASHA workers to maintain their due lists, today’s program, and a list of upcoming PNC mother and infant details.'**
  String get aboutUsP4;

  /// No description provided for @incentiveHeaderDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get incentiveHeaderDistrict;

  /// No description provided for @incentiveHeaderBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get incentiveHeaderBlock;

  /// No description provided for @incentiveHeaderHsc.
  ///
  /// In en, this message translates to:
  /// **'HSC'**
  String get incentiveHeaderHsc;

  /// No description provided for @incentiveHeaderPanchayat.
  ///
  /// In en, this message translates to:
  /// **'Panchayat'**
  String get incentiveHeaderPanchayat;

  /// No description provided for @incentiveHeaderAnganwadi.
  ///
  /// In en, this message translates to:
  /// **'Anganwadi'**
  String get incentiveHeaderAnganwadi;

  /// No description provided for @incentiveNote.
  ///
  /// In en, this message translates to:
  /// **'Submit the payment file for each month\'s claim amount between the 28th and 30th of the next month.'**
  String get incentiveNote;

  /// No description provided for @incentiveFinancialYear.
  ///
  /// In en, this message translates to:
  /// **'Financial year'**
  String get incentiveFinancialYear;

  /// No description provided for @incentiveFinancialMonth.
  ///
  /// In en, this message translates to:
  /// **'Financial month'**
  String get incentiveFinancialMonth;

  /// No description provided for @incentiveTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount (Daily + Monthly): ₹{amount}'**
  String incentiveTotalAmount(Object amount);

  /// No description provided for @incentiveTabDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily tasks'**
  String get incentiveTabDaily;

  /// No description provided for @incentiveTabMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly tasks'**
  String get incentiveTabMonthly;

  /// No description provided for @incentiveTabFinalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get incentiveTabFinalize;

  /// No description provided for @monthlySectionStateContribution.
  ///
  /// In en, this message translates to:
  /// **'State Contribution'**
  String get monthlySectionStateContribution;

  /// No description provided for @monthlySectionRoutineRecurring.
  ///
  /// In en, this message translates to:
  /// **'Routine & Recurring'**
  String get monthlySectionRoutineRecurring;

  /// No description provided for @monthlyTaskPC11.
  ///
  /// In en, this message translates to:
  /// **'PC1.1 - At the beginning of the year, create household records and review them every month'**
  String get monthlyTaskPC11;

  /// No description provided for @monthlyTaskPC110.
  ///
  /// In en, this message translates to:
  /// **'PC1.10 - 6 and up to 35 beneficiaries'**
  String get monthlyTaskPC110;

  /// No description provided for @monthlyTaskPC21.
  ///
  /// In en, this message translates to:
  /// **'PC2.1 - Immunization: From the Due List, ensure 90% of registered children get full immunization'**
  String get monthlyTaskPC21;

  /// No description provided for @monthlyTaskPC23.
  ///
  /// In en, this message translates to:
  /// **'PC2.3 - Maternal Health: Line listing of all pregnant women and complete four ANC checkups for 60% of them'**
  String get monthlyTaskPC23;

  /// No description provided for @finalizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Incentive Portal'**
  String get finalizeTitle;

  /// No description provided for @finalizeClaimedAmount.
  ///
  /// In en, this message translates to:
  /// **'Claimed Amount'**
  String get finalizeClaimedAmount;

  /// No description provided for @finalizeStateAmount.
  ///
  /// In en, this message translates to:
  /// **'State Amount'**
  String get finalizeStateAmount;

  /// No description provided for @finalizeTotalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount:'**
  String get finalizeTotalAmountLabel;

  /// No description provided for @finalizeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get finalizeSave;

  /// No description provided for @usernameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be empty'**
  String get usernameEmpty;

  /// No description provided for @passwordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordEmpty;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordComplexity.
  ///
  /// In en, this message translates to:
  /// **'Password must contain letters, numbers, and special characters'**
  String get passwordComplexity;

  /// No description provided for @currentPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Current password cannot be empty'**
  String get currentPasswordEmpty;

  /// No description provided for @newPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'New password cannot be empty'**
  String get newPasswordEmpty;

  /// No description provided for @newPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get newPasswordTooShort;

  /// No description provided for @reenterPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password cannot be empty'**
  String get reenterPasswordEmpty;

  /// No description provided for @reenterPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get reenterPasswordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @guestSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest Beneficiary Search'**
  String get guestSearchTitle;

  /// No description provided for @beneficiaryNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary no.'**
  String get beneficiaryNumberLabel;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @districtLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabelSimple;

  /// No description provided for @blockLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockLabelSimple;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @ageLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabelSimple;

  /// No description provided for @mobileLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get mobileLabelSimple;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get search;

  /// No description provided for @showGuestBeneficiaryList.
  ///
  /// In en, this message translates to:
  /// **'SHOW GUEST BENEFICIARY LIST'**
  String get showGuestBeneficiaryList;

  /// No description provided for @advanceFilter.
  ///
  /// In en, this message translates to:
  /// **'Advance Filter'**
  String get advanceFilter;

  /// No description provided for @newMemberDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'New Member Details'**
  String get newMemberDetailsTitle;

  /// No description provided for @memberTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Member type'**
  String get memberTypeLabel;

  /// No description provided for @memberTypeAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get memberTypeAdult;

  /// No description provided for @memberTypeChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get memberTypeChild;

  /// No description provided for @memberTypeInfant.
  ///
  /// In en, this message translates to:
  /// **'Infant'**
  String get memberTypeInfant;

  /// No description provided for @relationWithHeadLabel.
  ///
  /// In en, this message translates to:
  /// **'Relation with the family head'**
  String get relationWithHeadLabel;

  /// No description provided for @relationSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relationSpouse;

  /// No description provided for @relationSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get relationSon;

  /// No description provided for @relationDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get relationDaughter;

  /// No description provided for @relationFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relationFather;

  /// No description provided for @relationMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relationMother;

  /// No description provided for @relationBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get relationBrother;

  /// No description provided for @relationSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get relationSister;

  /// No description provided for @relationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationOther;

  /// No description provided for @nameOfMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of member'**
  String get nameOfMemberLabel;

  /// No description provided for @nameOfMemberHint.
  ///
  /// In en, this message translates to:
  /// **'Name of member'**
  String get nameOfMemberHint;

  /// No description provided for @fatherGuardianNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Father/Guardian Name'**
  String get fatherGuardianNameLabel;

  /// No description provided for @motherNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother Name'**
  String get motherNameLabel;

  /// No description provided for @dobShort.
  ///
  /// In en, this message translates to:
  /// **'DOB'**
  String get dobShort;

  /// No description provided for @ageApproximate.
  ///
  /// In en, this message translates to:
  /// **'Age/Approximate Age'**
  String get ageApproximate;

  /// No description provided for @birthOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth Order'**
  String get birthOrderLabel;

  /// No description provided for @birthOrder1.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get birthOrder1;

  /// No description provided for @birthOrder2.
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get birthOrder2;

  /// No description provided for @birthOrder3.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get birthOrder3;

  /// No description provided for @birthOrder4.
  ///
  /// In en, this message translates to:
  /// **'4'**
  String get birthOrder4;

  /// No description provided for @birthOrder5Plus.
  ///
  /// In en, this message translates to:
  /// **'5+'**
  String get birthOrder5Plus;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @occupationLabel.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupationLabel;

  /// No description provided for @occupationEmployed.
  ///
  /// In en, this message translates to:
  /// **'Employed'**
  String get occupationEmployed;

  /// No description provided for @occupationSelfEmployed.
  ///
  /// In en, this message translates to:
  /// **'Self-employed'**
  String get occupationSelfEmployed;

  /// No description provided for @occupationStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get occupationStudent;

  /// No description provided for @occupationUnemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get occupationUnemployed;

  /// No description provided for @educationLabel.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationLabel;

  /// No description provided for @educationPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get educationPrimary;

  /// No description provided for @educationSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get educationSecondary;

  /// No description provided for @educationGraduate.
  ///
  /// In en, this message translates to:
  /// **'Graduate'**
  String get educationGraduate;

  /// No description provided for @educationPostgraduate.
  ///
  /// In en, this message translates to:
  /// **'Postgraduate'**
  String get educationPostgraduate;

  /// No description provided for @religionLabel.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get religionLabel;

  /// No description provided for @religionHindu.
  ///
  /// In en, this message translates to:
  /// **'Hindu'**
  String get religionHindu;

  /// No description provided for @religionMuslim.
  ///
  /// In en, this message translates to:
  /// **'Muslim'**
  String get religionMuslim;

  /// No description provided for @religionChristian.
  ///
  /// In en, this message translates to:
  /// **'Christian'**
  String get religionChristian;

  /// No description provided for @religionSikh.
  ///
  /// In en, this message translates to:
  /// **'Sikh'**
  String get religionSikh;

  /// No description provided for @religionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get religionOther;

  /// No description provided for @abhaAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'ABHA address'**
  String get abhaAddressLabel;

  /// No description provided for @whoseMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Whose mobile no.?'**
  String get whoseMobileLabel;

  /// No description provided for @self.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get self;

  /// No description provided for @spouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get spouse;

  /// No description provided for @father.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get father;

  /// No description provided for @mother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get mother;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @voterIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Voter Id'**
  String get voterIdLabel;

  /// No description provided for @rationCardIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Ration Card Id'**
  String get rationCardIdLabel;

  /// No description provided for @personalHealthIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Personal Health Id'**
  String get personalHealthIdLabel;

  /// No description provided for @beneficiaryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of beneficiary'**
  String get beneficiaryTypeLabel;

  /// No description provided for @beneficiaryTypeAPL.
  ///
  /// In en, this message translates to:
  /// **'APL'**
  String get beneficiaryTypeAPL;

  /// No description provided for @beneficiaryTypeBPL.
  ///
  /// In en, this message translates to:
  /// **'BPL'**
  String get beneficiaryTypeBPL;

  /// No description provided for @beneficiaryTypeAntyodaya.
  ///
  /// In en, this message translates to:
  /// **'Antyodaya'**
  String get beneficiaryTypeAntyodaya;

  /// No description provided for @maritalStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get maritalStatusLabel;

  /// No description provided for @married.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get married;

  /// No description provided for @unmarried.
  ///
  /// In en, this message translates to:
  /// **'Unmarried'**
  String get unmarried;

  /// No description provided for @widowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get widowed;

  /// No description provided for @separated.
  ///
  /// In en, this message translates to:
  /// **'Separated'**
  String get separated;

  /// No description provided for @divorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get divorced;

  /// No description provided for @ageAtMarriageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age at the time of marriage'**
  String get ageAtMarriageLabel;

  /// No description provided for @ageAtMarriageHint.
  ///
  /// In en, this message translates to:
  /// **'Age at the time of marriage'**
  String get ageAtMarriageHint;

  /// No description provided for @spouseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Spouse Name'**
  String get spouseNameLabel;

  /// No description provided for @spouseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Spouse Name'**
  String get spouseNameHint;

  /// No description provided for @haveChildrenQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you have children?'**
  String get haveChildrenQuestion;

  /// No description provided for @isWomanPregnantQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is the Woman Pregnant?'**
  String get isWomanPregnantQuestion;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @enterValidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter valid mobile'**
  String get enterValidMobile;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get addButton;

  /// No description provided for @addingButton.
  ///
  /// In en, this message translates to:
  /// **'ADDING...'**
  String get addingButton;

  /// No description provided for @familyHeadDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Head Details'**
  String get familyHeadDetailsTitle;

  /// No description provided for @houseNoLabel.
  ///
  /// In en, this message translates to:
  /// **'House no'**
  String get houseNoLabel;

  /// No description provided for @houseNoHint.
  ///
  /// In en, this message translates to:
  /// **'House no'**
  String get houseNoHint;

  /// No description provided for @nameOfFamilyHeadLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of family head'**
  String get nameOfFamilyHeadLabel;

  /// No description provided for @nameOfFamilyHeadHint.
  ///
  /// In en, this message translates to:
  /// **'Name of family head'**
  String get nameOfFamilyHeadHint;

  /// No description provided for @fatherNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Father name'**
  String get fatherNameLabel;

  /// No description provided for @villageNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Village name'**
  String get villageNameLabel;

  /// No description provided for @wardNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Ward no.'**
  String get wardNoLabel;

  /// No description provided for @mohallaTolaNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Mohalla/Tola name'**
  String get mohallaTolaNameLabel;

  /// No description provided for @rnhTabMemberDetails.
  ///
  /// In en, this message translates to:
  /// **'MEMBER DETAILS'**
  String get rnhTabMemberDetails;

  /// No description provided for @rnhTabHouseholdDetails.
  ///
  /// In en, this message translates to:
  /// **'HOUSEHOLD DETAILS'**
  String get rnhTabHouseholdDetails;

  /// No description provided for @rnhTabHouseholdAmenities.
  ///
  /// In en, this message translates to:
  /// **'HOUSEHOLD AMENITIES'**
  String get rnhTabHouseholdAmenities;

  /// No description provided for @rnhAddHeadFirstTabs.
  ///
  /// In en, this message translates to:
  /// **'Please add a family head before accessing other sections.'**
  String get rnhAddHeadFirstTabs;

  /// No description provided for @rnhAddHeadProceed.
  ///
  /// In en, this message translates to:
  /// **'Please add a family head before proceeding.'**
  String get rnhAddHeadProceed;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get nextButton;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get finishButton;

  /// No description provided for @addNewMemberButton.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW MEMBER'**
  String get addNewMemberButton;

  /// No description provided for @addFamilyHeadButton.
  ///
  /// In en, this message translates to:
  /// **'ADD FAMILY HEAD'**
  String get addFamilyHeadButton;

  /// No description provided for @rnhTotalMembers.
  ///
  /// In en, this message translates to:
  /// **'No. of total members'**
  String get rnhTotalMembers;

  /// No description provided for @thNumber.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get thNumber;

  /// No description provided for @thType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get thType;

  /// No description provided for @thName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get thName;

  /// No description provided for @thAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get thAge;

  /// No description provided for @thGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get thGender;

  /// No description provided for @thRelation.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get thRelation;

  /// No description provided for @thFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get thFather;

  /// No description provided for @thSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get thSpouse;

  /// No description provided for @thTotalChildren.
  ///
  /// In en, this message translates to:
  /// **'Total Children'**
  String get thTotalChildren;

  /// No description provided for @addressDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetailsTitle;

  /// No description provided for @socioEconomicDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Socio-economic Details'**
  String get socioEconomicDetailsTitle;

  /// No description provided for @waterSanitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Water & Sanitation'**
  String get waterSanitationTitle;

  /// No description provided for @cookingFuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking Fuel'**
  String get cookingFuelTitle;

  /// No description provided for @electricityTitle.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get electricityTitle;

  /// No description provided for @streetLocalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Street/Locality'**
  String get streetLocalityLabel;

  /// No description provided for @pincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincodeLabel;

  /// No description provided for @economicStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Economic Status'**
  String get economicStatusLabel;

  /// No description provided for @casteLabel.
  ///
  /// In en, this message translates to:
  /// **'Caste'**
  String get casteLabel;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @remarksLabel.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarksLabel;

  /// No description provided for @previousButton.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS'**
  String get previousButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get saveButton;

  /// No description provided for @residentialAreaTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of residential area'**
  String get residentialAreaTypeLabel;

  /// No description provided for @areaRural.
  ///
  /// In en, this message translates to:
  /// **'Rural'**
  String get areaRural;

  /// No description provided for @areaUrban.
  ///
  /// In en, this message translates to:
  /// **'Urban'**
  String get areaUrban;

  /// No description provided for @areaTribal.
  ///
  /// In en, this message translates to:
  /// **'Tribal'**
  String get areaTribal;

  /// No description provided for @houseTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of house'**
  String get houseTypeLabel;

  /// No description provided for @houseNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get houseNone;

  /// No description provided for @houseKachcha.
  ///
  /// In en, this message translates to:
  /// **'Kuchcha house'**
  String get houseKachcha;

  /// No description provided for @houseSemiPucca.
  ///
  /// In en, this message translates to:
  /// **'Semi Pucca house'**
  String get houseSemiPucca;

  /// No description provided for @housePucca.
  ///
  /// In en, this message translates to:
  /// **'Pucca house'**
  String get housePucca;

  /// No description provided for @houseThatch.
  ///
  /// In en, this message translates to:
  /// **'Thatch house'**
  String get houseThatch;

  /// No description provided for @ownershipTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of ownership'**
  String get ownershipTypeLabel;

  /// No description provided for @rental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get rental;

  /// No description provided for @sharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get sharing;

  /// No description provided for @kitchenInsideLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the kitchen inside the house'**
  String get kitchenInsideLabel;

  /// No description provided for @cookingFuelTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of Fuel used for cooking'**
  String get cookingFuelTypeLabel;

  /// No description provided for @fuelLpg.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get fuelLpg;

  /// No description provided for @fuelFirewood.
  ///
  /// In en, this message translates to:
  /// **'Firewood'**
  String get fuelFirewood;

  /// No description provided for @fuelCoal.
  ///
  /// In en, this message translates to:
  /// **'Coal'**
  String get fuelCoal;

  /// No description provided for @fuelKerosene.
  ///
  /// In en, this message translates to:
  /// **'Kerosene'**
  String get fuelKerosene;

  /// No description provided for @fuelCropResidue.
  ///
  /// In en, this message translates to:
  /// **'Crop Residue'**
  String get fuelCropResidue;

  /// No description provided for @fuelDungCake.
  ///
  /// In en, this message translates to:
  /// **'Dung Cake'**
  String get fuelDungCake;

  /// No description provided for @fuelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fuelOther;

  /// No description provided for @primaryWaterSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary source of water'**
  String get primaryWaterSourceLabel;

  /// No description provided for @waterSupply.
  ///
  /// In en, this message translates to:
  /// **'Supply Water'**
  String get waterSupply;

  /// No description provided for @waterRO.
  ///
  /// In en, this message translates to:
  /// **'R.O'**
  String get waterRO;

  /// No description provided for @waterHandpumpInside.
  ///
  /// In en, this message translates to:
  /// **'Hand pump within house'**
  String get waterHandpumpInside;

  /// No description provided for @waterHandpumpOutside.
  ///
  /// In en, this message translates to:
  /// **'Hand pump outside of house'**
  String get waterHandpumpOutside;

  /// No description provided for @waterTanker.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get waterTanker;

  /// No description provided for @waterRiver.
  ///
  /// In en, this message translates to:
  /// **'River'**
  String get waterRiver;

  /// No description provided for @waterPond.
  ///
  /// In en, this message translates to:
  /// **'Pond'**
  String get waterPond;

  /// No description provided for @waterLake.
  ///
  /// In en, this message translates to:
  /// **'Lake'**
  String get waterLake;

  /// No description provided for @waterWell.
  ///
  /// In en, this message translates to:
  /// **'Well'**
  String get waterWell;

  /// No description provided for @waterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get waterOther;

  /// No description provided for @electricityAvailabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability of electricity'**
  String get electricityAvailabilityLabel;

  /// No description provided for @elecSupply.
  ///
  /// In en, this message translates to:
  /// **'Electricity Supply'**
  String get elecSupply;

  /// No description provided for @elecGenerator.
  ///
  /// In en, this message translates to:
  /// **'Generator'**
  String get elecGenerator;

  /// No description provided for @elecSolar.
  ///
  /// In en, this message translates to:
  /// **'Solar Power'**
  String get elecSolar;

  /// No description provided for @elecKeroseneLamp.
  ///
  /// In en, this message translates to:
  /// **'Kerosene Lamp'**
  String get elecKeroseneLamp;

  /// No description provided for @elecOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get elecOther;

  /// No description provided for @toiletAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Do you have access to toilet at your home'**
  String get toiletAccessLabel;

  /// No description provided for @eligibleCouples.
  ///
  /// In en, this message translates to:
  /// **'Eligible couples'**
  String get eligibleCouples;

  /// No description provided for @pregnantWomen.
  ///
  /// In en, this message translates to:
  /// **'Pregnant women'**
  String get pregnantWomen;

  /// No description provided for @elderlyAbove65.
  ///
  /// In en, this message translates to:
  /// **'Elderly (>65 Y)'**
  String get elderlyAbove65;

  /// No description provided for @children0to1.
  ///
  /// In en, this message translates to:
  /// **'0-1 year old children'**
  String get children0to1;

  /// No description provided for @children1to2.
  ///
  /// In en, this message translates to:
  /// **'1-2 year old children'**
  String get children1to2;

  /// No description provided for @children2to5.
  ///
  /// In en, this message translates to:
  /// **'2-5 year old children'**
  String get children2to5;

  /// No description provided for @householdBeneficiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Household Beneficiary'**
  String get householdBeneficiaryTitle;

  /// No description provided for @householdBeneficiarySearch.
  ///
  /// In en, this message translates to:
  /// **'Household Beneficiary Search'**
  String get householdBeneficiarySearch;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @addNewBeneficiaryButton.
  ///
  /// In en, this message translates to:
  /// **'Add New Beneficiary'**
  String get addNewBeneficiaryButton;

  /// No description provided for @registrationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Date'**
  String get registrationDateLabel;

  /// No description provided for @registrationTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Type'**
  String get registrationTypeLabel;

  /// No description provided for @beneficiaryIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary ID'**
  String get beneficiaryIdLabel;

  /// No description provided for @ageGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Age | Gender'**
  String get ageGenderLabel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
