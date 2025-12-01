part of 'outcome_form_bloc.dart';

class OutcomeFormState extends Equatable {
  final String? householdId;
  final String? beneficiaryId;
  final DateTime? deliveryDate;
  final String gestationWeeks;
  final String? deliveryTime;
  final String placeOfDelivery;
  final String deliveryType;
  final String complications;
  final String outcomeCount;
  final String familyPlanningCounseling;
  final bool submitting;
  final bool submitted;
  final String? errorMessage;
  final String? fpMethod;
  final DateTime? removalDate;
  final String? removalReason;
  final String? condomQuantity;
  final String? malaQuantity;
  final String? chhayaQuantity;
  final String? ecpQuantity;
  final String? institutionalPlaceType; // 'Public' or 'Private'
  final String? institutionalPlaceOfDelivery; // e.g. Sub-Center, PHC, Nursing Home
  final String? conductedBy; // 'ANM', 'LHV', 'Doctor', 'Staff Nurse', 'Relative TBA'
  final String? typeOfDelivery; // 'Cesarean', 'Assisted/Forceps', 'Normal'
  final String? hadComplications; // 'Yes' or 'No'
  final String? nonInstitutionalPlaceType; // 'Home', 'In Transit', 'Other'
  final String? transitPlace; // 'Ambulance', 'Other'
  final String? otherNonInstitutionalPlaceName; // free text when Other
  final String? otherPlaceOfDeliveryName;
  final String? otherTransitPlaceName;
  final String? complicationType;
  final String? otherComplicationName;

  const OutcomeFormState({
    this.householdId,
    this.beneficiaryId,
    this.fpMethod,
    this.removalDate,
    this.removalReason,
    this.condomQuantity,
    this.malaQuantity,
    this.chhayaQuantity,
    this.ecpQuantity,
    required this.deliveryDate,
    required this.gestationWeeks,
    required this.deliveryTime,
    required this.placeOfDelivery,
    required this.deliveryType,
    required this.complications,
    required this.outcomeCount,
    required this.familyPlanningCounseling,
    required this.submitting,
    required this.submitted,
    required this.errorMessage,
    this.institutionalPlaceType,
    this.institutionalPlaceOfDelivery,
    this.conductedBy,
    this.typeOfDelivery,
    this.hadComplications,
    this.nonInstitutionalPlaceType,
    this.transitPlace,
    this.otherNonInstitutionalPlaceName,
    this.otherPlaceOfDeliveryName,
    this.otherTransitPlaceName,
    this.complicationType,
    this.otherComplicationName,
  });

  factory OutcomeFormState.initial() => const OutcomeFormState(
    householdId: null,
    beneficiaryId: null,
    deliveryDate: null,
    gestationWeeks: '',
    deliveryTime: null,
    placeOfDelivery: '',
    deliveryType: '',
    complications: '',
    outcomeCount: '',
    familyPlanningCounseling: 'No',
    submitting: false,
    submitted: false,
    errorMessage: null,
    fpMethod: null,
    removalDate: null,
    removalReason: null,
    condomQuantity: null,
    malaQuantity: null,
    chhayaQuantity: null,
    ecpQuantity: null,
    institutionalPlaceType: null,  // ✅ ADDED
    institutionalPlaceOfDelivery: null,
    conductedBy: null,              // ✅ ADDED
    typeOfDelivery: null,
    hadComplications: null,
    nonInstitutionalPlaceType: null,
    transitPlace: null,
    otherNonInstitutionalPlaceName: null,
    otherPlaceOfDeliveryName: null,
    otherTransitPlaceName: null,
    complicationType: null,
    otherComplicationName: null,
  );

  OutcomeFormState copyWith({
    String? householdId,
    String? beneficiaryId,
    DateTime? deliveryDate,
    String? gestationWeeks,
    String? deliveryTime,
    String? placeOfDelivery,
    String? deliveryType,
    String? complications,
    String? outcomeCount,
    String? familyPlanningCounseling,
    bool? submitting,
    bool? submitted,
    String? errorMessage,
    String? fpMethod,
    DateTime? removalDate,
    String? removalReason,
    String? condomQuantity,
    String? malaQuantity,
    String? chhayaQuantity,
    String? ecpQuantity,
    String? institutionalPlaceType,
    String? institutionalPlaceOfDelivery,
    String? conductedBy,
    String? typeOfDelivery,
    String? hadComplications,
    String? nonInstitutionalPlaceType,
    String? transitPlace,
    String? otherNonInstitutionalPlaceName,
    String? otherPlaceOfDeliveryName,
    String? otherTransitPlaceName,
    String? complicationType,
    String? otherComplicationName,
  }) {
    return OutcomeFormState(
      householdId: householdId ?? this.householdId,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      gestationWeeks: gestationWeeks ?? this.gestationWeeks,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      placeOfDelivery: placeOfDelivery ?? this.placeOfDelivery,
      deliveryType: deliveryType ?? this.deliveryType,
      complications: complications ?? this.complications,
      outcomeCount: outcomeCount ?? this.outcomeCount,
      familyPlanningCounseling:
      familyPlanningCounseling ?? this.familyPlanningCounseling,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      errorMessage: errorMessage ?? this.errorMessage,
      fpMethod: fpMethod ?? this.fpMethod,
      removalDate: removalDate ?? this.removalDate,
      removalReason: removalReason ?? this.removalReason,
      condomQuantity: condomQuantity ?? this.condomQuantity,
      malaQuantity: malaQuantity ?? this.malaQuantity,
      chhayaQuantity: chhayaQuantity ?? this.chhayaQuantity,
      ecpQuantity: ecpQuantity ?? this.ecpQuantity,
      institutionalPlaceType: institutionalPlaceType ?? this.institutionalPlaceType,
      institutionalPlaceOfDelivery: institutionalPlaceOfDelivery ?? this.institutionalPlaceOfDelivery,
      conductedBy: conductedBy ?? this.conductedBy,
      typeOfDelivery: typeOfDelivery ?? this.typeOfDelivery,
      hadComplications: hadComplications ?? this.hadComplications,
      nonInstitutionalPlaceType: nonInstitutionalPlaceType ?? this.nonInstitutionalPlaceType,
      transitPlace: transitPlace ?? this.transitPlace,
      otherNonInstitutionalPlaceName: otherNonInstitutionalPlaceName ?? this.otherNonInstitutionalPlaceName,
      otherPlaceOfDeliveryName: otherPlaceOfDeliveryName ?? this.otherPlaceOfDeliveryName,
      otherTransitPlaceName: otherTransitPlaceName ?? this.otherTransitPlaceName,
      complicationType: complicationType ?? this.complicationType,
      otherComplicationName: otherComplicationName ?? this.otherComplicationName,
    );
  }

  @override
  List<Object?> get props => [
    householdId,
    beneficiaryId,
    deliveryDate,
    gestationWeeks,
    deliveryTime,
    placeOfDelivery,
    deliveryType,
    complications,
    outcomeCount,
    familyPlanningCounseling,
    submitting,
    submitted,
    errorMessage,
    fpMethod,
    removalDate,
    removalReason,
    condomQuantity,
    malaQuantity,
    chhayaQuantity,
    ecpQuantity,
    institutionalPlaceType,
    institutionalPlaceOfDelivery,
    conductedBy,
    typeOfDelivery,
    hadComplications,
    nonInstitutionalPlaceType,
    transitPlace,
    otherNonInstitutionalPlaceName,
    otherPlaceOfDeliveryName,
    otherTransitPlaceName,
    complicationType,
    otherComplicationName,
  ];
}
