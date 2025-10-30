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
  /// **'ABHA address'**
  String get abhaAddressLabel;

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

  /// No description provided for @accountNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get accountNumberHint;

  /// No description provided for @accountNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
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

  /// No description provided for @occupationUnemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get occupationUnemployed;

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

  /// No description provided for @educationNoSchooling.
  ///
  /// In en, this message translates to:
  /// **'No Schooling'**
  String get educationNoSchooling;

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

  /// No description provided for @migrationStayingInHouse.
  ///
  /// In en, this message translates to:
  /// **'Staying in House'**
  String get migrationStayingInHouse;

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
  /// **'Advance Filter'**
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

  /// No description provided for @ageAtMarriageHint.
  ///
  /// In en, this message translates to:
  /// **'Age at the time of marriage'**
  String get ageAtMarriageHint;

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
  /// **'Announcement'**
  String get announcement;

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

  /// No description provided for @cbacC_fuelKerosene.
  ///
  /// In en, this message translates to:
  /// **'Kerosene'**
  String get cbacC_fuelKerosene;

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

  /// No description provided for @cbacC_fuelWood.
  ///
  /// In en, this message translates to:
  /// **'Wood'**
  String get cbacC_fuelWood;

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
  /// **'Please fill'**
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
  /// **'Registered Child\nBeneficiary list'**
  String get childRegisteredBeneficiaryListTitle;

  /// No description provided for @childRegisteredDueListTitle.
  ///
  /// In en, this message translates to:
  /// **'Child Registered\nDue List'**
  String get childRegisteredDueListTitle;

  /// No description provided for @childTrackingDueListTitle.
  ///
  /// In en, this message translates to:
  /// **'Child Tracking\nDue List'**
  String get childTrackingDueListTitle;

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

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

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
  /// **'Delivery Outcome'**
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
  /// **'New house has been added successfully'**
  String get dataSavedSuccessfully;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get closeButton;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

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

  /// No description provided for @familySurvey.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get familySurvey;

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

  /// No description provided for @financialYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Financial Year'**
  String get financialYearLabel;

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
  /// **'Contraceptive method'**
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

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

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

  /// No description provided for @gridAllHousehold.
  ///
  /// In en, this message translates to:
  /// **'All Household'**
  String get gridAllHousehold;

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
  /// **'Advice on administering iron folic acid syrup'**
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
  /// **'Advice on preparing and administering ORS'**
  String get hbycAdvicePreparingAdministeringOrsLabel;

  /// No description provided for @hbycBhramanLabel.
  ///
  /// In en, this message translates to:
  /// **'HBYC Bhraman*'**
  String get hbycBhramanLabel;

  /// No description provided for @hbycBhramanRequired.
  ///
  /// In en, this message translates to:
  /// **'HBYC Bhraman is required'**
  String get hbycBhramanRequired;

  /// No description provided for @hbycBreastfeedingContinuingLabel.
  ///
  /// In en, this message translates to:
  /// **'Is breastfeeding continuing?'**
  String get hbycBreastfeedingContinuingLabel;

  /// No description provided for @hbycCompleteDietProvidedLabel.
  ///
  /// In en, this message translates to:
  /// **'Was a complete diet provided?'**
  String get hbycCompleteDietProvidedLabel;

  /// No description provided for @hbycCompletionDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion date of activities'**
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
  /// **'Is iron folic acid syrup available at home?'**
  String get hbycIronFolicSyrupAvailableLabel;

  /// No description provided for @hbycIsChildSickLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the child sick?'**
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
  /// **'Measles vaccine given (MCP card)?'**
  String get hbycMeaslesVaccineGivenLabel;

  /// No description provided for @hbycOrsPacketAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Is ORS packet available at home?'**
  String get hbycOrsPacketAvailableLabel;

  /// No description provided for @hbycTitleDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hbycTitleDetails;

  /// No description provided for @hbycVitaminADosageGivenLabel.
  ///
  /// In en, this message translates to:
  /// **'Vitamin A dosage given (MCP card)?'**
  String get hbycVitaminADosageGivenLabel;

  /// No description provided for @hbycWeighedByAwwLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the child been weighed by the Anganwadi worker based on age?'**
  String get hbycWeighedByAwwLabel;

  /// No description provided for @hbycWeightLessThan3sdLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight < 3 SD referred as per MCP card?'**
  String get hbycWeightLessThan3sdLabel;

  /// No description provided for @healthWorkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Health Worker'**
  String get healthWorkerLabel;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

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
  /// **'Thatch house'**
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

  /// No description provided for @hscNameHint.
  ///
  /// In en, this message translates to:
  /// **'HSC Name'**
  String get hscNameHint;

  /// No description provided for @hscNameLabel.
  ///
  /// In en, this message translates to:
  /// **'HSC Name'**
  String get hscNameLabel;

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
  /// **'Husband\'s Name'**
  String get husbandNameLabel;

  /// No description provided for @hwcNameHint.
  ///
  /// In en, this message translates to:
  /// **'HWC Name'**
  String get hwcNameHint;

  /// No description provided for @hwcNameLabel.
  ///
  /// In en, this message translates to:
  /// **'HWC Name'**
  String get hwcNameLabel;

  /// No description provided for @idTypeAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar'**
  String get idTypeAadhaar;

  /// No description provided for @idTypeRationCard.
  ///
  /// In en, this message translates to:
  /// **'Ration Card'**
  String get idTypeRationCard;

  /// No description provided for @idTypeStateInsurance.
  ///
  /// In en, this message translates to:
  /// **'Affiliated to State Health Insurance Scheme'**
  String get idTypeStateInsurance;

  /// No description provided for @idTypeVoterId.
  ///
  /// In en, this message translates to:
  /// **'Voter ID'**
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
  /// **'Submit the payment file for each month\'s claim amount between the 28th and 30th of the next month.'**
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
  /// **'Total amount (Daily + Monthly): ₹{amount}'**
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

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login Failed'**
  String get loginFailed;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccess;

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
  /// **'Mobile No.'**
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

  /// No description provided for @nameOfMemberHint.
  ///
  /// In en, this message translates to:
  /// **'Name of member'**
  String get nameOfMemberHint;

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

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get nextButton;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

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

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

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

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

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
  /// **'Powered By Medixcel Lite © 2025'**
  String get poweredBy;

  /// No description provided for @preExistingDiseaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pre - Existing disease'**
  String get preExistingDiseaseLabel;

  /// No description provided for @pregnantWomen.
  ///
  /// In en, this message translates to:
  /// **'Pregnant women'**
  String get pregnantWomen;

  /// No description provided for @previousButton.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS'**
  String get previousButton;

  /// No description provided for @previousVisits.
  ///
  /// In en, this message translates to:
  /// **'Previous Visits'**
  String get previousVisits;

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

  /// No description provided for @religionLabel.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get religionLabel;

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
  /// **'Saved successfully'**
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
  /// **'Search by ID/Name/Contact'**
  String get searchHint;

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

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

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

  /// No description provided for @spouseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Spouse Name'**
  String get spouseNameHint;

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
  /// **'Eligible Couple Tracking'**
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
  /// **'List of eligible couples'**
  String get updatedEligibleCoupleListSubtitle;

  /// No description provided for @updatedEligibleCoupleListTitle.
  ///
  /// In en, this message translates to:
  /// **'Updated Eligible Couple List'**
  String get updatedEligibleCoupleListTitle;

  /// No description provided for @updatedEligibleCoupleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Updated Eligible Couple'**
  String get updatedEligibleCoupleSearchHint;

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

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Username'**
  String get usernameHint;

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
  /// **'Visit Date: {date}'**
  String visitDate(Object date);

  /// No description provided for @visitDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit Date'**
  String get visitDateLabel;

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

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

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

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @youngestChildAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age of youngest child'**
  String get youngestChildAgeLabel;

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
  /// **'mobile number *'**
  String get mobileNumberLabel;

  /// No description provided for @mothersRchIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s RCH ID number'**
  String get mothersRchIdLabel;

  /// No description provided for @birthCertificateIssuedLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the birth certificate been issued?'**
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
  /// **'alive'**
  String get alive;

  /// No description provided for @dead.
  ///
  /// In en, this message translates to:
  /// **'dead'**
  String get dead;

  /// No description provided for @babyConditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s condition*'**
  String get babyConditionLabel;

  /// No description provided for @babyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s name*'**
  String get babyNameLabel;

  /// No description provided for @babyGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s gender*'**
  String get babyGenderLabel;

  /// No description provided for @newbornWeightGramLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s weight (g) *'**
  String get newbornWeightGramLabel;

  /// No description provided for @newbornTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'temperature *'**
  String get newbornTemperatureLabel;

  /// No description provided for @infantTemperatureUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Infant\'s temperature (measure and record in the axilla) *'**
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

  /// No description provided for @weightColorMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'What color does the weight match?'**
  String get weightColorMatchLabel;

  /// No description provided for @weighingScaleColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Weighing Scale Color *'**
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
  /// **'The mother reports that the child feels hot or cold to the touch, or that the child\'s temperature is 37.5°C or higher or less than 35.5°C, and that the chest draws inward when breathing.*'**
  String get motherReportsTempOrChestIndrawingLabel;

  /// No description provided for @bleedingUmbilicalCordLabel.
  ///
  /// In en, this message translates to:
  /// **'Is there bleeding from the umbilical cord?*'**
  String get bleedingUmbilicalCordLabel;

  /// No description provided for @pusInNavelLabel.
  ///
  /// In en, this message translates to:
  /// **'Is there pus in the navel?*'**
  String get pusInNavelLabel;

  /// No description provided for @routineCareDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Were routine newborn care tasks performed?*'**
  String get routineCareDoneLabel;

  /// No description provided for @breathingRapidLabel.
  ///
  /// In en, this message translates to:
  /// **'Is your baby breathing rapidly (60 or more per minute)?*'**
  String get breathingRapidLabel;

  /// No description provided for @lethargicLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby lethargic?'**
  String get lethargicLabel;

  /// No description provided for @congenitalAbnormalitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Does the baby have any congenital physical abnormalities?*'**
  String get congenitalAbnormalitiesLabel;

  /// No description provided for @eyesNormalLabel.
  ///
  /// In en, this message translates to:
  /// **'Eyes: Normal*'**
  String get eyesNormalLabel;

  /// No description provided for @eyesSwollenOrPusLabel.
  ///
  /// In en, this message translates to:
  /// **'Are the eyes swollen? Is there pus coming from the eyes?*'**
  String get eyesSwollenOrPusLabel;

  /// No description provided for @skinFoldRednessLabel.
  ///
  /// In en, this message translates to:
  /// **'Is there any cracking/redness in the skin fold? (thigh/armpit/hip) *'**
  String get skinFoldRednessLabel;

  /// No description provided for @newbornJaundiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Yellowing of the skin/palms/soles/eyes: Jaundice*'**
  String get newbornJaundiceLabel;

  /// No description provided for @pusBumpsOrBoilLabel.
  ///
  /// In en, this message translates to:
  /// **'More than 10 pus-filled bumps on the skin or one large boil?*'**
  String get pusBumpsOrBoilLabel;

  /// No description provided for @newbornSeizuresLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the child having seizures?*'**
  String get newbornSeizuresLabel;

  /// No description provided for @cryingConstantlyOrLessUrineLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby crying constantly or urinating less than 6 times a day?*'**
  String get cryingConstantlyOrLessUrineLabel;

  /// No description provided for @cryingSoftlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby crying softly?*'**
  String get cryingSoftlyLabel;

  /// No description provided for @stoppedCryingLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the baby stopped crying?*'**
  String get stoppedCryingLabel;

  /// No description provided for @newbornReferredByAshaLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the child been referred by ASHA for the above symptoms?*'**
  String get newbornReferredByAshaLabel;

  /// No description provided for @birthRegisteredLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the birth been registered?*'**
  String get birthRegisteredLabel;

  /// No description provided for @mcpCardAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Is \'Matra Child Protection (MCP)\' card available?*'**
  String get mcpCardAvailableLabel;

  /// No description provided for @birthDoseVaccinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Has the baby received the birth dose vaccination?*'**
  String get birthDoseVaccinationLabel;

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
  /// **'Date of home visit*'**
  String get dateOfHomeVisitLabel;

  /// No description provided for @motherStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s status*'**
  String get motherStatusLabel;

  /// No description provided for @mcpCardAvailableLabelMother.
  ///
  /// In en, this message translates to:
  /// **'Is \'Matra Shishu Prakshyan (MCP)\' card available? *'**
  String get mcpCardAvailableLabelMother;

  /// No description provided for @postDeliveryProblemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Does the mother have any problems after delivery?*'**
  String get postDeliveryProblemsLabel;

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

  /// No description provided for @breastfeedingProblemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the mother having problems breastfeeding?*'**
  String get breastfeedingProblemsLabel;

  /// No description provided for @mealsPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'How many times does a mother take a full meal in 24 hours?'**
  String get mealsPerDayLabel;

  /// No description provided for @padsPerDayLabel.
  ///
  /// In en, this message translates to:
  /// **'How many pads are changed in a day for bleeding?*'**
  String get padsPerDayLabel;

  /// No description provided for @mothersTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Mother\'s temperature*'**
  String get mothersTemperatureLabel;

  /// No description provided for @foulDischargeHighFeverLabel.
  ///
  /// In en, this message translates to:
  /// **'Foul-smelling discharge and fever 102°F (38.9°C)*'**
  String get foulDischargeHighFeverLabel;

  /// No description provided for @abnormalSpeechOrSeizureLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the mother speaking abnormally or having seizures?*'**
  String get abnormalSpeechOrSeizureLabel;

  /// No description provided for @counselingAdviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Counseling / Advice*'**
  String get counselingAdviceLabel;

  /// No description provided for @milkNotProducingOrLessLabel.
  ///
  /// In en, this message translates to:
  /// **'After delivery, is the mother not producing milk or does she feel milk is less?*'**
  String get milkNotProducingOrLessLabel;

  /// No description provided for @nippleCracksPainOrEngorgedLabel.
  ///
  /// In en, this message translates to:
  /// **'Does the mother have nipple cracks/pain and/or engorged breasts?*'**
  String get nippleCracksPainOrEngorgedLabel;

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

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @subCenter.
  ///
  /// In en, this message translates to:
  /// **'Sub-Center'**
  String get subCenter;

  /// No description provided for @phc.
  ///
  /// In en, this message translates to:
  /// **'PHC'**
  String get phc;

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
  /// **'Type of Delivery'**
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
  /// **'Assisted (Vacuum/Forceps)'**
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

  /// No description provided for @exclusiveBreastfeedingStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Has exclusive breastfeeding started?*'**
  String get exclusiveBreastfeedingStartedLabel;

  /// No description provided for @firstBreastfeedTimingLabel.
  ///
  /// In en, this message translates to:
  /// **'When was the first breastfeed given to the baby?*'**
  String get firstBreastfeedTimingLabel;

  /// No description provided for @howWasBreastfedLabel.
  ///
  /// In en, this message translates to:
  /// **'How was the baby breastfed?*'**
  String get howWasBreastfedLabel;

  /// No description provided for @firstFeedGivenAfterBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'What was given to the baby as the first feed after birth?*'**
  String get firstFeedGivenAfterBirthLabel;

  /// No description provided for @adequatelyFedSevenToEightTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby being fed properly (whenever hungry or at least 7–8 times in 24 hours)?*'**
  String get adequatelyFedSevenToEightTimesLabel;

  /// No description provided for @babyDrinkingLessMilkLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby drinking less milk?*'**
  String get babyDrinkingLessMilkLabel;

  /// No description provided for @breastfeedingStoppedLabel.
  ///
  /// In en, this message translates to:
  /// **'Has breastfeeding been stopped for the baby?*'**
  String get breastfeedingStoppedLabel;

  /// No description provided for @bloatedStomachOrFrequentVomitingLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the baby\'s stomach bloated or does the mother report frequent vomiting?*'**
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

  /// No description provided for @tabGeneralDetails.
  ///
  /// In en, this message translates to:
  /// **'General Details'**
  String get tabGeneralDetails;

  /// No description provided for @tabMotherDetails.
  ///
  /// In en, this message translates to:
  /// **'Mother Details'**
  String get tabMotherDetails;

  /// No description provided for @tabNewbornDetails.
  ///
  /// In en, this message translates to:
  /// **'Newborn Details'**
  String get tabNewbornDetails;

  /// No description provided for @confirmAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Attention!'**
  String get confirmAttentionTitle;

  /// No description provided for @confirmBackLoseDetailsMsg.
  ///
  /// In en, this message translates to:
  /// **'If you go back, details will be lost. Do you want to go back?'**
  String get confirmBackLoseDetailsMsg;

  /// No description provided for @confirmYesExit.
  ///
  /// In en, this message translates to:
  /// **'Yes, Exit'**
  String get confirmYesExit;

  /// No description provided for @confirmNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get confirmNo;

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
