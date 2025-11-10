import 'package:equatable/equatable.dart';

class HbncVisitState extends Equatable {
  final int currentTabIndex;
  final Map<String, dynamic> motherDetails;
  final Map<String, dynamic> newbornDetails;
  final Map<String, dynamic> visitDetails;
  final bool isSubmitting;
  final bool isSaving;
  final bool saveSuccess;
  final String? errorMessage;
  final List<String> validationErrors;
  final int? lastValidatedIndex;
  final bool lastValidationWasSave;
  final int validationTick;

  const HbncVisitState({
    this.currentTabIndex = 0,
    Map<String, dynamic>? motherDetails,
    Map<String, dynamic>? newbornDetails,
    Map<String, dynamic>? visitDetails,
    this.isSubmitting = false,
    this.isSaving = false,
    this.saveSuccess = false,
    this.errorMessage,
    List<String>? validationErrors,
    this.lastValidatedIndex,
    this.lastValidationWasSave = false,
    this.validationTick = 0,
  })  : motherDetails = motherDetails ?? const {
          'motherStatus': null,
          'mcpCardAvailable': null,
          'postDeliveryProblems': null,
          'breastfeedingProblems': null,
          'mealsPerDay': null,
          'padsPerDay': null,
          'temperature': '',
          'foulDischargeHighFever': null,
          'abnormalSpeechOrSeizure': null,
          'counselingAdvice': null,
          'milkNotProducingOrLess': null,
          'nippleCracksPainOrEngorged': null,
        },
        newbornDetails = newbornDetails ?? const {
          'babyCondition': null,
          'babyName': '',
          'gender': null,
          'weightAtBirth': '',
          'temperature': '',
          'tempUnit': null,
          'weightColorMatch': null,
          'weighingScaleColor': null,
          'motherReportsTempOrChestIndrawing': null,
          'bleedingUmbilicalCord': null,
          'pusInNavel': null,
          'routineCareDone': null,
          'breathingRapid': null,
          'congenitalAbnormalities': null,
          'eyesNormal': null,
          'eyesSwollenOrPus': null,
          'skinFoldRedness': null,
          'jaundice': null,
          'pusBumpsOrBoil': null,
          'seizures': null,
          'cryingConstantlyOrLessUrine': null,
          'cryingSoftly': null,
          'stoppedCrying': null,
          'referredByASHA': null,
          'birthRegistered': null,
          'birthCertificateIssued': null,
          'birthDoseVaccination': null,
          'mcpCardAvailable': null,
          'exclusiveBreastfeedingStarted': null,
          'firstBreastfeedTiming': null,
          'howWasBreastfed': null,
          'firstFeedGivenAfterBirth': null,
          'adequatelyFedSevenToEightTimes': null,
          'babyDrinkingLessMilk': null,
          'breastfeedingStopped': null,
          'bloatedStomachOrFrequentVomiting': null,
        },
        visitDetails = visitDetails ?? const {
          'visitDate': null,
          'nextVisitDate': null,
          'visitNumber': null,
        },
        validationErrors = validationErrors ?? const [];

  HbncVisitState copyWith({
    int? currentTabIndex,
    Map<String, dynamic>? motherDetails,
    Map<String, dynamic>? newbornDetails,
    Map<String, dynamic>? visitDetails,
    bool? isSubmitting,
    bool? isSaving,
    bool? saveSuccess,
    String? errorMessage,
    List<String>? validationErrors,
    int? lastValidatedIndex,
    bool? lastValidationWasSave,
    int? validationTick,
  }) {
    return HbncVisitState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      motherDetails: motherDetails ?? this.motherDetails,
      newbornDetails: newbornDetails ?? this.newbornDetails,
      visitDetails: visitDetails ?? this.visitDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      errorMessage: errorMessage,
      validationErrors: validationErrors ?? this.validationErrors,
      lastValidatedIndex: lastValidatedIndex ?? this.lastValidatedIndex,
      lastValidationWasSave: lastValidationWasSave ?? this.lastValidationWasSave,
      validationTick: validationTick ?? this.validationTick,
    );
  }

  // Static method to create an initial state
  static HbncVisitState initial() => const HbncVisitState();

  @override
  List<Object?> get props => [
        currentTabIndex,
        motherDetails,
        newbornDetails,
        visitDetails,
        isSubmitting,
        isSaving,
        saveSuccess,
        errorMessage,
        validationErrors,
        lastValidatedIndex,
        lastValidationWasSave,
        validationTick,
      ];
}
