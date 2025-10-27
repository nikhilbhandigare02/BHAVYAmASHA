part of 'hbyc_child_care_bloc.dart';

enum HbycFormStatus { initial, submitting, success, failure }

class HbycChildCareState extends Equatable {
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

  const HbycChildCareState({
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
  });

  HbycChildCareState copyWith({
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
  }) {
    return HbycChildCareState(
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
    );
  }

  @override
  List<Object?> get props => [
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
      ];
}

class HbycChildCareInitial extends HbycChildCareState {
  const HbycChildCareInitial() : super();
}
