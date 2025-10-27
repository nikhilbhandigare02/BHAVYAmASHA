import 'package:equatable/equatable.dart';

class HbncVisitState extends Equatable {
  final int currentTabIndex;
  final Map<String, dynamic> motherDetails;
  final Map<String, dynamic> newbornDetails;
  final Map<String, dynamic> visitDetails;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final bool isSaving;
  final bool saveSuccess;
  final int? lastValidatedIndex;
  final bool lastValidationWasSave;
  final List<String> validationErrors;
  final int validationTick;

  const HbncVisitState({
    this.currentTabIndex = 0,
    this.motherDetails = const {
      'name': '',
      'age': '',
      'registrationNo': '',
      'lmpDate': null,
      'deliveryDate': null,
      'deliveryType': '',
      'complications': '',
      'bloodGroup': '',
      'bloodPressure': '',
      'hbLevel': '',
      'temperature': '',
      'pulse': '',
      'respiration': '',
      'weight': '',
    },
    this.newbornDetails = const {
      'name': '',
      'gender': '',
      'weightAtBirth': '',
      'birthCertificateNo': '',
      'breastfeedingInitiated': false,
      'bcgDone': false,
      'opv0Done': false,
      'hepatitisBDose1Done': false,
      'temperature': '',
      'respiratoryRate': '',
      'heartRate': '',
      'jaundice': false,
      'umbilicalCord': '',
      'feedingStatus': '',
    },
    this.visitDetails = const {
      'visitDate': null,
      'nextVisitDate': null,
      'visitNumber': '',
      'visitType': '',
      'visitPlace': '',
      'visitStatus': 'Pending',
      'remarks': '',
      'referredTo': '',
      'referredDate': null,
      'referredReason': '',
    },
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.isSaving = false,
    this.saveSuccess = false,
    this.lastValidatedIndex,
    this.lastValidationWasSave = false,
    this.validationErrors = const [],
    this.validationTick = 0,
  });

  HbncVisitState copyWith({
    int? currentTabIndex,
    Map<String, dynamic>? motherDetails,
    Map<String, dynamic>? newbornDetails,
    Map<String, dynamic>? visitDetails,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool? isSaving,
    bool? saveSuccess,
    int? lastValidatedIndex,
    bool? lastValidationWasSave,
    List<String>? validationErrors,
    int? validationTick,
  }) {
    return HbncVisitState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      motherDetails: motherDetails ?? this.motherDetails,
      newbornDetails: newbornDetails ?? this.newbornDetails,
      visitDetails: visitDetails ?? this.visitDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      lastValidatedIndex: lastValidatedIndex ?? this.lastValidatedIndex,
      lastValidationWasSave: lastValidationWasSave ?? this.lastValidationWasSave,
      validationErrors: validationErrors ?? this.validationErrors,
      validationTick: validationTick ?? this.validationTick,
    );
  }

  @override
  List<Object?> get props => [
        currentTabIndex,
        motherDetails,
        newbornDetails,
        visitDetails,
        isSubmitting,
        isSuccess,
        errorMessage,
        isSaving,
        saveSuccess,
        lastValidatedIndex,
        lastValidationWasSave,
        validationErrors,
        validationTick,
      ];
}
