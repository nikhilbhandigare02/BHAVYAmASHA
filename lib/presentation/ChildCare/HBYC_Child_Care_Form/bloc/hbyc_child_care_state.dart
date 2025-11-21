part of 'hbyc_child_care_bloc.dart';

enum HbycFormStatus { initial, submitting, success, failure }

class HbycChildCareState extends Equatable {
  final String beneficiaryAbsent;
  final String beneficiaryAbsentReason;
  final String hbycBhraman; // required
  final String isChildSick;
  final String breastfeedingContinuing;
  final String completeDietProvided;
  final String weighedByAww;
  final String lengthHeightRecorded;
  final String weightLessThan3sdReferred;
  final String developmentDelaysObserved;
  final String fullyVaccinatedAsPerMcp;
  final String measlesVaccineGiven;
  final String vitaminADosageGiven;
  final String orsPacketAvailable;
  final String ironFolicSyrupAvailable;
  final String counselingExclusiveBf6m;
  final String adviceComplementaryFoods;
  final String adviceHandWashingHygiene;
  final String adviceParentingSupport;
  final String counselingFamilyPlanning;
  final String advicePreparingAdministeringOrs;
  final String adviceAdministeringIfaSyrup;
  final String completionDate; // dd-MM-yyyy
  final HbycFormStatus status;
  final String? error;
  final String foodFrequency1; // 2-3 tablespoons, 2-3 times daily
  final String foodFrequency2; // 1/2 cup, 2-3 times daily + 1-2 snacks
  final String foodFrequency3; // 1/2 cup, 3-4 times daily + 1-2 snacks
  final String foodFrequency4;
  final String weightForAge;  // For "Mention the recorded weight-for-age"
  final String weightForLength;  // For "Mention the recorded weight-for-length/height"
  final String orsGiven;  // For "ORS given?"
  final String orsCount;  // For "Number of ORS given"
  final String ifaSyrupGiven;  // For "Iron Folic Acid syrup Given?"
  final String ifaSyrupCount;// 3/4-1 cup, 3-4 times daily + 1-2 snacks


  const HbycChildCareState({
    this.beneficiaryAbsent = '',
    this.beneficiaryAbsentReason = '',
    this.hbycBhraman = '',
    this.isChildSick = '',
    this.breastfeedingContinuing = '',
    this.completeDietProvided = '',
    this.weighedByAww = '',
    this.lengthHeightRecorded = '',
    this.weightLessThan3sdReferred = '',
    this.developmentDelaysObserved = '',
    this.fullyVaccinatedAsPerMcp = '',
    this.measlesVaccineGiven = '',
    this.vitaminADosageGiven = '',
    this.orsPacketAvailable = '',
    this.ironFolicSyrupAvailable = '',
    this.counselingExclusiveBf6m = '',
    this.adviceComplementaryFoods = '',
    this.adviceHandWashingHygiene = '',
    this.adviceParentingSupport = '',
    this.counselingFamilyPlanning = '',
    this.advicePreparingAdministeringOrs = '',
    this.adviceAdministeringIfaSyrup = '',
    this.completionDate = '',
    this.status = HbycFormStatus.initial,
    this.error,
    this.foodFrequency1 = '',
    this.foodFrequency2 = '',
    this.foodFrequency3 = '',
    this.foodFrequency4 = '',
    this.weightForAge = '',
    this.weightForLength = '',
    this.orsGiven = '',
    this.orsCount = '',
    this.ifaSyrupGiven = '',
    this.ifaSyrupCount = '',
  });

