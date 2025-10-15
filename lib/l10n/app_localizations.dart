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
