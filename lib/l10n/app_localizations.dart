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

  /// No description provided for @aadhaarNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get aadhaarNumberLabel;

  /// No description provided for @abhaAadhaarNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get abhaAadhaarNumberLabel;

  /// No description provided for @abhaAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'ABHA Address'**
  String get abhaAddressLabel;

  /// No description provided for @methodOfContra.
  ///
  /// In en, this message translates to:
  /// **'Method of contraception'**
  String get methodOfContra;

  /// No description provided for @abhaConsent1.
  ///
  /// In en, this message translates to:
  /// **'I am voluntarily sharing my Aadhaar Number / Virtual ID issued by the Unique Identification Authority of India (\"UIDAI\"), and my demographic information for the purpose of creating an Ayushman Bharat Health Account number (\"ABHA number\") and Ayushman Bharat Health Account address (\"ABHA Address\"). I authorize NHA to use my Aadhaar number / Virtual ID for performing Aadhaar based authentication with UIDAI as per the provisions of the Aadhaar (Targeted Delivery of Financial and other Subsidies, Benefits and Services) Act, 2016 for the aforesaid purpose. I understand that UIDAI will share my e-KYC details, or response of \"Yes\" with NHA upon successful authentication.'**
  String get abhaConsent1;

  /// No description provided for @abhaConsent2.
  ///
  /// In en, this message translates to:
  /// **'I intend to create Ayushman Bharat Health Account Number (\"ABHA number\") and Ayushman Bharat Health Account address (\"ABHA Address\") using document other than Aadhaar.'**
  String get abhaConsent2;

  /// No description provided for @abhaConsent3.
  ///
  /// In en, this message translates to:
  /// **'I consent to usage of my ABHA address and ABHA number for linking of my legacy (past) government health records and those which will be generated during this encounter.'**
  String get abhaConsent3;

  /// No description provided for @abhaConsent4.
  ///
  /// In en, this message translates to:
  /// **'I authorize the sharing of all my health records with healthcare provider(s) for the purpose of providing healthcare services to me during this encounter'**
  String get abhaConsent4;

  /// No description provided for @abhaConsent5.
  ///
  /// In en, this message translates to:
  /// **'I consent to the anonymization and subsequent use of my government health records for public health purposes.'**
  String get abhaConsent5;

  /// No description provided for @abhaConsent6.
  ///
  /// In en, this message translates to:
  /// **'I, Rohit Chavan, confirm that I have duly informed and explained the beneficiary of the contents of consent for aforementioned purposes.'**
  String get abhaConsent6;

  /// No description provided for @abhaConsent7.
  ///
  /// In en, this message translates to:
  /// **'I, (beneficiary name), have been explained about the consent as stated above and hereby provide my consent for the aforementioned purposes.'**
  String get abhaConsent7;

  /// No description provided for @abhaDeclarationTitle.
  ///
  /// In en, this message translates to:
  /// **'I hereby declare that:'**
  String get abhaDeclarationTitle;

  /// No description provided for @abhaGenerateOtpButton.
  ///
  /// In en, this message translates to:
  /// **'GENERATE OTP'**
  String get abhaGenerateOtpButton;

  /// No description provided for @abhaOtpGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP generated successfully'**
  String get abhaOtpGeneratedSuccess;

  /// No description provided for @aboutUsP1Title.
  ///
  /// In en, this message translates to:
  /// **'ASHA (ACCREDITED SOCIAL HEALTH ACTIVIST)'**
  String get aboutUsP1Title;

  /// No description provided for @aboutUsP1Part2.
  ///
  /// In en, this message translates to:
  /// **'App, is an application to help ASHA front-line workers to do their everyday work related to population immunization, eligible couple tracking, mother and child care and different more programs run by the health society.'**
  String get aboutUsP1Part2;

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

  /// No description provided for @accountNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountNumberHint;

  /// No description provided for @accountNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank Account number'**
  String get accountNumberLabel;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get addButton;

  /// No description provided for @addFamilyHeadButton.
  ///
  /// In en, this message translates to:
  /// **'ADD FAMILY HEAD'**
  String get addFamilyHeadButton;

  /// No description provided for @transgender.
  ///
  /// In en, this message translates to:
  /// **'Transgender'**
  String get transgender;

  /// No description provided for @occupationHousewife.
  ///
  /// In en, this message translates to:
  /// **'Housewife'**
  String get occupationHousewife;

  /// No description provided for @occupationDailyWageLabor.
  ///
  /// In en, this message translates to:
  /// **'Daily Wage Labor'**
  String get occupationDailyWageLabor;

  /// No description provided for @occupationAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get occupationAgriculture;

  /// No description provided for @occupationSalaried.
  ///
  /// In en, this message translates to:
  /// **'Salaried'**
  String get occupationSalaried;

  /// No description provided for @occupationBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get occupationBusiness;

  /// No description provided for @occupationRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get occupationRetired;

  /// No description provided for @occupationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get occupationOther;

  /// No description provided for @enterOccupationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get enterOccupationOther;

  /// No description provided for @educationNoSchooling.
  ///
  /// In en, this message translates to:
  /// **'No Schooling'**
  String get educationNoSchooling;

  /// No description provided for @educationHighSchool.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get educationHighSchool;

  /// No description provided for @educationIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get educationIntermediate;

  /// No description provided for @educationDiploma.
  ///
  /// In en, this message translates to:
  /// **'Diploma'**
  String get educationDiploma;

  /// No description provided for @educationGraduateAndAbove.
  ///
  /// In en, this message translates to:
  /// **'Graduate and above'**
  String get educationGraduateAndAbove;

  /// No description provided for @religionNotDisclosed.
  ///
  /// In en, this message translates to:
  /// **'Do not want to disclose'**
  String get religionNotDisclosed;

  /// No description provided for @religionBuddhism.
  ///
  /// In en, this message translates to:
  /// **'Buddhism'**
  String get religionBuddhism;

  /// No description provided for @religionJainism.
  ///
  /// In en, this message translates to:
  /// **'Jainism'**
  String get religionJainism;

  /// No description provided for @religionParsi.
  ///
  /// In en, this message translates to:
  /// **'Parsi'**
  String get religionParsi;

  /// No description provided for @religionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get religionOther;

  /// No description provided for @categoryNotDisclosed.
  ///
  /// In en, this message translates to:
  /// **'Do not want to disclose'**
  String get categoryNotDisclosed;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @categoryOBC.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get categoryOBC;

  /// No description provided for @categorySC.
  ///
  /// In en, this message translates to:
  /// **'SC'**
  String get categorySC;

  /// No description provided for @categoryST.
  ///
  /// In en, this message translates to:
  /// **'ST'**
  String get categoryST;

  /// No description provided for @categoryPichdaVarg1.
  ///
  /// In en, this message translates to:
  /// **'Pichda Varg 1'**
  String get categoryPichdaVarg1;

  /// No description provided for @categoryPichdaVarg2.
  ///
  /// In en, this message translates to:
  /// **'Pichda Varg 2'**
  String get categoryPichdaVarg2;

  /// No description provided for @categoryAtyantPichdaVarg.
  ///
  /// In en, this message translates to:
  /// **'Atyant Pichda Varg'**
  String get categoryAtyantPichdaVarg;

  /// No description provided for @categoryDontKnow.
  ///
  /// In en, this message translates to:
  /// **'Do not know'**
  String get categoryDontKnow;

  /// No description provided for @migrationSeasonalMigrant.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Migrant'**
  String get migrationSeasonalMigrant;

  /// No description provided for @maritalStatusMarried.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get maritalStatusMarried;

  /// No description provided for @maritalStatusUnmarried.
  ///
  /// In en, this message translates to:
  /// **'Unmarried'**
  String get maritalStatusUnmarried;

  /// No description provided for @maritalStatusWidowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get maritalStatusWidowed;

  /// No description provided for @maritalStatusWidower.
  ///
  /// In en, this message translates to:
  /// **'Widower'**
  String get maritalStatusWidower;

  /// No description provided for @maritalStatusSeparated.
  ///
  /// In en, this message translates to:
  /// **'Separated'**
  String get maritalStatusSeparated;

  /// No description provided for @maritalStatusDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get maritalStatusDivorced;

  /// No description provided for @addNewBeneficiaryButton.
  ///
  /// In en, this message translates to:
  /// **'Add New Beneficiary'**
  String get addNewBeneficiaryButton;

  /// No description provided for @addNewMemberButton.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW MEMBER'**
  String get addNewMemberButton;

  /// No description provided for @addingButton.
  ///
  /// In en, this message translates to:
  /// **'ADDING...'**
  String get addingButton;

  /// No description provided for @addressDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetailsTitle;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @advanceFilter.
  ///
  /// In en, this message translates to:
  /// **'Advance Filters'**
  String get advanceFilter;

  /// No description provided for @affiliatedToStateInsuranceLabel.
  ///
  /// In en, this message translates to:
  /// **'Affiliated to state Health Insurance Scheme'**
  String get affiliatedToStateInsuranceLabel;

  /// No description provided for @ageApproximate.
  ///
  /// In en, this message translates to:
  /// **'Age/Approximate Age'**
  String get ageApproximate;

  /// No description provided for @ageAtMarriageInYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Age at marriage (in years)'**
  String get ageAtMarriageInYearsLabel;

  /// No description provided for @ageAtMarriageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age at the time of marriage'**
  String get ageAtMarriageLabel;

  /// No description provided for @ageGender.
  ///
  /// In en, this message translates to:
  /// **'{age} Y | {gender}'**
  String ageGender(Object age, Object gender);

  /// No description provided for @ageGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Age | Gender'**
  String get ageGenderLabel;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @ageLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabelSimple;

  /// No description provided for @altMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Alternate mobile no.'**
  String get altMobileHint;

  /// No description provided for @altMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Alternate mobile no.'**
  String get altMobileLabel;

  /// No description provided for @ancVisitFormTitle.
  ///
  /// In en, this message translates to:
  /// **'ANC Visit Form'**
  String get ancVisitFormTitle;

  /// No description provided for @ancVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'ANC visit'**
  String get ancVisitLabel;

  /// No description provided for @ancVisitListTitle.
  ///
  /// In en, this message translates to:
  /// **'ANC Visit List'**
  String get ancVisitListTitle;

  /// No description provided for @ancVisitSearchHint.
  ///
  /// In en, this message translates to:
  /// **'ANC Visit Search'**
  String get ancVisitSearchHint;

  /// No description provided for @anganwadiCenterNoHint.
  ///
  /// In en, this message translates to:
  /// **'Anganwadi Center no.'**
  String get anganwadiCenterNoHint;

  /// No description provided for @anganwadiCenterNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Anganwadi Center no.'**
  String get anganwadiCenterNoLabel;

  /// No description provided for @anm1MobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ANM1'**
  String get anm1MobileHint;

  /// No description provided for @anm1MobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ANM1'**
  String get anm1MobileLabel;

  /// No description provided for @anm1NameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of ANM1'**
  String get anm1NameHint;

  /// No description provided for @anm1NameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of ANM1'**
  String get anm1NameLabel;

  /// No description provided for @anm2MobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ANM2'**
  String get anm2MobileHint;

  /// No description provided for @anm2MobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ANM2'**
  String get anm2MobileLabel;

  /// No description provided for @anm2NameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of ANM2'**
  String get anm2NameHint;

  /// No description provided for @anm2NameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of ANM2'**
  String get anm2NameLabel;

  /// No description provided for @anmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'ANM Name'**
  String get anmNameLabel;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcements List'**
  String get announcement;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcements;

  /// No description provided for @selectOptions.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectOptions;

  /// No description provided for @antenatal.
  ///
  /// In en, this message translates to:
  /// **'Next Antenatal Date:'**
  String get antenatal;

  /// No description provided for @announcementItem1Body.
  ///
  /// In en, this message translates to:
  /// **'In the local primary health center, smart phones were given to the ASHA workers of the block area for health related work. PHC in-charge Dr. Purushottam Priyadarshi said that a total of 126 ASHA workers of the block area have been given smart phones to make them hi-tech.He told that writing ASHA in the register will now give freedom. The mobile is specially designed for health related programs. Mobile cannot be used for any other purpose.All ASHA workers can send claim form for honorarium from their smart phone itself. On the basis of this, the amount of honorarium will be sent to their bank account. BCM Sanjit Kumar said that there are a total of 120 ASHA workers and 6 facilitators in the block area. Out of which smart phones have been made available to 122.'**
  String get announcementItem1Body;

  /// No description provided for @announcementItem1Title.
  ///
  /// In en, this message translates to:
  /// **'Distribution: Smart phones given to ASHA workers'**
  String get announcementItem1Title;

  /// No description provided for @announcementItem2Body.
  ///
  /// In en, this message translates to:
  /// **'If you are a resident of Bihar and you are a woman, then let us tell you that tremendous recruitment has been done for Bihar ASHA for women on about 1.12 lakh posts in Bihar. In which all the women of Bihar can apply, a big change has also been made in the application process under Bihar ASHA Recruitment 2023. As earlier it was necessary to have only 8th pass for ASHA restoration, but now it has been changed to 10th pass, so now if you want to get a job for Bihar ASHA moment, then it will be mandatory for you to have at least 10th pass You can apply for the post of ASHA.'**
  String get announcementItem2Body;

  /// No description provided for @announcementItem2Title.
  ///
  /// In en, this message translates to:
  /// **'Bihar ASHA Worker Vacancy 2023: (Great opportunity for women, this department will recruit more than 1.12 lakh posts'**
  String get announcementItem2Title;

  /// No description provided for @announcementItem3Body.
  ///
  /// In en, this message translates to:
  /// **'ASHA Workers have been at the forefront of the fight against COVID-19. Apart from the regular duties of taking care of newborn child and their mother, regular vaccinations and surveys, ASHA workers from all over the country are doing extra duties for COVID-19 without any extra pay.'**
  String get announcementItem3Body;

  /// No description provided for @announcementItem3Title.
  ///
  /// In en, this message translates to:
  /// **'ASHA Workers of Bihar Demand Better Wages, Work Environment'**
  String get announcementItem3Title;

  /// No description provided for @anyHighRiskProblemLabel.
  ///
  /// In en, this message translates to:
  /// **'Is there any high risk problem?'**
  String get anyHighRiskProblemLabel;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Medixcel'**
  String get appTitle;

  /// No description provided for @areaOfWorking.
  ///
  /// In en, this message translates to:
  /// **'Area of working'**
  String get areaOfWorking;

  /// No description provided for @areaRural.
  ///
  /// In en, this message translates to:
  /// **'Rural'**
  String get areaRural;

  /// No description provided for @areaTribal.
  ///
  /// In en, this message translates to:
  /// **'Tribal'**
  String get areaTribal;

  /// No description provided for @areaUrban.
  ///
  /// In en, this message translates to:
  /// **'Urban'**
  String get areaUrban;

  /// No description provided for @ashaFacilitatorMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ASHA Facilitator'**
  String get ashaFacilitatorMobileHint;

  /// No description provided for @ashaFacilitatorMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of ASHA Facilitator'**
  String get ashaFacilitatorMobileLabel;

  /// No description provided for @ashaFacilitatorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA Facilitator'**
  String get ashaFacilitatorNameHint;

  /// No description provided for @ashaFacilitatorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA Facilitator'**
  String get ashaFacilitatorNameLabel;

  /// No description provided for @ashaIdHint.
  ///
  /// In en, this message translates to:
  /// **'A10000555'**
  String get ashaIdHint;

  /// No description provided for @ashaIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ASHA ID'**
  String get ashaIdLabel;

  /// No description provided for @ashaNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA'**
  String get ashaNameHint;

  /// No description provided for @ashaNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA'**
  String get ashaNameLabel;

  /// No description provided for @ashaProfile.
  ///
  /// In en, this message translates to:
  /// **'ASHA Profile'**
  String get ashaProfile;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @awwMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of AWW'**
  String get awwMobileHint;

  /// No description provided for @awwMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of AWW'**
  String get awwMobileLabel;

  /// No description provided for @awwNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of AWW'**
  String get awwNameHint;

  /// No description provided for @awwNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of AWW'**
  String get awwNameLabel;

  /// No description provided for @bankDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank details'**
  String get bankDetailsTitle;

  /// No description provided for @bcmMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get bcmMobileHint;

  /// No description provided for @bcmMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of Block Community Mobilizer'**
  String get bcmMobileLabel;

  /// No description provided for @bcmNameHint.
  ///
  /// In en, this message translates to:
  /// **'Block Community Mobilizer name'**
  String get bcmNameHint;

  /// No description provided for @bcmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Block Community Mobilizer name'**
  String get bcmNameLabel;

  /// No description provided for @beneficiaryAbsentLabel.
  ///
  /// In en, this message translates to:
  /// **'Is Beneficiary Absent?'**
  String get beneficiaryAbsentLabel;

  /// No description provided for @beneficiaryIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary ID'**
  String get beneficiaryIdLabel;

  /// No description provided for @beneficiaryNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary no.'**
  String get beneficiaryNumberLabel;

  /// No description provided for @beneficiaryTypeAPL.
  ///
  /// In en, this message translates to:
  /// **'APL'**
  String get beneficiaryTypeAPL;

  /// No description provided for @beneficiaryTypeAntyodaya.
  ///
  /// In en, this message translates to:
  /// **'Antyodaya'**
  String get beneficiaryTypeAntyodaya;

  /// No description provided for @beneficiaryTypeBPL.
  ///
  /// In en, this message translates to:
  /// **'BPL'**
  String get beneficiaryTypeBPL;

  /// No description provided for @beneficiaryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of beneficiary'**
  String get beneficiaryTypeLabel;

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

  /// No description provided for @birthOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth Order'**
  String get birthOrderLabel;

  /// No description provided for @blockHint.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockHint;

  /// No description provided for @blockLabel.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockLabel;

  /// No description provided for @blockLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockLabelSimple;

  /// No description provided for @callNumber.
  ///
  /// In en, this message translates to:
  /// **'Call: {number}'**
  String callNumber(Object number);

  /// No description provided for @casteLabel.
  ///
  /// In en, this message translates to:
  /// **'Social class'**
  String get casteLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @cbacA_actGT150.
  ///
  /// In en, this message translates to:
  /// **'more than 150 minutes a week'**
  String get cbacA_actGT150;

  /// No description provided for @cbacA_actLT150.
  ///
  /// In en, this message translates to:
  /// **'Less than 150 minutes a week'**
  String get cbacA_actLT150;

  /// No description provided for @cbacA_activityQ.
  ///
  /// In en, this message translates to:
  /// **'Do you do at least 150 minutes of physical activity a week? (At least 30 minutes a day, 5 days a week) *'**
  String get cbacA_activityQ;

  /// No description provided for @cbacA_age30to39.
  ///
  /// In en, this message translates to:
  /// **'30 to 39 years'**
  String get cbacA_age30to39;

  /// No description provided for @cbacA_age40to49.
  ///
  /// In en, this message translates to:
  /// **'40 to 49 years'**
  String get cbacA_age40to49;

  /// No description provided for @cbacA_age50to69.
  ///
  /// In en, this message translates to:
  /// **'50 to 69 years'**
  String get cbacA_age50to69;

  /// No description provided for @cbacA_ageLT30.
  ///
  /// In en, this message translates to:
  /// **'<30 years'**
  String get cbacA_ageLT30;

  /// No description provided for @cbacA_ageQ.
  ///
  /// In en, this message translates to:
  /// **'What is your age? (in years) *'**
  String get cbacA_ageQ;

  /// No description provided for @cbacA_alcoholQ.
  ///
  /// In en, this message translates to:
  /// **'Do you consume alcohol/liquor daily? *'**
  String get cbacA_alcoholQ;

  /// No description provided for @cbacA_familyQ.
  ///
  /// In en, this message translates to:
  /// **'Does anyone in your family (parents, siblings) suffer from high blood pressure, diabetes or heart disease? *'**
  String get cbacA_familyQ;

  /// No description provided for @cbacA_tobDaily.
  ///
  /// In en, this message translates to:
  /// **'Do it everyday'**
  String get cbacA_tobDaily;

  /// No description provided for @cbacA_tobNever.
  ///
  /// In en, this message translates to:
  /// **'Have never done'**
  String get cbacA_tobNever;

  /// No description provided for @cbacA_tobSometimes.
  ///
  /// In en, this message translates to:
  /// **'Used to do in the past or do sometimes in the present'**
  String get cbacA_tobSometimes;

  /// No description provided for @cbacA_tobaccoQ.
  ///
  /// In en, this message translates to:
  /// **'Do you smoke or consume smokeless tobacco products like Gutka/Khaini? *'**
  String get cbacA_tobaccoQ;

  /// No description provided for @cbacA_waist81to90.
  ///
  /// In en, this message translates to:
  /// **'81 to 90 cm'**
  String get cbacA_waist81to90;

  /// No description provided for @cbacA_waistGT90.
  ///
  /// In en, this message translates to:
  /// **'90 cm more than'**
  String get cbacA_waistGT90;

  /// No description provided for @cbacA_waistLE80.
  ///
  /// In en, this message translates to:
  /// **'80 cm or less'**
  String get cbacA_waistLE80;

  /// No description provided for @cbacA_waistQ.
  ///
  /// In en, this message translates to:
  /// **'Waist Measurement (in cm) *'**
  String get cbacA_waistQ;

  /// No description provided for @cbacB_b1_bloodMucus.
  ///
  /// In en, this message translates to:
  /// **'Is there blood in the mucus?'**
  String get cbacB_b1_bloodMucus;

  /// No description provided for @cbacB_b1_breath.
  ///
  /// In en, this message translates to:
  /// **'Is there trouble in breathing (shortness of breath)?'**
  String get cbacB_b1_breath;

  /// No description provided for @cbacB_b1_changeVoice.
  ///
  /// In en, this message translates to:
  /// **'Is there a change in voice?'**
  String get cbacB_b1_changeVoice;

  /// No description provided for @cbacB_b1_chewPain.
  ///
  /// In en, this message translates to:
  /// **'Is it difficult/painful to chew anything?'**
  String get cbacB_b1_chewPain;

  /// No description provided for @cbacB_b1_closeEyelidsDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Is there difficulty in closing the eyelids?'**
  String get cbacB_b1_closeEyelidsDifficulty;

  /// No description provided for @cbacB_b1_cough2w.
  ///
  /// In en, this message translates to:
  /// **'Does the cough last for more than two weeks?'**
  String get cbacB_b1_cough2w;

  /// No description provided for @cbacB_b1_druggs.
  ///
  /// In en, this message translates to:
  /// **'Are you currently taking anti-TB drugs?'**
  String get cbacB_b1_druggs;

  /// No description provided for @cbacB_b1_eyePain.
  ///
  /// In en, this message translates to:
  /// **'Have you had eye pain for more than a week?'**
  String get cbacB_b1_eyePain;

  /// No description provided for @cbacB_b1_eyeRedness.
  ///
  /// In en, this message translates to:
  /// **'Have you had redness in your eyes for more than a week?'**
  String get cbacB_b1_eyeRedness;

  /// No description provided for @cbacB_b1_fever2w.
  ///
  /// In en, this message translates to:
  /// **'Has the fever lasted for more than two weeks?'**
  String get cbacB_b1_fever2w;

  /// No description provided for @cbacB_b1_hearingDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Are you having trouble/difficulty in hearing?'**
  String get cbacB_b1_hearingDifficulty;

  /// No description provided for @cbacB_b1_history.
  ///
  /// In en, this message translates to:
  /// **'Does any member of your family have a previous history of TB?'**
  String get cbacB_b1_history;

  /// No description provided for @cbacB_b1_holdingDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Do you have difficulty in holding anything with your fingers?'**
  String get cbacB_b1_holdingDifficulty;

  /// No description provided for @cbacB_b1_legWeaknessWalk.
  ///
  /// In en, this message translates to:
  /// **'Is there weakness in the legs that makes it difficult to walk?'**
  String get cbacB_b1_legWeaknessWalk;

  /// No description provided for @cbacB_b1_nightSweat.
  ///
  /// In en, this message translates to:
  /// **'Do you sweat a lot at night?'**
  String get cbacB_b1_nightSweat;

  /// No description provided for @cbacB_b1_numbnessHotCold.
  ///
  /// In en, this message translates to:
  /// **'Is there no feeling (numbness) on hot/cold touch in the palms or soles of the feet?'**
  String get cbacB_b1_numbnessHotCold;

  /// No description provided for @cbacB_b1_openMouth.
  ///
  /// In en, this message translates to:
  /// **'Do you have trouble to open your mouth?'**
  String get cbacB_b1_openMouth;

  /// No description provided for @cbacB_b1_palmsSores.
  ///
  /// In en, this message translates to:
  /// **'Do the palms or soles get sores frequently?'**
  String get cbacB_b1_palmsSores;

  /// No description provided for @cbacB_b1_rashMouth.
  ///
  /// In en, this message translates to:
  /// **'Is there a white or red ring/rash in the mouth that has not healed for two weeks?'**
  String get cbacB_b1_rashMouth;

  /// No description provided for @cbacB_b1_readingDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Do you have difficulty in reading?'**
  String get cbacB_b1_readingDifficulty;

  /// No description provided for @cbacB_b1_scratchesCracks.
  ///
  /// In en, this message translates to:
  /// **'Are there scratches/cracks/torn on the fingers or toes?'**
  String get cbacB_b1_scratchesCracks;

  /// No description provided for @cbacB_b1_seizures.
  ///
  /// In en, this message translates to:
  /// **'Do seizures occur?'**
  String get cbacB_b1_seizures;

  /// No description provided for @cbacB_b1_skinLump.
  ///
  /// In en, this message translates to:
  /// **'Is there a lump on the skin?'**
  String get cbacB_b1_skinLump;

  /// No description provided for @cbacB_b1_skinRashDiscolor.
  ///
  /// In en, this message translates to:
  /// **'Is there a rash or discoloration of the skin that is not sensitive?'**
  String get cbacB_b1_skinRashDiscolor;

  /// No description provided for @cbacB_b1_skinThick.
  ///
  /// In en, this message translates to:
  /// **'Is the skin thick somewhere?'**
  String get cbacB_b1_skinThick;

  /// No description provided for @cbacB_b1_swellingMouth.
  ///
  /// In en, this message translates to:
  /// **'Is there any kind of swelling in the mouth that has not healed for two weeks?'**
  String get cbacB_b1_swellingMouth;

  /// No description provided for @cbacB_b1_tingling.
  ///
  /// In en, this message translates to:
  /// **'Is there frequent tingling in the palms or soles?'**
  String get cbacB_b1_tingling;

  /// No description provided for @cbacB_b1_tinglingNumbness.
  ///
  /// In en, this message translates to:
  /// **'Is there tingling and numbness in the hands or feet?'**
  String get cbacB_b1_tinglingNumbness;

  /// No description provided for @cbacB_b1_tuberculosisFamily.
  ///
  /// In en, this message translates to:
  /// **'Is anyone in your family currently suffering from Tuberculosis (TB)?'**
  String get cbacB_b1_tuberculosisFamily;

  /// No description provided for @cbacB_b1_ulcers.
  ///
  /// In en, this message translates to:
  /// **'Have mouth ulcers that are not healing for two weeks?'**
  String get cbacB_b1_ulcers;

  /// No description provided for @cbacB_b1_visionBlurred.
  ///
  /// In en, this message translates to:
  /// **'Is your vision blurred?'**
  String get cbacB_b1_visionBlurred;

  /// No description provided for @cbacB_b1_weightLoss.
  ///
  /// In en, this message translates to:
  /// **'Is your weight continuously decreasing?'**
  String get cbacB_b1_weightLoss;

  /// No description provided for @cbacB_b2_breastLump.
  ///
  /// In en, this message translates to:
  /// **'Is there a lump in the breast as well?'**
  String get cbacB_b2_breastLump;

  /// No description provided for @cbacB_b2_breastShapeDiff.
  ///
  /// In en, this message translates to:
  /// **'Is there a difference in breast shape and size?'**
  String get cbacB_b2_breastShapeDiff;

  /// No description provided for @cbacB_b2_depression.
  ///
  /// In en, this message translates to:
  /// **'Is there a condition of mental depression?'**
  String get cbacB_b2_depression;

  /// No description provided for @cbacB_b2_excessBleeding.
  ///
  /// In en, this message translates to:
  /// **'Is there excessive bleeding during menstruation?'**
  String get cbacB_b2_excessBleeding;

  /// No description provided for @cbacB_b2_irregularPeriods.
  ///
  /// In en, this message translates to:
  /// **'Are there irregular periods?'**
  String get cbacB_b2_irregularPeriods;

  /// No description provided for @cbacB_b2_jointPain.
  ///
  /// In en, this message translates to:
  /// **'Do you have joint pains?'**
  String get cbacB_b2_jointPain;

  /// No description provided for @cbacB_b2_nippleBleed.
  ///
  /// In en, this message translates to:
  /// **'Are the nipples/areolas leaking with blood?'**
  String get cbacB_b2_nippleBleed;

  /// No description provided for @cbacB_b2_postIntercourseBleed.
  ///
  /// In en, this message translates to:
  /// **'Does bleeding occur after intercourse?'**
  String get cbacB_b2_postIntercourseBleed;

  /// No description provided for @cbacB_b2_postMenopauseBleed.
  ///
  /// In en, this message translates to:
  /// **'Does bleeding occur after menopause (even after menstruation stops)?'**
  String get cbacB_b2_postMenopauseBleed;

  /// No description provided for @cbacB_b2_smellyDischarge.
  ///
  /// In en, this message translates to:
  /// **'Is there a smelly vaginal discharge?'**
  String get cbacB_b2_smellyDischarge;

  /// No description provided for @cbacB_b2_uterusProlapse.
  ///
  /// In en, this message translates to:
  /// **'Does the uterus come out?'**
  String get cbacB_b2_uterusProlapse;

  /// No description provided for @cbacC_businessRiskQ.
  ///
  /// In en, this message translates to:
  /// **'Business Risk -'**
  String get cbacC_businessRiskQ;

  /// No description provided for @cbacC_fuelGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get cbacC_fuelGas;

  /// No description provided for @cbacC_fuelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cbacC_fuelOther;

  /// No description provided for @cbacC_fuelQ.
  ///
  /// In en, this message translates to:
  /// **'What type of fuel is used for cooking?'**
  String get cbacC_fuelQ;

  /// No description provided for @cbacConsentAgree.
  ///
  /// In en, this message translates to:
  /// **'AGREE'**
  String get cbacConsentAgree;

  /// No description provided for @cbacConsentBody.
  ///
  /// In en, this message translates to:
  /// **'I have been explained by the ASHA, the purpose for which the information and measurement findings is being collected from me, in a language I understand and I give my consent to collect the information and measurement findings on my personal health profile.'**
  String get cbacConsentBody;

  /// No description provided for @cbacConsentDisagree.
  ///
  /// In en, this message translates to:
  /// **'DISAGREE'**
  String get cbacConsentDisagree;

  /// No description provided for @cbacConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Consent Form'**
  String get cbacConsentTitle;

  /// No description provided for @cbacD_opt0.
  ///
  /// In en, this message translates to:
  /// **'No way'**
  String get cbacD_opt0;

  /// No description provided for @cbacD_opt1.
  ///
  /// In en, this message translates to:
  /// **'Just a few days'**
  String get cbacD_opt1;

  /// No description provided for @cbacD_opt2.
  ///
  /// In en, this message translates to:
  /// **'More than half a day'**
  String get cbacD_opt2;

  /// No description provided for @cbacD_opt3.
  ///
  /// In en, this message translates to:
  /// **'Almost every day'**
  String get cbacD_opt3;

  /// No description provided for @cbacD_q1.
  ///
  /// In en, this message translates to:
  /// **'Feeling hopeless, depressed'**
  String get cbacD_q1;

  /// No description provided for @cbacD_q2.
  ///
  /// In en, this message translates to:
  /// **'Less interest or pleasure in performing the task'**
  String get cbacD_q2;

  /// No description provided for @cbacFormTitle.
  ///
  /// In en, this message translates to:
  /// **'CBAC Form'**
  String get cbacFormTitle;

  /// No description provided for @cbacHeaderLungRisk.
  ///
  /// In en, this message translates to:
  /// **'Risk factors for lung diseases'**
  String get cbacHeaderLungRisk;

  /// No description provided for @cbacPartAOption1.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get cbacPartAOption1;

  /// No description provided for @cbacPartAOption2.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get cbacPartAOption2;

  /// No description provided for @cbacPartAQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Do you have a cough that brings up phlegm?'**
  String get cbacPartAQuestion1;

  /// No description provided for @cbacPartAQuestion10.
  ///
  /// In en, this message translates to:
  /// **'Do you have a loss of appetite?'**
  String get cbacPartAQuestion10;

  /// No description provided for @cbacPartAQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Do you have a cough that brings up blood?'**
  String get cbacPartAQuestion2;

  /// No description provided for @cbacPartAQuestion3.
  ///
  /// In en, this message translates to:
  /// **'Do you have difficulty breathing?'**
  String get cbacPartAQuestion3;

  /// No description provided for @cbacPartAQuestion4.
  ///
  /// In en, this message translates to:
  /// **'Do you have chest pain or tightness?'**
  String get cbacPartAQuestion4;

  /// No description provided for @cbacPartAQuestion5.
  ///
  /// In en, this message translates to:
  /// **'Do you have a fever?'**
  String get cbacPartAQuestion5;

  /// No description provided for @cbacPartAQuestion6.
  ///
  /// In en, this message translates to:
  /// **'Do you have a headache?'**
  String get cbacPartAQuestion6;

  /// No description provided for @cbacPartAQuestion7.
  ///
  /// In en, this message translates to:
  /// **'Do you have a sore throat?'**
  String get cbacPartAQuestion7;

  /// No description provided for @cbacPartAQuestion8.
  ///
  /// In en, this message translates to:
  /// **'Do you have a runny nose?'**
  String get cbacPartAQuestion8;

  /// No description provided for @cbacPartAQuestion9.
  ///
  /// In en, this message translates to:
  /// **'Do you have a rash?'**
  String get cbacPartAQuestion9;

  /// No description provided for @cbacPartB1.
  ///
  /// In en, this message translates to:
  /// **'Part B1'**
  String get cbacPartB1;

  /// No description provided for @cbacPartB2.
  ///
  /// In en, this message translates to:
  /// **'Part B2'**
  String get cbacPartB2;

  /// No description provided for @cbacPartBOption1.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get cbacPartBOption1;

  /// No description provided for @cbacPartBOption2.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get cbacPartBOption2;

  /// No description provided for @cbacPartBQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Do you smoke?'**
  String get cbacPartBQuestion1;

  /// No description provided for @cbacPartBQuestion10.
  ///
  /// In en, this message translates to:
  /// **'Do you have a history of cancer?'**
  String get cbacPartBQuestion10;

  /// No description provided for @cbacPartBQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Do you drink alcohol?'**
  String get cbacPartBQuestion2;

  /// No description provided for @cbacPartBQuestion3.
  ///
  /// In en, this message translates to:
  /// **'Do you have a family history of lung disease?'**
  String get cbacPartBQuestion3;

  /// No description provided for @cbacPartBQuestion4.
  ///
  /// In en, this message translates to:
  /// **'Do you have a history of lung disease?'**
  String get cbacPartBQuestion4;

  /// No description provided for @cbacPartBQuestion5.
  ///
  /// In en, this message translates to:
  /// **'Do you have a history of heart disease?'**
  String get cbacPartBQuestion5;

  /// No description provided for @cbacPartBQuestion6.
  ///
  /// In en, this message translates to:
  /// **'Do you have a history of diabetes?'**
  String get cbacPartBQuestion6;

  /// No description provided for @cbacPartBQuestion7.
  ///
  /// In en, this message translates to:
  /// **'Do you have a history of high blood pressure?'**
  String get cbacPartBQuestion7;

  /// No description provided for @cbacPartBQuestion8.
  ///
  /// In en, this message translates to:
  /// **'Do you have a history of kidney disease?'**
  String get cbacPartBQuestion8;

  /// No description provided for @cbacPartBQuestion9.
  ///
  /// In en, this message translates to:
  /// **'Do you have a history of liver disease?'**
  String get cbacPartBQuestion9;

  /// No description provided for @cbacPartCOption1.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get cbacPartCOption1;

  /// No description provided for @cbacPartCOption2.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get cbacPartCOption2;

  /// No description provided for @cbacPartCQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Do you have a cough that brings up phlegm?'**
  String get cbacPartCQuestion1;

  /// No description provided for @cbacPartCQuestion10.
  ///
  /// In en, this message translates to:
  /// **'Do you have a loss of appetite?'**
  String get cbacPartCQuestion10;

  /// No description provided for @cbacPartCQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Do you have a cough that brings up blood?'**
  String get cbacPartCQuestion2;

  /// No description provided for @cbacPartCQuestion3.
  ///
  /// In en, this message translates to:
  /// **'Do you have difficulty breathing?'**
  String get cbacPartCQuestion3;

  /// No description provided for @cbacPartCQuestion4.
  ///
  /// In en, this message translates to:
  /// **'Do you have chest pain or tightness?'**
  String get cbacPartCQuestion4;

  /// No description provided for @cbacPartCQuestion5.
  ///
  /// In en, this message translates to:
  /// **'Do you have a fever?'**
  String get cbacPartCQuestion5;

  /// No description provided for @cbacPartCQuestion6.
  ///
  /// In en, this message translates to:
  /// **'Do you have a headache?'**
  String get cbacPartCQuestion6;

  /// No description provided for @cbacPartCQuestion7.
  ///
  /// In en, this message translates to:
  /// **'Do you have a sore throat?'**
  String get cbacPartCQuestion7;

  /// No description provided for @cbacPartCQuestion8.
  ///
  /// In en, this message translates to:
  /// **'Do you have a runny nose?'**
  String get cbacPartCQuestion8;

  /// No description provided for @cbacPartCQuestion9.
  ///
  /// In en, this message translates to:
  /// **'Do you have a rash?'**
  String get cbacPartCQuestion9;

  /// No description provided for @cbacPartDOption1.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get cbacPartDOption1;

  /// No description provided for @cbacPartDOption2.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get cbacPartDOption2;

  /// No description provided for @cbacPartDQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Do you have a cough that brings up phlegm?'**
  String get cbacPartDQuestion1;

  /// No description provided for @cbacPartDQuestion10.
  ///
  /// In en, this message translates to:
  /// **'Do you have a loss of appetite?'**
  String get cbacPartDQuestion10;

  /// No description provided for @cbacPartDQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Do you have a cough that brings up blood?'**
  String get cbacPartDQuestion2;

  /// No description provided for @cbacPartDQuestion3.
  ///
  /// In en, this message translates to:
  /// **'Do you have difficulty breathing?'**
  String get cbacPartDQuestion3;

  /// No description provided for @cbacPartDQuestion4.
  ///
  /// In en, this message translates to:
  /// **'Do you have chest pain or tightness?'**
  String get cbacPartDQuestion4;

  /// No description provided for @cbacPartDQuestion5.
  ///
  /// In en, this message translates to:
  /// **'Do you have a fever?'**
  String get cbacPartDQuestion5;

  /// No description provided for @cbacPartDQuestion6.
  ///
  /// In en, this message translates to:
  /// **'Do you have a headache?'**
  String get cbacPartDQuestion6;

  /// No description provided for @cbacPartDQuestion7.
  ///
  /// In en, this message translates to:
  /// **'Do you have a sore throat?'**
  String get cbacPartDQuestion7;

  /// No description provided for @cbacPartDQuestion8.
  ///
  /// In en, this message translates to:
  /// **'Do you have a runny nose?'**
  String get cbacPartDQuestion8;

  /// No description provided for @cbacPartDQuestion9.
  ///
  /// In en, this message translates to:
  /// **'Do you have a rash?'**
  String get cbacPartDQuestion9;

  /// No description provided for @cbacPleaseFill.
  ///
  /// In en, this message translates to:
  /// **'Please Select'**
  String get cbacPleaseFill;

  /// No description provided for @cbacQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get cbacQuestions;

  /// No description provided for @cbacScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get cbacScore;

  /// No description provided for @cbacTabGeneral.
  ///
  /// In en, this message translates to:
  /// **'GENERAL INFORMATION'**
  String get cbacTabGeneral;

  /// No description provided for @cbacTabPartA.
  ///
  /// In en, this message translates to:
  /// **'PART A'**
  String get cbacTabPartA;

  /// No description provided for @cbacTabPartB.
  ///
  /// In en, this message translates to:
  /// **'PART B'**
  String get cbacTabPartB;

  /// No description provided for @cbacTabPartC.
  ///
  /// In en, this message translates to:
  /// **'PART C'**
  String get cbacTabPartC;

  /// No description provided for @cbacTabPartD.
  ///
  /// In en, this message translates to:
  /// **'PART D'**
  String get cbacTabPartD;

  /// No description provided for @cbacTabPersonal.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFORMATION'**
  String get cbacTabPersonal;

  /// No description provided for @cbacTotalScorePartA.
  ///
  /// In en, this message translates to:
  /// **'Total Score (Part A) {score}'**
  String cbacTotalScorePartA(Object score);

  /// No description provided for @cbacTotalScorePartD.
  ///
  /// In en, this message translates to:
  /// **'Total Score (Part D) {score}'**
  String cbacTotalScorePartD(Object score);

  /// No description provided for @childRegisteredBeneficiaryListTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered Child Beneficiary list'**
  String get childRegisteredBeneficiaryListTitle;

  /// No description provided for @childRegisteredDueListTitle.
  ///
  /// In en, this message translates to:
  /// **'Child Registered Due List'**
  String get childRegisteredDueListTitle;

  /// No description provided for @childTrackingDueListTitle.
  ///
  /// In en, this message translates to:
  /// **'Child Tracking Due List'**
  String get childTrackingDueListTitle;

  /// No description provided for @searchHintchildTrackingDueListTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Child Tracking Due'**
  String get searchHintchildTrackingDueListTitle;

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

  /// No description provided for @childrenDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Children Details'**
  String get childrenDetailsTitle;

  /// No description provided for @choMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of CHO'**
  String get choMobileHint;

  /// No description provided for @choMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of CHO'**
  String get choMobileLabel;

  /// No description provided for @choNameHint.
  ///
  /// In en, this message translates to:
  /// **'CHO Name'**
  String get choNameHint;

  /// No description provided for @choNameLabel.
  ///
  /// In en, this message translates to:
  /// **'CHO Name'**
  String get choNameLabel;

  /// No description provided for @completedVisits.
  ///
  /// In en, this message translates to:
  /// **'Completed visits'**
  String get completedVisits;

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactLabel;

  /// No description provided for @cookingFuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking Fuel'**
  String get cookingFuelTitle;

  /// No description provided for @cookingFuelTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of Fuel used for cooking'**
  String get cookingFuelTypeLabel;

  /// No description provided for @currentAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Current age (in years)'**
  String get currentAgeLabel;

  /// No description provided for @currentPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Current password cannot be empty'**
  String get currentPasswordEmpty;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get currentPasswordHint;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @dateHint.
  ///
  /// In en, this message translates to:
  /// **'dd-mm-yyyy'**
  String get dateHint;

  /// No description provided for @dateOfInspectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of inspection *'**
  String get dateOfInspectionLabel;

  /// No description provided for @daughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get daughter;

  /// No description provided for @dcmMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get dcmMobileHint;

  /// No description provided for @dcmMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of District Community Mobilizer'**
  String get dcmMobileLabel;

  /// No description provided for @dcmNameHint.
  ///
  /// In en, this message translates to:
  /// **'District Community Mobilizer name'**
  String get dcmNameHint;

  /// No description provided for @dcmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'District Community Mobilizer name'**
  String get dcmNameLabel;

  /// No description provided for @deceasedChildSnack.
  ///
  /// In en, this message translates to:
  /// **'Deceased Child'**
  String get deceasedChildSnack;

  /// No description provided for @deceasedChildTitle.
  ///
  /// In en, this message translates to:
  /// **'Deceased Child'**
  String get deceasedChildTitle;

  /// No description provided for @declarationIntro.
  ///
  /// In en, this message translates to:
  /// **'I hereby declare that:'**
  String get declarationIntro;

  /// No description provided for @deliveryOutcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery\nOutcome'**
  String get deliveryOutcomeTitle;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @diastolicLabel.
  ///
  /// In en, this message translates to:
  /// **'Diastolic'**
  String get diastolicLabel;

  /// No description provided for @disabilityBedridden.
  ///
  /// In en, this message translates to:
  /// **'Bedridden due to some illness'**
  String get disabilityBedridden;

  /// No description provided for @disabilityNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need for help from another person to perform daily tasks'**
  String get disabilityNeedHelp;

  /// No description provided for @disabilityPhysicallyHandicap.
  ///
  /// In en, this message translates to:
  /// **'Physically Handicap'**
  String get disabilityPhysicallyHandicap;

  /// No description provided for @disabilityQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Whether the person has one of the following'**
  String get disabilityQuestionLabel;

  /// No description provided for @disabilityVisualImpairment.
  ///
  /// In en, this message translates to:
  /// **'Visual impairment'**
  String get disabilityVisualImpairment;

  /// No description provided for @diseaseAnemia.
  ///
  /// In en, this message translates to:
  /// **'Anemia'**
  String get diseaseAnemia;

  /// No description provided for @diseaseDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Diabetes'**
  String get diseaseDiabetes;

  /// No description provided for @diseaseHypertension.
  ///
  /// In en, this message translates to:
  /// **'Hypertension'**
  String get diseaseHypertension;

  /// No description provided for @diseaseNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get diseaseNone;

  /// No description provided for @diseaseOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get diseaseOther;

  /// No description provided for @districtHint.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtHint;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @districtLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabelSimple;

  /// No description provided for @divisionHint.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get divisionHint;

  /// No description provided for @divisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get divisionLabel;

  /// No description provided for @divorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get divorced;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dobLabel;

  /// No description provided for @dobShort.
  ///
  /// In en, this message translates to:
  /// **'DOB'**
  String get dobShort;

  /// No description provided for @dojLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Joining'**
  String get dojLabel;

  /// No description provided for @drawerAboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get drawerAboutUs;

  /// No description provided for @drawerFetchData.
  ///
  /// In en, this message translates to:
  /// **'Fetch Data'**
  String get drawerFetchData;

  /// No description provided for @drawerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// No description provided for @drawerIncentivePortal.
  ///
  /// In en, this message translates to:
  /// **'Incentive Portal'**
  String get drawerIncentivePortal;

  /// No description provided for @drawerLogout.
  ///
  /// In en, this message translates to:
  /// **'LOGOUT'**
  String get drawerLogout;

  /// No description provided for @drawerMisReport.
  ///
  /// In en, this message translates to:
  /// **'MIS Report'**
  String get drawerMisReport;

  /// No description provided for @drawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get drawerProfile;

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

  /// No description provided for @drawerSyncedData.
  ///
  /// In en, this message translates to:
  /// **'Synced Data'**
  String get drawerSyncedData;

  /// No description provided for @economicStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Economic Status'**
  String get economicStatusLabel;

  /// No description provided for @eddDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected date of delivery (EDD)'**
  String get eddDateLabel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @educationGraduate.
  ///
  /// In en, this message translates to:
  /// **'Graduate'**
  String get educationGraduate;

  /// No description provided for @educationLabel.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get educationLabel;

  /// No description provided for @educationPostgraduate.
  ///
  /// In en, this message translates to:
  /// **'Postgraduate'**
  String get educationPostgraduate;

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

  /// No description provided for @elderlyAbove65.
  ///
  /// In en, this message translates to:
  /// **'Elderly (>65 Y)'**
  String get elderlyAbove65;

  /// No description provided for @elecGenerator.
  ///
  /// In en, this message translates to:
  /// **'Generator'**
  String get elecGenerator;

  /// No description provided for @householdSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Total beneficiaries: {count}'**
  String householdSavedSuccessfully(Object count);

  /// No description provided for @dataSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data saved successfully!'**
  String get dataSavedSuccessfully;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get closeButton;

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

  /// No description provided for @elecSolar.
  ///
  /// In en, this message translates to:
  /// **'Solar Power'**
  String get elecSolar;

  /// No description provided for @elecSupply.
  ///
  /// In en, this message translates to:
  /// **'Electricity Supply'**
  String get elecSupply;

  /// No description provided for @electricityAvailabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability of electricity'**
  String get electricityAvailabilityLabel;

  /// No description provided for @electricityTitle.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get electricityTitle;

  /// No description provided for @eligibleCoupleListDownload.
  ///
  /// In en, this message translates to:
  /// **'Download eligible couple list'**
  String get eligibleCoupleListDownload;

  /// No description provided for @eligibleCoupleListFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter eligible couples'**
  String get eligibleCoupleListFilter;

  /// No description provided for @eligibleCoupleListLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading eligible couples...'**
  String get eligibleCoupleListLoading;

  /// No description provided for @eligibleCoupleListNoData.
  ///
  /// In en, this message translates to:
  /// **'No eligible couples found'**
  String get eligibleCoupleListNoData;

  /// No description provided for @eligibleCoupleListRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh eligible couple list'**
  String get eligibleCoupleListRefresh;

  /// No description provided for @eligibleCoupleListSearch.
  ///
  /// In en, this message translates to:
  /// **'Search eligible couples'**
  String get eligibleCoupleListSearch;

  /// No description provided for @eligibleCoupleListSort.
  ///
  /// In en, this message translates to:
  /// **'Sort eligible couples'**
  String get eligibleCoupleListSort;

  /// No description provided for @eligibleCoupleUpdateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading eligible couple...'**
  String get eligibleCoupleUpdateLoading;

  /// No description provided for @eligibleCoupleUpdateNoData.
  ///
  /// In en, this message translates to:
  /// **'No eligible couple found'**
  String get eligibleCoupleUpdateNoData;

  /// No description provided for @eligibleCoupleUpdateSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search eligible couple to update'**
  String get eligibleCoupleUpdateSearchHint;

  /// No description provided for @eligibleCoupleUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update eligible couple details'**
  String get eligibleCoupleUpdateSubtitle;

  /// No description provided for @eligibleCoupleUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple Update'**
  String get eligibleCoupleUpdateTitle;

  /// No description provided for @eligibleCouples.
  ///
  /// In en, this message translates to:
  /// **'Eligible couples'**
  String get eligibleCouples;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get emailLabel;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @enterValidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter valid mobile'**
  String get enterValidMobile;

  /// No description provided for @familyHeadDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Head Details'**
  String get familyHeadDetailsTitle;

  /// No description provided for @father.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get father;

  /// No description provided for @fatherGuardianNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Father/Guardian Name'**
  String get fatherGuardianNameLabel;

  /// No description provided for @fatherInLaw.
  ///
  /// In en, this message translates to:
  /// **'Father in Law'**
  String get fatherInLaw;

  /// No description provided for @fatherNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Father name'**
  String get fatherNameLabel;

  /// No description provided for @fatherSpouseHint.
  ///
  /// In en, this message translates to:
  /// **'Father/Spouse Name'**
  String get fatherSpouseHint;

  /// No description provided for @fatherSpouseLabel.
  ///
  /// In en, this message translates to:
  /// **'Father/Spouse Name'**
  String get fatherSpouseLabel;

  /// No description provided for @finalizeClaimedAmount.
  ///
  /// In en, this message translates to:
  /// **'Claimed Amount'**
  String get finalizeClaimedAmount;

  /// No description provided for @finalizeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get finalizeSave;

  /// No description provided for @finalizeStateAmount.
  ///
  /// In en, this message translates to:
  /// **'State Amount'**
  String get finalizeStateAmount;

  /// No description provided for @finalizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Final Incentive Portal'**
  String get finalizeTitle;

  /// No description provided for @finalizeTotalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount:'**
  String get finalizeTotalAmountLabel;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get finishButton;

  /// No description provided for @firstAncLabel.
  ///
  /// In en, this message translates to:
  /// **'First ANC'**
  String get firstAncLabel;

  /// No description provided for @folicAcidTabletsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Folic Acid tablets given'**
  String get folicAcidTabletsLabel;

  /// No description provided for @fpAdoptingLabel.
  ///
  /// In en, this message translates to:
  /// **'Are you/your partner adopting family planning?'**
  String get fpAdoptingLabel;

  /// No description provided for @fpMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Family Planning Method'**
  String get fpMethodLabel;

  /// No description provided for @fruNameHint.
  ///
  /// In en, this message translates to:
  /// **'FRU name'**
  String get fruNameHint;

  /// No description provided for @fruNameLabel.
  ///
  /// In en, this message translates to:
  /// **'FRU name'**
  String get fruNameLabel;

  /// No description provided for @fuelCoal.
  ///
  /// In en, this message translates to:
  /// **'Coal'**
  String get fuelCoal;

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

  /// No description provided for @fuelFirewood.
  ///
  /// In en, this message translates to:
  /// **'Firewood'**
  String get fuelFirewood;

  /// No description provided for @fuelKerosene.
  ///
  /// In en, this message translates to:
  /// **'Kerosene'**
  String get fuelKerosene;

  /// No description provided for @fuelLpg.
  ///
  /// In en, this message translates to:
  /// **'LPG'**
  String get fuelLpg;

  /// No description provided for @fuelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get fuelOther;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @generateOtp.
  ///
  /// In en, this message translates to:
  /// **'GENERATE OTP'**
  String get generateOtp;

  /// No description provided for @gridAbhaGeneration.
  ///
  /// In en, this message translates to:
  /// **'Abha Generation'**
  String get gridAbhaGeneration;

  /// No description provided for @gridAllBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'All Beneficiaries'**
  String get gridAllBeneficiaries;

  /// No description provided for @searchBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'Beneficiaries Search'**
  String get searchBeneficiaries;

  /// No description provided for @gridAllHousehold.
  ///
  /// In en, this message translates to:
  /// **'All Household'**
  String get gridAllHousehold;

  /// No description provided for @searchHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household Search'**
  String get searchHousehold;

  /// No description provided for @gridAshaKiDuniya.
  ///
  /// In en, this message translates to:
  /// **'Asha ki Duniya'**
  String get gridAshaKiDuniya;

  /// No description provided for @gridChildCare.
  ///
  /// In en, this message translates to:
  /// **'Child Care'**
  String get gridChildCare;

  /// No description provided for @hintTemp.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get hintTemp;

  /// No description provided for @gridEligibleCouple.
  ///
  /// In en, this message translates to:
  /// **'Number Of Eligible Couple Identified'**
  String get gridEligibleCouple;

  /// No description provided for @gridEligibleCoupleASHA.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple'**
  String get gridEligibleCoupleASHA;

  /// No description provided for @gridHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High-Risk'**
  String get gridHighRisk;

  /// No description provided for @gridMotherCare.
  ///
  /// In en, this message translates to:
  /// **'Mother Care'**
  String get gridMotherCare;

  /// No description provided for @gridMyBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'My Beneficiaries'**
  String get gridMyBeneficiaries;

  /// No description provided for @gridRegisterNewHousehold.
  ///
  /// In en, this message translates to:
  /// **'Register New Household'**
  String get gridRegisterNewHousehold;

  /// No description provided for @gridNewHouseholdRegister.
  ///
  /// In en, this message translates to:
  /// **'New Household Registration'**
  String get gridNewHouseholdRegister;

  /// No description provided for @gridTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get gridTraining;

  /// No description provided for @gridWorkProgress.
  ///
  /// In en, this message translates to:
  /// **'Work Progress'**
  String get gridWorkProgress;

  /// No description provided for @guestSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest Beneficiary Search'**
  String get guestSearchTitle;

  /// No description provided for @haveChildrenQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you have children?'**
  String get haveChildrenQuestion;

  /// No description provided for @hbncListTitle.
  ///
  /// In en, this message translates to:
  /// **'HBNC List'**
  String get hbncListTitle;

  /// No description provided for @hbncMotherTitle.
  ///
  /// In en, this message translates to:
  /// **'HBNC Mother'**
  String get hbncMotherTitle;

  /// No description provided for @hbycAdviceAdministeringIfaSyrupLabel.
  ///
  /// In en, this message translates to:
  /// **'Counsel mother on how to measure the correct millilitres dose of IFA syrup'**
  String get hbycAdviceAdministeringIfaSyrupLabel;

  /// No description provided for @hbycAdviceComplementaryFoodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Advice on introducing complementary foods'**
  String get hbycAdviceComplementaryFoodsLabel;

  /// No description provided for @hbycAdviceHandWashingHygieneLabel.
  ///
  /// In en, this message translates to:
  /// **'Advice on hand washing and hygienic practices'**
  String get hbycAdviceHandWashingHygieneLabel;

  /// No description provided for @hbycAdviceParentingSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Advice about parenting (parenting support)'**
  String get hbycAdviceParentingSupportLabel;

  /// No description provided for @hbycAdvicePreparingAdministeringOrsLabel.
  ///
  /// In en, this message translates to:
  /// **'Assisted mother on Steps to prepare ORS at home and serve to child'**
  String get hbycAdvicePreparingAdministeringOrsLabel;

  /// No description provided for @hbycBhramanLabel.
  ///
  /// In en, this message translates to:
  /// **'HBYC home visit'**
  String get hbycBhramanLabel;

  /// No description provided for @hbycBhramanRequired.
  ///
  /// In en, this message translates to:
  /// **'HBYC home visit'**
  String get hbycBhramanRequired;

  /// No description provided for @hbycBreastfeedingContinuingLabel.
  ///
  /// In en, this message translates to:
  /// **'Breastfeeding continuing?'**
  String get hbycBreastfeedingContinuingLabel;

  /// No description provided for @hbycCompleteDietProvidedLabel.
  ///
  /// In en, this message translates to:
  /// **'Was a complete diet provided?'**
  String get hbycCompleteDietProvidedLabel;

  /// No description provided for @hbycCompletionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of completion of HBYC visit activities'**
  String get hbycCompletionDateLabel;

  /// No description provided for @hbycCounselingExclusiveBf6mLabel.
  ///
  /// In en, this message translates to:
  /// **'Counseling on exclusive breastfeeding for 6 months'**
  String get hbycCounselingExclusiveBf6mLabel;

  /// No description provided for @hbycCounselingFamilyPlanningLabel.
  ///
  /// In en, this message translates to:
  /// **'Counseling about family planning'**
  String get hbycCounselingFamilyPlanningLabel;

  /// No description provided for @hbycDevelopmentDelaysObservedLabel.
  ///
  /// In en, this message translates to:
  /// **'Delays/obstacles observed (development)?'**
  String get hbycDevelopmentDelaysObservedLabel;

  /// No description provided for @hbycFullyVaccinatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Fully vaccinated as per MCP card?'**
  String get hbycFullyVaccinatedLabel;

  /// No description provided for @hbycIronFolicSyrupAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **' iron folic acid syrup available at home?'**
  String get hbycIronFolicSyrupAvailableLabel;

  /// No description provided for @hbycIsChildSickLabel.
  ///
  /// In en, this message translates to:
  /// **'Whether child is sick?'**
  String get hbycIsChildSickLabel;

  /// No description provided for @hbycLengthHeightRecordedLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the length/height been recorded based on weight by AWW?'**
  String get hbycLengthHeightRecordedLabel;

  /// No description provided for @hbycListTitle.
  ///
  /// In en, this message translates to:
  /// **'HBYC List'**
  String get hbycListTitle;

  /// No description provided for @hbycMeaslesVaccineGivenLabel.
  ///
  /// In en, this message translates to:
  /// **'Measles vaccine given?'**
  String get hbycMeaslesVaccineGivenLabel;

  /// No description provided for @hbycOrsPacketAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **' ORS available at home?'**
  String get hbycOrsPacketAvailableLabel;

  /// No description provided for @hbycTitleDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hbycTitleDetails;

  /// No description provided for @hbycVitaminADosageGivenLabel.
  ///
  /// In en, this message translates to:
  /// **'Vitamin A  given?'**
  String get hbycVitaminADosageGivenLabel;

  /// No description provided for @hbycWeighedByAwwLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording of weight for-age by Anganwadi Worker?'**
  String get hbycWeighedByAwwLabel;

  /// No description provided for @hbycWeightLessThan3sdLabel.
  ///
  /// In en, this message translates to:
  /// **'Child with <3SD weight-for-length/height referred?'**
  String get hbycWeightLessThan3sdLabel;

  /// No description provided for @healthWorkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Health Worker'**
  String get healthWorkerLabel;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please call on below help numbers for any help and assistance.'**
  String get helpInstructions;

  /// No description provided for @hemoglobinLabel.
  ///
  /// In en, this message translates to:
  /// **'Hemoglobin (HB)'**
  String get hemoglobinLabel;

  /// No description provided for @hhIdLabel.
  ///
  /// In en, this message translates to:
  /// **'HH ID'**
  String get hhIdLabel;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'BHAVYA mASHA Home'**
  String get homeTitle;

  /// No description provided for @houseKachcha.
  ///
  /// In en, this message translates to:
  /// **'Kuchcha house'**
  String get houseKachcha;

  /// No description provided for @houseNoHint.
  ///
  /// In en, this message translates to:
  /// **'House no'**
  String get houseNoHint;

  /// No description provided for @houseNoLabel.
  ///
  /// In en, this message translates to:
  /// **'House no'**
  String get houseNoLabel;

  /// No description provided for @houseNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get houseNone;

  /// No description provided for @houseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'House number'**
  String get houseNumberLabel;

  /// No description provided for @housePucca.
  ///
  /// In en, this message translates to:
  /// **'Pucca house'**
  String get housePucca;

  /// No description provided for @houseSemiPucca.
  ///
  /// In en, this message translates to:
  /// **'Semi Pucca house'**
  String get houseSemiPucca;

  /// No description provided for @houseThatch.
  ///
  /// In en, this message translates to:
  /// **'Thrust house'**
  String get houseThatch;

  /// No description provided for @houseTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of house'**
  String get houseTypeLabel;

  /// No description provided for @householdBeneficiarySearch.
  ///
  /// In en, this message translates to:
  /// **'Household Beneficiary Search'**
  String get householdBeneficiarySearch;

  /// No description provided for @householdBeneficiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Household Beneficiary'**
  String get householdBeneficiaryTitle;

  /// No description provided for @husbandFatherNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Husband / Father Name'**
  String get husbandFatherNameLabel;

  /// No description provided for @husbandLabel.
  ///
  /// In en, this message translates to:
  /// **'Husband'**
  String get husbandLabel;

  /// No description provided for @husbandNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Husband\'s name'**
  String get husbandNameLabel;

  /// No description provided for @idTypeAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar card'**
  String get idTypeAadhaar;

  /// No description provided for @idTypeRationCard.
  ///
  /// In en, this message translates to:
  /// **'Ration Card'**
  String get idTypeRationCard;

  /// No description provided for @uid.
  ///
  /// In en, this message translates to:
  /// **'UID'**
  String get uid;

  /// No description provided for @idTypeStateInsurance.
  ///
  /// In en, this message translates to:
  /// **'Affiliated to State Health Insurance Scheme'**
  String get idTypeStateInsurance;

  /// No description provided for @idTypeVoterId.
  ///
  /// In en, this message translates to:
  /// **'Voter Card'**
  String get idTypeVoterId;

  /// No description provided for @identificationTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Identification type'**
  String get identificationTypeLabel;

  /// No description provided for @ifscHint.
  ///
  /// In en, this message translates to:
  /// **'IFSC code'**
  String get ifscHint;

  /// No description provided for @ifscLabel.
  ///
  /// In en, this message translates to:
  /// **'IFSC code'**
  String get ifscLabel;

  /// No description provided for @incentiveFinancialMonth.
  ///
  /// In en, this message translates to:
  /// **'Financial month'**
  String get incentiveFinancialMonth;

  /// No description provided for @incentiveFinancialYear.
  ///
  /// In en, this message translates to:
  /// **'Financial year'**
  String get incentiveFinancialYear;

  /// No description provided for @incentiveHeaderAnganwadi.
  ///
  /// In en, this message translates to:
  /// **'Anganwadi'**
  String get incentiveHeaderAnganwadi;

  /// No description provided for @incentiveDailyTabPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Daily tasks content here'**
  String get incentiveDailyTabPlaceholder;

  /// No description provided for @incentiveFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Incentive Form'**
  String get incentiveFormTitle;

  /// No description provided for @incentiveFormWorkCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Work code :'**
  String get incentiveFormWorkCodeLabel;

  /// No description provided for @incentiveFormWorkCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter work code'**
  String get incentiveFormWorkCodeHint;

  /// No description provided for @incentiveFormCategoryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Category type : [*]'**
  String get incentiveFormCategoryTypeLabel;

  /// No description provided for @incentiveFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Work category : [*]'**
  String get incentiveFormCategoryLabel;

  /// No description provided for @incentiveFormWorkLabel.
  ///
  /// In en, this message translates to:
  /// **'Work : [*]'**
  String get incentiveFormWorkLabel;

  /// No description provided for @incentiveFormWorkHint.
  ///
  /// In en, this message translates to:
  /// **'Select work'**
  String get incentiveFormWorkHint;

  /// No description provided for @incentiveFormBeneficiaryCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of beneficiaries : [*]'**
  String get incentiveFormBeneficiaryCountLabel;

  /// No description provided for @incentiveFormBeneficiaryCountHint.
  ///
  /// In en, this message translates to:
  /// **'Number of beneficiaries'**
  String get incentiveFormBeneficiaryCountHint;

  /// No description provided for @incentiveFormWorkAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Work amount : [*]'**
  String get incentiveFormWorkAmountLabel;

  /// No description provided for @incentiveFormWorkAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Work amount'**
  String get incentiveFormWorkAmountHint;

  /// No description provided for @incentiveFormClaimedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Claimed amount : [*]'**
  String get incentiveFormClaimedAmountLabel;

  /// No description provided for @incentiveFormClaimedAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Claimed amount'**
  String get incentiveFormClaimedAmountHint;

  /// No description provided for @incentiveFormCompletionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Work completion date : [*]'**
  String get incentiveFormCompletionDateLabel;

  /// No description provided for @incentiveFormCompletionDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get incentiveFormCompletionDateHint;

  /// No description provided for @incentiveFormRegisterNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Register name : [*]'**
  String get incentiveFormRegisterNameLabel;

  /// No description provided for @incentiveFormVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume : [*]'**
  String get incentiveFormVolumeLabel;

  /// No description provided for @incentiveFormRegisterDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Register date : [*]'**
  String get incentiveFormRegisterDateLabel;

  /// No description provided for @incentiveFormRegisterDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get incentiveFormRegisterDateHint;

  /// No description provided for @incentiveFormRemarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Remark : [*]'**
  String get incentiveFormRemarkLabel;

  /// No description provided for @incentiveFormRemarkHint.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get incentiveFormRemarkHint;

  /// No description provided for @incentiveHeaderBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get incentiveHeaderBlock;

  /// No description provided for @incentiveHeaderDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get incentiveHeaderDistrict;

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

  /// No description provided for @incentiveNote.
  ///
  /// In en, this message translates to:
  /// **'Submit monthly incentive claim files between 28th and 30th of next month.'**
  String get incentiveNote;

  /// No description provided for @incentiveTabDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily tasks'**
  String get incentiveTabDaily;

  /// No description provided for @incentiveTabFinalize.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get incentiveTabFinalize;

  /// No description provided for @incentiveTabMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly tasks'**
  String get incentiveTabMonthly;

  /// No description provided for @incentiveTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount (daily + monthly): ₹{amount}'**
  String incentiveTotalAmount(Object amount);

  /// No description provided for @isPregnantLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the woman pregnant?'**
  String get isPregnantLabel;

  /// No description provided for @isWomanBreastfeedingLabel.
  ///
  /// In en, this message translates to:
  /// **'Is woman breastfeeding?'**
  String get isWomanBreastfeedingLabel;

  /// No description provided for @isWomanPregnantQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is the Woman Pregnant?'**
  String get isWomanPregnantQuestion;

  /// No description provided for @kitchenInsideLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the kitchen inside the house'**
  String get kitchenInsideLabel;

  /// No description provided for @legendCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get legendCompleted;

  /// No description provided for @legendPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get legendPending;

  /// No description provided for @linkHealthRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Health Records'**
  String get linkHealthRecordsTitle;

  /// No description provided for @linkedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Linked successfully'**
  String get linkedSuccessfully;

  /// No description provided for @listANC.
  ///
  /// In en, this message translates to:
  /// **'ANC List'**
  String get listANC;

  /// No description provided for @listEligibleCoupleDue.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple Due List'**
  String get listEligibleCoupleDue;

  /// No description provided for @listFamilySurvey.
  ///
  /// In en, this message translates to:
  /// **'Family Survey List'**
  String get listFamilySurvey;

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

  /// No description provided for @lmpDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of last menstrual period (LMP) *'**
  String get lmpDateLabel;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Login to continue'**
  String get loginToContinue;

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

  /// No description provided for @memberTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Member type'**
  String get memberTypeLabel;

  /// No description provided for @misMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month : '**
  String get misMonthLabel;

  /// No description provided for @misStatAbhaFetched.
  ///
  /// In en, this message translates to:
  /// **'Total number of Exisiting ABHA fetched by user :'**
  String get misStatAbhaFetched;

  /// No description provided for @misStatAbhaGenerated.
  ///
  /// In en, this message translates to:
  /// **'Total number of ABHA generated by user :'**
  String get misStatAbhaGenerated;

  /// No description provided for @misStatNewborns.
  ///
  /// In en, this message translates to:
  /// **'Total number of newborns :'**
  String get misStatNewborns;

  /// No description provided for @misStatPregnantWomen.
  ///
  /// In en, this message translates to:
  /// **'Number of total Pregnant Women :'**
  String get misStatPregnantWomen;

  /// No description provided for @mobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get mobileHint;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get mobileLabel;

  /// No description provided for @mobileLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'Mobile no.'**
  String get mobileLabelSimple;

  /// No description provided for @mobileTelephoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile/Telephone Number'**
  String get mobileTelephoneLabel;

  /// No description provided for @mohallaTolaNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Mohalla/Tola name'**
  String get mohallaTolaNameLabel;

  /// No description provided for @monthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// No description provided for @monthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// No description provided for @monthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// No description provided for @monthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// No description provided for @monthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// No description provided for @monthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// No description provided for @monthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// No description provided for @monthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// No description provided for @monthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// No description provided for @monthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// No description provided for @monthlySectionRoutineRecurring.
  ///
  /// In en, this message translates to:
  /// **'Routine & Recurring'**
  String get monthlySectionRoutineRecurring;

  /// No description provided for @monthlySectionStateContribution.
  ///
  /// In en, this message translates to:
  /// **'State Contribution'**
  String get monthlySectionStateContribution;

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

  /// No description provided for @mother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get mother;

  /// No description provided for @motherAncVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'ANC Visit'**
  String get motherAncVisitTitle;

  /// No description provided for @motherInLaw.
  ///
  /// In en, this message translates to:
  /// **'Mother in Law'**
  String get motherInLaw;

  /// No description provided for @motherNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother Name'**
  String get motherNameLabel;

  /// No description provided for @mukhiyaMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of mukhiya'**
  String get mukhiyaMobileHint;

  /// No description provided for @mukhiyaMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. of mukhiya'**
  String get mukhiyaMobileLabel;

  /// No description provided for @mukhiyaNameHint.
  ///
  /// In en, this message translates to:
  /// **'Village mukhiya name'**
  String get mukhiyaNameHint;

  /// No description provided for @mukhiyaNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Village mukhiya name'**
  String get mukhiyaNameLabel;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameLabelSimple.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabelSimple;

  /// No description provided for @nameOfFamilyHeadHint.
  ///
  /// In en, this message translates to:
  /// **'Name of family head'**
  String get nameOfFamilyHeadHint;

  /// No description provided for @nameOfFamilyHeadLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of family head'**
  String get nameOfFamilyHeadLabel;

  /// No description provided for @nameOfMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of member'**
  String get nameOfMemberLabel;

  /// No description provided for @nameOfPregnantWomanLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of Pregnant Woman'**
  String get nameOfPregnantWomanLabel;

  /// No description provided for @nameOfWomanLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of woman'**
  String get nameOfWomanLabel;

  /// No description provided for @ncd.
  ///
  /// In en, this message translates to:
  /// **'NCD'**
  String get ncd;

  /// No description provided for @neighbour.
  ///
  /// In en, this message translates to:
  /// **'Neighbour'**
  String get neighbour;

  /// No description provided for @newMemberDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'New Member Details'**
  String get newMemberDetailsTitle;

  /// No description provided for @newPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'New password cannot be empty'**
  String get newPasswordEmpty;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get newPasswordHint;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get newPasswordTooShort;

  /// No description provided for @noHbncVisits.
  ///
  /// In en, this message translates to:
  /// **'No HBNC visits found'**
  String get noHbncVisits;

  /// No description provided for @noPreviousVisits.
  ///
  /// In en, this message translates to:
  /// **'No previous visits found'**
  String get noPreviousVisits;

  /// No description provided for @noRecordFound.
  ///
  /// In en, this message translates to:
  /// **'No Record Found.'**
  String get noRecordFound;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @occupationEmployed.
  ///
  /// In en, this message translates to:
  /// **'Employed'**
  String get occupationEmployed;

  /// No description provided for @occupationLabel.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get occupationLabel;

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

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @orderOfPregnancyLabel.
  ///
  /// In en, this message translates to:
  /// **'Order of Pregnancy(Gravida)'**
  String get orderOfPregnancyLabel;

  /// No description provided for @otpGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'OTP generated successfully'**
  String get otpGeneratedSuccess;

  /// No description provided for @ownershipTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of ownership'**
  String get ownershipTypeLabel;

  /// No description provided for @panchayatHint.
  ///
  /// In en, this message translates to:
  /// **'Panchayat'**
  String get panchayatHint;

  /// No description provided for @panchayatLabel.
  ///
  /// In en, this message translates to:
  /// **'Panchayat'**
  String get panchayatLabel;

  /// No description provided for @passwordComplexity.
  ///
  /// In en, this message translates to:
  /// **'Password must contain letters, numbers, and special characters'**
  String get passwordComplexity;

  /// No description provided for @passwordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordEmpty;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @personalHealthIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Personal Health Id'**
  String get personalHealthIdLabel;

  /// No description provided for @phcChcHint.
  ///
  /// In en, this message translates to:
  /// **'PHC/CHC'**
  String get phcChcHint;

  /// No description provided for @phcChcLabel.
  ///
  /// In en, this message translates to:
  /// **'PHC/CHC'**
  String get phcChcLabel;

  /// No description provided for @phcNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of Primary Health Center'**
  String get phcNameLabel;

  /// No description provided for @pincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincodeLabel;

  /// No description provided for @placeOfAncLabel.
  ///
  /// In en, this message translates to:
  /// **'Place of ANC'**
  String get placeOfAncLabel;

  /// No description provided for @pmsmaLabel.
  ///
  /// In en, this message translates to:
  /// **'PMSMA'**
  String get pmsmaLabel;

  /// No description provided for @populationCoveredHint.
  ///
  /// In en, this message translates to:
  /// **'Population covered under ASHA'**
  String get populationCoveredHint;

  /// No description provided for @populationCoveredLabel.
  ///
  /// In en, this message translates to:
  /// **'Population covered under ASHA'**
  String get populationCoveredLabel;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered By Medixcel Lite © '**
  String get poweredBy;

  /// No description provided for @preExistingDiseaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pre - Existing disease'**
  String get preExistingDiseaseLabel;

  /// No description provided for @previousVisitsButton.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS VISITS'**
  String get previousVisitsButton;

  /// No description provided for @primaryWaterSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary source of water'**
  String get primaryWaterSourceLabel;

  /// No description provided for @proceedButton.
  ///
  /// In en, this message translates to:
  /// **'PROCEED'**
  String get proceedButton;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @rationCardIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Ration Card Id'**
  String get rationCardIdLabel;

  /// No description provided for @rchIdLabel.
  ///
  /// In en, this message translates to:
  /// **'RCH ID'**
  String get rchIdLabel;

  /// No description provided for @rchNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'RCH number'**
  String get rchNumberLabel;

  /// No description provided for @submissionCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Form Submfvissions'**
  String get submissionCountLabel;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @reenterPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password cannot be empty'**
  String get reenterPasswordEmpty;

  /// No description provided for @reenterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get reenterPasswordHint;

  /// No description provided for @reenterPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Re-Enter Password'**
  String get reenterPasswordLabel;

  /// No description provided for @reenterPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get reenterPasswordTooShort;

  /// No description provided for @registrationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Date'**
  String get registrationDateLabel;

  /// No description provided for @registrationThroughTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration through'**
  String get registrationThroughTitle;

  /// No description provided for @registrationTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Type'**
  String get registrationTypeLabel;

  /// No description provided for @relationBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get relationBrother;

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

  /// No description provided for @relationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationOther;

  /// No description provided for @relationSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get relationSister;

  /// No description provided for @relationSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get relationSon;

  /// No description provided for @relationSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relationSpouse;

  /// No description provided for @relationNephew.
  ///
  /// In en, this message translates to:
  /// **'Nephew'**
  String get relationNephew;

  /// No description provided for @relationNiece.
  ///
  /// In en, this message translates to:
  /// **'Niece'**
  String get relationNiece;

  /// No description provided for @relationGrandFather.
  ///
  /// In en, this message translates to:
  /// **'Grand Father'**
  String get relationGrandFather;

  /// No description provided for @relationGrandMother.
  ///
  /// In en, this message translates to:
  /// **'Grand Mother'**
  String get relationGrandMother;

  /// No description provided for @relationFatherInLaw.
  ///
  /// In en, this message translates to:
  /// **'Father In Law'**
  String get relationFatherInLaw;

  /// No description provided for @relationMotherInLaw.
  ///
  /// In en, this message translates to:
  /// **'Mother In Law'**
  String get relationMotherInLaw;

  /// No description provided for @relationGrandSon.
  ///
  /// In en, this message translates to:
  /// **'Grand Son'**
  String get relationGrandSon;

  /// No description provided for @relationGrandDaughter.
  ///
  /// In en, this message translates to:
  /// **'Grand Daughter'**
  String get relationGrandDaughter;

  /// No description provided for @relationSonInLaw.
  ///
  /// In en, this message translates to:
  /// **'Son In Law'**
  String get relationSonInLaw;

  /// No description provided for @relationDaughterInLaw.
  ///
  /// In en, this message translates to:
  /// **'Daughter In Law'**
  String get relationDaughterInLaw;

  /// No description provided for @relationWithHeadLabel.
  ///
  /// In en, this message translates to:
  /// **'Relation with the family head'**
  String get relationWithHeadLabel;

  /// No description provided for @relative.
  ///
  /// In en, this message translates to:
  /// **'Relative'**
  String get relative;

  /// No description provided for @religionChristian.
  ///
  /// In en, this message translates to:
  /// **'Christian'**
  String get religionChristian;

  /// No description provided for @religionHindu.
  ///
  /// In en, this message translates to:
  /// **'Hindu'**
  String get religionHindu;

  /// No description provided for @religionLabel.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get religionLabel;

  /// No description provided for @religionMuslim.
  ///
  /// In en, this message translates to:
  /// **'Muslim'**
  String get religionMuslim;

  /// No description provided for @religionSikh.
  ///
  /// In en, this message translates to:
  /// **'Sikh'**
  String get religionSikh;

  /// No description provided for @remarksLabel.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarksLabel;

  /// No description provided for @rental.
  ///
  /// In en, this message translates to:
  /// **'Rental'**
  String get rental;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @resetCreateNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get resetCreateNewPasswordTitle;

  /// No description provided for @residentialAreaTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of residential area'**
  String get residentialAreaTypeLabel;

  /// No description provided for @rhSdhDhHint.
  ///
  /// In en, this message translates to:
  /// **'RH/SDH/DH/SADAR Hospital'**
  String get rhSdhDhHint;

  /// No description provided for @rhSdhDhLabel.
  ///
  /// In en, this message translates to:
  /// **'RH/SDH/DH/SADAR Hospital'**
  String get rhSdhDhLabel;

  /// No description provided for @richIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Rich ID'**
  String get richIdLabel;

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

  /// No description provided for @rnhTabHouseholdAmenities.
  ///
  /// In en, this message translates to:
  /// **'HOUSEHOLD AMENITIES'**
  String get rnhTabHouseholdAmenities;

  /// No description provided for @rnhTabHouseholdDetails.
  ///
  /// In en, this message translates to:
  /// **'HOUSEHOLD DETAILS'**
  String get rnhTabHouseholdDetails;

  /// No description provided for @rnhTabMemberDetails.
  ///
  /// In en, this message translates to:
  /// **'MEMBER DETAILS'**
  String get rnhTabMemberDetails;

  /// No description provided for @rnhTotalMembers.
  ///
  /// In en, this message translates to:
  /// **'No. of total members'**
  String get rnhTotalMembers;

  /// No description provided for @routine.
  ///
  /// In en, this message translates to:
  /// **'Routine Immunization (RI)'**
  String get routine;

  /// No description provided for @routineChildList0to1.
  ///
  /// In en, this message translates to:
  /// **'0-1 Year Child List'**
  String get routineChildList0to1;

  /// No description provided for @routineChildList1to2.
  ///
  /// In en, this message translates to:
  /// **'1-2 Year Child List'**
  String get routineChildList1to2;

  /// No description provided for @routineChildList2to5.
  ///
  /// In en, this message translates to:
  /// **'2-5 Year Child List'**
  String get routineChildList2to5;

  /// No description provided for @routinePoornTikakaran.
  ///
  /// In en, this message translates to:
  /// **'No. of Poorn Tikakaran'**
  String get routinePoornTikakaran;

  /// No description provided for @routinePwList.
  ///
  /// In en, this message translates to:
  /// **'PW List'**
  String get routinePwList;

  /// No description provided for @routineSampoornTikakaran.
  ///
  /// In en, this message translates to:
  /// **'No. of Sampoorn Tikakaran'**
  String get routineSampoornTikakaran;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get saveButton;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Form Submitted successfully'**
  String get saveSuccess;

  /// No description provided for @savingButton.
  ///
  /// In en, this message translates to:
  /// **'SAVING...'**
  String get savingButton;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Registered Child Beneficiary'**
  String get searchHint;

  /// No description provided for @searchEligibleCouple.
  ///
  /// In en, this message translates to:
  /// **'Search Eligible Couple'**
  String get searchEligibleCouple;

  /// No description provided for @searchDelOutcome.
  ///
  /// In en, this message translates to:
  /// **'Delivery Outcome Search'**
  String get searchDelOutcome;

  /// No description provided for @searchHintRegisterChildDueList.
  ///
  /// In en, this message translates to:
  /// **'Child Registered Due Search'**
  String get searchHintRegisterChildDueList;

  /// No description provided for @searchHintHbycBen.
  ///
  /// In en, this message translates to:
  /// **'Search HBYC Beneficiary'**
  String get searchHintHbycBen;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @eligibleCoupleListTitle.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple List'**
  String get eligibleCoupleListTitle;

  /// No description provided for @eligibleCoupleStatus.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple'**
  String get eligibleCoupleStatus;

  /// No description provided for @deathRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Death Register'**
  String get deathRegisterTitle;

  /// No description provided for @placeLabel.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get placeLabel;

  /// No description provided for @searchHBNC.
  ///
  /// In en, this message translates to:
  /// **'search HBNC'**
  String get searchHBNC;

  /// No description provided for @secondAncLabel.
  ///
  /// In en, this message translates to:
  /// **'Second ANC'**
  String get secondAncLabel;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectArea.
  ///
  /// In en, this message translates to:
  /// **'Select area'**
  String get selectArea;

  /// No description provided for @self.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get self;

  /// No description provided for @separated.
  ///
  /// In en, this message translates to:
  /// **'Separated'**
  String get separated;

  /// No description provided for @separatedMarried.
  ///
  /// In en, this message translates to:
  /// **'Separated'**
  String get separatedMarried;

  /// No description provided for @settingsAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// No description provided for @settingsCheck.
  ///
  /// In en, this message translates to:
  /// **'CHECK'**
  String get settingsCheck;

  /// No description provided for @settingsCheckForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckForUpdates;

  /// No description provided for @sharing.
  ///
  /// In en, this message translates to:
  /// **'Sharing'**
  String get sharing;

  /// No description provided for @showGuestBeneficiaryList.
  ///
  /// In en, this message translates to:
  /// **'SHOW GUEST BENEFICIARY LIST'**
  String get showGuestBeneficiaryList;

  /// No description provided for @socioEconomicDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Socio-economic Details'**
  String get socioEconomicDetailsTitle;

  /// No description provided for @son.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get son;

  /// No description provided for @spouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get spouse;

  /// No description provided for @spouseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Spouse Name'**
  String get spouseNameLabel;

  /// No description provided for @stateHint.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateHint;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get stateLabel;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @streetLocalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Street/Locality'**
  String get streetLocalityLabel;

  /// No description provided for @systolicLabel.
  ///
  /// In en, this message translates to:
  /// **'Systolic'**
  String get systolicLabel;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get tabAll;

  /// No description provided for @tabAshaDashboard.
  ///
  /// In en, this message translates to:
  /// **'ASHA DASHBOARD'**
  String get tabAshaDashboard;

  /// No description provided for @tabProtected.
  ///
  /// In en, this message translates to:
  /// **'PROTECTED'**
  String get tabProtected;

  /// No description provided for @tabTodaysProgram.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PROGRAM'**
  String get tabTodaysProgram;

  /// No description provided for @tabUnprotected.
  ///
  /// In en, this message translates to:
  /// **'UNPROTECTED'**
  String get tabUnprotected;

  /// No description provided for @td1DateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of T.D(Tetanus and adult diphtheria) 1'**
  String get td1DateLabel;

  /// No description provided for @td2DateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of T.D(Tetanus and adult diphtheria) 2'**
  String get td2DateLabel;

  /// No description provided for @tdBoosterDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of T.D(Tetanus and adult diphtheria) booster'**
  String get tdBoosterDateLabel;

  /// No description provided for @thAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get thAge;

  /// No description provided for @thFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get thFather;

  /// No description provided for @thGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get thGender;

  /// No description provided for @thName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get thName;

  /// No description provided for @thNumber.
  ///
  /// In en, this message translates to:
  /// **'#'**
  String get thNumber;

  /// No description provided for @thRelation.
  ///
  /// In en, this message translates to:
  /// **'Relation'**
  String get thRelation;

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

  /// No description provided for @thType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get thType;

  /// No description provided for @thirdAncLabel.
  ///
  /// In en, this message translates to:
  /// **'Third ANC'**
  String get thirdAncLabel;

  /// No description provided for @toDoVisits.
  ///
  /// In en, this message translates to:
  /// **'To do visits'**
  String get toDoVisits;

  /// No description provided for @todayWorkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed visits :'**
  String get todayWorkCompleted;

  /// No description provided for @todayWorkPending.
  ///
  /// In en, this message translates to:
  /// **'Pending visits :'**
  String get todayWorkPending;

  /// No description provided for @todayWorkProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress :'**
  String get todayWorkProgress;

  /// No description provided for @todayWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Work Progress'**
  String get todayWorkTitle;

  /// No description provided for @todayWorkToDo.
  ///
  /// In en, this message translates to:
  /// **'To do visits :'**
  String get todayWorkToDo;

  /// No description provided for @toiletAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Do you have access to toilet at your home'**
  String get toiletAccessLabel;

  /// No description provided for @tolaHint.
  ///
  /// In en, this message translates to:
  /// **'Tola'**
  String get tolaHint;

  /// No description provided for @tolaLabel.
  ///
  /// In en, this message translates to:
  /// **'Tola'**
  String get tolaLabel;

  /// No description provided for @totalChildrenBornLabel.
  ///
  /// In en, this message translates to:
  /// **'Total number of children born'**
  String get totalChildrenBornLabel;

  /// No description provided for @totalFemaleChildrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Total number of female children'**
  String get totalFemaleChildrenLabel;

  /// No description provided for @totalLiveChildrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Total number of live children'**
  String get totalLiveChildrenLabel;

  /// No description provided for @totalMaleChildrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Total number of male children'**
  String get totalMaleChildrenLabel;

  /// No description provided for @trackEligibleCoupleTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Eligible Couples'**
  String get trackEligibleCoupleTitle;

  /// No description provided for @trainingDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Training Date'**
  String get trainingDateLabel;

  /// No description provided for @trainingDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'No. of days'**
  String get trainingDaysLabel;

  /// No description provided for @trainingFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Details'**
  String get trainingFormTitle;

  /// No description provided for @trainingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Training Name'**
  String get trainingNameLabel;

  /// No description provided for @trainingPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Place of Training'**
  String get trainingPlaceLabel;

  /// No description provided for @trainingProvidedTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Provided'**
  String get trainingProvidedTitle;

  /// No description provided for @trainingReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Received'**
  String get trainingReceivedTitle;

  /// No description provided for @trainingSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get trainingSave;

  /// No description provided for @trainingTitle.
  ///
  /// In en, this message translates to:
  /// **'BHAVYA mASHA Training'**
  String get trainingTitle;

  /// No description provided for @trainingTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Training Type'**
  String get trainingTypeLabel;

  /// No description provided for @unmarried.
  ///
  /// In en, this message translates to:
  /// **'Unmarried'**
  String get unmarried;

  /// No description provided for @updateButton.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get updateButton;

  /// No description provided for @updatedEligibleCoupleListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couples List'**
  String get updatedEligibleCoupleListSubtitle;

  /// No description provided for @updatedEligibleCoupleListTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated Eligible Couple List '**
  String get updatedEligibleCoupleListTitle;

  /// No description provided for @updatedEligibleCoupleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Updated Eligible Couple Search'**
  String get updatedEligibleCoupleSearchHint;

  /// No description provided for @eligibleCoupleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Eligible Couple'**
  String get eligibleCoupleSearchHint;

  /// No description provided for @userHfrIdLabel.
  ///
  /// In en, this message translates to:
  /// **'HFR ID:'**
  String get userHfrIdLabel;

  /// No description provided for @userHscLabel.
  ///
  /// In en, this message translates to:
  /// **'HSC:'**
  String get userHscLabel;

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

  /// No description provided for @usernameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be empty'**
  String get usernameEmpty;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @villageHint.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get villageHint;

  /// No description provided for @villageLabel.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get villageLabel;

  /// No description provided for @villageNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Village name'**
  String get villageNameLabel;

  /// No description provided for @visitDate.
  ///
  /// In en, this message translates to:
  /// **'Visit Date :'**
  String get visitDate;

  /// No description provided for @visitDetailsANC.
  ///
  /// In en, this message translates to:
  /// **'Antenatal Care visit'**
  String get visitDetailsANC;

  /// No description provided for @visitDetailsHBNC.
  ///
  /// In en, this message translates to:
  /// **'Home Based Newborn Care visit'**
  String get visitDetailsHBNC;

  /// No description provided for @visitDetailsPNC.
  ///
  /// In en, this message translates to:
  /// **'Post Natal Care visit for routine checkup'**
  String get visitDetailsPNC;

  /// No description provided for @visitStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get visitStatusLabel;

  /// No description provided for @visitTypeANC.
  ///
  /// In en, this message translates to:
  /// **'Antenatal Care'**
  String get visitTypeANC;

  /// No description provided for @visitTypeHBNC.
  ///
  /// In en, this message translates to:
  /// **'Home Based Newborn Care'**
  String get visitTypeHBNC;

  /// No description provided for @visitTypeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get visitTypeHome;

  /// No description provided for @visitTypeHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get visitTypeHospital;

  /// No description provided for @visitTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit type *'**
  String get visitTypeLabel;

  /// No description provided for @visitTypePNC.
  ///
  /// In en, this message translates to:
  /// **'Post Natal Care'**
  String get visitTypePNC;

  /// No description provided for @visitTypePhc.
  ///
  /// In en, this message translates to:
  /// **'PHC'**
  String get visitTypePhc;

  /// No description provided for @visitTypeSubcenter.
  ///
  /// In en, this message translates to:
  /// **'Subcenter'**
  String get visitTypeSubcenter;

  /// No description provided for @visitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Visits :'**
  String get visitsLabel;

  /// No description provided for @voterIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Voter Id'**
  String get voterIdLabel;

  /// No description provided for @wardNoLabel.
  ///
  /// In en, this message translates to:
  /// **'Ward no.'**
  String get wardNoLabel;

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

  /// No description provided for @waterLake.
  ///
  /// In en, this message translates to:
  /// **'Lake'**
  String get waterLake;

  /// No description provided for @waterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get waterOther;

  /// No description provided for @waterPond.
  ///
  /// In en, this message translates to:
  /// **'Pond'**
  String get waterPond;

  /// No description provided for @waterRO.
  ///
  /// In en, this message translates to:
  /// **'R.O'**
  String get waterRO;

  /// No description provided for @waterRiver.
  ///
  /// In en, this message translates to:
  /// **'River'**
  String get waterRiver;

  /// No description provided for @waterSanitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Water & Sanitation'**
  String get waterSanitationTitle;

  /// No description provided for @waterSupply.
  ///
  /// In en, this message translates to:
  /// **'Supply Water'**
  String get waterSupply;

  /// No description provided for @waterTanker.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get waterTanker;

  /// No description provided for @waterWell.
  ///
  /// In en, this message translates to:
  /// **'Well'**
  String get waterWell;

  /// No description provided for @weeksOfPregnancyLabel.
  ///
  /// In en, this message translates to:
  /// **'No. of weeks of pregnancy'**
  String get weeksOfPregnancyLabel;

  /// No description provided for @weightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (Kg)'**
  String get weightKgLabel;

  /// No description provided for @whoseMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Whose mobile no.?'**
  String get whoseMobileLabel;

  /// No description provided for @widowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get widowed;

  /// No description provided for @wife.
  ///
  /// In en, this message translates to:
  /// **'Wife'**
  String get wife;

  /// No description provided for @yearsSuffix.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get yearsSuffix;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get nextButton;

  /// No description provided for @previousButton.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS'**
  String get previousButton;

  /// No description provided for @youngestChildAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age of youngest child'**
  String get youngestChildAgeLabel;

  /// No description provided for @familySurvey.
  ///
  /// In en, this message translates to:
  /// **'Family Survey'**
  String get familySurvey;

  /// No description provided for @suchivani.
  ///
  /// In en, this message translates to:
  /// **'Suchivani'**
  String get suchivani;

  /// No description provided for @ashaDiary.
  ///
  /// In en, this message translates to:
  /// **'ASHA Diary'**
  String get ashaDiary;

  /// No description provided for @householdSurvey.
  ///
  /// In en, this message translates to:
  /// **'Household Survey'**
  String get householdSurvey;

  /// No description provided for @vhsncMeeting.
  ///
  /// In en, this message translates to:
  /// **'VHSNC Meeting'**
  String get vhsncMeeting;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @youngestChildAgeUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Age of youngest child unit'**
  String get youngestChildAgeUnitLabel;

  /// No description provided for @youngestChildGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender of youngest child'**
  String get youngestChildGenderLabel;

  /// No description provided for @deliveryOutcomeList.
  ///
  /// In en, this message translates to:
  /// **'Delivery Outcome List'**
  String get deliveryOutcomeList;

  /// No description provided for @searchDeliveryOutcome.
  ///
  /// In en, this message translates to:
  /// **'Search delivery outcome...'**
  String get searchDeliveryOutcome;

  /// No description provided for @previousPncDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous PNC Date'**
  String get previousPncDateLabel;

  /// No description provided for @nextPncDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Next PNC Date'**
  String get nextPncDateLabel;

  /// No description provided for @registrationDueTitle.
  ///
  /// In en, this message translates to:
  /// **'registration due'**
  String get registrationDueTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @rchIdChildLabel.
  ///
  /// In en, this message translates to:
  /// **'RCH ID (Child)'**
  String get rchIdChildLabel;

  /// No description provided for @rchChildSerialHint.
  ///
  /// In en, this message translates to:
  /// **'Serial number of the child in the RCH register'**
  String get rchChildSerialHint;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth *'**
  String get dateOfBirthLabel;

  /// No description provided for @dateOfRegistrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Registration *'**
  String get dateOfRegistrationLabel;

  /// No description provided for @childNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Child\'s name *'**
  String get childNameLabel;

  /// No description provided for @whoseMobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Whose mobile number is this'**
  String get whoseMobileNumberLabel;

  /// No description provided for @mobileNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'mobile number'**
  String get mobileNumberLabel;

  /// No description provided for @mothersRchIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s RCH ID number'**
  String get mothersRchIdLabel;

  /// No description provided for @birthCertificateIssuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Is birth certificate issued?'**
  String get birthCertificateIssuedLabel;

  /// No description provided for @birthCertificateNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'birth certificate number'**
  String get birthCertificateNumberLabel;

  /// No description provided for @weightGramLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (g)'**
  String get weightGramLabel;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'choose'**
  String get choose;

  /// No description provided for @headOfFamily.
  ///
  /// In en, this message translates to:
  /// **'Head of the family'**
  String get headOfFamily;

  /// No description provided for @casteGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get casteGeneral;

  /// No description provided for @casteObc.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get casteObc;

  /// No description provided for @casteSc.
  ///
  /// In en, this message translates to:
  /// **'SC'**
  String get casteSc;

  /// No description provided for @casteSt.
  ///
  /// In en, this message translates to:
  /// **'ST'**
  String get casteSt;

  /// No description provided for @addNewTrainingButton.
  ///
  /// In en, this message translates to:
  /// **'Add New Training'**
  String get addNewTrainingButton;

  /// No description provided for @linkAbha.
  ///
  /// In en, this message translates to:
  /// **'LINK FROM ABHA'**
  String get linkAbha;

  /// No description provided for @ncdTitle.
  ///
  /// In en, this message translates to:
  /// **'NCD'**
  String get ncdTitle;

  /// No description provided for @ncdListTitle.
  ///
  /// In en, this message translates to:
  /// **'NCD List'**
  String get ncdListTitle;

  /// No description provided for @ncdEligibleListTitle.
  ///
  /// In en, this message translates to:
  /// **'NCD Eligible List'**
  String get ncdEligibleListTitle;

  /// No description provided for @ncdPriorityListTitle.
  ///
  /// In en, this message translates to:
  /// **'NCD Priority List'**
  String get ncdPriorityListTitle;

  /// No description provided for @ncdNonEligibleListTitle.
  ///
  /// In en, this message translates to:
  /// **'NCD Non-Eligible List'**
  String get ncdNonEligibleListTitle;

  /// No description provided for @ncdMsgRegisteredChildBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Registered Child Beneficiary list'**
  String get ncdMsgRegisteredChildBeneficiary;

  /// No description provided for @ncdMsgChildRegisteredDueList.
  ///
  /// In en, this message translates to:
  /// **'Child Registered Due List'**
  String get ncdMsgChildRegisteredDueList;

  /// No description provided for @ncdMsgChildTrackingDueList.
  ///
  /// In en, this message translates to:
  /// **'Child Tracking Due List'**
  String get ncdMsgChildTrackingDueList;

  /// No description provided for @ncdMsgHbycList.
  ///
  /// In en, this message translates to:
  /// **'HBYC List'**
  String get ncdMsgHbycList;

  /// No description provided for @registrationDue.
  ///
  /// In en, this message translates to:
  /// **'Registration Due'**
  String get registrationDue;

  /// No description provided for @alive.
  ///
  /// In en, this message translates to:
  /// **'Alive'**
  String get alive;

  /// No description provided for @babyConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Child status'**
  String get babyConditionLabel;

  /// No description provided for @babyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s name'**
  String get babyNameLabel;

  /// No description provided for @babyGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s gender '**
  String get babyGenderLabel;

  /// No description provided for @newbornWeightGramLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s weight (1200-4000)gms'**
  String get newbornWeightGramLabel;

  /// No description provided for @newbornTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get newbornTemperatureLabel;

  /// No description provided for @infantTemperatureUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature of the baby (Measure in axial and record)'**
  String get infantTemperatureUnitLabel;

  /// No description provided for @temperatureUnitCelsius.
  ///
  /// In en, this message translates to:
  /// **'Celsius'**
  String get temperatureUnitCelsius;

  /// No description provided for @temperatureUnitFahrenheit.
  ///
  /// In en, this message translates to:
  /// **'Fahrenheit'**
  String get temperatureUnitFahrenheit;

  /// No description provided for @weighingScaleColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Scale color of weighing machine'**
  String get weighingScaleColorLabel;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @motherReportsTempOrChestIndrawingLabel.
  ///
  /// In en, this message translates to:
  /// **'The mother reports that the child feels hot or cold when touching and the temperature of the child is more than 37.5°C  or less than 35.5°C, and the chest is pulled inward while breathing.'**
  String get motherReportsTempOrChestIndrawingLabel;

  /// No description provided for @bleedingUmbilicalCordLabel.
  ///
  /// In en, this message translates to:
  /// **'Is Umbilical cord bleeding'**
  String get bleedingUmbilicalCordLabel;

  /// No description provided for @newbornSeizuresLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the child having seizures?'**
  String get newbornSeizuresLabel;

  /// No description provided for @stoppedCryingLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the child stopped crying?'**
  String get stoppedCryingLabel;

  /// No description provided for @homeVisitDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Home Visit Day *'**
  String get homeVisitDayLabel;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High-Risk Pregnancy List'**
  String get highRisk;

  /// No description provided for @dateOfHomeVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Home visit date *'**
  String get dateOfHomeVisitLabel;

  /// No description provided for @motherStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother status *'**
  String get motherStatusLabel;

  /// No description provided for @mcpCardAvailableLabelMother.
  ///
  /// In en, this message translates to:
  /// **'Is there availability of \'Mother Child Protection (MCP) card? *'**
  String get mcpCardAvailableLabelMother;

  /// No description provided for @postDeliveryProblemNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get postDeliveryProblemNone;

  /// No description provided for @postDeliveryProblemExcessiveBleeding.
  ///
  /// In en, this message translates to:
  /// **'Excessive bleeding'**
  String get postDeliveryProblemExcessiveBleeding;

  /// No description provided for @postDeliveryProblemSevereHeadacheBlurredVision.
  ///
  /// In en, this message translates to:
  /// **'Severe headache/blurred vision'**
  String get postDeliveryProblemSevereHeadacheBlurredVision;

  /// No description provided for @postDeliveryProblemLowerAbdominalPain.
  ///
  /// In en, this message translates to:
  /// **'Lower abdominal pain'**
  String get postDeliveryProblemLowerAbdominalPain;

  /// No description provided for @postDeliveryProblemFoulSmellingDischarge.
  ///
  /// In en, this message translates to:
  /// **'Foul-smelling discharge'**
  String get postDeliveryProblemFoulSmellingDischarge;

  /// No description provided for @postDeliveryProblemHighFever.
  ///
  /// In en, this message translates to:
  /// **'High fever'**
  String get postDeliveryProblemHighFever;

  /// No description provided for @postDeliveryProblemConvulsions.
  ///
  /// In en, this message translates to:
  /// **'Convulsions'**
  String get postDeliveryProblemConvulsions;

  /// No description provided for @mealsPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'No. of times does a mother take a full meal in 24 hours?'**
  String get mealsPerDayLabel;

  /// No description provided for @padsPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'How many pads have been changed in a day for bleeding? *'**
  String get padsPerDayLabel;

  /// No description provided for @mothersTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature of mother'**
  String get mothersTemperatureLabel;

  /// No description provided for @foulDischargeHighFeverLabel.
  ///
  /// In en, this message translates to:
  /// **'Foul smelling discharge and fever 102 degree Fahrenheit (38.9 degree C) *'**
  String get foulDischargeHighFeverLabel;

  /// No description provided for @abnormalSpeechOrSeizureLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the mother speaking abnormally or having fits?'**
  String get abnormalSpeechOrSeizureLabel;

  /// No description provided for @counselingAdviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Counseling / Advise *'**
  String get counselingAdviceLabel;

  /// No description provided for @outcomeFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Outcome'**
  String get outcomeFormTitle;

  /// No description provided for @deliveryOutcomeDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery Outcome Details'**
  String get deliveryOutcomeDetails;

  /// No description provided for @deliveryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Delivery *'**
  String get deliveryDateLabel;

  /// No description provided for @pregnancyWeeksLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of weeks of pregnancy during delivery.'**
  String get pregnancyWeeksLabel;

  /// No description provided for @outcomeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of Outcome *'**
  String get outcomeTypeLabel;

  /// No description provided for @outcomeTypeLiveBirth.
  ///
  /// In en, this message translates to:
  /// **'Live Birth'**
  String get outcomeTypeLiveBirth;

  /// No description provided for @outcomeTypeStillBirth.
  ///
  /// In en, this message translates to:
  /// **'Still Birth'**
  String get outcomeTypeStillBirth;

  /// No description provided for @outcomeTypeAbortion.
  ///
  /// In en, this message translates to:
  /// **'Abortion'**
  String get outcomeTypeAbortion;

  /// No description provided for @birthWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth Weight (in kg)'**
  String get birthWeightLabel;

  /// No description provided for @genderOfChildLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender of Child'**
  String get genderOfChildLabel;

  /// No description provided for @placeOfDeliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Place of Delivery *'**
  String get placeOfDeliveryLabel;

  /// No description provided for @placeOfDeliveryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get placeOfDeliveryHome;

  /// No description provided for @placeOfDeliveryGovt.
  ///
  /// In en, this message translates to:
  /// **'Government Facility'**
  String get placeOfDeliveryGovt;

  /// No description provided for @placeOfDeliveryPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private Facility'**
  String get placeOfDeliveryPrivate;

  /// No description provided for @placeOfDeliveryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get placeOfDeliveryOther;

  /// No description provided for @deliveryConductedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Conducted By *'**
  String get deliveryConductedByLabel;

  /// No description provided for @deliveryConductedByDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get deliveryConductedByDoctor;

  /// No description provided for @deliveryConductedByANM.
  ///
  /// In en, this message translates to:
  /// **'ANM'**
  String get deliveryConductedByANM;

  /// No description provided for @deliveryConductedByNurse.
  ///
  /// In en, this message translates to:
  /// **'Nurse'**
  String get deliveryConductedByNurse;

  /// No description provided for @deliveryConductedByDai.
  ///
  /// In en, this message translates to:
  /// **'Dai'**
  String get deliveryConductedByDai;

  /// No description provided for @deliveryConductedByOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get deliveryConductedByOther;

  /// No description provided for @complicationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Complications (if any)'**
  String get complicationsLabel;

  /// No description provided for @complicationBleeding.
  ///
  /// In en, this message translates to:
  /// **'Excessive Bleeding'**
  String get complicationBleeding;

  /// No description provided for @complicationInfection.
  ///
  /// In en, this message translates to:
  /// **'Infection'**
  String get complicationInfection;

  /// No description provided for @complicationEclampsia.
  ///
  /// In en, this message translates to:
  /// **'Eclampsia'**
  String get complicationEclampsia;

  /// No description provided for @complicationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get complicationOther;

  /// No description provided for @referralFacilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Referred to Facility'**
  String get referralFacilityLabel;

  /// No description provided for @referralFacilityYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get referralFacilityYes;

  /// No description provided for @referralFacilityNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get referralFacilityNo;

  /// No description provided for @referralFacilityNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name of Facility'**
  String get referralFacilityNameLabel;

  /// No description provided for @referralFacilityNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter facility name'**
  String get referralFacilityNameHint;

  /// No description provided for @referralReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for Referral'**
  String get referralReasonLabel;

  /// No description provided for @referralReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for referral'**
  String get referralReasonHint;

  /// No description provided for @dataSavedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Data saved successfully'**
  String get dataSavedSuccessMessage;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Date of Delivery *'**
  String get deliveryDate;

  /// No description provided for @gestationWeeks.
  ///
  /// In en, this message translates to:
  /// **'Number of weeks of pregnancy during delivery'**
  String get gestationWeeks;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time (hh:mm)'**
  String get deliveryTime;

  /// No description provided for @deliveryTimeHint.
  ///
  /// In en, this message translates to:
  /// **'hh:mm'**
  String get deliveryTimeHint;

  /// No description provided for @placeOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Place of Delivery'**
  String get placeOfDelivery;

  /// No description provided for @selectPlaceOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Select Place of Delivery *'**
  String get selectPlaceOfDelivery;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectOption;

  /// No description provided for @subCenter.
  ///
  /// In en, this message translates to:
  /// **'Sub-Center'**
  String get subCenter;

  /// No description provided for @chc.
  ///
  /// In en, this message translates to:
  /// **'CHC'**
  String get chc;

  /// No description provided for @districtHospital.
  ///
  /// In en, this message translates to:
  /// **'District Hospital'**
  String get districtHospital;

  /// No description provided for @privateHospital.
  ///
  /// In en, this message translates to:
  /// **'Private Hospital'**
  String get privateHospital;

  /// No description provided for @deliveryType.
  ///
  /// In en, this message translates to:
  /// **'Type of Delivery *'**
  String get deliveryType;

  /// No description provided for @normalDelivery.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalDelivery;

  /// No description provided for @cesareanDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cesarean'**
  String get cesareanDelivery;

  /// No description provided for @assistedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Assisted/Forceps)'**
  String get assistedDelivery;

  /// No description provided for @complications.
  ///
  /// In en, this message translates to:
  /// **'Complications during delivery? *'**
  String get complications;

  /// No description provided for @outcomeCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Outcomes *'**
  String get outcomeCount;

  /// No description provided for @familyPlanningCounseling.
  ///
  /// In en, this message translates to:
  /// **'Family Planning Counseling Provided?'**
  String get familyPlanningCounseling;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillAllFields;

  /// No description provided for @howWasBreastfedLabel.
  ///
  /// In en, this message translates to:
  /// **'How did the baby breastfed?'**
  String get howWasBreastfedLabel;

  /// No description provided for @firstFeedGivenAfterBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'What was given as the baby first feed to baby after birth? *'**
  String get firstFeedGivenAfterBirthLabel;

  /// No description provided for @adequatelyFedSevenToEightTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby being fed properly (whenever hungry or at least 7–8 times in 24 hours)?'**
  String get adequatelyFedSevenToEightTimesLabel;

  /// No description provided for @babyDrinkingLessMilkLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the child feeding less?'**
  String get babyDrinkingLessMilkLabel;

  /// No description provided for @breastfeedingStoppedLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the child stopped feeding?'**
  String get breastfeedingStoppedLabel;

  /// No description provided for @bloatedStomachOrFrequentVomitingLabel.
  ///
  /// In en, this message translates to:
  /// **'Bloated stomach or mother tells that the child vomits again and again'**
  String get bloatedStomachOrFrequentVomitingLabel;

  /// No description provided for @err_visit_day_required.
  ///
  /// In en, this message translates to:
  /// **'Home Visit Day is required.'**
  String get err_visit_day_required;

  /// No description provided for @err_visit_date_required.
  ///
  /// In en, this message translates to:
  /// **'Date of home visit is required.'**
  String get err_visit_date_required;

  /// No description provided for @err_mother_status_required.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s status is required.'**
  String get err_mother_status_required;

  /// No description provided for @err_mcp_mother_required.
  ///
  /// In en, this message translates to:
  /// **'MCP card availability is required (Mother).'**
  String get err_mcp_mother_required;

  /// No description provided for @err_post_delivery_problems_required.
  ///
  /// In en, this message translates to:
  /// **'Post-delivery problems selection is required.'**
  String get err_post_delivery_problems_required;

  /// No description provided for @err_breastfeeding_problems_required.
  ///
  /// In en, this message translates to:
  /// **'Breastfeeding problems selection is required.'**
  String get err_breastfeeding_problems_required;

  /// No description provided for @err_pads_per_day_required.
  ///
  /// In en, this message translates to:
  /// **'Pads changed per day is required.'**
  String get err_pads_per_day_required;

  /// No description provided for @err_mothers_temperature_required.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s temperature is required.'**
  String get err_mothers_temperature_required;

  /// No description provided for @err_foul_discharge_high_fever_required.
  ///
  /// In en, this message translates to:
  /// **'Foul discharge/high fever selection is required.'**
  String get err_foul_discharge_high_fever_required;

  /// No description provided for @err_abnormal_speech_or_seizure_required.
  ///
  /// In en, this message translates to:
  /// **'Abnormal speech or seizures selection is required.'**
  String get err_abnormal_speech_or_seizure_required;

  /// No description provided for @err_counseling_advice_required.
  ///
  /// In en, this message translates to:
  /// **'Counseling / Advice is required.'**
  String get err_counseling_advice_required;

  /// No description provided for @err_milk_not_producing_or_less_required.
  ///
  /// In en, this message translates to:
  /// **'Milk not producing/less selection is required.'**
  String get err_milk_not_producing_or_less_required;

  /// No description provided for @err_nipple_cracks_pain_or_engorged_required.
  ///
  /// In en, this message translates to:
  /// **'Nipple cracks/pain or engorged breasts selection is required.'**
  String get err_nipple_cracks_pain_or_engorged_required;

  /// No description provided for @err_baby_condition_required.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s condition is required.'**
  String get err_baby_condition_required;

  /// No description provided for @err_baby_name_required.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s name is required.'**
  String get err_baby_name_required;

  /// No description provided for @err_baby_gender_required.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s gender is required.'**
  String get err_baby_gender_required;

  /// No description provided for @err_baby_weight_required.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s weight is required.'**
  String get err_baby_weight_required;

  /// No description provided for @err_newborn_temperature_required.
  ///
  /// In en, this message translates to:
  /// **'Temperature is required.'**
  String get err_newborn_temperature_required;

  /// No description provided for @err_infant_temp_unit_required.
  ///
  /// In en, this message translates to:
  /// **'Infant\'s temperature unit is required.'**
  String get err_infant_temp_unit_required;

  /// No description provided for @err_weight_color_match_required.
  ///
  /// In en, this message translates to:
  /// **'Weight color match is required.'**
  String get err_weight_color_match_required;

  /// No description provided for @err_weighing_scale_color_required.
  ///
  /// In en, this message translates to:
  /// **'Weighing scale color is required.'**
  String get err_weighing_scale_color_required;

  /// No description provided for @err_mother_reports_temp_or_chest_indrawing_required.
  ///
  /// In en, this message translates to:
  /// **'Mother reports temp/chest indrawing selection is required.'**
  String get err_mother_reports_temp_or_chest_indrawing_required;

  /// No description provided for @err_bleeding_umbilical_cord_required.
  ///
  /// In en, this message translates to:
  /// **'Bleeding from umbilical cord selection is required.'**
  String get err_bleeding_umbilical_cord_required;

  /// No description provided for @err_pus_in_navel_required.
  ///
  /// In en, this message translates to:
  /// **'Pus in navel selection is required.'**
  String get err_pus_in_navel_required;

  /// No description provided for @err_routine_care_done_required.
  ///
  /// In en, this message translates to:
  /// **'Routine newborn care selection is required.'**
  String get err_routine_care_done_required;

  /// No description provided for @err_breathing_rapid_required.
  ///
  /// In en, this message translates to:
  /// **'Rapid breathing selection is required.'**
  String get err_breathing_rapid_required;

  /// No description provided for @err_congenital_abnormalities_required.
  ///
  /// In en, this message translates to:
  /// **'Congenital abnormalities selection is required.'**
  String get err_congenital_abnormalities_required;

  /// No description provided for @err_eyes_normal_required.
  ///
  /// In en, this message translates to:
  /// **'Eyes: Normal selection is required.'**
  String get err_eyes_normal_required;

  /// No description provided for @err_eyes_swollen_or_pus_required.
  ///
  /// In en, this message translates to:
  /// **'Eyes swollen/pus selection is required.'**
  String get err_eyes_swollen_or_pus_required;

  /// No description provided for @err_skin_fold_redness_required.
  ///
  /// In en, this message translates to:
  /// **'Skin fold crack/redness selection is required.'**
  String get err_skin_fold_redness_required;

  /// No description provided for @err_newborn_jaundice_required.
  ///
  /// In en, this message translates to:
  /// **'Jaundice selection is required.'**
  String get err_newborn_jaundice_required;

  /// No description provided for @err_pus_bumps_or_boil_required.
  ///
  /// In en, this message translates to:
  /// **'Pus-filled bumps/boil selection is required.'**
  String get err_pus_bumps_or_boil_required;

  /// No description provided for @err_newborn_seizures_required.
  ///
  /// In en, this message translates to:
  /// **'Seizures selection is required.'**
  String get err_newborn_seizures_required;

  /// No description provided for @err_crying_constant_or_less_urine_required.
  ///
  /// In en, this message translates to:
  /// **'Crying constantly/less urine selection is required.'**
  String get err_crying_constant_or_less_urine_required;

  /// No description provided for @err_crying_softly_required.
  ///
  /// In en, this message translates to:
  /// **'Crying softly selection is required.'**
  String get err_crying_softly_required;

  /// No description provided for @err_stopped_crying_required.
  ///
  /// In en, this message translates to:
  /// **'Stopped crying selection is required.'**
  String get err_stopped_crying_required;

  /// No description provided for @err_referred_by_asha_required.
  ///
  /// In en, this message translates to:
  /// **'Referred by ASHA selection is required.'**
  String get err_referred_by_asha_required;

  /// No description provided for @err_birth_registered_required.
  ///
  /// In en, this message translates to:
  /// **'Birth registration selection is required.'**
  String get err_birth_registered_required;

  /// No description provided for @err_birth_certificate_issued_required.
  ///
  /// In en, this message translates to:
  /// **'Birth certificate issued selection is required.'**
  String get err_birth_certificate_issued_required;

  /// No description provided for @err_birth_dose_vaccination_required.
  ///
  /// In en, this message translates to:
  /// **'Birth dose vaccination selection is required.'**
  String get err_birth_dose_vaccination_required;

  /// No description provided for @err_mcp_child_required.
  ///
  /// In en, this message translates to:
  /// **'MCP card availability is required (Child).'**
  String get err_mcp_child_required;

  /// No description provided for @err_exclusive_breastfeeding_started_required.
  ///
  /// In en, this message translates to:
  /// **'Exclusive breastfeeding started selection is required.'**
  String get err_exclusive_breastfeeding_started_required;

  /// No description provided for @err_first_breastfeed_timing_required.
  ///
  /// In en, this message translates to:
  /// **'First breastfeed timing selection is required.'**
  String get err_first_breastfeed_timing_required;

  /// No description provided for @err_how_was_breastfed_required.
  ///
  /// In en, this message translates to:
  /// **'How was breastfed selection is required.'**
  String get err_how_was_breastfed_required;

  /// No description provided for @err_first_feed_given_after_birth_required.
  ///
  /// In en, this message translates to:
  /// **'First feed after birth selection is required.'**
  String get err_first_feed_given_after_birth_required;

  /// No description provided for @err_adequately_fed_seven_eight_required.
  ///
  /// In en, this message translates to:
  /// **'Adequate feeding (7–8 times) selection is required.'**
  String get err_adequately_fed_seven_eight_required;

  /// No description provided for @err_baby_drinking_less_milk_required.
  ///
  /// In en, this message translates to:
  /// **'Baby drinking less milk selection is required.'**
  String get err_baby_drinking_less_milk_required;

  /// No description provided for @err_breastfeeding_stopped_required.
  ///
  /// In en, this message translates to:
  /// **'Breastfeeding stopped selection is required.'**
  String get err_breastfeeding_stopped_required;

  /// No description provided for @err_bloated_or_frequent_vomit_required.
  ///
  /// In en, this message translates to:
  /// **'Bloated stomach/frequent vomiting selection is required.'**
  String get err_bloated_or_frequent_vomit_required;

  /// No description provided for @previousVisits.
  ///
  /// In en, this message translates to:
  /// **'Previous Visits'**
  String get previousVisits;

  /// No description provided for @prevVisitSrNo.
  ///
  /// In en, this message translates to:
  /// **'S. No.'**
  String get prevVisitSrNo;

  /// No description provided for @prevVisitPncDate.
  ///
  /// In en, this message translates to:
  /// **'PNC Date'**
  String get prevVisitPncDate;

  /// No description provided for @prevVisitPncDay.
  ///
  /// In en, this message translates to:
  /// **'PNC Day'**
  String get prevVisitPncDay;

  /// No description provided for @confirmBackLoseDetailsMsg.
  ///
  /// In en, this message translates to:
  /// **'If you go back, details will be lost. Do you want to go back?'**
  String get confirmBackLoseDetailsMsg;

  /// No description provided for @confirmCloseFormMsg.
  ///
  /// In en, this message translates to:
  /// **'Do you want to close this form?'**
  String get confirmCloseFormMsg;

  /// No description provided for @confirmYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get confirmYes;

  /// No description provided for @nationalProgramsTitle.
  ///
  /// In en, this message translates to:
  /// **'National Programs'**
  String get nationalProgramsTitle;

  /// No description provided for @leprosyEradicationProgram.
  ///
  /// In en, this message translates to:
  /// **'Leprosy Eradication Program'**
  String get leprosyEradicationProgram;

  /// No description provided for @kalaAzarEradicationProgram.
  ///
  /// In en, this message translates to:
  /// **'Kala-azar Eradication Program'**
  String get kalaAzarEradicationProgram;

  /// No description provided for @malariaEradicationProgram.
  ///
  /// In en, this message translates to:
  /// **'Malaria Eradication Program'**
  String get malariaEradicationProgram;

  /// No description provided for @migrationStayingInHouse.
  ///
  /// In en, this message translates to:
  /// **'Staying in House'**
  String get migrationStayingInHouse;

  /// No description provided for @aesJeEradicationProgram.
  ///
  /// In en, this message translates to:
  /// **'AES/JE Eradication Program'**
  String get aesJeEradicationProgram;

  /// No description provided for @ambEradicationProgram.
  ///
  /// In en, this message translates to:
  /// **'AMB Eradication Program'**
  String get ambEradicationProgram;

  /// No description provided for @abPmjayProgram.
  ///
  /// In en, this message translates to:
  /// **'AB-PMJAY Program'**
  String get abPmjayProgram;

  /// No description provided for @abpmjayScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'AB-PMJAY Program'**
  String get abpmjayScreenTitle;

  /// No description provided for @abpmjayQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Under AB-PMJAY, for patients brought by Asha for treatment in government hospitals (who will get medical benefits after getting admitted in the hospital)'**
  String get abpmjayQuestion1;

  /// No description provided for @abpmjayDataSaved.
  ///
  /// In en, this message translates to:
  /// **'AB-PMJAY data saved successfully!'**
  String get abpmjayDataSaved;

  /// No description provided for @visitHbnc.
  ///
  /// In en, this message translates to:
  /// **'HBNC Visit Form'**
  String get visitHbnc;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exitAppMessage;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutMessage;

  /// No description provided for @spousDetails.
  ///
  /// In en, this message translates to:
  /// **'Spous Details'**
  String get spousDetails;

  /// No description provided for @relationWithFamilyHead.
  ///
  /// In en, this message translates to:
  /// **'Relation with the family head'**
  String get relationWithFamilyHead;

  /// No description provided for @nameOfMember.
  ///
  /// In en, this message translates to:
  /// **'Name of member'**
  String get nameOfMember;

  /// No description provided for @nameOfMemberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter member name'**
  String get nameOfMemberHint;

  /// No description provided for @ageAtMarriage.
  ///
  /// In en, this message translates to:
  /// **'Age at the time of marriage'**
  String get ageAtMarriage;

  /// No description provided for @ageAtMarriageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter age at marriage'**
  String get ageAtMarriageHint;

  /// No description provided for @spouseName.
  ///
  /// In en, this message translates to:
  /// **'Spouse Name'**
  String get spouseName;

  /// No description provided for @spouseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter spouse name'**
  String get spouseNameHint;

  /// No description provided for @fatherName.
  ///
  /// In en, this message translates to:
  /// **'Father name'**
  String get fatherName;

  /// No description provided for @fatherNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter father\'s name'**
  String get fatherNameHint;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get usernameHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordHint;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get years;

  /// No description provided for @yearsHint.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearsHint;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get months;

  /// No description provided for @monthsHint.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthsHint;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get days;

  /// No description provided for @daysHint.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get daysHint;

  /// No description provided for @totalChildrenBorn.
  ///
  /// In en, this message translates to:
  /// **'Total number of children born'**
  String get totalChildrenBorn;

  /// No description provided for @totalLiveChildren.
  ///
  /// In en, this message translates to:
  /// **'Total number of live children'**
  String get totalLiveChildren;

  /// No description provided for @totalMaleChildren.
  ///
  /// In en, this message translates to:
  /// **'Total number of male children'**
  String get totalMaleChildren;

  /// No description provided for @totalFemaleChildren.
  ///
  /// In en, this message translates to:
  /// **'Total number of female children'**
  String get totalFemaleChildren;

  /// No description provided for @malePlusFemaleError.
  ///
  /// In en, this message translates to:
  /// **'Male + Female must equal Total number of live children'**
  String get malePlusFemaleError;

  /// No description provided for @youngestChildAge.
  ///
  /// In en, this message translates to:
  /// **'Age of youngest child'**
  String get youngestChildAge;

  /// No description provided for @ageUnitOfYoungest.
  ///
  /// In en, this message translates to:
  /// **'Age unit of youngest child'**
  String get ageUnitOfYoungest;

  /// No description provided for @genderOfYoungest.
  ///
  /// In en, this message translates to:
  /// **'Gender of youngest child'**
  String get genderOfYoungest;

  /// No description provided for @bankAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Number'**
  String get bankAccountNumber;

  /// No description provided for @bankAccountNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter bank account number'**
  String get bankAccountNumberHint;

  /// No description provided for @ifscCode.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get ifscCode;

  /// No description provided for @ifscCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 11-digit IFSC code'**
  String get ifscCodeHint;

  /// No description provided for @voterId.
  ///
  /// In en, this message translates to:
  /// **'Voter ID'**
  String get voterId;

  /// No description provided for @voterIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Voter ID'**
  String get voterIdHint;

  /// No description provided for @rationCardId.
  ///
  /// In en, this message translates to:
  /// **'Ration Card ID'**
  String get rationCardId;

  /// No description provided for @rationCardIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Ration Card ID'**
  String get rationCardIdHint;

  /// No description provided for @personalHealthId.
  ///
  /// In en, this message translates to:
  /// **'Personal Health ID (ABHA ID)'**
  String get personalHealthId;

  /// No description provided for @personalHealthIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 14-digit Personal Health ID'**
  String get personalHealthIdHint;

  /// No description provided for @confirmAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAttentionTitle;

  /// No description provided for @confirmYesExit.
  ///
  /// In en, this message translates to:
  /// **'Yes, Exit'**
  String get confirmYesExit;

  /// No description provided for @confirmNo.
  ///
  /// In en, this message translates to:
  /// **'No, Stay'**
  String get confirmNo;

  /// No description provided for @memberRemainsToAdd.
  ///
  /// In en, this message translates to:
  /// **'No. of members remains to be added'**
  String get memberRemainsToAdd;

  /// No description provided for @cbac.
  ///
  /// In en, this message translates to:
  /// **'CBAC'**
  String get cbac;

  /// No description provided for @videoTutorialList.
  ///
  /// In en, this message translates to:
  /// **'Video Tutorial List'**
  String get videoTutorialList;

  /// No description provided for @visitDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit Date'**
  String get visitDateLabel;

  /// No description provided for @financialYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Financial Year'**
  String get financialYearLabel;

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

  /// No description provided for @lmpDateLabelText.
  ///
  /// In en, this message translates to:
  /// **'LMP Date'**
  String get lmpDateLabelText;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get previousPage;

  /// No description provided for @completeTutorial.
  ///
  /// In en, this message translates to:
  /// **'Complete Tutorial'**
  String get completeTutorial;

  /// No description provided for @ashwinPortalFilm.
  ///
  /// In en, this message translates to:
  /// **'Ashwin Portal Film'**
  String get ashwinPortalFilm;

  /// No description provided for @pneumoniaAwareness.
  ///
  /// In en, this message translates to:
  /// **'Pneumonia Awareness (Child Health)'**
  String get pneumoniaAwareness;

  /// No description provided for @healthMinisterMessage.
  ///
  /// In en, this message translates to:
  /// **'Message from the Honorable Health Minister Bihar'**
  String get healthMinisterMessage;

  /// No description provided for @errorLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error loading video'**
  String get errorLoadingVideo;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @myBeneficiariesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Beneficiaries'**
  String get myBeneficiariesTitle;

  /// No description provided for @familyUpdate.
  ///
  /// In en, this message translates to:
  /// **'Family Update'**
  String get familyUpdate;

  /// No description provided for @eligibleCoupleList.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple List'**
  String get eligibleCoupleList;

  /// No description provided for @pregnantWomenList.
  ///
  /// In en, this message translates to:
  /// **'Pregnant Women List'**
  String get pregnantWomenList;

  /// No description provided for @pregnancyOutcome.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Outcome'**
  String get pregnancyOutcome;

  /// No description provided for @hbcnList.
  ///
  /// In en, this message translates to:
  /// **'HBNC List'**
  String get hbcnList;

  /// No description provided for @lbwReferred.
  ///
  /// In en, this message translates to:
  /// **'LBW Referred'**
  String get lbwReferred;

  /// No description provided for @abortionList.
  ///
  /// In en, this message translates to:
  /// **'Abortion List'**
  String get abortionList;

  /// No description provided for @deathRegister.
  ///
  /// In en, this message translates to:
  /// **'Death Register'**
  String get deathRegister;

  /// No description provided for @migratedOut.
  ///
  /// In en, this message translates to:
  /// **'Migrated Out'**
  String get migratedOut;

  /// No description provided for @guestBeneficiaryList.
  ///
  /// In en, this message translates to:
  /// **'Guest Beneficiary List'**
  String get guestBeneficiaryList;

  /// No description provided for @firewod.
  ///
  /// In en, this message translates to:
  /// **'Firewood'**
  String get firewod;

  /// No description provided for @cropResidues.
  ///
  /// In en, this message translates to:
  /// **'Crop Residues'**
  String get cropResidues;

  /// No description provided for @cowdung.
  ///
  /// In en, this message translates to:
  /// **'Cow dung cakes'**
  String get cowdung;

  /// No description provided for @coal.
  ///
  /// In en, this message translates to:
  /// **'Coal'**
  String get coal;

  /// No description provided for @lpg.
  ///
  /// In en, this message translates to:
  /// **'L.P.G'**
  String get lpg;

  /// No description provided for @cbacC_fuelKerosene.
  ///
  /// In en, this message translates to:
  /// **'Kerosene Oil (Kerosene)'**
  String get cbacC_fuelKerosene;

  /// No description provided for @burningCrop.
  ///
  /// In en, this message translates to:
  /// **'Burning of crop residue'**
  String get burningCrop;

  /// No description provided for @burningOfGrabage.
  ///
  /// In en, this message translates to:
  /// **'Burning of garbage and leaves'**
  String get burningOfGrabage;

  /// No description provided for @cbacC_workingSmokeyFactory.
  ///
  /// In en, this message translates to:
  /// **'Working in a smokey factory'**
  String get cbacC_workingSmokeyFactory;

  /// No description provided for @cbacC_workingPollutedIndustries.
  ///
  /// In en, this message translates to:
  /// **'Working in industries with gas and smoke pollution such as brick kiln and glass industry etc.'**
  String get cbacC_workingPollutedIndustries;

  /// No description provided for @aesJeProgram.
  ///
  /// In en, this message translates to:
  /// **'AES/JE Eradication Program'**
  String get aesJeProgram;

  /// No description provided for @aesJeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'AES/JE Eradication Program'**
  String get aesJeScreenTitle;

  /// No description provided for @aesJeQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Amount payable to ASHA as community catalyst in 1000 population during IRS spraying'**
  String get aesJeQuestion1;

  /// No description provided for @aesJeDataSaved.
  ///
  /// In en, this message translates to:
  /// **'AES/JE data saved successfully!'**
  String get aesJeDataSaved;

  /// No description provided for @ambProgram.
  ///
  /// In en, this message translates to:
  /// **'AMB Eradication Program'**
  String get ambProgram;

  /// No description provided for @ambScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'AMB Eradication Program'**
  String get ambScreenTitle;

  /// No description provided for @ambQuestion1.
  ///
  /// In en, this message translates to:
  /// **'ASHA women of reproductive age (20 to 49 years) in their area who are pregnant or traveling maintenance in their Line Listing Register and the amount due for distribution of 4 IFA red pills per month to those women.'**
  String get ambQuestion1;

  /// No description provided for @ambQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Amount payable for regularizing the line listing register of the children of ASHA area from 6 months to 59 months and for distribution of syrup of IFA to those guardians/parents of the children.'**
  String get ambQuestion2;

  /// No description provided for @ambDataSaved.
  ///
  /// In en, this message translates to:
  /// **'AMB data saved successfully!'**
  String get ambDataSaved;

  /// No description provided for @kalaAzarProgram.
  ///
  /// In en, this message translates to:
  /// **'Kala-azar Eradication Program'**
  String get kalaAzarProgram;

  /// No description provided for @kalaAzarScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Kala-azar Eradication Program'**
  String get kalaAzarScreenTitle;

  /// No description provided for @kalaAzarQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Amount payable to ASHA for search of Kala-azar patient, to PHC, investigation, complete treatment, monitoring for 6 months.'**
  String get kalaAzarQuestion1;

  /// No description provided for @kalaAzarQuestion2.
  ///
  /// In en, this message translates to:
  /// **'ASHA on completion of treatment of Kala-azar patients in the government hospital under the chief minister Kala-azar Relief Scheme'**
  String get kalaAzarQuestion2;

  /// No description provided for @kalaAzarDataSaved.
  ///
  /// In en, this message translates to:
  /// **'Kala-azar screening data saved successfully!'**
  String get kalaAzarDataSaved;

  /// No description provided for @niddcpProgram.
  ///
  /// In en, this message translates to:
  /// **'NIDDCP Program'**
  String get niddcpProgram;

  /// No description provided for @niddcpScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'NIDDCP Program'**
  String get niddcpScreenTitle;

  /// No description provided for @niddcpQuestion1.
  ///
  /// In en, this message translates to:
  /// **'ASHA Incentive under NIDDCP'**
  String get niddcpQuestion1;

  /// No description provided for @niddcpDataSaved.
  ///
  /// In en, this message translates to:
  /// **'NIDDCP data saved successfully!'**
  String get niddcpDataSaved;

  /// No description provided for @trackingDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracking Due'**
  String get trackingDueTitle;

  /// No description provided for @birthDoses.
  ///
  /// In en, this message translates to:
  /// **'BIRTH DOSES'**
  String get birthDoses;

  /// No description provided for @sixWeek.
  ///
  /// In en, this message translates to:
  /// **'6 WEEK'**
  String get sixWeek;

  /// No description provided for @tenWeek.
  ///
  /// In en, this message translates to:
  /// **'10 WEEK'**
  String get tenWeek;

  /// No description provided for @fourteenWeek.
  ///
  /// In en, this message translates to:
  /// **'14 WEEK'**
  String get fourteenWeek;

  /// No description provided for @nineMonths.
  ///
  /// In en, this message translates to:
  /// **'9 MONTHS'**
  String get nineMonths;

  /// No description provided for @sixteenToTwentyFourMonths.
  ///
  /// In en, this message translates to:
  /// **'16-24 MONTHS'**
  String get sixteenToTwentyFourMonths;

  /// No description provided for @fiveToSixYear.
  ///
  /// In en, this message translates to:
  /// **'5-6 YEAR'**
  String get fiveToSixYear;

  /// No description provided for @tenYear.
  ///
  /// In en, this message translates to:
  /// **'10 YEAR'**
  String get tenYear;

  /// No description provided for @sixteenYear.
  ///
  /// In en, this message translates to:
  /// **'16 YEAR'**
  String get sixteenYear;

  /// No description provided for @dateOfVisit.
  ///
  /// In en, this message translates to:
  /// **'Date of visit'**
  String get dateOfVisit;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (1.2–90)kg'**
  String get weightLabel;

  /// No description provided for @enterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get enterWeight;

  /// No description provided for @doseTableDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get doseTableDueDate;

  /// No description provided for @doseTableActualDate.
  ///
  /// In en, this message translates to:
  /// **'Actual Date'**
  String get doseTableActualDate;

  /// No description provided for @datePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'dd-mm-yyyy'**
  String get datePlaceholder;

  /// No description provided for @contentComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Content Coming Soon...'**
  String get contentComingSoon;

  /// No description provided for @anyOtherSpecify.
  ///
  /// In en, this message translates to:
  /// **'Any other (specify)'**
  String get anyOtherSpecify;

  /// No description provided for @sixWeekDoses.
  ///
  /// In en, this message translates to:
  /// **'6 Week Doses'**
  String get sixWeekDoses;

  /// No description provided for @tenWeekDoses.
  ///
  /// In en, this message translates to:
  /// **'10 Week Doses'**
  String get tenWeekDoses;

  /// No description provided for @fourteenWeekDoses.
  ///
  /// In en, this message translates to:
  /// **'14 Week Doses'**
  String get fourteenWeekDoses;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @placeOfDeathLabel.
  ///
  /// In en, this message translates to:
  /// **'Place of Death'**
  String get placeOfDeathLabel;

  /// No description provided for @causeOfDeathLabel.
  ///
  /// In en, this message translates to:
  /// **'Cause of Death'**
  String get causeOfDeathLabel;

  /// No description provided for @dateOfDeathLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Death'**
  String get dateOfDeathLabel;

  /// No description provided for @deathDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Death Details'**
  String get deathDetailsLabel;

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @deceasedChildDetails.
  ///
  /// In en, this message translates to:
  /// **'Deceased Child Details'**
  String get deceasedChildDetails;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to our app'**
  String get welcome;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @patients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patients;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @selfHelp.
  ///
  /// In en, this message translates to:
  /// **'Self-help'**
  String get selfHelp;

  /// No description provided for @scanAndShare.
  ///
  /// In en, this message translates to:
  /// **'Scan and Share'**
  String get scanAndShare;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appUpdates.
  ///
  /// In en, this message translates to:
  /// **'App Updates'**
  String get appUpdates;

  /// No description provided for @upcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get upcomingAppointments;

  /// No description provided for @morningSummary.
  ///
  /// In en, this message translates to:
  /// **'Morning Summary'**
  String get morningSummary;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @updatePin.
  ///
  /// In en, this message translates to:
  /// **'Update PIN'**
  String get updatePin;

  /// No description provided for @switchClinic.
  ///
  /// In en, this message translates to:
  /// **'Switch Clinic'**
  String get switchClinic;

  /// No description provided for @defaultEmrSettings.
  ///
  /// In en, this message translates to:
  /// **'Default EMR Settings'**
  String get defaultEmrSettings;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @allowBackDatedAppointments.
  ///
  /// In en, this message translates to:
  /// **'Allow Back-dated Appointments'**
  String get allowBackDatedAppointments;

  /// No description provided for @hindiLanguage.
  ///
  /// In en, this message translates to:
  /// **'Hindi Language'**
  String get hindiLanguage;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @verifyPin.
  ///
  /// In en, this message translates to:
  /// **'Verify PIN'**
  String get verifyPin;

  /// No description provided for @loginWithBiometric.
  ///
  /// In en, this message translates to:
  /// **'Login With Biometric'**
  String get loginWithBiometric;

  /// No description provided for @enter4DigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4 digit PIN'**
  String get enter4DigitPin;

  /// No description provided for @signInWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Sign In with OTP'**
  String get signInWithOtp;

  /// No description provided for @enterEmailOrMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter your Email or Mobile No.'**
  String get enterEmailOrMobile;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// No description provided for @setupNewPin.
  ///
  /// In en, this message translates to:
  /// **'SET-UP NEW PIN'**
  String get setupNewPin;

  /// No description provided for @enterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Enter new PIN'**
  String get enterNewPin;

  /// No description provided for @reenterNewPin.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new PIN'**
  String get reenterNewPin;

  /// No description provided for @pinInstruction.
  ///
  /// In en, this message translates to:
  /// **'PIN is a 4-digit PIN that you have to set for mandatory two-factor authentication'**
  String get pinInstruction;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @pinSuccessfullySet.
  ///
  /// In en, this message translates to:
  /// **'PIN successfully set'**
  String get pinSuccessfullySet;

  /// No description provided for @pinLengthError.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 digits long'**
  String get pinLengthError;

  /// No description provided for @pinMismatchError.
  ///
  /// In en, this message translates to:
  /// **'PIN and Re-entered PIN do not match'**
  String get pinMismatchError;

  /// No description provided for @noVisitToday.
  ///
  /// In en, this message translates to:
  /// **'You have no visit today'**
  String get noVisitToday;

  /// No description provided for @noVisit.
  ///
  /// In en, this message translates to:
  /// **'You have no visit'**
  String get noVisit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @consultFreely.
  ///
  /// In en, this message translates to:
  /// **'Consult Freely. Practice Anywhere'**
  String get consultFreely;

  /// No description provided for @selectClinic.
  ///
  /// In en, this message translates to:
  /// **'Please select your clinic'**
  String get selectClinic;

  /// No description provided for @youHaveNoBillingDetails.
  ///
  /// In en, this message translates to:
  /// **'You have no billing details'**
  String get youHaveNoBillingDetails;

  /// No description provided for @addPatient.
  ///
  /// In en, this message translates to:
  /// **'Add Patient'**
  String get addPatient;

  /// No description provided for @noPatients.
  ///
  /// In en, this message translates to:
  /// **'You have no patients yet'**
  String get noPatients;

  /// No description provided for @fillDetailsToAddPatient.
  ///
  /// In en, this message translates to:
  /// **'Fill below details to add patient'**
  String get fillDetailsToAddPatient;

  /// No description provided for @uploadProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Profile Photo'**
  String get uploadProfilePhoto;

  /// No description provided for @patientFullName.
  ///
  /// In en, this message translates to:
  /// **'Patient\'s Full Name'**
  String get patientFullName;

  /// No description provided for @enterPatientFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the patient\'s full name'**
  String get enterPatientFullName;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'Date Of Birth'**
  String get dob;

  /// No description provided for @enterDob.
  ///
  /// In en, this message translates to:
  /// **'Please enter the date of birth'**
  String get enterDob;

  /// No description provided for @enterAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter the age'**
  String get enterAge;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter the mobile number'**
  String get enterMobileNumber;

  /// No description provided for @enterValidMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get enterValidMobileNumber;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @isGuardianPresent.
  ///
  /// In en, this message translates to:
  /// **'Is the guardian present?'**
  String get isGuardianPresent;

  /// No description provided for @guardianFullName.
  ///
  /// In en, this message translates to:
  /// **'Guardian Full Name'**
  String get guardianFullName;

  /// No description provided for @enterGuardianFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the guardian full name'**
  String get enterGuardianFullName;

  /// No description provided for @addPatientButton.
  ///
  /// In en, this message translates to:
  /// **'+ Add Patient'**
  String get addPatientButton;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong!'**
  String get somethingWentWrong;

  /// No description provided for @quickDemo.
  ///
  /// In en, this message translates to:
  /// **'Quick Demo'**
  String get quickDemo;

  /// No description provided for @noVideoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No video available for this topic'**
  String get noVideoAvailable;

  /// No description provided for @supportRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Your support request has been sent successfully!'**
  String get supportRequestSent;

  /// No description provided for @pleaseSelectSupportType.
  ///
  /// In en, this message translates to:
  /// **'Please select a support type *'**
  String get pleaseSelectSupportType;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @requestCallback.
  ///
  /// In en, this message translates to:
  /// **'Request Callback'**
  String get requestCallback;

  /// No description provided for @supportType.
  ///
  /// In en, this message translates to:
  /// **'Support Type'**
  String get supportType;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @abha.
  ///
  /// In en, this message translates to:
  /// **'ABHA'**
  String get abha;

  /// No description provided for @emr.
  ///
  /// In en, this message translates to:
  /// **'EMR (Electronic Medical Record)'**
  String get emr;

  /// No description provided for @teleconsultation.
  ///
  /// In en, this message translates to:
  /// **'Teleconsultation'**
  String get teleconsultation;

  /// No description provided for @mis.
  ///
  /// In en, this message translates to:
  /// **'MIS (Management Information System)'**
  String get mis;

  /// No description provided for @billDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill Details'**
  String get billDetailsTitle;

  /// No description provided for @billItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill Items'**
  String get billItemsTitle;

  /// No description provided for @consultation.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get consultation;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @taxesLabel.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get taxesLabel;

  /// No description provided for @netAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Amount'**
  String get netAmountLabel;

  /// No description provided for @paidAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmountLabel;

  /// No description provided for @pendingAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending Amount'**
  String get pendingAmountLabel;

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsTitle;

  /// No description provided for @sNoLabel.
  ///
  /// In en, this message translates to:
  /// **'SNo'**
  String get sNoLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @detailLabel.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detailLabel;

  /// No description provided for @paidByLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid ₹{amount} by {paymentMode}'**
  String paidByLabel(Object amount, Object paymentMode);

  /// No description provided for @billNumber.
  ///
  /// In en, this message translates to:
  /// **'Bill Number :'**
  String get billNumber;

  /// No description provided for @visitNumber.
  ///
  /// In en, this message translates to:
  /// **'Visit No :'**
  String get visitNumber;

  /// No description provided for @billedTo.
  ///
  /// In en, this message translates to:
  /// **'Billed To :'**
  String get billedTo;

  /// No description provided for @billDate.
  ///
  /// In en, this message translates to:
  /// **'Bill Date :'**
  String get billDate;

  /// No description provided for @pendingAmount.
  ///
  /// In en, this message translates to:
  /// **'Pending Amount :'**
  String get pendingAmount;

  /// No description provided for @visitTime.
  ///
  /// In en, this message translates to:
  /// **'Visit Time :'**
  String get visitTime;

  /// No description provided for @inClinic.
  ///
  /// In en, this message translates to:
  /// **'in clinic'**
  String get inClinic;

  /// No description provided for @withDoctor.
  ///
  /// In en, this message translates to:
  /// **'with'**
  String get withDoctor;

  /// No description provided for @onDateAtTime.
  ///
  /// In en, this message translates to:
  /// **'on {date} at {time}'**
  String onDateAtTime(Object date, Object time);

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @currentWeek.
  ///
  /// In en, this message translates to:
  /// **'Current Week'**
  String get currentWeek;

  /// No description provided for @currentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current Month'**
  String get currentMonth;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'(Rs.)'**
  String get currencySymbol;

  /// No description provided for @billed.
  ///
  /// In en, this message translates to:
  /// **'Billed'**
  String get billed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @yearToDate.
  ///
  /// In en, this message translates to:
  /// **'Year to Date'**
  String get yearToDate;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @newP.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newP;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @avgPatientLoad.
  ///
  /// In en, this message translates to:
  /// **'Avg Patient Load'**
  String get avgPatientLoad;

  /// No description provided for @avgPatientWaitTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Patient Wait Time'**
  String get avgPatientWaitTime;

  /// No description provided for @mins.
  ///
  /// In en, this message translates to:
  /// **'Mins'**
  String get mins;

  /// No description provided for @noOfLogins.
  ///
  /// In en, this message translates to:
  /// **'No of Logins'**
  String get noOfLogins;

  /// No description provided for @logins.
  ///
  /// In en, this message translates to:
  /// **'Logins'**
  String get logins;

  /// No description provided for @timeSpent.
  ///
  /// In en, this message translates to:
  /// **'Time Spent'**
  String get timeSpent;

  /// No description provided for @timeInHrs.
  ///
  /// In en, this message translates to:
  /// **'Time in Hrs'**
  String get timeInHrs;

  /// No description provided for @appointmentType.
  ///
  /// In en, this message translates to:
  /// **'Appointment Type'**
  String get appointmentType;

  /// No description provided for @clinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get clinic;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @abdm.
  ///
  /// In en, this message translates to:
  /// **'ABDM'**
  String get abdm;

  /// No description provided for @hfr.
  ///
  /// In en, this message translates to:
  /// **'HFR'**
  String get hfr;

  /// No description provided for @hprDhis.
  ///
  /// In en, this message translates to:
  /// **'HPR DHIS'**
  String get hprDhis;

  /// No description provided for @dhis.
  ///
  /// In en, this message translates to:
  /// **'DHIS'**
  String get dhis;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @languageBengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get languageBengali;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @useAI.
  ///
  /// In en, this message translates to:
  /// **'Use AI'**
  String get useAI;

  /// No description provided for @writeClinicalNotes.
  ///
  /// In en, this message translates to:
  /// **'Write Clinical Notes'**
  String get writeClinicalNotes;

  /// No description provided for @medicalSummary.
  ///
  /// In en, this message translates to:
  /// **'Medical Summary'**
  String get medicalSummary;

  /// No description provided for @visitedSummaryText.
  ///
  /// In en, this message translates to:
  /// **'Visited 15 days ago for hypertension and high cholesterol. Often complains of headaches and dizziness (6 visits this year). Takes Amlodipine 5 mg and Atorvastatin 20 mg. Allergic to penicillin and peanuts. Has Type 2 Diabetes for 10 years. Smokes 5 cigs/day, drinks alcohol occasionally. Family history of heart disease and diabetes. BP: 150/90, BMI: 28. Needs diet changes and to quit smoking for better health.'**
  String get visitedSummaryText;

  /// No description provided for @clickToTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Click to take photo'**
  String get clickToTakePhoto;

  /// No description provided for @complaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// No description provided for @vitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitals;

  /// No description provided for @diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosis;

  /// No description provided for @icd10.
  ///
  /// In en, this message translates to:
  /// **'ICD-10'**
  String get icd10;

  /// No description provided for @prescription.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescription;

  /// No description provided for @searchMedicinesHint.
  ///
  /// In en, this message translates to:
  /// **'Search medicines.'**
  String get searchMedicinesHint;

  /// No description provided for @doctorsPad.
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s Pad'**
  String get doctorsPad;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'Follow-Up'**
  String get followUp;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @doctorNote.
  ///
  /// In en, this message translates to:
  /// **'Doctor Note'**
  String get doctorNote;

  /// No description provided for @abhaRecords.
  ///
  /// In en, this message translates to:
  /// **'ABHA Records'**
  String get abhaRecords;

  /// No description provided for @how_to_book_appointment_new_patient.
  ///
  /// In en, this message translates to:
  /// **'How to book an appointment for a new patient?'**
  String get how_to_book_appointment_new_patient;

  /// No description provided for @how_to_book_appointment_existing_patient.
  ///
  /// In en, this message translates to:
  /// **'How to book an appointment for an existing patient?'**
  String get how_to_book_appointment_existing_patient;

  /// No description provided for @how_to_book_appointment_with_abha.
  ///
  /// In en, this message translates to:
  /// **'How to book an appointment with ABHA?'**
  String get how_to_book_appointment_with_abha;

  /// No description provided for @how_to_update_patient_details.
  ///
  /// In en, this message translates to:
  /// **'How to update patient details when adding an appointment?'**
  String get how_to_update_patient_details;

  /// No description provided for @how_to_reschedule_cancel_appointment.
  ///
  /// In en, this message translates to:
  /// **'How to reschedule or cancel an appointment?'**
  String get how_to_reschedule_cancel_appointment;

  /// No description provided for @how_to_view_daily_visit_list.
  ///
  /// In en, this message translates to:
  /// **'How to view the daily visit list?'**
  String get how_to_view_daily_visit_list;

  /// No description provided for @how_to_view_upcoming_visit_list.
  ///
  /// In en, this message translates to:
  /// **'How to view upcoming visit list?'**
  String get how_to_view_upcoming_visit_list;

  /// No description provided for @how_to_view_past_visit_list.
  ///
  /// In en, this message translates to:
  /// **'How to view past visit list?'**
  String get how_to_view_past_visit_list;

  /// No description provided for @how_to_search_patient_and_view_record.
  ///
  /// In en, this message translates to:
  /// **'How to search for a patient and see their complete medical record?'**
  String get how_to_search_patient_and_view_record;

  /// No description provided for @how_to_view_patient_records_abdm.
  ///
  /// In en, this message translates to:
  /// **'How to view patient records via ABDM?'**
  String get how_to_view_patient_records_abdm;

  /// No description provided for @how_to_pay_pending_bill.
  ///
  /// In en, this message translates to:
  /// **'How to pay a pending bill?'**
  String get how_to_pay_pending_bill;

  /// No description provided for @how_to_access_patient_bills.
  ///
  /// In en, this message translates to:
  /// **'How to access patient bills?'**
  String get how_to_access_patient_bills;

  /// No description provided for @how_to_check_pending_payments_today.
  ///
  /// In en, this message translates to:
  /// **'How to check pending payments for the day?'**
  String get how_to_check_pending_payments_today;

  /// No description provided for @how_to_create_abha_for_new_patient.
  ///
  /// In en, this message translates to:
  /// **'How to create ABHA for new patients?'**
  String get how_to_create_abha_for_new_patient;

  /// No description provided for @how_to_link_existing_abha_with_appointment.
  ///
  /// In en, this message translates to:
  /// **'How to link a patient’s existing ABHA with an appointment?'**
  String get how_to_link_existing_abha_with_appointment;

  /// No description provided for @how_to_link_abha_completed_consultation.
  ///
  /// In en, this message translates to:
  /// **'How to link ABHA for a completed consultation?'**
  String get how_to_link_abha_completed_consultation;

  /// No description provided for @how_to_upload_rx_complete_consultation.
  ///
  /// In en, this message translates to:
  /// **'How to upload an Rx and complete a consultation?'**
  String get how_to_upload_rx_complete_consultation;

  /// No description provided for @how_to_add_notes_complete_consultation.
  ///
  /// In en, this message translates to:
  /// **'How to add clinical notes and complete a consultation?'**
  String get how_to_add_notes_complete_consultation;

  /// No description provided for @how_to_consult_using_voice_analyzer.
  ///
  /// In en, this message translates to:
  /// **'How to consult using the Voice analyzer?'**
  String get how_to_consult_using_voice_analyzer;

  /// No description provided for @how_to_view_prescription_info.
  ///
  /// In en, this message translates to:
  /// **'How to view prescription or consultation information for the patient?'**
  String get how_to_view_prescription_info;

  /// No description provided for @how_to_send_prescription_info_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'How to send prescription or consultation information to the patient via WhatsApp?'**
  String get how_to_send_prescription_info_whatsapp;

  /// No description provided for @how_to_create_prescription_templates.
  ///
  /// In en, this message translates to:
  /// **'How to create pre-set prescription templates?'**
  String get how_to_create_prescription_templates;

  /// No description provided for @how_to_create_test_recommendation_lists.
  ///
  /// In en, this message translates to:
  /// **'How to create test recommendation lists?'**
  String get how_to_create_test_recommendation_lists;

  /// No description provided for @how_to_add_complete_tele_consult.
  ///
  /// In en, this message translates to:
  /// **'How to add and complete a tele-consult?'**
  String get how_to_add_complete_tele_consult;

  /// No description provided for @how_to_enable_tele_consultation.
  ///
  /// In en, this message translates to:
  /// **'How to enable tele-consultation?'**
  String get how_to_enable_tele_consultation;

  /// No description provided for @how_to_change_account_password.
  ///
  /// In en, this message translates to:
  /// **'How to change account password?'**
  String get how_to_change_account_password;

  /// No description provided for @how_to_change_account_pin.
  ///
  /// In en, this message translates to:
  /// **'How to change account PIN?'**
  String get how_to_change_account_pin;

  /// No description provided for @how_to_consult_in_multiple_clinics.
  ///
  /// In en, this message translates to:
  /// **'How to consult in multiple clinics?'**
  String get how_to_consult_in_multiple_clinics;

  /// No description provided for @how_to_switch_between_clinics.
  ///
  /// In en, this message translates to:
  /// **'How to switch between clinics?'**
  String get how_to_switch_between_clinics;

  /// No description provided for @how_to_set_primary_consultation_type.
  ///
  /// In en, this message translates to:
  /// **'How to set the primary consultation type?'**
  String get how_to_set_primary_consultation_type;

  /// No description provided for @how_to_setup_biometric_login.
  ///
  /// In en, this message translates to:
  /// **'How to setup biometric login?'**
  String get how_to_setup_biometric_login;

  /// No description provided for @how_to_check_clinic_insights.
  ///
  /// In en, this message translates to:
  /// **'How to check clinic insights?'**
  String get how_to_check_clinic_insights;

  /// No description provided for @doctorNotesAnalyser.
  ///
  /// In en, this message translates to:
  /// **'Doctor Notes Analyser'**
  String get doctorNotesAnalyser;

  /// No description provided for @transcribedNotes.
  ///
  /// In en, this message translates to:
  /// **'Transcribed Notes'**
  String get transcribedNotes;

  /// No description provided for @chiefComplaints.
  ///
  /// In en, this message translates to:
  /// **'Chief Complaints'**
  String get chiefComplaints;

  /// No description provided for @advice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get advice;

  /// No description provided for @provisionalDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Provisional Diagnosis'**
  String get provisionalDiagnosis;

  /// No description provided for @drugListSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Drug List - Select one from list'**
  String get drugListSelectOne;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressure;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// No description provided for @noPrescriptionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No prescriptions available'**
  String get noPrescriptionsAvailable;

  /// No description provided for @strength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get strength;

  /// No description provided for @formulation.
  ///
  /// In en, this message translates to:
  /// **'Formulation'**
  String get formulation;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @noOfDays.
  ///
  /// In en, this message translates to:
  /// **'No. of Days'**
  String get noOfDays;

  /// No description provided for @instruction.
  ///
  /// In en, this message translates to:
  /// **'Instruction'**
  String get instruction;

  /// No description provided for @matchingDrugs.
  ///
  /// In en, this message translates to:
  /// **'Matching Drugs'**
  String get matchingDrugs;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @visitHistory.
  ///
  /// In en, this message translates to:
  /// **'Visit History'**
  String get visitHistory;

  /// No description provided for @noVisitHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No Visit History Found'**
  String get noVisitHistoryFound;

  /// No description provided for @noDoctorNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No doctor notes available'**
  String get noDoctorNotesAvailable;

  /// No description provided for @unknownComplaint.
  ///
  /// In en, this message translates to:
  /// **'Unknown Complaint'**
  String get unknownComplaint;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @dosageFrequency.
  ///
  /// In en, this message translates to:
  /// **'Dosage | Frequency'**
  String get dosageFrequency;

  /// No description provided for @drugNameStrengthFormulation.
  ///
  /// In en, this message translates to:
  /// **'Drug Name [Strength | Formulation]'**
  String get drugNameStrengthFormulation;

  /// No description provided for @doctorNotes.
  ///
  /// In en, this message translates to:
  /// **'Doctor Notes'**
  String get doctorNotes;

  /// No description provided for @unknownVital.
  ///
  /// In en, this message translates to:
  /// **'Unknown Vital'**
  String get unknownVital;

  /// No description provided for @vitalName.
  ///
  /// In en, this message translates to:
  /// **'Vital Name'**
  String get vitalName;

  /// No description provided for @noImageFound.
  ///
  /// In en, this message translates to:
  /// **'No image found'**
  String get noImageFound;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @noDocumentFound.
  ///
  /// In en, this message translates to:
  /// **'No document found'**
  String get noDocumentFound;

  /// No description provided for @consultationDetails.
  ///
  /// In en, this message translates to:
  /// **'Consultation Details'**
  String get consultationDetails;

  /// No description provided for @tapToStop.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get tapToStop;

  /// No description provided for @consultationAboutToComplete.
  ///
  /// In en, this message translates to:
  /// **'It is about to complete the consultation'**
  String get consultationAboutToComplete;

  /// No description provided for @consultationDataGathered.
  ///
  /// In en, this message translates to:
  /// **'We have almost gathered your consultation data'**
  String get consultationDataGathered;

  /// No description provided for @analysingData.
  ///
  /// In en, this message translates to:
  /// **'Analysing Data'**
  String get analysingData;

  /// No description provided for @transcribedNote.
  ///
  /// In en, this message translates to:
  /// **'Transcribed Note'**
  String get transcribedNote;

  /// No description provided for @totalUsageTime.
  ///
  /// In en, this message translates to:
  /// **'Total Usage Time'**
  String get totalUsageTime;

  /// No description provided for @analysedNotedSummary.
  ///
  /// In en, this message translates to:
  /// **'Analysed Noted Summary'**
  String get analysedNotedSummary;

  /// No description provided for @analysedOn.
  ///
  /// In en, this message translates to:
  /// **'Analysed on'**
  String get analysedOn;

  /// No description provided for @hearRecording.
  ///
  /// In en, this message translates to:
  /// **'Hear Recording'**
  String get hearRecording;

  /// No description provided for @drugList.
  ///
  /// In en, this message translates to:
  /// **'Drug List'**
  String get drugList;

  /// No description provided for @noAdvice.
  ///
  /// In en, this message translates to:
  /// **'No advice'**
  String get noAdvice;

  /// No description provided for @noDiagnosisAvailable.
  ///
  /// In en, this message translates to:
  /// **'No diagnosis available'**
  String get noDiagnosisAvailable;

  /// No description provided for @noVitalsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No vitals available'**
  String get noVitalsAvailable;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @fillBelowDetailsToAddPatient.
  ///
  /// In en, this message translates to:
  /// **'Fill below details to add patient'**
  String get fillBelowDetailsToAddPatient;

  /// No description provided for @patientsFullName.
  ///
  /// In en, this message translates to:
  /// **'Patient\'s Full Name'**
  String get patientsFullName;

  /// No description provided for @pleaseEnterPatientsFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the patient\'s full name'**
  String get pleaseEnterPatientsFullName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date Of Birth'**
  String get dateOfBirth;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @pleaseEnterGuardianFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter the guardian full name'**
  String get pleaseEnterGuardianFullName;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @searchPatientName.
  ///
  /// In en, this message translates to:
  /// **'Search Patient Name'**
  String get searchPatientName;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'+ Add New'**
  String get addNew;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender: '**
  String get genderLabel;

  /// No description provided for @abhaIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ABHA Id: '**
  String get abhaIdLabel;

  /// No description provided for @availableSlots.
  ///
  /// In en, this message translates to:
  /// **'Available Slots'**
  String get availableSlots;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @consultantFees.
  ///
  /// In en, this message translates to:
  /// **'Consultant Fees'**
  String get consultantFees;

  /// No description provided for @walkInConsultation.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Consultation'**
  String get walkInConsultation;

  /// No description provided for @selectConsultantType.
  ///
  /// In en, this message translates to:
  /// **'Select Consultant Type :'**
  String get selectConsultantType;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @payLater.
  ///
  /// In en, this message translates to:
  /// **'Pay Later'**
  String get payLater;

  /// No description provided for @pleaseEnterValidMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get pleaseEnterValidMobileNumber;

  /// No description provided for @enterPatientName.
  ///
  /// In en, this message translates to:
  /// **'Enter Patient Name'**
  String get enterPatientName;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @bookWithAbha.
  ///
  /// In en, this message translates to:
  /// **'Book With ABHA'**
  String get bookWithAbha;

  /// No description provided for @appointmentActions.
  ///
  /// In en, this message translates to:
  /// **'Appointment Actions'**
  String get appointmentActions;

  /// No description provided for @rxUploadAndSave.
  ///
  /// In en, this message translates to:
  /// **'Rx upload and save'**
  String get rxUploadAndSave;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @linkWithAbha.
  ///
  /// In en, this message translates to:
  /// **'Link with ABHA'**
  String get linkWithAbha;

  /// No description provided for @viewRx.
  ///
  /// In en, this message translates to:
  /// **'View Rx'**
  String get viewRx;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @enterYourReasonHere.
  ///
  /// In en, this message translates to:
  /// **'Enter your reason here'**
  String get enterYourReasonHere;

  /// No description provided for @uploadRx.
  ///
  /// In en, this message translates to:
  /// **'Upload Rx'**
  String get uploadRx;

  /// No description provided for @useCamera.
  ///
  /// In en, this message translates to:
  /// **'Use Camera'**
  String get useCamera;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @healthIdAbhaAddress.
  ///
  /// In en, this message translates to:
  /// **'Health ID (ABHA Address)'**
  String get healthIdAbhaAddress;

  /// No description provided for @healthId.
  ///
  /// In en, this message translates to:
  /// **'Health ID'**
  String get healthId;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @createAbha.
  ///
  /// In en, this message translates to:
  /// **'Create ABHA'**
  String get createAbha;

  /// No description provided for @igree1.
  ///
  /// In en, this message translates to:
  /// **'I intend to create Ayushman Bharat Health Account Number (“ABHA number”) and Ayushman Bharat Health Account address (“ABHA Address”) using a document other than Aadhaar. (Click here to proceed further)'**
  String get igree1;

  /// No description provided for @igree2.
  ///
  /// In en, this message translates to:
  /// **'I consent to the usage of my ABHA address and ABHA number for linking my legacy (past) government health records and those which will be generated during this encounter.'**
  String get igree2;

  /// No description provided for @igree3.
  ///
  /// In en, this message translates to:
  /// **'I authorize the sharing of all my health records with healthcare provider(s) for the purpose of providing healthcare services to me during this encounter.'**
  String get igree3;

  /// No description provided for @igree4.
  ///
  /// In en, this message translates to:
  /// **'I consent to the anonymization and subsequent use of my government health records for public health purposes.'**
  String get igree4;

  /// No description provided for @igree6.
  ///
  /// In en, this message translates to:
  /// **'I have been explained about the consent as stated above and hereby provide my consent for the aforementioned purposes.'**
  String get igree6;

  /// No description provided for @checkAvailableAbhaAddress.
  ///
  /// In en, this message translates to:
  /// **'Check Available ABHA Address'**
  String get checkAvailableAbhaAddress;

  /// No description provided for @abhaNumber.
  ///
  /// In en, this message translates to:
  /// **'ABHA Number'**
  String get abhaNumber;

  /// No description provided for @linkExisting.
  ///
  /// In en, this message translates to:
  /// **'Link Existing'**
  String get linkExisting;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @createVia.
  ///
  /// In en, this message translates to:
  /// **'Create Via'**
  String get createVia;

  /// No description provided for @aadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get aadhaarNumber;

  /// No description provided for @iHerebyDeclareThat.
  ///
  /// In en, this message translates to:
  /// **'I hereby declare that:'**
  String get iHerebyDeclareThat;

  /// No description provided for @agreeAll.
  ///
  /// In en, this message translates to:
  /// **'Agree All'**
  String get agreeAll;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @useExisting.
  ///
  /// In en, this message translates to:
  /// **'Use Existing'**
  String get useExisting;

  /// No description provided for @createAbhaAddress.
  ///
  /// In en, this message translates to:
  /// **'Create ABHA Address'**
  String get createAbhaAddress;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @proceedwithkyc.
  ///
  /// In en, this message translates to:
  /// **'Proceed With KYC'**
  String get proceedwithkyc;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @enterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Enter First Name'**
  String get enterFirstName;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get middleName;

  /// No description provided for @enterMiddleName.
  ///
  /// In en, this message translates to:
  /// **'Enter Middle Name'**
  String get enterMiddleName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @enterLastName.
  ///
  /// In en, this message translates to:
  /// **'Enter Last Name'**
  String get enterLastName;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @emailId.
  ///
  /// In en, this message translates to:
  /// **'Email ID'**
  String get emailId;

  /// No description provided for @enterEmailId.
  ///
  /// In en, this message translates to:
  /// **'Enter Email ID'**
  String get enterEmailId;

  /// No description provided for @enterMobileNo.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Number'**
  String get enterMobileNo;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'Pin Code'**
  String get pinCode;

  /// No description provided for @enterPincode.
  ///
  /// In en, this message translates to:
  /// **'Enter Pincode'**
  String get enterPincode;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @abhaId.
  ///
  /// In en, this message translates to:
  /// **'ABHA ID'**
  String get abhaId;

  /// No description provided for @suggestedAbhaAddress.
  ///
  /// In en, this message translates to:
  /// **'Suggested ABHA Address'**
  String get suggestedAbhaAddress;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @linkHealthId.
  ///
  /// In en, this message translates to:
  /// **'Link Health ID'**
  String get linkHealthId;

  /// No description provided for @authenticationMethod.
  ///
  /// In en, this message translates to:
  /// **'Authentication Method'**
  String get authenticationMethod;

  /// No description provided for @otp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otp;

  /// No description provided for @verifyAndLink.
  ///
  /// In en, this message translates to:
  /// **'Verify & Link'**
  String get verifyAndLink;

  /// No description provided for @msg_no_slots_available.
  ///
  /// In en, this message translates to:
  /// **'slots are not available'**
  String get msg_no_slots_available;

  /// No description provided for @mob_no.
  ///
  /// In en, this message translates to:
  /// **'Mobile No'**
  String get mob_no;

  /// No description provided for @mohalla.
  ///
  /// In en, this message translates to:
  /// **'Mohalla'**
  String get mohalla;

  /// No description provided for @search_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search by HH ID, Name or Mobile'**
  String get search_placeholder;

  /// No description provided for @no_pregnancy_cases_found.
  ///
  /// In en, this message translates to:
  /// **'No pregnancy cases found'**
  String get no_pregnancy_cases_found;

  /// No description provided for @no_hbnc_beneficiaries_found.
  ///
  /// In en, this message translates to:
  /// **'No HBNC beneficiaries found'**
  String get no_hbnc_beneficiaries_found;

  /// No description provided for @no_high_risk_anc_visits_found.
  ///
  /// In en, this message translates to:
  /// **'No high-risk ANC visits found'**
  String get no_high_risk_anc_visits_found;

  /// No description provided for @hrp.
  ///
  /// In en, this message translates to:
  /// **'HRP'**
  String get hrp;

  /// No description provided for @no_name.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get no_name;

  /// No description provided for @search_by_id_name_contact.
  ///
  /// In en, this message translates to:
  /// **'Search by ID/Name/Contact'**
  String get search_by_id_name_contact;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @death_record_details.
  ///
  /// In en, this message translates to:
  /// **'Death Record Details'**
  String get death_record_details;

  /// No description provided for @death_record.
  ///
  /// In en, this message translates to:
  /// **'Death Record'**
  String get death_record;

  /// No description provided for @try_different_search_term.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get try_different_search_term;

  /// No description provided for @no_matching_records_found.
  ///
  /// In en, this message translates to:
  /// **'No matching records found'**
  String get no_matching_records_found;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @no_death_records_in_database.
  ///
  /// In en, this message translates to:
  /// **'There are no death records in the database.'**
  String get no_death_records_in_database;

  /// No description provided for @no_death_records_found.
  ///
  /// In en, this message translates to:
  /// **'No death records found'**
  String get no_death_records_found;

  /// No description provided for @refresh_data.
  ///
  /// In en, this message translates to:
  /// **'Refresh data'**
  String get refresh_data;

  /// No description provided for @guest_beneficiaries.
  ///
  /// In en, this message translates to:
  /// **'Guest Beneficiaries'**
  String get guest_beneficiaries;

  /// No description provided for @no_guest_beneficiaries_found.
  ///
  /// In en, this message translates to:
  /// **'No guest beneficiaries found'**
  String get no_guest_beneficiaries_found;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @pendingVisits.
  ///
  /// In en, this message translates to:
  /// **'Pending visits'**
  String get pendingVisits;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @failedToLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video'**
  String get failedToLoadVideo;

  /// No description provided for @unableToOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Unable to open dialer on this device.'**
  String get unableToOpenDialer;

  /// No description provided for @unableToOpenEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Unable to open email app on this device.'**
  String get unableToOpenEmailApp;

  /// No description provided for @disability.
  ///
  /// In en, this message translates to:
  /// **'Disability'**
  String get disability;

  /// No description provided for @hasConditions.
  ///
  /// In en, this message translates to:
  /// **'Has Conditions'**
  String get hasConditions;

  /// No description provided for @idType.
  ///
  /// In en, this message translates to:
  /// **'ID Type'**
  String get idType;

  /// No description provided for @village.
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @fathersName.
  ///
  /// In en, this message translates to:
  /// **'Father\'s Name'**
  String get fathersName;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @beneficiaryId.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary ID'**
  String get beneficiaryId;

  /// No description provided for @householdId.
  ///
  /// In en, this message translates to:
  /// **'Household ID'**
  String get householdId;

  /// No description provided for @registrationDate.
  ///
  /// In en, this message translates to:
  /// **'Registration Date'**
  String get registrationDate;

  /// No description provided for @formId.
  ///
  /// In en, this message translates to:
  /// **'Form ID'**
  String get formId;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @cbacFormDetails.
  ///
  /// In en, this message translates to:
  /// **'CBAC Form Details'**
  String get cbacFormDetails;

  /// No description provided for @anmName.
  ///
  /// In en, this message translates to:
  /// **'ANM Name'**
  String get anmName;

  /// No description provided for @ashaName.
  ///
  /// In en, this message translates to:
  /// **'ASHA Name'**
  String get ashaName;

  /// No description provided for @healthcareProviderInformation.
  ///
  /// In en, this message translates to:
  /// **'Healthcare Provider Information'**
  String get healthcareProviderInformation;

  /// No description provided for @hsc.
  ///
  /// In en, this message translates to:
  /// **'HSC'**
  String get hsc;

  /// No description provided for @phc.
  ///
  /// In en, this message translates to:
  /// **'PHC'**
  String get phc;

  /// No description provided for @familyHistory.
  ///
  /// In en, this message translates to:
  /// **'Family History'**
  String get familyHistory;

  /// No description provided for @waistMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Waist Measurement'**
  String get waistMeasurement;

  /// No description provided for @physicalActivity.
  ///
  /// In en, this message translates to:
  /// **'Physical Activity'**
  String get physicalActivity;

  /// No description provided for @alcoholConsumption.
  ///
  /// In en, this message translates to:
  /// **'Alcohol Consumption'**
  String get alcoholConsumption;

  /// No description provided for @tobaccoUse.
  ///
  /// In en, this message translates to:
  /// **'Tobacco Use'**
  String get tobaccoUse;

  /// No description provided for @ageGroup.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get ageGroup;

  /// No description provided for @partA_riskFactors.
  ///
  /// In en, this message translates to:
  /// **'Part A - Risk Factors'**
  String get partA_riskFactors;

  /// No description provided for @voiceChange.
  ///
  /// In en, this message translates to:
  /// **'Voice Change'**
  String get voiceChange;

  /// No description provided for @hearingDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Hearing Difficulty'**
  String get hearingDifficulty;

  /// No description provided for @eyeRedness.
  ///
  /// In en, this message translates to:
  /// **'Eye Redness'**
  String get eyeRedness;

  /// No description provided for @eyePain.
  ///
  /// In en, this message translates to:
  /// **'Eye Pain'**
  String get eyePain;

  /// No description provided for @readingDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Reading Difficulty'**
  String get readingDifficulty;

  /// No description provided for @blurredVision.
  ///
  /// In en, this message translates to:
  /// **'Blurred Vision'**
  String get blurredVision;

  /// No description provided for @tinglingSensation.
  ///
  /// In en, this message translates to:
  /// **'Tingling Sensation'**
  String get tinglingSensation;

  /// No description provided for @palmsSolesIssues.
  ///
  /// In en, this message translates to:
  /// **'Palms/Soles Issues'**
  String get palmsSolesIssues;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @tuberculosis.
  ///
  /// In en, this message translates to:
  /// **'Tuberculosis'**
  String get tuberculosis;

  /// No description provided for @drugUse.
  ///
  /// In en, this message translates to:
  /// **'Drug Use'**
  String get drugUse;

  /// No description provided for @painWhileChewing.
  ///
  /// In en, this message translates to:
  /// **'Pain While Chewing'**
  String get painWhileChewing;

  /// No description provided for @rashInMouth.
  ///
  /// In en, this message translates to:
  /// **'Rash in Mouth'**
  String get rashInMouth;

  /// No description provided for @swellingInMouth.
  ///
  /// In en, this message translates to:
  /// **'Swelling in Mouth'**
  String get swellingInMouth;

  /// No description provided for @ulcers.
  ///
  /// In en, this message translates to:
  /// **'Ulcers'**
  String get ulcers;

  /// No description provided for @difficultyOpeningMouth.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Opening Mouth'**
  String get difficultyOpeningMouth;

  /// No description provided for @seizures.
  ///
  /// In en, this message translates to:
  /// **'Seizures'**
  String get seizures;

  /// No description provided for @nightSweats.
  ///
  /// In en, this message translates to:
  /// **'Night Sweats'**
  String get nightSweats;

  /// No description provided for @weightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight Loss'**
  String get weightLoss;

  /// No description provided for @fever2Weeks.
  ///
  /// In en, this message translates to:
  /// **'Fever for 2+ Weeks'**
  String get fever2Weeks;

  /// No description provided for @bloodInMucus.
  ///
  /// In en, this message translates to:
  /// **'Blood in Mucus'**
  String get bloodInMucus;

  /// No description provided for @cough2Weeks.
  ///
  /// In en, this message translates to:
  /// **'Cough for 2+ Weeks'**
  String get cough2Weeks;

  /// No description provided for @shortnessOfBreath.
  ///
  /// In en, this message translates to:
  /// **'Shortness of Breath'**
  String get shortnessOfBreath;

  /// No description provided for @partB1GeneralSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Part B1 - General Symptoms'**
  String get partB1GeneralSymptoms;

  /// No description provided for @partB1_skinSensorySymptoms.
  ///
  /// In en, this message translates to:
  /// **'Part B1 - Skin & Sensory Symptoms'**
  String get partB1_skinSensorySymptoms;

  /// No description provided for @skinRashDiscoloration.
  ///
  /// In en, this message translates to:
  /// **'Skin Rash/Discoloration'**
  String get skinRashDiscoloration;

  /// No description provided for @thickSkin.
  ///
  /// In en, this message translates to:
  /// **'Thick Skin'**
  String get thickSkin;

  /// No description provided for @skinLump.
  ///
  /// In en, this message translates to:
  /// **'Skin Lump'**
  String get skinLump;

  /// No description provided for @numbnessHotCold.
  ///
  /// In en, this message translates to:
  /// **'Numbness (Hot/Cold)'**
  String get numbnessHotCold;

  /// No description provided for @scratchesCracks.
  ///
  /// In en, this message translates to:
  /// **'Scratches/Cracks'**
  String get scratchesCracks;

  /// No description provided for @tinglingNumbness.
  ///
  /// In en, this message translates to:
  /// **'Tingling/Numbness'**
  String get tinglingNumbness;

  /// No description provided for @eyelidClosingDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Eyelid Closing Difficulty'**
  String get eyelidClosingDifficulty;

  /// No description provided for @holdingDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Holding Difficulty'**
  String get holdingDifficulty;

  /// No description provided for @legWeaknessWalk.
  ///
  /// In en, this message translates to:
  /// **'Leg Weakness/Walk'**
  String get legWeaknessWalk;

  /// No description provided for @partB2_womenHealthSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Part B2 - Women’s Health Symptoms'**
  String get partB2_womenHealthSymptoms;

  /// No description provided for @breastLump.
  ///
  /// In en, this message translates to:
  /// **'Breast Lump'**
  String get breastLump;

  /// No description provided for @nippleBleeding.
  ///
  /// In en, this message translates to:
  /// **'Nipple Bleeding'**
  String get nippleBleeding;

  /// No description provided for @breastShapeDifference.
  ///
  /// In en, this message translates to:
  /// **'Breast Shape Difference'**
  String get breastShapeDifference;

  /// No description provided for @excessiveBleeding.
  ///
  /// In en, this message translates to:
  /// **'Excessive Bleeding'**
  String get excessiveBleeding;

  /// No description provided for @depression.
  ///
  /// In en, this message translates to:
  /// **'Depression'**
  String get depression;

  /// No description provided for @uterusProlapse.
  ///
  /// In en, this message translates to:
  /// **'Uterus Prolapse'**
  String get uterusProlapse;

  /// No description provided for @postMenopauseBleeding.
  ///
  /// In en, this message translates to:
  /// **'Post Menopause Bleeding'**
  String get postMenopauseBleeding;

  /// No description provided for @postIntercourseBleeding.
  ///
  /// In en, this message translates to:
  /// **'Post Intercourse Bleeding'**
  String get postIntercourseBleeding;

  /// No description provided for @smellyDischarge.
  ///
  /// In en, this message translates to:
  /// **'Smelly Discharge'**
  String get smellyDischarge;

  /// No description provided for @irregularPeriods.
  ///
  /// In en, this message translates to:
  /// **'Irregular Periods'**
  String get irregularPeriods;

  /// No description provided for @jointPain.
  ///
  /// In en, this message translates to:
  /// **'Joint Pain'**
  String get jointPain;

  /// No description provided for @totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get totalScore;

  /// No description provided for @partDScore.
  ///
  /// In en, this message translates to:
  /// **'Part D Score'**
  String get partDScore;

  /// No description provided for @partAScore.
  ///
  /// In en, this message translates to:
  /// **'Part A Score'**
  String get partAScore;

  /// No description provided for @assessmentScores.
  ///
  /// In en, this message translates to:
  /// **'Assessment Scores'**
  String get assessmentScores;

  /// No description provided for @question2.
  ///
  /// In en, this message translates to:
  /// **'Question 2'**
  String get question2;

  /// No description provided for @question1.
  ///
  /// In en, this message translates to:
  /// **'Question 1'**
  String get question1;

  /// No description provided for @partD_mentalHealthAssessment.
  ///
  /// In en, this message translates to:
  /// **'Part D - Mental Health Assessment'**
  String get partD_mentalHealthAssessment;

  /// No description provided for @businessRisk.
  ///
  /// In en, this message translates to:
  /// **'Business Risk'**
  String get businessRisk;

  /// No description provided for @cookingFuel.
  ///
  /// In en, this message translates to:
  /// **'Cooking Fuel'**
  String get cookingFuel;

  /// No description provided for @partC_environmentalFactors.
  ///
  /// In en, this message translates to:
  /// **'Part C - Environmental Factors'**
  String get partC_environmentalFactors;

  /// No description provided for @ncdBeneficiarySearch.
  ///
  /// In en, this message translates to:
  /// **'NCD Beneficiary Search'**
  String get ncdBeneficiarySearch;

  /// No description provided for @wifeName.
  ///
  /// In en, this message translates to:
  /// **'Wife Name'**
  String get wifeName;

  /// No description provided for @husbandName.
  ///
  /// In en, this message translates to:
  /// **'Husband Name'**
  String get husbandName;

  /// No description provided for @noRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No records found'**
  String get noRecordsFound;

  /// No description provided for @tolaMohalla.
  ///
  /// In en, this message translates to:
  /// **'Mohalla/Tola'**
  String get tolaMohalla;

  /// No description provided for @noHouseholdsFound.
  ///
  /// In en, this message translates to:
  /// **'No households found'**
  String get noHouseholdsFound;

  /// No description provided for @noOfASHAUnderTheFacilitator.
  ///
  /// In en, this message translates to:
  /// **'No. of ASHA under the facilitator'**
  String get noOfASHAUnderTheFacilitator;

  /// No description provided for @ashaFacilitatorClusterMeetingList.
  ///
  /// In en, this message translates to:
  /// **'ASHA Facilitator Cluster Meeting List'**
  String get ashaFacilitatorClusterMeetingList;

  /// No description provided for @addNewClusterMeeting.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW CLUSTER MEETING'**
  String get addNewClusterMeeting;

  /// No description provided for @facilitatorNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Facilitator not specified'**
  String get facilitatorNotSpecified;

  /// No description provided for @clusterMeetings.
  ///
  /// In en, this message translates to:
  /// **'Cluster meetings'**
  String get clusterMeetings;

  /// No description provided for @ashaFacilitatorClusterMeeting.
  ///
  /// In en, this message translates to:
  /// **'ASHA Facilitator Cluster Meeting'**
  String get ashaFacilitatorClusterMeeting;

  /// No description provided for @phcName.
  ///
  /// In en, this message translates to:
  /// **'PHC Name'**
  String get phcName;

  /// No description provided for @decisionTakenDuringMeeting.
  ///
  /// In en, this message translates to:
  /// **'Decision Taken During the Meeting'**
  String get decisionTakenDuringMeeting;

  /// No description provided for @discussionSubTopicProgram.
  ///
  /// In en, this message translates to:
  /// **'Discussion Sub Topic/Program'**
  String get discussionSubTopicProgram;

  /// No description provided for @discussionTopicProgram.
  ///
  /// In en, this message translates to:
  /// **'Discussion Topic/Program'**
  String get discussionTopicProgram;

  /// No description provided for @selectTopics.
  ///
  /// In en, this message translates to:
  /// **'Select Topics'**
  String get selectTopics;

  /// No description provided for @clusterMeetingsCountThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No. of cluster meetings conducted in this month'**
  String get clusterMeetingsCountThisMonth;

  /// No description provided for @noOfASHAAbsentInThisMeeting.
  ///
  /// In en, this message translates to:
  /// **'No. of ASHA absent in this meeting'**
  String get noOfASHAAbsentInThisMeeting;

  /// No description provided for @ashaPresentCount.
  ///
  /// In en, this message translates to:
  /// **'No. of ASHA present in this meeting'**
  String get ashaPresentCount;

  /// No description provided for @totalAshaUnderFacilitator.
  ///
  /// In en, this message translates to:
  /// **'Total no. of ASHA under facilitator'**
  String get totalAshaUnderFacilitator;

  /// No description provided for @noOfHours.
  ///
  /// In en, this message translates to:
  /// **'No. of hours'**
  String get noOfHours;

  /// No description provided for @toTime.
  ///
  /// In en, this message translates to:
  /// **'To (HH:MM)'**
  String get toTime;

  /// No description provided for @ashaInchargeName.
  ///
  /// In en, this message translates to:
  /// **'ASHA Incharge Name'**
  String get ashaInchargeName;

  /// No description provided for @ashaFacilitatorName.
  ///
  /// In en, this message translates to:
  /// **'ASHA Facilitator Name'**
  String get ashaFacilitatorName;

  /// No description provided for @subcenterName.
  ///
  /// In en, this message translates to:
  /// **'Subcenter Name'**
  String get subcenterName;

  /// No description provided for @awwName.
  ///
  /// In en, this message translates to:
  /// **'AWW Name'**
  String get awwName;

  /// No description provided for @awcNumber.
  ///
  /// In en, this message translates to:
  /// **'AWC Number'**
  String get awcNumber;

  /// No description provided for @villageName.
  ///
  /// In en, this message translates to:
  /// **'Village Name'**
  String get villageName;

  /// No description provided for @wardName.
  ///
  /// In en, this message translates to:
  /// **'Ward Name'**
  String get wardName;

  /// No description provided for @wardNumber.
  ///
  /// In en, this message translates to:
  /// **'Ward Number'**
  String get wardNumber;

  /// No description provided for @blockName.
  ///
  /// In en, this message translates to:
  /// **'Block Name'**
  String get blockName;

  /// No description provided for @dateOfMeeting.
  ///
  /// In en, this message translates to:
  /// **'Date of the meeting'**
  String get dateOfMeeting;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @selectDay.
  ///
  /// In en, this message translates to:
  /// **'Select Day'**
  String get selectDay;

  /// No description provided for @fromTime.
  ///
  /// In en, this message translates to:
  /// **'From (HH:MM)'**
  String get fromTime;

  /// No description provided for @selectDiscussionTopics.
  ///
  /// In en, this message translates to:
  /// **'Select Discussion Topics'**
  String get selectDiscussionTopics;

  /// No description provided for @selectMonthYear.
  ///
  /// In en, this message translates to:
  /// **'Select Month & Year'**
  String get selectMonthYear;

  /// No description provided for @toTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'To Time'**
  String get toTimeLabel;

  /// No description provided for @fromTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'From Time'**
  String get fromTimeLabel;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @immunization.
  ///
  /// In en, this message translates to:
  /// **'Immunization'**
  String get immunization;

  /// No description provided for @pregnantWomen.
  ///
  /// In en, this message translates to:
  /// **'Pregnant Women'**
  String get pregnantWomen;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @pnc.
  ///
  /// In en, this message translates to:
  /// **'PNC (Post Natal Care)'**
  String get pnc;

  /// No description provided for @maternalChildHealth.
  ///
  /// In en, this message translates to:
  /// **'Maternal & Child Health'**
  String get maternalChildHealth;

  /// No description provided for @homeVisit.
  ///
  /// In en, this message translates to:
  /// **'Home Visit'**
  String get homeVisit;

  /// No description provided for @newBornCare.
  ///
  /// In en, this message translates to:
  /// **'New Born Care'**
  String get newBornCare;

  /// No description provided for @deaths.
  ///
  /// In en, this message translates to:
  /// **'Deaths'**
  String get deaths;

  /// No description provided for @adolescentHealth.
  ///
  /// In en, this message translates to:
  /// **'Adolescent Health'**
  String get adolescentHealth;

  /// No description provided for @familyPlanning.
  ///
  /// In en, this message translates to:
  /// **'Family Planning'**
  String get familyPlanning;

  /// No description provided for @otherPublicHealthProgram.
  ///
  /// In en, this message translates to:
  /// **'Other Public Health Program'**
  String get otherPublicHealthProgram;

  /// No description provided for @administrative.
  ///
  /// In en, this message translates to:
  /// **'Administrative'**
  String get administrative;

  /// No description provided for @trainingSupport.
  ///
  /// In en, this message translates to:
  /// **'Training and Support'**
  String get trainingSupport;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @districtPatna.
  ///
  /// In en, this message translates to:
  /// **'Patna'**
  String get districtPatna;

  /// No description provided for @districtManer.
  ///
  /// In en, this message translates to:
  /// **'Maner'**
  String get districtManer;

  /// No description provided for @categoryANC.
  ///
  /// In en, this message translates to:
  /// **'ANC'**
  String get categoryANC;

  /// No description provided for @categoryPNC.
  ///
  /// In en, this message translates to:
  /// **'PNC'**
  String get categoryPNC;

  /// No description provided for @categoryRI.
  ///
  /// In en, this message translates to:
  /// **'RI'**
  String get categoryRI;

  /// No description provided for @enter10DigitNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter 10 digit number'**
  String get enter10DigitNumber;

  /// No description provided for @viewRawData.
  ///
  /// In en, this message translates to:
  /// **'View Raw Data (Check Console)'**
  String get viewRawData;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @noNotificationsFound.
  ///
  /// In en, this message translates to:
  /// **'No notifications found.'**
  String get noNotificationsFound;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get beneficiary;

  /// No description provided for @followUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow Up'**
  String get followUpLabel;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get lastSynced;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No Record found'**
  String get noDataFound;

  /// No description provided for @newHouseholdRegistration.
  ///
  /// In en, this message translates to:
  /// **'NEW HOUSEHOLD REGISTRATION'**
  String get newHouseholdRegistration;

  /// No description provided for @noMatchingBeneficiariesFound.
  ///
  /// In en, this message translates to:
  /// **'No matching beneficiaries found.'**
  String get noMatchingBeneficiariesFound;

  /// No description provided for @noBeneficiariesFoundAddNew.
  ///
  /// In en, this message translates to:
  /// **'No beneficiaries found. Add a new beneficiary to get started.'**
  String get noBeneficiariesFoundAddNew;

  /// No description provided for @richId.
  ///
  /// In en, this message translates to:
  /// **'RICH ID'**
  String get richId;

  /// No description provided for @mothersName.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s Name'**
  String get mothersName;

  /// No description provided for @wifesName.
  ///
  /// In en, this message translates to:
  /// **'Wife\'s Name'**
  String get wifesName;

  /// No description provided for @splitMigration.
  ///
  /// In en, this message translates to:
  /// **'Split / Migration'**
  String get splitMigration;

  /// No description provided for @splitUpdated.
  ///
  /// In en, this message translates to:
  /// **'Split updated'**
  String get splitUpdated;

  /// No description provided for @splitFailed.
  ///
  /// In en, this message translates to:
  /// **'Split failed'**
  String get splitFailed;

  /// No description provided for @migration.
  ///
  /// In en, this message translates to:
  /// **'Migration'**
  String get migration;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @failedToLoadMembers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load members'**
  String get failedToLoadMembers;

  /// No description provided for @loadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Loading members...'**
  String get loadingMembers;

  /// No description provided for @selectMember.
  ///
  /// In en, this message translates to:
  /// **'Select Member'**
  String get selectMember;

  /// No description provided for @selectChild.
  ///
  /// In en, this message translates to:
  /// **'Select Child'**
  String get selectChild;

  /// No description provided for @selectAMember.
  ///
  /// In en, this message translates to:
  /// **'Select a member'**
  String get selectAMember;

  /// No description provided for @migrate.
  ///
  /// In en, this message translates to:
  /// **'MIGRATE'**
  String get migrate;

  /// No description provided for @selectMemberType.
  ///
  /// In en, this message translates to:
  /// **'Select Member Type'**
  String get selectMemberType;

  /// No description provided for @selectChildOptional.
  ///
  /// In en, this message translates to:
  /// **'Select Child (Optional)'**
  String get selectChildOptional;

  /// No description provided for @enterHouseNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter house number'**
  String get enterHouseNumber;

  /// No description provided for @splitLabel.
  ///
  /// In en, this message translates to:
  /// **'SPLIT'**
  String get splitLabel;

  /// No description provided for @selectNewFamilyHead.
  ///
  /// In en, this message translates to:
  /// **'Select New Family Head'**
  String get selectNewFamilyHead;

  /// No description provided for @noAdultMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No adult members found for this household'**
  String get noAdultMembersFound;

  /// No description provided for @doYouWantToContinue.
  ///
  /// In en, this message translates to:
  /// **'Do you want to continue?'**
  String get doYouWantToContinue;

  /// No description provided for @updateMemberDetails.
  ///
  /// In en, this message translates to:
  /// **'Update Member Details'**
  String get updateMemberDetails;

  /// No description provided for @verifyLabel.
  ///
  /// In en, this message translates to:
  /// **'VERIFY'**
  String get verifyLabel;

  /// No description provided for @weightRange.
  ///
  /// In en, this message translates to:
  /// **'Weight (1.2-90)Kg'**
  String get weightRange;

  /// No description provided for @isBirthCertificateIssued.
  ///
  /// In en, this message translates to:
  /// **'Is birth certificate issued? *'**
  String get isBirthCertificateIssued;

  /// No description provided for @isSchoolGoingChild.
  ///
  /// In en, this message translates to:
  /// **'Is He/She school going child?'**
  String get isSchoolGoingChild;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @correctHighlightedErrors.
  ///
  /// In en, this message translates to:
  /// **'Please correct the highlighted errors before continuing.'**
  String get correctHighlightedErrors;

  /// No description provided for @selectOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Option'**
  String get selectOptionLabel;

  /// No description provided for @screeningDate.
  ///
  /// In en, this message translates to:
  /// **'Screening Date'**
  String get screeningDate;

  /// No description provided for @enterCategory.
  ///
  /// In en, this message translates to:
  /// **'Enter category'**
  String get enterCategory;

  /// No description provided for @youngestChildDetail.
  ///
  /// In en, this message translates to:
  /// **'Youngest Child Detail'**
  String get youngestChildDetail;

  /// No description provided for @daysRangeValidation.
  ///
  /// In en, this message translates to:
  /// **'Days: only 1 to 31 allowed'**
  String get daysRangeValidation;

  /// No description provided for @monthRangeValidation.
  ///
  /// In en, this message translates to:
  /// **'Month: only 1 to 12 allowed'**
  String get monthRangeValidation;

  /// No description provided for @yearRangeValidation.
  ///
  /// In en, this message translates to:
  /// **'Year: only 1 to 90 allowed'**
  String get yearRangeValidation;

  /// No description provided for @postDeliveryProblemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Does the mother have any of the following problems post delivery? *'**
  String get postDeliveryProblemsLabel;

  /// No description provided for @breastfeedingProblemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Does the mother have breast feeding problem? *'**
  String get breastfeedingProblemsLabel;

  /// No description provided for @milkNotProducingOrLessLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s milk is not being produced after delivery or she thinks less milk is being produced'**
  String get milkNotProducingOrLessLabel;

  /// No description provided for @nippleCracksPainOrEngorgedLabel.
  ///
  /// In en, this message translates to:
  /// **'is the mother having cracked nipples/ painful and / or engorged breasts'**
  String get nippleCracksPainOrEngorgedLabel;

  /// No description provided for @tabGeneralDetails.
  ///
  /// In en, this message translates to:
  /// **'BASIC DETAILS'**
  String get tabGeneralDetails;

  /// No description provided for @tabMotherDetails.
  ///
  /// In en, this message translates to:
  /// **'MOTHER DETAILS'**
  String get tabMotherDetails;

  /// No description provided for @tabNewbornDetails.
  ///
  /// In en, this message translates to:
  /// **'CHIlD  DETAILS'**
  String get tabNewbornDetails;

  /// No description provided for @dead.
  ///
  /// In en, this message translates to:
  /// **'Death'**
  String get dead;

  /// No description provided for @weightColorMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Weighing matches with colour?'**
  String get weightColorMatchLabel;

  /// No description provided for @exclusiveBreastfeedingStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the exclusive breastfeeding initiated?'**
  String get exclusiveBreastfeedingStartedLabel;

  /// No description provided for @firstBreastfeedTimingLabel.
  ///
  /// In en, this message translates to:
  /// **'At what time was the baby first breastfed?'**
  String get firstBreastfeedTimingLabel;

  /// No description provided for @breathingRapidLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the breath of the baby going fast (60 or more per minute)'**
  String get breathingRapidLabel;

  /// No description provided for @lethargicLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby Lethargic? '**
  String get lethargicLabel;

  /// No description provided for @congenitalAbnormalitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby having any congenital physical abnormality'**
  String get congenitalAbnormalitiesLabel;

  /// No description provided for @eyesNormalLabel.
  ///
  /// In en, this message translates to:
  /// **'Eyes: Normal'**
  String get eyesNormalLabel;

  /// No description provided for @eyesSwollenOrPusLabel.
  ///
  /// In en, this message translates to:
  /// **'Are the eyes swollen? Is there pus coming out of the eyes?'**
  String get eyesSwollenOrPusLabel;

  /// No description provided for @skinFoldRednessLabel.
  ///
  /// In en, this message translates to:
  /// **'Is there any cracks/redness in the skin fold? (thigh/ Axilla / Buttock)'**
  String get skinFoldRednessLabel;

  /// No description provided for @newbornJaundiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Yellowness in skin/ palm/ sole/eyes: Jaudice'**
  String get newbornJaundiceLabel;

  /// No description provided for @pusBumpsOrBoilLabel.
  ///
  /// In en, this message translates to:
  /// **'More than ten pus- filled pustules or large boil'**
  String get pusBumpsOrBoilLabel;

  /// No description provided for @pusInNavelLabel.
  ///
  /// In en, this message translates to:
  /// **'Is pus in the navel?'**
  String get pusInNavelLabel;

  /// No description provided for @routineCareDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Whether the Routine Newborn care tasks was performed?'**
  String get routineCareDoneLabel;

  /// No description provided for @cryingConstantlyOrLessUrineLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby crying continuously or passing usrine less than 6 times a day?'**
  String get cryingConstantlyOrLessUrineLabel;

  /// No description provided for @cryingSoftlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the child crying weak?'**
  String get cryingSoftlyLabel;

  /// No description provided for @newbornReferredByAshaLabel.
  ///
  /// In en, this message translates to:
  /// **'In the above symptoms, weather the child is referred by ASHA?'**
  String get newbornReferredByAshaLabel;

  /// No description provided for @birthRegisteredLabel.
  ///
  /// In en, this message translates to:
  /// **'Is birth registration completed?'**
  String get birthRegisteredLabel;

  /// No description provided for @birthDoseVaccinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the Birthdose vaccination given to baby?'**
  String get birthDoseVaccinationLabel;

  /// No description provided for @mcpCardAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Is there availability of \'Mother Child Protection (MCP) card?'**
  String get mcpCardAvailableLabel;

  /// No description provided for @formUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Form updated successfully'**
  String get formUpdatedSuccessfully;

  /// No description provided for @doNotWantToDisclose.
  ///
  /// In en, this message translates to:
  /// **'Do not want to disclose'**
  String get doNotWantToDisclose;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @visitInformation.
  ///
  /// In en, this message translates to:
  /// **'Visit Information'**
  String get visitInformation;

  /// No description provided for @visitId.
  ///
  /// In en, this message translates to:
  /// **'Visit ID'**
  String get visitId;

  /// No description provided for @formData.
  ///
  /// In en, this message translates to:
  /// **'Form Data'**
  String get formData;

  /// No description provided for @rawData.
  ///
  /// In en, this message translates to:
  /// **'Raw Data'**
  String get rawData;

  /// No description provided for @formSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Form has been saved successfully'**
  String get formSavedSuccessfully;

  /// No description provided for @pregnantAddedToAnc.
  ///
  /// In en, this message translates to:
  /// **'Pregnant beneficiary has been added to antenatal care (ANC) list.'**
  String get pregnantAddedToAnc;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @formSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Form saved successfully'**
  String get formSavedSuccess;

  /// No description provided for @eligibleCoupleTrackingDue.
  ///
  /// In en, this message translates to:
  /// **'Eligible Couple Tracking Due'**
  String get eligibleCoupleTrackingDue;

  /// No description provided for @methodOfContraception.
  ///
  /// In en, this message translates to:
  /// **'Method of contraception'**
  String get methodOfContraception;

  /// No description provided for @condom.
  ///
  /// In en, this message translates to:
  /// **'Condom'**
  String get condom;

  /// No description provided for @malaN.
  ///
  /// In en, this message translates to:
  /// **'Mala -N (Daily contraceptive pill)'**
  String get malaN;

  /// No description provided for @atraInjection.
  ///
  /// In en, this message translates to:
  /// **'Atra Injection'**
  String get atraInjection;

  /// No description provided for @copperT.
  ///
  /// In en, this message translates to:
  /// **'Copper -T (IUCD)'**
  String get copperT;

  /// No description provided for @chhaya.
  ///
  /// In en, this message translates to:
  /// **'Chhaya (Weekly contraceptive pill)'**
  String get chhaya;

  /// No description provided for @ecp.
  ///
  /// In en, this message translates to:
  /// **'ECP (Emergency contraceptive pill)'**
  String get ecp;

  /// No description provided for @maleSterilization.
  ///
  /// In en, this message translates to:
  /// **'Male Sterilization'**
  String get maleSterilization;

  /// No description provided for @femaleSterilization.
  ///
  /// In en, this message translates to:
  /// **'Female Sterilization'**
  String get femaleSterilization;

  /// No description provided for @anyOtherSpecifyy.
  ///
  /// In en, this message translates to:
  /// **'Any Other Specify'**
  String get anyOtherSpecifyy;

  /// No description provided for @dateOfAntraInjection.
  ///
  /// In en, this message translates to:
  /// **'Date of Antra Injection'**
  String get dateOfAntraInjection;

  /// No description provided for @dateOfRemoval.
  ///
  /// In en, this message translates to:
  /// **'Date of removal'**
  String get dateOfRemoval;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason'**
  String get enterReason;

  /// No description provided for @reasonForAbsent.
  ///
  /// In en, this message translates to:
  /// **'Reason for absent'**
  String get reasonForAbsent;

  /// No description provided for @isBeneficiaryAbsent.
  ///
  /// In en, this message translates to:
  /// **'Is Beneficiary Absent'**
  String get isBeneficiaryAbsent;

  /// No description provided for @quantityOfMalaN.
  ///
  /// In en, this message translates to:
  /// **'Quantity of Mala -N (Daily contraceptive pill)'**
  String get quantityOfMalaN;

  /// No description provided for @quantityOfECP.
  ///
  /// In en, this message translates to:
  /// **'Quantity of ECP (Emergency contraceptive pill)'**
  String get quantityOfECP;

  /// No description provided for @quantityOfChhaya.
  ///
  /// In en, this message translates to:
  /// **'Quantity of Chhaya (Weekly contraceptive pill)'**
  String get quantityOfChhaya;

  /// No description provided for @quantityOfCondoms.
  ///
  /// In en, this message translates to:
  /// **'Quantity of Condoms'**
  String get quantityOfCondoms;

  /// No description provided for @enterReasonForRemoval.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for removal'**
  String get enterReasonForRemoval;

  /// No description provided for @reasonForRemoval.
  ///
  /// In en, this message translates to:
  /// **'Reason for Removal'**
  String get reasonForRemoval;

  /// No description provided for @anc.
  ///
  /// In en, this message translates to:
  /// **'ANC'**
  String get anc;

  /// No description provided for @pmsma.
  ///
  /// In en, this message translates to:
  /// **'PMSMA'**
  String get pmsma;

  /// No description provided for @vhsndAnganwadi.
  ///
  /// In en, this message translates to:
  /// **'VHSND/Anganwadi'**
  String get vhsndAnganwadi;

  /// No description provided for @hscHwc.
  ///
  /// In en, this message translates to:
  /// **'Health Sub-center/Health & Wealth Centre (HSC/HWC)'**
  String get hscHwc;

  /// No description provided for @phcLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Health Centre (PHC)'**
  String get phcLabel;

  /// No description provided for @chcLabel.
  ///
  /// In en, this message translates to:
  /// **'Community Health Centre (CHC)'**
  String get chcLabel;

  /// No description provided for @rh.
  ///
  /// In en, this message translates to:
  /// **'Referral Hospital (RH)'**
  String get rh;

  /// No description provided for @dh.
  ///
  /// In en, this message translates to:
  /// **'District Hospital (DH)'**
  String get dh;

  /// No description provided for @mch.
  ///
  /// In en, this message translates to:
  /// **'Medical College Hospital (MCH)'**
  String get mch;

  /// No description provided for @pmsmaSite.
  ///
  /// In en, this message translates to:
  /// **'PMSMA Site'**
  String get pmsmaSite;

  /// No description provided for @hepetitisB.
  ///
  /// In en, this message translates to:
  /// **'Hepetitis - B'**
  String get hepetitisB;

  /// No description provided for @tuberculosisLabel.
  ///
  /// In en, this message translates to:
  /// **'Tuberculosis (TB)'**
  String get tuberculosisLabel;

  /// No description provided for @asthma.
  ///
  /// In en, this message translates to:
  /// **'Asthma'**
  String get asthma;

  /// No description provided for @highBP.
  ///
  /// In en, this message translates to:
  /// **'High BP'**
  String get highBP;

  /// No description provided for @stirti.
  ///
  /// In en, this message translates to:
  /// **'STI/RTI'**
  String get stirti;

  /// No description provided for @heartDisease.
  ///
  /// In en, this message translates to:
  /// **'Heart Disease'**
  String get heartDisease;

  /// No description provided for @liver_disease.
  ///
  /// In en, this message translates to:
  /// **'Liver Disease'**
  String get liver_disease;

  /// No description provided for @kideny_disease.
  ///
  /// In en, this message translates to:
  /// **'Kideny Disease'**
  String get kideny_disease;

  /// No description provided for @epilespy.
  ///
  /// In en, this message translates to:
  /// **'Epilepsy'**
  String get epilespy;

  /// No description provided for @specifyOtherDisease.
  ///
  /// In en, this message translates to:
  /// **'Please specify other disease'**
  String get specifyOtherDisease;

  /// No description provided for @selectRisks.
  ///
  /// In en, this message translates to:
  /// **'Select Risks'**
  String get selectRisks;

  /// No description provided for @riskSevereAnemia.
  ///
  /// In en, this message translates to:
  /// **'Severe Anemia'**
  String get riskSevereAnemia;

  /// No description provided for @riskPIH.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Induced Hypertension, pre-eclampsia, Eclampsia'**
  String get riskPIH;

  /// No description provided for @riskInfections.
  ///
  /// In en, this message translates to:
  /// **'Syphilis, HIV Positive, Hepatitis B, Hepatitis C'**
  String get riskInfections;

  /// No description provided for @riskGestationalDiabetes.
  ///
  /// In en, this message translates to:
  /// **'Gestational Diabetes'**
  String get riskGestationalDiabetes;

  /// No description provided for @riskHypothyroidism.
  ///
  /// In en, this message translates to:
  /// **'Hypothyroidism'**
  String get riskHypothyroidism;

  /// No description provided for @riskTeenagePregnancy.
  ///
  /// In en, this message translates to:
  /// **'Teenage Pregnancy (<20 year)/ Pregnancy after 35 Year'**
  String get riskTeenagePregnancy;

  /// No description provided for @riskTwins.
  ///
  /// In en, this message translates to:
  /// **'Pregnant With Twins Or More'**
  String get riskTwins;

  /// No description provided for @riskMalPresentation.
  ///
  /// In en, this message translates to:
  /// **'Mal Presentation of baby (Breech/Transverse/Oblique)'**
  String get riskMalPresentation;

  /// No description provided for @riskPreviousCesarean.
  ///
  /// In en, this message translates to:
  /// **'Previous Cesarean Delivery'**
  String get riskPreviousCesarean;

  /// No description provided for @riskPreviousHistory.
  ///
  /// In en, this message translates to:
  /// **'Previous History of Neo-Natal Death, Still Birth, Premature Birth, Repeated Abortion, PIH, PPH, APH, Obstructed Labour'**
  String get riskPreviousHistory;

  /// No description provided for @riskRhNegative.
  ///
  /// In en, this message translates to:
  /// **'RH Negative'**
  String get riskRhNegative;

  /// No description provided for @didPregnantWomanGiveBirth.
  ///
  /// In en, this message translates to:
  /// **'Did the pregnant woman give birth to a baby?'**
  String get didPregnantWomanGiveBirth;

  /// No description provided for @dateOfAbortion.
  ///
  /// In en, this message translates to:
  /// **'Date of Abortion'**
  String get dateOfAbortion;

  /// No description provided for @abortionComplication.
  ///
  /// In en, this message translates to:
  /// **'Any complication leading to abortion?'**
  String get abortionComplication;

  /// No description provided for @deliveryOutcomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery outcome *'**
  String get deliveryOutcomeLabel;

  /// No description provided for @liveBirth.
  ///
  /// In en, this message translates to:
  /// **'Live birth'**
  String get liveBirth;

  /// No description provided for @stillBirth.
  ///
  /// In en, this message translates to:
  /// **'Still birth'**
  String get stillBirth;

  /// No description provided for @newbornDeath.
  ///
  /// In en, this message translates to:
  /// **'Newborn death'**
  String get newbornDeath;

  /// No description provided for @numberOfChildrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Children *'**
  String get numberOfChildrenLabel;

  /// No description provided for @oneChild.
  ///
  /// In en, this message translates to:
  /// **'One Child'**
  String get oneChild;

  /// No description provided for @twins.
  ///
  /// In en, this message translates to:
  /// **'Twins'**
  String get twins;

  /// No description provided for @triplets.
  ///
  /// In en, this message translates to:
  /// **'Triplets'**
  String get triplets;

  /// No description provided for @babysName.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s Name'**
  String get babysName;

  /// No description provided for @enterBabyName.
  ///
  /// In en, this message translates to:
  /// **'Enter Baby\'s Name'**
  String get enterBabyName;

  /// No description provided for @babyWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s Weight (1200–4000 gms)'**
  String get babyWeightLabel;

  /// No description provided for @enterBabyWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter Baby\'s Weight'**
  String get enterBabyWeight;

  /// No description provided for @firstBabyName.
  ///
  /// In en, this message translates to:
  /// **'First Baby Name *'**
  String get firstBabyName;

  /// No description provided for @enterFirstBabyName.
  ///
  /// In en, this message translates to:
  /// **'Enter First Baby Name'**
  String get enterFirstBabyName;

  /// No description provided for @firstBabyGender.
  ///
  /// In en, this message translates to:
  /// **'First Baby Gender *'**
  String get firstBabyGender;

  /// No description provided for @firstBabyWeight.
  ///
  /// In en, this message translates to:
  /// **'First Baby Weight (1200–4000 gms) *'**
  String get firstBabyWeight;

  /// No description provided for @enterFirstBabyWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter First Baby Weight'**
  String get enterFirstBabyWeight;

  /// No description provided for @secondBabyName.
  ///
  /// In en, this message translates to:
  /// **'Second Baby Name *'**
  String get secondBabyName;

  /// No description provided for @enterSecondBabyName.
  ///
  /// In en, this message translates to:
  /// **'Enter Second Baby Name'**
  String get enterSecondBabyName;

  /// No description provided for @secondBabyGender.
  ///
  /// In en, this message translates to:
  /// **'Second Baby Gender *'**
  String get secondBabyGender;

  /// No description provided for @secondBabyWeight.
  ///
  /// In en, this message translates to:
  /// **'Second Baby Weight (1200–4000 gms) *'**
  String get secondBabyWeight;

  /// No description provided for @enterSecondBabyWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter Second Baby Weight'**
  String get enterSecondBabyWeight;

  /// No description provided for @thirdBabyName.
  ///
  /// In en, this message translates to:
  /// **'Third Baby Name *'**
  String get thirdBabyName;

  /// No description provided for @enterThirdBabyName.
  ///
  /// In en, this message translates to:
  /// **'Enter Third Baby Name'**
  String get enterThirdBabyName;

  /// No description provided for @thirdBabyGender.
  ///
  /// In en, this message translates to:
  /// **'Third Baby Gender *'**
  String get thirdBabyGender;

  /// No description provided for @thirdBabyWeight.
  ///
  /// In en, this message translates to:
  /// **'Third Baby Weight (1200–4000 gms) *'**
  String get thirdBabyWeight;

  /// No description provided for @enterThirdBabyWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter Third Baby Weight'**
  String get enterThirdBabyWeight;

  /// No description provided for @reasonForAbsence.
  ///
  /// In en, this message translates to:
  /// **'Reason for Absence'**
  String get reasonForAbsence;

  /// No description provided for @enterReasonForAbsence.
  ///
  /// In en, this message translates to:
  /// **'Enter the reason for absence'**
  String get enterReasonForAbsence;

  /// No description provided for @pleaseFillFieldsCorrectly.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields correctly'**
  String get pleaseFillFieldsCorrectly;

  /// No description provided for @noPregnantWomenFound.
  ///
  /// In en, this message translates to:
  /// **'No pregnant women found'**
  String get noPregnantWomenFound;

  /// No description provided for @registerNewANCCases.
  ///
  /// In en, this message translates to:
  /// **'Register new ANC cases in the family registration'**
  String get registerNewANCCases;

  /// No description provided for @fourthANCLabel.
  ///
  /// In en, this message translates to:
  /// **'Fourth ANC'**
  String get fourthANCLabel;

  /// No description provided for @pmama.
  ///
  /// In en, this message translates to:
  /// **'PMAMA'**
  String get pmama;

  /// No description provided for @srNo.
  ///
  /// In en, this message translates to:
  /// **'Sr No.'**
  String get srNo;

  /// No description provided for @pregnancyWeek.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Week'**
  String get pregnancyWeek;

  /// No description provided for @high_Risk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get high_Risk;

  /// No description provided for @noPregnancyOutcomesFound.
  ///
  /// In en, this message translates to:
  /// **'No pregnancy outcomes found'**
  String get noPregnancyOutcomesFound;

  /// No description provided for @nextHBNCDate.
  ///
  /// In en, this message translates to:
  /// **'Next HBNC Date'**
  String get nextHBNCDate;

  /// No description provided for @previousHBNCDate.
  ///
  /// In en, this message translates to:
  /// **'Previous HBNC Date'**
  String get previousHBNCDate;

  /// No description provided for @beneficiaryAddedToHbnc.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary has been added to HBNC list'**
  String get beneficiaryAddedToHbnc;

  /// No description provided for @institutional.
  ///
  /// In en, this message translates to:
  /// **'Institutional'**
  String get institutional;

  /// No description provided for @nonInstitutional.
  ///
  /// In en, this message translates to:
  /// **'Non-Institutional'**
  String get nonInstitutional;

  /// No description provided for @enterPlace.
  ///
  /// In en, this message translates to:
  /// **'Enter place'**
  String get enterPlace;

  /// No description provided for @enterOtherPlaceOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Enter other place of delivery'**
  String get enterOtherPlaceOfDelivery;

  /// No description provided for @publicPlace.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicPlace;

  /// No description provided for @privatePlace.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privatePlace;

  /// No description provided for @institutionPlaceOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Institution place of delivery'**
  String get institutionPlaceOfDelivery;

  /// No description provided for @nursingHome.
  ///
  /// In en, this message translates to:
  /// **'Nursing Home'**
  String get nursingHome;

  /// No description provided for @hospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get hospital;

  /// No description provided for @homeBasedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Home Based Delivery'**
  String get homeBasedDelivery;

  /// No description provided for @inTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get inTransit;

  /// No description provided for @nonInstitutionalPlaceOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Non-institutional place of delivery'**
  String get nonInstitutionalPlaceOfDelivery;

  /// No description provided for @enterOtherNonInstitutionalDelivery.
  ///
  /// In en, this message translates to:
  /// **'Enter name of other non-institutional delivery'**
  String get enterOtherNonInstitutionalDelivery;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @transitPlace.
  ///
  /// In en, this message translates to:
  /// **'Transit place'**
  String get transitPlace;

  /// No description provided for @ambulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get ambulance;

  /// No description provided for @enterOtherTransitPlace.
  ///
  /// In en, this message translates to:
  /// **'Please enter name of other transit place'**
  String get enterOtherTransitPlace;

  /// No description provided for @anm.
  ///
  /// In en, this message translates to:
  /// **'ANM'**
  String get anm;

  /// No description provided for @lhv.
  ///
  /// In en, this message translates to:
  /// **'LHV'**
  String get lhv;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @staffNurse.
  ///
  /// In en, this message translates to:
  /// **'Staff Nurse'**
  String get staffNurse;

  /// No description provided for @tba.
  ///
  /// In en, this message translates to:
  /// **'TBA (Non-Skilled birth attendant)'**
  String get tba;

  /// No description provided for @whoConductedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Who conducted the delivery?'**
  String get whoConductedDelivery;

  /// No description provided for @whoElseConductedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Who else did the delivery?'**
  String get whoElseConductedDelivery;

  /// No description provided for @convulsion.
  ///
  /// In en, this message translates to:
  /// **'Convulsion'**
  String get convulsion;

  /// No description provided for @aph.
  ///
  /// In en, this message translates to:
  /// **'Ante Partumhaemorrhage (Aph)'**
  String get aph;

  /// No description provided for @pih.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy Induced Hypertension (PIH)'**
  String get pih;

  /// No description provided for @repeatedAbortion.
  ///
  /// In en, this message translates to:
  /// **'Repeated Abortion'**
  String get repeatedAbortion;

  /// No description provided for @motherDeath.
  ///
  /// In en, this message translates to:
  /// **'Mother Death'**
  String get motherDeath;

  /// No description provided for @congenitalAnomaly.
  ///
  /// In en, this message translates to:
  /// **'Congenital Anomaly'**
  String get congenitalAnomaly;

  /// No description provided for @bloodTransfusion.
  ///
  /// In en, this message translates to:
  /// **'Blood Transfusion'**
  String get bloodTransfusion;

  /// No description provided for @obstructedLabour.
  ///
  /// In en, this message translates to:
  /// **'Obstructed Labour'**
  String get obstructedLabour;

  /// No description provided for @pph.
  ///
  /// In en, this message translates to:
  /// **'PPH'**
  String get pph;

  /// No description provided for @anyOther.
  ///
  /// In en, this message translates to:
  /// **'Any other'**
  String get anyOther;

  /// No description provided for @complication.
  ///
  /// In en, this message translates to:
  /// **'Complication *'**
  String get complication;

  /// No description provided for @dateOfDischarge.
  ///
  /// In en, this message translates to:
  /// **'Date of discharge'**
  String get dateOfDischarge;

  /// No description provided for @enterComplication.
  ///
  /// In en, this message translates to:
  /// **'Enter complication'**
  String get enterComplication;

  /// No description provided for @enterOtherComplication.
  ///
  /// In en, this message translates to:
  /// **'Enter other complication during delivery'**
  String get enterOtherComplication;

  /// No description provided for @discharge_time.
  ///
  /// In en, this message translates to:
  /// **'Discharge time (hh:mm)'**
  String get discharge_time;

  /// No description provided for @adaptFamilyPlanningMethod.
  ///
  /// In en, this message translates to:
  /// **'Do you want to adapt family planning method?'**
  String get adaptFamilyPlanningMethod;

  /// No description provided for @formSavedSuccessfullyMsg.
  ///
  /// In en, this message translates to:
  /// **'Form saved successfully'**
  String get formSavedSuccessfullyMsg;

  /// No description provided for @firstBreastfeedTiming.
  ///
  /// In en, this message translates to:
  /// **'First Breastfeeding Timing'**
  String get firstBreastfeedTiming;

  /// No description provided for @within30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Within 30 minutes of birth'**
  String get within30Minutes;

  /// No description provided for @within1Hour.
  ///
  /// In en, this message translates to:
  /// **'Within 1 hour of birth'**
  String get within1Hour;

  /// No description provided for @within6Hours.
  ///
  /// In en, this message translates to:
  /// **'Within 6 hours of birth'**
  String get within6Hours;

  /// No description provided for @within24Hours.
  ///
  /// In en, this message translates to:
  /// **'Within 24 hours of birth'**
  String get within24Hours;

  /// No description provided for @notBreastfed.
  ///
  /// In en, this message translates to:
  /// **'Not breastfed'**
  String get notBreastfed;

  /// No description provided for @howWasBreastfed.
  ///
  /// In en, this message translates to:
  /// **'How was the baby breastfed?'**
  String get howWasBreastfed;

  /// No description provided for @breastfeedingTime.
  ///
  /// In en, this message translates to:
  /// **'Please enter breastfeeding time (hh:mm)'**
  String get breastfeedingTime;

  /// No description provided for @hhmm.
  ///
  /// In en, this message translates to:
  /// **'hh:mm'**
  String get hhmm;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @forcefully.
  ///
  /// In en, this message translates to:
  /// **'Forcefully'**
  String get forcefully;

  /// No description provided for @withWeakness.
  ///
  /// In en, this message translates to:
  /// **'With weakness'**
  String get withWeakness;

  /// No description provided for @couldNotBreastfeedButSpoon.
  ///
  /// In en, this message translates to:
  /// **'Could not breast feed but had to be fed with spoon'**
  String get couldNotBreastfeedButSpoon;

  /// No description provided for @couldNeitherBreastfeedNorSpoon.
  ///
  /// In en, this message translates to:
  /// **'Could neither breast feed nor take given by spoon'**
  String get couldNeitherBreastfeedNorSpoon;

  /// No description provided for @firstFeedGivenAfterBirth.
  ///
  /// In en, this message translates to:
  /// **'First feed given after birth'**
  String get firstFeedGivenAfterBirth;

  /// No description provided for @firstBreastfeeding.
  ///
  /// In en, this message translates to:
  /// **'First Breastfeeding'**
  String get firstBreastfeeding;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @honey.
  ///
  /// In en, this message translates to:
  /// **'Honey'**
  String get honey;

  /// No description provided for @mishriWater.
  ///
  /// In en, this message translates to:
  /// **'Mishri Water / Sugar Syrup'**
  String get mishriWater;

  /// No description provided for @goatMilk.
  ///
  /// In en, this message translates to:
  /// **'Goat Milk'**
  String get goatMilk;

  /// No description provided for @cowMilk.
  ///
  /// In en, this message translates to:
  /// **'Cow Milk'**
  String get cowMilk;

  /// No description provided for @enter_other_feeding_option.
  ///
  /// In en, this message translates to:
  /// **'Please enter other option'**
  String get enter_other_feeding_option;

  /// No description provided for @counsellingAdviceNeeded.
  ///
  /// In en, this message translates to:
  /// **'Counselling/Advice needed?'**
  String get counsellingAdviceNeeded;

  /// No description provided for @is_navel_tied_with_thread.
  ///
  /// In en, this message translates to:
  /// **'Is navel tied with a clean thread by ASHA or ANM?'**
  String get is_navel_tied_with_thread;

  /// No description provided for @babyWipedWithCleanCloth.
  ///
  /// In en, this message translates to:
  /// **'Has the baby wiped with clean dry cloth?'**
  String get babyWipedWithCleanCloth;

  /// No description provided for @is_child_kept_warm.
  ///
  /// In en, this message translates to:
  /// **'Has the baby kept warm?'**
  String get is_child_kept_warm;

  /// No description provided for @babyGivenBath.
  ///
  /// In en, this message translates to:
  /// **'Has the baby given bath?'**
  String get babyGivenBath;

  /// No description provided for @babyWrappedAndPlacedNearMother.
  ///
  /// In en, this message translates to:
  /// **'Whether the baby was wrapped in a cloth and placed near the mother?'**
  String get babyWrappedAndPlacedNearMother;

  /// No description provided for @selectEyeProblemTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select type of eye problem'**
  String get selectEyeProblemTypeLabel;

  /// No description provided for @swelling.
  ///
  /// In en, this message translates to:
  /// **'Swelling'**
  String get swelling;

  /// No description provided for @oozingPus.
  ///
  /// In en, this message translates to:
  /// **'Oozing pus'**
  String get oozingPus;

  /// No description provided for @counsellingBreastfeeding.
  ///
  /// In en, this message translates to:
  /// **'Counselling/Advice needed for breastfeeding?'**
  String get counsellingBreastfeeding;

  /// No description provided for @referredByASHA.
  ///
  /// In en, this message translates to:
  /// **'Referred by ASHA to'**
  String get referredByASHA;

  /// No description provided for @aphc.
  ///
  /// In en, this message translates to:
  /// **'APHC'**
  String get aphc;

  /// No description provided for @rhLabel.
  ///
  /// In en, this message translates to:
  /// **'RH'**
  String get rhLabel;

  /// No description provided for @sdh.
  ///
  /// In en, this message translates to:
  /// **'SDH'**
  String get sdh;

  /// No description provided for @dhLabel.
  ///
  /// In en, this message translates to:
  /// **'DH'**
  String get dhLabel;

  /// No description provided for @babyWeightRecordedInMPC.
  ///
  /// In en, this message translates to:
  /// **'Is the weight of the newborn baby recorded in the Mother Protection Card? *'**
  String get babyWeightRecordedInMPC;

  /// No description provided for @referToHospital.
  ///
  /// In en, this message translates to:
  /// **'Refer to hospital?'**
  String get referToHospital;

  /// No description provided for @referToLabel.
  ///
  /// In en, this message translates to:
  /// **'Refer to *'**
  String get referToLabel;

  /// No description provided for @mchLabel.
  ///
  /// In en, this message translates to:
  /// **'MCH'**
  String get mchLabel;

  /// No description provided for @date_of_death.
  ///
  /// In en, this message translates to:
  /// **'Date of death '**
  String get date_of_death;

  /// No description provided for @place_of_death.
  ///
  /// In en, this message translates to:
  /// **'Place of death '**
  String get place_of_death;

  /// No description provided for @migrated_out.
  ///
  /// In en, this message translates to:
  /// **'Migrated Out'**
  String get migrated_out;

  /// No description provided for @on_the_way.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get on_the_way;

  /// No description provided for @facility.
  ///
  /// In en, this message translates to:
  /// **'Facility'**
  String get facility;

  /// No description provided for @reason_of_death.
  ///
  /// In en, this message translates to:
  /// **'Reason of death '**
  String get reason_of_death;

  /// No description provided for @ph.
  ///
  /// In en, this message translates to:
  /// **'PH'**
  String get ph;

  /// No description provided for @severe_anaemia.
  ///
  /// In en, this message translates to:
  /// **'Severe Anaemia'**
  String get severe_anaemia;

  /// No description provided for @spesis.
  ///
  /// In en, this message translates to:
  /// **'Sepsis'**
  String get spesis;

  /// No description provided for @obstructed_labour.
  ///
  /// In en, this message translates to:
  /// **'Obstructed Labour'**
  String get obstructed_labour;

  /// No description provided for @malpresentation.
  ///
  /// In en, this message translates to:
  /// **'Malpresentation'**
  String get malpresentation;

  /// No description provided for @eclampsia_severe_hypertension.
  ///
  /// In en, this message translates to:
  /// **'Eclampsia / Severe Hypertension'**
  String get eclampsia_severe_hypertension;

  /// No description provided for @unsafe_abortion.
  ///
  /// In en, this message translates to:
  /// **'Unsafe Abortion'**
  String get unsafe_abortion;

  /// No description provided for @surgical_complication.
  ///
  /// In en, this message translates to:
  /// **'Surgical Complication'**
  String get surgical_complication;

  /// No description provided for @other_reason_not_maternal_complication.
  ///
  /// In en, this message translates to:
  /// **'Other reason apart from maternal complication'**
  String get other_reason_not_maternal_complication;

  /// No description provided for @other_specify.
  ///
  /// In en, this message translates to:
  /// **'Other (Specify)'**
  String get other_specify;

  /// No description provided for @other_reason_of_death.
  ///
  /// In en, this message translates to:
  /// **'Other reason of death *'**
  String get other_reason_of_death;

  /// No description provided for @specify_other_reason.
  ///
  /// In en, this message translates to:
  /// **'Specify other reason'**
  String get specify_other_reason;

  /// No description provided for @unconscious_fits.
  ///
  /// In en, this message translates to:
  /// **'Unconscious / fits *'**
  String get unconscious_fits;

  /// No description provided for @excessive_bleeding.
  ///
  /// In en, this message translates to:
  /// **'Excessive bleeding *'**
  String get excessive_bleeding;

  /// No description provided for @has_mcp_card_filled.
  ///
  /// In en, this message translates to:
  /// **'Has the MCP card filled? *'**
  String get has_mcp_card_filled;

  /// No description provided for @please_enter_problem.
  ///
  /// In en, this message translates to:
  /// **'Please enter problem *'**
  String get please_enter_problem;

  /// No description provided for @enter_breastfeeding_problem.
  ///
  /// In en, this message translates to:
  /// **'Please enter problem'**
  String get enter_breastfeeding_problem;

  /// No description provided for @write_take_action.
  ///
  /// In en, this message translates to:
  /// **'Please write down the action taken'**
  String get write_take_action;

  /// No description provided for @breastfeeding_problem_help.
  ///
  /// In en, this message translates to:
  /// **'If there is a problem in breastfeeding, help the mother to overcome it *'**
  String get breastfeeding_problem_help;

  /// No description provided for @temp_upto_102.
  ///
  /// In en, this message translates to:
  /// **'Temperature upto 102°F (38.9°C)'**
  String get temp_upto_102;

  /// No description provided for @temp_more_than_102.
  ///
  /// In en, this message translates to:
  /// **'Temperature more than 102°F (38.9°C)'**
  String get temp_more_than_102;

  /// No description provided for @paracetamolGivenLabel.
  ///
  /// In en, this message translates to:
  /// **'Paracetamol tablet given (Temperature up to 102°F / 38.9°C)'**
  String get paracetamolGivenLabel;

  /// No description provided for @refer_to_hospital.
  ///
  /// In en, this message translates to:
  /// **'Refer to Hospital'**
  String get refer_to_hospital;

  /// No description provided for @please_add_family_head_details.
  ///
  /// In en, this message translates to:
  /// **'Please add family head details'**
  String get please_add_family_head_details;

  /// No description provided for @totalBeneficiaryAdded.
  ///
  /// In en, this message translates to:
  /// **'Total beneficiary added'**
  String get totalBeneficiaryAdded;

  /// No description provided for @enterTypeOfFuelForCooking.
  ///
  /// In en, this message translates to:
  /// **'Enter type of fuel for cooking'**
  String get enterTypeOfFuelForCooking;

  /// No description provided for @enterPrimarySourceOfWater.
  ///
  /// In en, this message translates to:
  /// **'Enter primary source of water'**
  String get enterPrimarySourceOfWater;

  /// No description provided for @other_availability_of_electricity.
  ///
  /// In en, this message translates to:
  /// **'Enter availability of electricity'**
  String get other_availability_of_electricity;

  /// No description provided for @typeOfToiletLabel.
  ///
  /// In en, this message translates to:
  /// **'Type of toilet'**
  String get typeOfToiletLabel;

  /// No description provided for @flushToiletWithRunningWater.
  ///
  /// In en, this message translates to:
  /// **'Flush toilet with running water'**
  String get flushToiletWithRunningWater;

  /// No description provided for @flushToiletWithoutWater.
  ///
  /// In en, this message translates to:
  /// **'Flush toilet without water'**
  String get flushToiletWithoutWater;

  /// No description provided for @pitToiletWithRunningWater.
  ///
  /// In en, this message translates to:
  /// **'Pit toilet with running water'**
  String get pitToiletWithRunningWater;

  /// No description provided for @pitToiletWithoutWaterSupply.
  ///
  /// In en, this message translates to:
  /// **'Pit toilet without water supply'**
  String get pitToiletWithoutWaterSupply;

  /// No description provided for @enterTypeOfToiletLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter Type of toilet'**
  String get enterTypeOfToiletLabel;

  /// No description provided for @whereDoYouGoForToiletLabel.
  ///
  /// In en, this message translates to:
  /// **'Where do you go for toilet?'**
  String get whereDoYouGoForToiletLabel;

  /// No description provided for @communityToilet.
  ///
  /// In en, this message translates to:
  /// **'Community toilet'**
  String get communityToilet;

  /// No description provided for @friendRelativeToilet.
  ///
  /// In en, this message translates to:
  /// **'Friend/Relative toilet'**
  String get friendRelativeToilet;

  /// No description provided for @openSpace.
  ///
  /// In en, this message translates to:
  /// **'Open space'**
  String get openSpace;

  /// No description provided for @other_type_of_residential_area.
  ///
  /// In en, this message translates to:
  /// **'Enter type of residential area'**
  String get other_type_of_residential_area;

  /// No description provided for @enterTypeOfOwnershipLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter type of ownership'**
  String get enterTypeOfOwnershipLabel;

  /// No description provided for @other_type_of_house.
  ///
  /// In en, this message translates to:
  /// **'Enter type of house'**
  String get other_type_of_house;

  /// No description provided for @failedToSaveFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Failed to save family member. Please try again.'**
  String get failedToSaveFamilyMember;

  /// No description provided for @setMaritaDetails.
  ///
  /// In en, this message translates to:
  /// **'Set Marital Status = Married to fill Spouse details.'**
  String get setMaritaDetails;

  /// No description provided for @setChildDetails.
  ///
  /// In en, this message translates to:
  /// **'Select Have Children = Yes to fill Children details.'**
  String get setChildDetails;

  /// No description provided for @childrenDetails.
  ///
  /// In en, this message translates to:
  /// **'Children Details'**
  String get childrenDetails;

  /// No description provided for @spouseDetails.
  ///
  /// In en, this message translates to:
  /// **'Spouse Details'**
  String get spouseDetails;

  /// No description provided for @member_status_label.
  ///
  /// In en, this message translates to:
  /// **'Member Status *'**
  String get member_status_label;

  /// No description provided for @death.
  ///
  /// In en, this message translates to:
  /// **'Death'**
  String get death;

  /// No description provided for @please_select_date_of_death.
  ///
  /// In en, this message translates to:
  /// **'Please select date of death'**
  String get please_select_date_of_death;

  /// No description provided for @enter_place_of_death.
  ///
  /// In en, this message translates to:
  /// **'Enter place of death'**
  String get enter_place_of_death;

  /// No description provided for @please_enter_place_of_death.
  ///
  /// In en, this message translates to:
  /// **'Please enter place of death'**
  String get please_enter_place_of_death;

  /// No description provided for @please_select_member_status.
  ///
  /// In en, this message translates to:
  /// **'Please select member status'**
  String get please_select_member_status;

  /// No description provided for @reason_of_death_label.
  ///
  /// In en, this message translates to:
  /// **'Reason of Death *'**
  String get reason_of_death_label;

  /// No description provided for @natural_causes.
  ///
  /// In en, this message translates to:
  /// **'Natural Causes'**
  String get natural_causes;

  /// No description provided for @illness.
  ///
  /// In en, this message translates to:
  /// **'Illness'**
  String get illness;

  /// No description provided for @accident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get accident;

  /// No description provided for @please_select_reason_of_death.
  ///
  /// In en, this message translates to:
  /// **'Please select reason of death'**
  String get please_select_reason_of_death;

  /// No description provided for @please_specify_reason_of_death.
  ///
  /// In en, this message translates to:
  /// **'Please specify reason of death'**
  String get please_specify_reason_of_death;

  /// No description provided for @enter_reason_of_death.
  ///
  /// In en, this message translates to:
  /// **'Enter reason of death'**
  String get enter_reason_of_death;

  /// No description provided for @specify_reason_required.
  ///
  /// In en, this message translates to:
  /// **'Specify Reason *'**
  String get specify_reason_required;

  /// No description provided for @enter_12_digit_rch_id.
  ///
  /// In en, this message translates to:
  /// **'Enter 12 digit RCH ID'**
  String get enter_12_digit_rch_id;

  /// No description provided for @must_be_12_digits.
  ///
  /// In en, this message translates to:
  /// **'Must be 12 digits'**
  String get must_be_12_digits;

  /// No description provided for @rch_id_must_be_12_digits.
  ///
  /// In en, this message translates to:
  /// **'RCH ID must be exactly 12 digits'**
  String get rch_id_must_be_12_digits;

  /// No description provided for @verifying_rch_id.
  ///
  /// In en, this message translates to:
  /// **'Verifying RCH ID...'**
  String get verifying_rch_id;

  /// No description provided for @invalid_rch_id.
  ///
  /// In en, this message translates to:
  /// **'Invalid RCH ID'**
  String get invalid_rch_id;

  /// No description provided for @rch_id_must_be_12digits.
  ///
  /// In en, this message translates to:
  /// **'RCH ID must be exactly 12 digits'**
  String get rch_id_must_be_12digits;

  /// No description provided for @please_enter_rch_id_first.
  ///
  /// In en, this message translates to:
  /// **'Please enter RCH ID first'**
  String get please_enter_rch_id_first;

  /// No description provided for @no_data_found_rch_id.
  ///
  /// In en, this message translates to:
  /// **'No data found for this RCH ID'**
  String get no_data_found_rch_id;

  /// No description provided for @api_returned_null_response.
  ///
  /// In en, this message translates to:
  /// **'API returned null response'**
  String get api_returned_null_response;

  /// No description provided for @failed_to_fetch_rch_data.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch RCH data'**
  String get failed_to_fetch_rch_data;

  /// No description provided for @failedTo_fetch_rch_data.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch RCH data'**
  String get failedTo_fetch_rch_data;

  /// No description provided for @rch_data_loaded_successfully.
  ///
  /// In en, this message translates to:
  /// **'RCH data loaded successfully!'**
  String get rch_data_loaded_successfully;

  /// No description provided for @enter_relation_with_family_head.
  ///
  /// In en, this message translates to:
  /// **'Enter relation with family head'**
  String get enter_relation_with_family_head;

  /// No description provided for @relation_with_mobile_holder_required.
  ///
  /// In en, this message translates to:
  /// **'Relation with mobile no. holder is required'**
  String get relation_with_mobile_holder_required;

  /// No description provided for @enter_relation_with_mobile_holder.
  ///
  /// In en, this message translates to:
  /// **'Enter relation with mobile no. holder'**
  String get enter_relation_with_mobile_holder;

  /// No description provided for @error_loading_head_mobile.
  ///
  /// In en, this message translates to:
  /// **'Error loading head of family mobile number'**
  String get error_loading_head_mobile;

  /// No description provided for @no_mobile_found_for_head.
  ///
  /// In en, this message translates to:
  /// **'No mobile number found for the head of family'**
  String get no_mobile_found_for_head;

  /// No description provided for @child_age_validation.
  ///
  /// In en, this message translates to:
  /// **'For Child: Age should be between 1 day to 15 years.'**
  String get child_age_validation;

  /// No description provided for @dob_cannot_be_future.
  ///
  /// In en, this message translates to:
  /// **'Date of birth cannot be in the future'**
  String get dob_cannot_be_future;

  /// No description provided for @dob_required.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get dob_required;

  /// No description provided for @enter_other_occupation.
  ///
  /// In en, this message translates to:
  /// **'Enter occupation'**
  String get enter_other_occupation;

  /// No description provided for @enter_valid_weight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get enter_valid_weight;

  /// No description provided for @weight_range_validation.
  ///
  /// In en, this message translates to:
  /// **'Weight must be between 1.2 and 90 Kg'**
  String get weight_range_validation;

  /// No description provided for @weight_at_birth.
  ///
  /// In en, this message translates to:
  /// **'Birth Weight (1200-4000)gms'**
  String get weight_at_birth;

  /// No description provided for @birth_weight_range_validation.
  ///
  /// In en, this message translates to:
  /// **'Birth weight must be between 1200 and 4000 gms'**
  String get birth_weight_range_validation;

  /// No description provided for @enter_valid_birth_weight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid birth weight'**
  String get enter_valid_birth_weight;

  /// No description provided for @is_school_going_child.
  ///
  /// In en, this message translates to:
  /// **'Is he/she a school-going child?'**
  String get is_school_going_child;

  /// No description provided for @is_birth_certificate_issued.
  ///
  /// In en, this message translates to:
  /// **'Is birth certificate issued?'**
  String get is_birth_certificate_issued;

  /// No description provided for @enter_religion.
  ///
  /// In en, this message translates to:
  /// **'Enter Religion'**
  String get enter_religion;

  /// No description provided for @enter_category.
  ///
  /// In en, this message translates to:
  /// **'Enter Category'**
  String get enter_category;

  /// No description provided for @invalid_length.
  ///
  /// In en, this message translates to:
  /// **'Invalid length'**
  String get invalid_length;

  /// No description provided for @bank_account_length_error.
  ///
  /// In en, this message translates to:
  /// **'Bank account number must be between 11 to 18 digits'**
  String get bank_account_length_error;

  /// No description provided for @ifsc_invalid_format.
  ///
  /// In en, this message translates to:
  /// **'IFSC code must have first 4 uppercase letters, followed by 0 and 6 digits'**
  String get ifsc_invalid_format;

  /// No description provided for @ifsc_invalid_length.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 11-character IFSC code'**
  String get ifsc_invalid_length;

  /// No description provided for @please_select_family_planning_status.
  ///
  /// In en, this message translates to:
  /// **'Please select family planning status'**
  String get please_select_family_planning_status;

  /// No description provided for @antraInjection.
  ///
  /// In en, this message translates to:
  /// **'Antra injection'**
  String get antraInjection;

  /// No description provided for @dateOfAntra.
  ///
  /// In en, this message translates to:
  /// **'Date of Antra'**
  String get dateOfAntra;

  /// No description provided for @removalDate.
  ///
  /// In en, this message translates to:
  /// **'Removal Date'**
  String get removalDate;

  /// No description provided for @pleaseCorrectErrors.
  ///
  /// In en, this message translates to:
  /// **'Please correct the highlighted errors before continuing.'**
  String get pleaseCorrectErrors;

  /// No description provided for @fillSpouseDetails.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields in the spouse details before continuing.'**
  String get fillSpouseDetails;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'UPDATING...'**
  String get updating;

  /// No description provided for @errorPreparingData.
  ///
  /// In en, this message translates to:
  /// **'Error preparing data. Please try again.'**
  String get errorPreparingData;

  /// No description provided for @please_age_unit.
  ///
  /// In en, this message translates to:
  /// **'Please select age unit'**
  String get please_age_unit;

  /// No description provided for @pleaseEnterValidAgeForUnit.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid age for selected unit'**
  String get pleaseEnterValidAgeForUnit;

  /// No description provided for @expectedDeliveryDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Expected delivery date is required'**
  String get expectedDeliveryDateRequired;

  /// No description provided for @lastMenstrualPeriodRequired.
  ///
  /// In en, this message translates to:
  /// **'Last menstrual period date is required'**
  String get lastMenstrualPeriodRequired;

  /// No description provided for @selectIsWomanPregnant.
  ///
  /// In en, this message translates to:
  /// **'Please select if the woman is pregnant'**
  String get selectIsWomanPregnant;

  /// No description provided for @validIfscCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 11-character IFSC code, with the first 4 characters in uppercase letters, 5th character must be 0, and the remaining characters being digits'**
  String get validIfscCode;

  /// No description provided for @validMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number must be 10 digits and start with 6-9'**
  String get validMobileNumber;

  /// No description provided for @mobileNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileNumberRequired;

  /// No description provided for @relationWithMobileHolder.
  ///
  /// In en, this message translates to:
  /// **'Relation with mobile no. holder'**
  String get relationWithMobileHolder;

  /// No description provided for @whoseMobileNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Whose mobile number is required'**
  String get whoseMobileNumberRequired;

  /// No description provided for @errorLoadingMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Error loading mobile number'**
  String get errorLoadingMobileNumber;

  /// No description provided for @rchIdFemaleOnly.
  ///
  /// In en, this message translates to:
  /// **'RCH ID is only applicable for female members'**
  String get rchIdFemaleOnly;

  /// No description provided for @invalidOrNotFoundRchId.
  ///
  /// In en, this message translates to:
  /// **'Invalid or not found RCH ID'**
  String get invalidOrNotFoundRchId;

  /// No description provided for @rchIdVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'RCH ID verified and data loaded successfully!'**
  String get rchIdVerifiedSuccess;

  /// No description provided for @please_enter_valid_rch_id.
  ///
  /// In en, this message translates to:
  /// **'Please enter RCH ID'**
  String get please_enter_valid_rch_id;

  /// No description provided for @spouseNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Spouse name is required'**
  String get spouseNameRequired;

  /// No description provided for @memberNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name of member is required'**
  String get memberNameRequired;

  /// No description provided for @relationWithFamilyHeadRequired.
  ///
  /// In en, this message translates to:
  /// **'Relation with family head is required'**
  String get relationWithFamilyHeadRequired;

  /// No description provided for @brother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get brother;

  /// No description provided for @sister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get sister;

  /// No description provided for @nephew.
  ///
  /// In en, this message translates to:
  /// **'Nephew'**
  String get nephew;

  /// No description provided for @niece.
  ///
  /// In en, this message translates to:
  /// **'Niece'**
  String get niece;

  /// No description provided for @grandFather.
  ///
  /// In en, this message translates to:
  /// **'Grand Father'**
  String get grandFather;

  /// No description provided for @grandMother.
  ///
  /// In en, this message translates to:
  /// **'Grand Mother'**
  String get grandMother;

  /// No description provided for @grandSon.
  ///
  /// In en, this message translates to:
  /// **'Grand Son'**
  String get grandSon;

  /// No description provided for @grandDaughter.
  ///
  /// In en, this message translates to:
  /// **'Grand Daughter'**
  String get grandDaughter;

  /// No description provided for @sonInLaw.
  ///
  /// In en, this message translates to:
  /// **'Son In Law'**
  String get sonInLaw;

  /// No description provided for @daughterInLaw.
  ///
  /// In en, this message translates to:
  /// **'Daughter In Law'**
  String get daughterInLaw;

  /// No description provided for @abhaDetailsSpouseSuccess.
  ///
  /// In en, this message translates to:
  /// **'ABHA details filled for Spouse successfully!'**
  String get abhaDetailsSpouseSuccess;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender is required'**
  String get genderRequired;

  /// No description provided for @rchVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'RCH Verified Successfully!'**
  String get rchVerifiedSuccess;

  /// No description provided for @rchVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'RCH Verified Successfully!'**
  String get rchVerifiedSuccessfully;

  /// No description provided for @enterRelationWithMobileHolder.
  ///
  /// In en, this message translates to:
  /// **'Enter relation with mobile number holder'**
  String get enterRelationWithMobileHolder;

  /// No description provided for @ifscValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 11-character IFSC code. The first 4 characters must be uppercase letters, the 5th character must be 0, and the remaining characters must be digits.'**
  String get ifscValidationMessage;

  /// No description provided for @enterSerialNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter serial number'**
  String get enterSerialNumber;

  /// No description provided for @pleaseEnterDob.
  ///
  /// In en, this message translates to:
  /// **'Please enter Date of Birth'**
  String get pleaseEnterDob;

  /// No description provided for @pleaseEnterDor.
  ///
  /// In en, this message translates to:
  /// **'Please enter Date of Registration'**
  String get pleaseEnterDor;

  /// No description provided for @enterFullNameChild.
  ///
  /// In en, this message translates to:
  /// **'Enter full name of the child'**
  String get enterFullNameChild;

  /// No description provided for @pleaseEnterChildName.
  ///
  /// In en, this message translates to:
  /// **'Please enter Child\'s name'**
  String get pleaseEnterChildName;

  /// No description provided for @pleaseEnterGender.
  ///
  /// In en, this message translates to:
  /// **'Please enter Gender'**
  String get pleaseEnterGender;

  /// No description provided for @pleaseEnterMothersName.
  ///
  /// In en, this message translates to:
  /// **'Please enter Mother\'s name'**
  String get pleaseEnterMothersName;

  /// No description provided for @enterMothersName.
  ///
  /// In en, this message translates to:
  /// **'Enter mother\'s name'**
  String get enterMothersName;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter address'**
  String get enterAddress;

  /// No description provided for @pleaseEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter Address'**
  String get pleaseEnterAddress;

  /// No description provided for @pleaseEnterWhoseMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter Whose mobile number'**
  String get pleaseEnterWhoseMobileNumber;

  /// No description provided for @enter10DigitMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get enter10DigitMobileNumber;

  /// No description provided for @mobileMustBe10DigitsAndStartWith.
  ///
  /// In en, this message translates to:
  /// **'Mobile no. must be 10 digits and start with 6-9'**
  String get mobileMustBe10DigitsAndStartWith;

  /// No description provided for @pleaseEnterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter Mobile number'**
  String get pleaseEnterMobileNumber;

  /// No description provided for @enterMothersRchId.
  ///
  /// In en, this message translates to:
  /// **'Enter mother\'s RCH ID'**
  String get enterMothersRchId;

  /// No description provided for @enterBirthCertificateNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter birth certificate number if available'**
  String get enterBirthCertificateNumber;

  /// No description provided for @child_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (500-12500)gms'**
  String get child_weight;

  /// No description provided for @enter_Weight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get enter_Weight;

  /// No description provided for @weightRangeError.
  ///
  /// In en, this message translates to:
  /// **'Weight must be between 500 and 12500 grams'**
  String get weightRangeError;

  /// No description provided for @enterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight in grams'**
  String get enterValidWeight;

  /// No description provided for @enterBirthWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter birth weight'**
  String get enterBirthWeight;

  /// No description provided for @birthWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Birth weight (1200-4000 gms)'**
  String get birthWeightRange;

  /// No description provided for @enterValidBirthWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid birth weight in grams'**
  String get enterValidBirthWeight;

  /// No description provided for @specifyReligionLabel.
  ///
  /// In en, this message translates to:
  /// **'Specify Religion'**
  String get specifyReligionLabel;

  /// No description provided for @enterReligion.
  ///
  /// In en, this message translates to:
  /// **'Enter your religion'**
  String get enterReligion;

  /// No description provided for @pleaseSpecifyReligion.
  ///
  /// In en, this message translates to:
  /// **'Please specify your religion'**
  String get pleaseSpecifyReligion;

  /// No description provided for @specifyCategory.
  ///
  /// In en, this message translates to:
  /// **'Please specify your category'**
  String get specifyCategory;

  /// No description provided for @enter_Category.
  ///
  /// In en, this message translates to:
  /// **'Enter your category'**
  String get enter_Category;

  /// No description provided for @ka.
  ///
  /// In en, this message translates to:
  /// **'ka'**
  String get ka;

  /// No description provided for @specifyCategoryShort.
  ///
  /// In en, this message translates to:
  /// **'Specify Category'**
  String get specifyCategoryShort;

  /// No description provided for @correctHighlightedFields.
  ///
  /// In en, this message translates to:
  /// **'Please correct the highlighted fields.'**
  String get correctHighlightedFields;

  /// No description provided for @noChildrenFound.
  ///
  /// In en, this message translates to:
  /// **'No children found for registration'**
  String get noChildrenFound;

  /// No description provided for @childrenRegistrationDue.
  ///
  /// In en, this message translates to:
  /// **'Children with \"registration_due\" status will appear here'**
  String get childrenRegistrationDue;

  /// No description provided for @noMatchingChild.
  ///
  /// In en, this message translates to:
  /// **'No matching child beneficiaries found.'**
  String get noMatchingChild;

  /// No description provided for @noChildBeneficiaries.
  ///
  /// In en, this message translates to:
  /// **'No child beneficiaries found. Add a new child to get started.'**
  String get noChildBeneficiaries;

  /// No description provided for @deceased.
  ///
  /// In en, this message translates to:
  /// **'Deceased'**
  String get deceased;

  /// No description provided for @noHbycChildrenFound.
  ///
  /// In en, this message translates to:
  /// **'No HBYC children found'**
  String get noHbycChildrenFound;

  /// No description provided for @months3.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get months3;

  /// No description provided for @months6.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get months6;

  /// No description provided for @months9.
  ///
  /// In en, this message translates to:
  /// **'9 months'**
  String get months9;

  /// No description provided for @months12.
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get months12;

  /// No description provided for @months15.
  ///
  /// In en, this message translates to:
  /// **'15 months'**
  String get months15;

  /// No description provided for @homeBasedCareForYoungChild.
  ///
  /// In en, this message translates to:
  /// **'Home Based Care For Young Child'**
  String get homeBasedCareForYoungChild;

  /// No description provided for @hbycHomeVisit.
  ///
  /// In en, this message translates to:
  /// **'HBYC home visit? *'**
  String get hbycHomeVisit;

  /// No description provided for @is_referred_to_health_facility.
  ///
  /// In en, this message translates to:
  /// **'Child referred to health facility?'**
  String get is_referred_to_health_facility;

  /// No description provided for @is_complementary_food_given.
  ///
  /// In en, this message translates to:
  /// **'Complementary food given?'**
  String get is_complementary_food_given;

  /// No description provided for @foodAdvice_1.
  ///
  /// In en, this message translates to:
  /// **'2–3 tablespoons of food at a time, 2–3 times each day'**
  String get foodAdvice_1;

  /// No description provided for @foodAdvice_2.
  ///
  /// In en, this message translates to:
  /// **'1/2 cup/katori serving at a time, 2–3 times each day with 1–2 snacks between meals'**
  String get foodAdvice_2;

  /// No description provided for @foodAdvice_3.
  ///
  /// In en, this message translates to:
  /// **'1/2 cup/katori serving at a time, 3–4 times each day with 1–2 snacks between meals'**
  String get foodAdvice_3;

  /// No description provided for @foodAdvice_4.
  ///
  /// In en, this message translates to:
  /// **'3/4 to 1 cup/katori serving at a time, 3–4 times each day with 1–2 snacks between meals'**
  String get foodAdvice_4;

  /// No description provided for @mentionRecordedWeightForAge.
  ///
  /// In en, this message translates to:
  /// **'Mention the recorded weight-for-age as per MCP card (in kg)'**
  String get mentionRecordedWeightForAge;

  /// No description provided for @pleaseEnterWeightForAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter weight-for-age'**
  String get pleaseEnterWeightForAge;

  /// No description provided for @recordingWeightForLengthHeight.
  ///
  /// In en, this message translates to:
  /// **'Recording of weight-for-length/height by Anganwadi Worker'**
  String get recordingWeightForLengthHeight;

  /// No description provided for @recorded_height.
  ///
  /// In en, this message translates to:
  /// **'Mention the recorded weight-for-length/height as per MCP card (in cm)'**
  String get recorded_height;

  /// No description provided for @enterWeightForLengthHeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter weight-for-length/height'**
  String get enterWeightForLengthHeight;

  /// No description provided for @referred_place.
  ///
  /// In en, this message translates to:
  /// **'Referred place'**
  String get referred_place;

  /// No description provided for @is_developmental_delay_checked.
  ///
  /// In en, this message translates to:
  /// **'Developmental delay checked?'**
  String get is_developmental_delay_checked;

  /// No description provided for @isChildReferred.
  ///
  /// In en, this message translates to:
  /// **'Is the child referred?'**
  String get isChildReferred;

  /// No description provided for @immunizationStatusChecked.
  ///
  /// In en, this message translates to:
  /// **'Immunization status checked as per MCP card?'**
  String get immunizationStatusChecked;

  /// No description provided for @orsGiven.
  ///
  /// In en, this message translates to:
  /// **'ORS given?'**
  String get orsGiven;

  /// No description provided for @enterOrsCount.
  ///
  /// In en, this message translates to:
  /// **'Please enter number of ORS given'**
  String get enterOrsCount;

  /// No description provided for @orsCount.
  ///
  /// In en, this message translates to:
  /// **'Number of ORS given'**
  String get orsCount;

  /// No description provided for @ifaSyrupGiven.
  ///
  /// In en, this message translates to:
  /// **'Iron Folic Acid syrup given?'**
  String get ifaSyrupGiven;

  /// No description provided for @ifaSyrupCount.
  ///
  /// In en, this message translates to:
  /// **'Number of Iron Folic Acid syrup given'**
  String get ifaSyrupCount;

  /// No description provided for @ifaSyrupCountValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter number of Iron Folic Acid syrup given'**
  String get ifaSyrupCountValidation;

  /// No description provided for @counselExclusiveBreastfeeding.
  ///
  /// In en, this message translates to:
  /// **'Counsel for exclusive breastfeeding?'**
  String get counselExclusiveBreastfeeding;

  /// No description provided for @is_counsel_for_complementary_feeding.
  ///
  /// In en, this message translates to:
  /// **'Counsel for complementary feeding?'**
  String get is_counsel_for_complementary_feeding;

  /// No description provided for @is_counsel_for_hand_washing.
  ///
  /// In en, this message translates to:
  /// **'Counsel for hand washing?'**
  String get is_counsel_for_hand_washing;

  /// No description provided for @is_counsel_for_parenting.
  ///
  /// In en, this message translates to:
  /// **'Counsel for parenting?'**
  String get is_counsel_for_parenting;

  /// No description provided for @familyPlanningCounselling.
  ///
  /// In en, this message translates to:
  /// **'Family Planning Counselling?'**
  String get familyPlanningCounselling;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @saveForm.
  ///
  /// In en, this message translates to:
  /// **'Save Form'**
  String get saveForm;

  /// No description provided for @child_deseased_list.
  ///
  /// In en, this message translates to:
  /// **'Deceased Child List'**
  String get child_deseased_list;

  /// No description provided for @searchByNameIdMobile.
  ///
  /// In en, this message translates to:
  /// **'Search by name, ID, or mobile'**
  String get searchByNameIdMobile;

  /// No description provided for @noMatchingRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching records found'**
  String get noMatchingRecordsFound;

  /// No description provided for @noDeceasedChildrenFound.
  ///
  /// In en, this message translates to:
  /// **'No deceased children found'**
  String get noDeceasedChildrenFound;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @temporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get temporary;

  /// No description provided for @permanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get permanent;

  /// No description provided for @measles.
  ///
  /// In en, this message translates to:
  /// **'Measles'**
  String get measles;

  /// No description provided for @lowBirthWeight.
  ///
  /// In en, this message translates to:
  /// **'Low birth weight'**
  String get lowBirthWeight;

  /// No description provided for @highFever.
  ///
  /// In en, this message translates to:
  /// **'High fever'**
  String get highFever;

  /// No description provided for @diarrhoea.
  ///
  /// In en, this message translates to:
  /// **'Diarrhoea'**
  String get diarrhoea;

  /// No description provided for @pneumonia.
  ///
  /// In en, this message translates to:
  /// **'Pneumonia'**
  String get pneumonia;

  /// No description provided for @severeAnaemia.
  ///
  /// In en, this message translates to:
  /// **'Severe Anaemia'**
  String get severeAnaemia;

  /// No description provided for @sepsis.
  ///
  /// In en, this message translates to:
  /// **'Sepsis'**
  String get sepsis;

  /// No description provided for @obstructLabour.
  ///
  /// In en, this message translates to:
  /// **'Obstruct Labour'**
  String get obstructLabour;

  /// No description provided for @eclampsiaHypertension.
  ///
  /// In en, this message translates to:
  /// **'Eclampsia/ Severe Hypertension'**
  String get eclampsiaHypertension;

  /// No description provided for @unsafeAbortion.
  ///
  /// In en, this message translates to:
  /// **'Unsafe Abortion'**
  String get unsafeAbortion;

  /// No description provided for @surgicalComplication.
  ///
  /// In en, this message translates to:
  /// **'Surgical Complication'**
  String get surgicalComplication;

  /// No description provided for @otherMaternalReason.
  ///
  /// In en, this message translates to:
  /// **'Other reason apart from maternal complication'**
  String get otherMaternalReason;

  /// No description provided for @otherSpecify.
  ///
  /// In en, this message translates to:
  /// **'Other Specify'**
  String get otherSpecify;

  /// No description provided for @case_closer.
  ///
  /// In en, this message translates to:
  /// **'Case closure'**
  String get case_closer;

  /// No description provided for @reasonOfClosure.
  ///
  /// In en, this message translates to:
  /// **'Reason of Closure'**
  String get reasonOfClosure;

  /// No description provided for @migrationType.
  ///
  /// In en, this message translates to:
  /// **'Migration Type'**
  String get migrationType;

  /// No description provided for @enterReasonForClosure.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for closure'**
  String get enterReasonForClosure;

  /// No description provided for @specifyReason.
  ///
  /// In en, this message translates to:
  /// **'Specify Reason'**
  String get specifyReason;

  /// No description provided for @probableCauseOfDeath.
  ///
  /// In en, this message translates to:
  /// **'Probable Cause of Death'**
  String get probableCauseOfDeath;

  /// No description provided for @specifyCauseOfDeath.
  ///
  /// In en, this message translates to:
  /// **'Specify cause of death'**
  String get specifyCauseOfDeath;

  /// No description provided for @deathPlace.
  ///
  /// In en, this message translates to:
  /// **'Death Place'**
  String get deathPlace;

  /// No description provided for @reasonOfDeath.
  ///
  /// In en, this message translates to:
  /// **'Reason of Death'**
  String get reasonOfDeath;

  /// No description provided for @otherReasonOfDeath.
  ///
  /// In en, this message translates to:
  /// **'Other reason of Death'**
  String get otherReasonOfDeath;

  /// No description provided for @no_ChildrenFound.
  ///
  /// In en, this message translates to:
  /// **'No children found'**
  String get no_ChildrenFound;

  /// No description provided for @caseClosureRecorded.
  ///
  /// In en, this message translates to:
  /// **'Case closure recorded. Child removed from tracking list.'**
  String get caseClosureRecorded;

  /// No description provided for @childRegistration.
  ///
  /// In en, this message translates to:
  /// **'Child Registration'**
  String get childRegistration;

  /// No description provided for @content_ComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Content Coming Soon...'**
  String get content_ComingSoon;

  /// No description provided for @birth_Doses.
  ///
  /// In en, this message translates to:
  /// **'Birth Doses'**
  String get birth_Doses;

  /// No description provided for @doses16Year.
  ///
  /// In en, this message translates to:
  /// **'16 Year Doses'**
  String get doses16Year;

  /// No description provided for @dateOfVisits.
  ///
  /// In en, this message translates to:
  /// **'Date of Visits'**
  String get dateOfVisits;

  /// No description provided for @six_WeekDoses.
  ///
  /// In en, this message translates to:
  /// **'6 Week Doses'**
  String get six_WeekDoses;

  /// No description provided for @ten_WeekDoses.
  ///
  /// In en, this message translates to:
  /// **'10 Week Doses'**
  String get ten_WeekDoses;

  /// No description provided for @fourteen_WeekDoses.
  ///
  /// In en, this message translates to:
  /// **'14 Week Doses'**
  String get fourteen_WeekDoses;

  /// No description provided for @nineMonthDoses.
  ///
  /// In en, this message translates to:
  /// **'9 Month Doses'**
  String get nineMonthDoses;

  /// No description provided for @sixteenToTwentyFourMonthDoses.
  ///
  /// In en, this message translates to:
  /// **'16-24 Month Doses'**
  String get sixteenToTwentyFourMonthDoses;

  /// No description provided for @fiveToSixYearDoses.
  ///
  /// In en, this message translates to:
  /// **'5-6 Year Doses'**
  String get fiveToSixYearDoses;

  /// No description provided for @tenYearDoses.
  ///
  /// In en, this message translates to:
  /// **'10 Year Doses'**
  String get tenYearDoses;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @facilitatorProfile.
  ///
  /// In en, this message translates to:
  /// **'Facilitator Profile'**
  String get facilitatorProfile;

  /// No description provided for @formSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Form Submitted Successfully'**
  String get formSubmittedSuccessfully;

  /// No description provided for @ashaFacilitatorId.
  ///
  /// In en, this message translates to:
  /// **'ASHA Facilitator ID'**
  String get ashaFacilitatorId;

  /// No description provided for @enterAshaFacilitatorId.
  ///
  /// In en, this message translates to:
  /// **'Enter ASHA Facilitator ID'**
  String get enterAshaFacilitatorId;

  /// No description provided for @ashaFacilitator_Name.
  ///
  /// In en, this message translates to:
  /// **'Name of ASHA Facilitator'**
  String get ashaFacilitator_Name;

  /// No description provided for @enterAshaFacilitatorName.
  ///
  /// In en, this message translates to:
  /// **'Enter Name of ASHA Facilitator'**
  String get enterAshaFacilitatorName;

  /// No description provided for @age_label.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age_label;

  /// No description provided for @populationCoveredAshaFacilitator.
  ///
  /// In en, this message translates to:
  /// **'Population covered under ASHA Facilitator'**
  String get populationCoveredAshaFacilitator;

  /// No description provided for @enterPopulationCoveredAshaFacilitator.
  ///
  /// In en, this message translates to:
  /// **'Enter population covered under ASHA Facilitator'**
  String get enterPopulationCoveredAshaFacilitator;

  /// No description provided for @numberOfAshaUnderFacilitator.
  ///
  /// In en, this message translates to:
  /// **'No. of ASHA under the facilitator'**
  String get numberOfAshaUnderFacilitator;

  /// No description provided for @population.
  ///
  /// In en, this message translates to:
  /// **'Population'**
  String get population;

  /// No description provided for @phoneNumberShort.
  ///
  /// In en, this message translates to:
  /// **'Ph No.'**
  String get phoneNumberShort;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @srNumber.
  ///
  /// In en, this message translates to:
  /// **'Sr'**
  String get srNumber;

  /// No description provided for @communityC.
  ///
  /// In en, this message translates to:
  /// **'C - Community'**
  String get communityC;

  /// No description provided for @institutionalI.
  ///
  /// In en, this message translates to:
  /// **'I - Institutional'**
  String get institutionalI;

  /// No description provided for @categoryA.
  ///
  /// In en, this message translates to:
  /// **'Category A'**
  String get categoryA;

  /// No description provided for @categoryB.
  ///
  /// In en, this message translates to:
  /// **'Category B'**
  String get categoryB;

  /// No description provided for @categoryC.
  ///
  /// In en, this message translates to:
  /// **'Category C'**
  String get categoryC;

  /// No description provided for @register1.
  ///
  /// In en, this message translates to:
  /// **'Register 1'**
  String get register1;

  /// No description provided for @register2.
  ///
  /// In en, this message translates to:
  /// **'Register 2'**
  String get register2;

  /// No description provided for @register3.
  ///
  /// In en, this message translates to:
  /// **'Register 3'**
  String get register3;

  /// No description provided for @setting_update_msg.
  ///
  /// In en, this message translates to:
  /// **'Your Bhavya m-ASHA application is up to date.'**
  String get setting_update_msg;

  /// No description provided for @aasha.
  ///
  /// In en, this message translates to:
  /// **'ASHA'**
  String get aasha;

  /// No description provided for @help_title.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help_title;

  /// No description provided for @ashaModule1.
  ///
  /// In en, this message translates to:
  /// **'ASHA module 1'**
  String get ashaModule1;

  /// No description provided for @ashaModule2.
  ///
  /// In en, this message translates to:
  /// **'ASHA module 2'**
  String get ashaModule2;

  /// No description provided for @ashaModule3.
  ///
  /// In en, this message translates to:
  /// **'ASHA module 3'**
  String get ashaModule3;

  /// No description provided for @ashaModule4.
  ///
  /// In en, this message translates to:
  /// **'ASHA module 4'**
  String get ashaModule4;

  /// No description provided for @ashaModule567.
  ///
  /// In en, this message translates to:
  /// **'ASHA module 5,6 & 7'**
  String get ashaModule567;

  /// No description provided for @ncdLabel.
  ///
  /// In en, this message translates to:
  /// **'NCD'**
  String get ncdLabel;

  /// No description provided for @hbnc.
  ///
  /// In en, this message translates to:
  /// **'HBNC'**
  String get hbnc;

  /// No description provided for @hbyc.
  ///
  /// In en, this message translates to:
  /// **'HBYC'**
  String get hbyc;

  /// No description provided for @ashaFacilitatorTraining.
  ///
  /// In en, this message translates to:
  /// **'ASHA Facilitator training'**
  String get ashaFacilitatorTraining;

  /// No description provided for @inductionTraining.
  ///
  /// In en, this message translates to:
  /// **'Induction Training'**
  String get inductionTraining;

  /// No description provided for @maa.
  ///
  /// In en, this message translates to:
  /// **'MAA (Mothers Absolute Affection)'**
  String get maa;

  /// No description provided for @idcf.
  ///
  /// In en, this message translates to:
  /// **'IDCF (Integrated Diarrhoea Control Fortnight)'**
  String get idcf;

  /// No description provided for @otherTraining.
  ///
  /// In en, this message translates to:
  /// **'Other Training'**
  String get otherTraining;

  /// No description provided for @receiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get receiving;

  /// No description provided for @providing.
  ///
  /// In en, this message translates to:
  /// **'Providing'**
  String get providing;

  /// No description provided for @newHouseholdRegister.
  ///
  /// In en, this message translates to:
  /// **'New Household Registration'**
  String get newHouseholdRegister;

  /// No description provided for @sr_No.
  ///
  /// In en, this message translates to:
  /// **'Sr.No.'**
  String get sr_No;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present?'**
  String get present;

  /// No description provided for @hscNameHint.
  ///
  /// In en, this message translates to:
  /// **'HSC'**
  String get hscNameHint;

  /// No description provided for @hscNameLabel.
  ///
  /// In en, this message translates to:
  /// **'HSC'**
  String get hscNameLabel;

  /// No description provided for @hwcNameHint.
  ///
  /// In en, this message translates to:
  /// **'HWC'**
  String get hwcNameHint;

  /// No description provided for @hwcNameLabel.
  ///
  /// In en, this message translates to:
  /// **'HWC'**
  String get hwcNameLabel;

  /// No description provided for @moveForward.
  ///
  /// In en, this message translates to:
  /// **'Move forward?'**
  String get moveForward;

  /// No description provided for @lastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last Visit'**
  String get lastVisit;

  /// No description provided for @postNatalMssg.
  ///
  /// In en, this message translates to:
  /// **'The post natal care of beneficiary has been completed'**
  String get postNatalMssg;

  /// No description provided for @okayLabel.
  ///
  /// In en, this message translates to:
  /// **'OKAY'**
  String get okayLabel;

  /// No description provided for @hospitalReferMsg.
  ///
  /// In en, this message translates to:
  /// **'Please refer the child to nearby hospital.'**
  String get hospitalReferMsg;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention!'**
  String get attention;

  /// No description provided for @deliveryOutcome.
  ///
  /// In en, this message translates to:
  /// **'Delivery outcome'**
  String get deliveryOutcome;

  /// No description provided for @formSavedSuccessfullyLabel.
  ///
  /// In en, this message translates to:
  /// **'Form has been saved successfully'**
  String get formSavedSuccessfullyLabel;

  /// No description provided for @incentiveHeaderHscLabel.
  ///
  /// In en, this message translates to:
  /// **'HSC'**
  String get incentiveHeaderHscLabel;

  /// No description provided for @tbEradicationProgram.
  ///
  /// In en, this message translates to:
  /// **'Tuberculosis(TB) Eradication Program'**
  String get tbEradicationProgram;

  /// No description provided for @tbLabel1.
  ///
  /// In en, this message translates to:
  /// **'First Indicative Work/Intensive Search Campaign (on the lane for notifying new Tuberculosis patients)'**
  String get tbLabel1;

  /// No description provided for @tbLabel2.
  ///
  /// In en, this message translates to:
  /// **'Treatment provider work'**
  String get tbLabel2;

  /// No description provided for @tbLabel3.
  ///
  /// In en, this message translates to:
  /// **'On feeding medicine to Drug Sensitive Tuberculosis patient or Drug Resistant Tuberculosis patient per Shorter regimen'**
  String get tbLabel3;

  /// No description provided for @tbLabel4.
  ///
  /// In en, this message translates to:
  /// **'Conventional MDR treated Drug Resistant Tuberculosis patient (Rs. 2000) for feeding medicine (on Intensive Phase).'**
  String get tbLabel4;

  /// No description provided for @leprosyQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Amount payable to ASHA for finding new leprosy free patients'**
  String get leprosyQuestion1;

  /// No description provided for @leprosyQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Amount payable to ASHA for finding new leprosy patients with disabilities'**
  String get leprosyQuestion2;

  /// No description provided for @leprosyQuestion3.
  ///
  /// In en, this message translates to:
  /// **'Pauci-Bacillary (PB) of Leprosy Payable after complete treatment of leprosy'**
  String get leprosyQuestion3;

  /// No description provided for @leprosyQuestion4.
  ///
  /// In en, this message translates to:
  /// **'Amount after complete cure in multi-bacillary(MB) cases of leprosy'**
  String get leprosyQuestion4;

  /// No description provided for @malariaQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Active malaria infection test of malaria fever victims'**
  String get malariaQuestion1;

  /// No description provided for @malariaQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Providing full radical treatment to malaria positive P.V. or P.F. patients as per the latest claim system'**
  String get malariaQuestion2;

  /// No description provided for @filariasisScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Filaria Eradication Program'**
  String get filariasisScreenTitle;

  /// No description provided for @filariasisQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Front feeding of medicine under MDA program for every 50 households by ASHA during filariasis cycle (to cover one thousand population)'**
  String get filariasisQuestion1;

  /// No description provided for @aesJeQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Those patients referred by ASHA to the nearest PHC, CHC, Referral, DH or Medical College Hospital, whose Unknown AES or Japanese Encephalitis (JE) has been confirmed by the Medical Officer,will be given incentive amount'**
  String get aesJeQuestion2;

  /// No description provided for @filariasisProgram.
  ///
  /// In en, this message translates to:
  /// **'Filaria Eradication Program'**
  String get filariasisProgram;

  /// No description provided for @validateEmptyUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter the username'**
  String get validateEmptyUsername;

  /// No description provided for @validateEmptyCP.
  ///
  /// In en, this message translates to:
  /// **'Please enter the current password'**
  String get validateEmptyCP;

  /// No description provided for @validateEmptyNP.
  ///
  /// In en, this message translates to:
  /// **'Please enter the new password'**
  String get validateEmptyNP;

  /// No description provided for @validateEmptyRRP.
  ///
  /// In en, this message translates to:
  /// **'Please re-enter the new password'**
  String get validateEmptyRRP;

  /// No description provided for @cpAndNPNotSame.
  ///
  /// In en, this message translates to:
  /// **'The Current password and the new password can not be same.'**
  String get cpAndNPNotSame;

  /// No description provided for @npAndRRPValidation.
  ///
  /// In en, this message translates to:
  /// **'The new password and the re-entered password must be the same.'**
  String get npAndRRPValidation;

  /// No description provided for @errorMsg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorMsg;

  /// No description provided for @failUpdatePassMsg.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password'**
  String get failUpdatePassMsg;

  /// No description provided for @successUpdatePassMsg.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed successfully'**
  String get successUpdatePassMsg;

  /// No description provided for @diseaseTb.
  ///
  /// In en, this message translates to:
  /// **'Tuberculosis (TB)'**
  String get diseaseTb;

  /// No description provided for @diseaseHepatitisB.
  ///
  /// In en, this message translates to:
  /// **'Hepatitis B'**
  String get diseaseHepatitisB;

  /// No description provided for @diseaseAsthma.
  ///
  /// In en, this message translates to:
  /// **'Asthma'**
  String get diseaseAsthma;

  /// No description provided for @diseaseHighBp.
  ///
  /// In en, this message translates to:
  /// **'High Blood Pressure'**
  String get diseaseHighBp;

  /// No description provided for @diseaseStiRti.
  ///
  /// In en, this message translates to:
  /// **'STI / RTI'**
  String get diseaseStiRti;

  /// No description provided for @diseaseHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart Disease'**
  String get diseaseHeart;

  /// No description provided for @diseaseLiver.
  ///
  /// In en, this message translates to:
  /// **'Liver Disease'**
  String get diseaseLiver;

  /// No description provided for @diseaseKidney.
  ///
  /// In en, this message translates to:
  /// **'Kidney Disease'**
  String get diseaseKidney;

  /// No description provided for @diseaseEpilepsy.
  ///
  /// In en, this message translates to:
  /// **'Epilepsy'**
  String get diseaseEpilepsy;

  /// No description provided for @pleaseSpecifyOtherDisease.
  ///
  /// In en, this message translates to:
  /// **'Please specify other disease'**
  String get pleaseSpecifyOtherDisease;

  /// No description provided for @calciumVitaminD3TabletsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Calcium and Vitamin D3 tablets given'**
  String get calciumVitaminD3TabletsLabel;

  /// No description provided for @selectVisitTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please select visit type'**
  String get selectVisitTypeError;

  /// No description provided for @protected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protected;

  /// No description provided for @unprotected.
  ///
  /// In en, this message translates to:
  /// **'Unprotected'**
  String get unprotected;

  /// No description provided for @identificationNumber.
  ///
  /// In en, this message translates to:
  /// **'Identification Number'**
  String get identificationNumber;

  /// No description provided for @igree_I.
  ///
  /// In en, this message translates to:
  /// **'I, '**
  String get igree_I;

  /// No description provided for @igree_7.
  ///
  /// In en, this message translates to:
  /// **'I am voluntarily sharing my Aadhaar Number / Virtual ID issued by the Unique Identification Authority of India (\"UIDAI\"), and my demographic information for the purpose of creating an Ayushman Bharat Health Account number (\"ABHA number\") and Ayushman Bharat Health Account address (\"ABHA Address\"). I authorize NHA to use my Aadhaar number / Virtual ID for performing Aadhaar based authentication with UIDAI as per the provisions of the Aadhaar (Targeted Delivery of Financial and other Subsidies, Benefits and Services) Act, 2016 for the aforesaid purpose. I\nunderstand that UIDAI will share my e-KYC details, or response of \"Yes\" with NHA upon successful\nauthentication.'**
  String get igree_7;

  /// No description provided for @igree5.
  ///
  /// In en, this message translates to:
  /// **'confirm that I have duly informed and explained the beneficiary of the contents of consent for the aforementioned purposes.'**
  String get igree5;
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