  HbycChildCareState copyWith({
    String? beneficiaryAbsent,
    String? beneficiaryAbsentReason,
    String? hbycBhraman,
    String? isChildSick,
    String? breastfeedingContinuing,
    String? completeDietProvided,
    String? weighedByAww,
    String? lengthHeightRecorded,
    String? weightLessThan3sdReferred,
    String? developmentDelaysObserved,
    String? fullyVaccinatedAsPerMcp,
    String? measlesVaccineGiven,
    String? vitaminADosageGiven,
    String? orsPacketAvailable,
    String? ironFolicSyrupAvailable,
    String? counselingExclusiveBf6m,
    String? adviceComplementaryFoods,
    String? adviceHandWashingHygiene,
    String? adviceParentingSupport,
    String? counselingFamilyPlanning,
    String? advicePreparingAdministeringOrs,
    String? adviceAdministeringIfaSyrup,
    String? completionDate,
    HbycFormStatus? status,
    String? error,
    String? foodFrequency1,
    String? foodFrequency2,
    String? foodFrequency3,
    String? foodFrequency4,
    String? weightForAge,
    String? weightForLength,
    String? orsGiven,
    String? orsCount,
    String? ifaSyrupGiven,
    String? ifaSyrupCount,
  }) {
    return HbycChildCareState(
      beneficiaryAbsent: beneficiaryAbsent ?? this.beneficiaryAbsent,
      beneficiaryAbsentReason: beneficiaryAbsentReason ?? this.beneficiaryAbsentReason,
      hbycBhraman: hbycBhraman ?? this.hbycBhraman,
      isChildSick: isChildSick ?? this.isChildSick,
      breastfeedingContinuing: breastfeedingContinuing ?? this.breastfeedingContinuing,
      completeDietProvided: completeDietProvided ?? this.completeDietProvided,
      weighedByAww: weighedByAww ?? this.weighedByAww,
      lengthHeightRecorded: lengthHeightRecorded ?? this.lengthHeightRecorded,
      weightLessThan3sdReferred: weightLessThan3sdReferred ?? this.weightLessThan3sdReferred,
      developmentDelaysObserved: developmentDelaysObserved ?? this.developmentDelaysObserved,
      fullyVaccinatedAsPerMcp: fullyVaccinatedAsPerMcp ?? this.fullyVaccinatedAsPerMcp,
      measlesVaccineGiven: measlesVaccineGiven ?? this.measlesVaccineGiven,
      vitaminADosageGiven: vitaminADosageGiven ?? this.vitaminADosageGiven,
      orsPacketAvailable: orsPacketAvailable ?? this.orsPacketAvailable,
      ironFolicSyrupAvailable: ironFolicSyrupAvailable ?? this.ironFolicSyrupAvailable,
      counselingExclusiveBf6m: counselingExclusiveBf6m ?? this.counselingExclusiveBf6m,
      adviceComplementaryFoods: adviceComplementaryFoods ?? this.adviceComplementaryFoods,
      adviceHandWashingHygiene: adviceHandWashingHygiene ?? this.adviceHandWashingHygiene,
      adviceParentingSupport: adviceParentingSupport ?? this.adviceParentingSupport,
      counselingFamilyPlanning: counselingFamilyPlanning ?? this.counselingFamilyPlanning,
      advicePreparingAdministeringOrs: advicePreparingAdministeringOrs ?? this.advicePreparingAdministeringOrs,
      adviceAdministeringIfaSyrup: adviceAdministeringIfaSyrup ?? this.adviceAdministeringIfaSyrup,
      completionDate: completionDate ?? this.completionDate,
      status: status ?? this.status,
      error: error,
      foodFrequency1: foodFrequency1 ?? this.foodFrequency1,
      foodFrequency2: foodFrequency2 ?? this.foodFrequency2,
      foodFrequency3: foodFrequency3 ?? this.foodFrequency3,
      foodFrequency4: foodFrequency4 ?? this.foodFrequency4,
      weightForLength: weightForLength ?? this.weightForLength,
      orsGiven: orsGiven ?? this.orsGiven,
      orsCount: orsCount ?? this.orsCount,
      ifaSyrupGiven: ifaSyrupGiven ?? this.ifaSyrupGiven,
      ifaSyrupCount: ifaSyrupCount ?? this.ifaSyrupCount,

    );
  }

  @override
  List<Object?> get props => [
        beneficiaryAbsent,
        beneficiaryAbsentReason,
        hbycBhraman,
        isChildSick,
        breastfeedingContinuing,
        completeDietProvided,
        weighedByAww,
        lengthHeightRecorded,
        weightLessThan3sdReferred,
        developmentDelaysObserved,
        fullyVaccinatedAsPerMcp,
        measlesVaccineGiven,
        vitaminADosageGiven,
        orsPacketAvailable,
        ironFolicSyrupAvailable,
        counselingExclusiveBf6m,
        adviceComplementaryFoods,
        adviceHandWashingHygiene,
        adviceParentingSupport,
        counselingFamilyPlanning,
        advicePreparingAdministeringOrs,
        adviceAdministeringIfaSyrup,
        completionDate,
        status,
        error,
    foodFrequency1,
    foodFrequency2,
    foodFrequency3,
    foodFrequency4,
    weightForAge,
    weightForLength,
    orsGiven,
    orsCount,
    ifaSyrupGiven,
    ifaSyrupCount,
      ];
}

class HbycChildCareInitial extends HbycChildCareState {
  const HbycChildCareInitial() : super();
}
