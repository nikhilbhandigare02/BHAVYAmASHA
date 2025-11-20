part of 'anvvisitform_bloc.dart';

class AnvvisitformState extends Equatable {
  final int ancVisitNo;
  final String visitType;
  final String placeOfAnc;
  final DateTime? dateOfInspection;
  final String houseNumber;
  final String womanName;
  final String husbandName;
  final String rchNumber;
  final String givesBirthToBaby;
  final DateTime? lmpDate;
  final DateTime? eddDate;
  final String weeksOfPregnancy;
  final int gravida;
  final String isBreastFeeding;
  final DateTime? td1Date;
  final DateTime? td2Date;
  final DateTime? tdBoosterDate;
  final String folicAcidTablets;
  final String preExistingDisease;
  final String weight;
  final String systolic;
  final String diastolic;
  final String hemoglobin;
  final String highRisk;
  final List<String> selectedRisks;
  final String hasAbortionComplication;
  final DateTime? abortionDate;
  final String beneficiaryAbsent;
  final String beneficiaryId;
  final String? householdRefKey;
  final String deliveryOutcome;
  final String numberOfChildren;
  final String baby1Name;
  final String baby1Gender;
  final String baby1Weight;

  final String baby2Name;
  final String baby2Gender;
  final String baby2Weight;

  final String baby3Name;
  final String baby3Gender;
  final String baby3Weight;

  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  const AnvvisitformState({
    this.ancVisitNo = 1,
    this.visitType = '',
    this.placeOfAnc = '',
    this.dateOfInspection,
    this.houseNumber = '',
    this.womanName = '',
    this.husbandName = '',
    this.rchNumber = '',
    this.lmpDate,
    this.givesBirthToBaby = '',
    this.eddDate,
    this.weeksOfPregnancy = '',
    this.gravida = 1,
    this.isBreastFeeding = '',
    this.td1Date,
    this.td2Date,
    this.tdBoosterDate,
    this.folicAcidTablets = '',
    this.preExistingDisease = '',
    this.weight = '',
    this.systolic = '',
    this.diastolic = '',
    this.hemoglobin = '',
    this.highRisk = '',
    this.selectedRisks = const [],
    this.hasAbortionComplication = '',
    this.abortionDate,
    this.beneficiaryAbsent = '',
    this.beneficiaryId = '',
    this.householdRefKey,
    this.deliveryOutcome = '',
    this.numberOfChildren = '',
    this.baby1Name = "",
    this.baby1Gender = "",
    this.baby1Weight = "",

    this.baby2Name = "",
    this.baby2Gender = "",
    this.baby2Weight = "",

    this.baby3Name = "",
    this.baby3Gender = "",
    this.baby3Weight = "",
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  AnvvisitformState copyWith({
    int? ancVisitNo,
    String? visitType,
    String? placeOfAnc,
    DateTime? dateOfInspection,
    String? houseNumber,
    String? womanName,
    String? husbandName,
    String? rchNumber,
    String? givesBirthToBaby,
    DateTime? lmpDate,
    DateTime? eddDate,
    String? weeksOfPregnancy,
    int? gravida,
    String? isBreastFeeding,
    DateTime? td1Date,
    DateTime? td2Date,
    DateTime? tdBoosterDate,
    String? folicAcidTablets,
    String? preExistingDisease,
    String? weight,
    String? systolic,
    String? diastolic,
    String? hemoglobin,
    String? highRisk,
    List<String>? selectedRisks,
    String? hasAbortionComplication,
    DateTime? abortionDate,
    String? beneficiaryAbsent,
    String? beneficiaryId,
    String? householdRefKey,
    bool? isSubmitting,
    String? deliveryOutcome,
    String? numberOfChildren,
    String? baby1Name,
    String? baby1Gender,
    String? baby1Weight,

    String? baby2Name,
    String? baby2Gender,
    String? baby2Weight,

    String? baby3Name,
    String? baby3Gender,
    String? baby3Weight,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return AnvvisitformState(
      ancVisitNo: ancVisitNo ?? this.ancVisitNo,
      visitType: visitType ?? this.visitType,
      placeOfAnc: placeOfAnc ?? this.placeOfAnc,
      dateOfInspection: dateOfInspection ?? this.dateOfInspection,
      houseNumber: houseNumber ?? this.houseNumber,
      womanName: womanName ?? this.womanName,
      husbandName: husbandName ?? this.husbandName,
      rchNumber: rchNumber ?? this.rchNumber,
      lmpDate: lmpDate ?? this.lmpDate,
      givesBirthToBaby: givesBirthToBaby ?? this.givesBirthToBaby,
      eddDate: eddDate ?? this.eddDate,
      weeksOfPregnancy: weeksOfPregnancy ?? this.weeksOfPregnancy,
      gravida: gravida ?? this.gravida,
      isBreastFeeding: isBreastFeeding ?? this.isBreastFeeding,
      td1Date: td1Date ?? this.td1Date,
      td2Date: td2Date ?? this.td2Date,
      tdBoosterDate: tdBoosterDate ?? this.tdBoosterDate,
      folicAcidTablets: folicAcidTablets ?? this.folicAcidTablets,
      preExistingDisease: preExistingDisease ?? this.preExistingDisease,
      weight: weight ?? this.weight,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      hemoglobin: hemoglobin ?? this.hemoglobin,
      highRisk: highRisk ?? this.highRisk,
      selectedRisks: selectedRisks ?? this.selectedRisks,
      hasAbortionComplication: hasAbortionComplication ?? this.hasAbortionComplication,
      abortionDate: abortionDate ?? this.abortionDate,
      beneficiaryAbsent: beneficiaryAbsent ?? this.beneficiaryAbsent,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      householdRefKey: householdRefKey ?? this.householdRefKey,
      deliveryOutcome: deliveryOutcome ?? this.deliveryOutcome,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      baby1Name: baby1Name ?? this.baby1Name,
      baby1Gender: baby1Gender ?? this.baby1Gender,
      baby1Weight: baby1Weight ?? this.baby1Weight,

      baby2Name: baby2Name ?? this.baby2Name,
      baby2Gender: baby2Gender ?? this.baby2Gender,
      baby2Weight: baby2Weight ?? this.baby2Weight,

      baby3Name: baby3Name ?? this.baby3Name,
      baby3Gender: baby3Gender ?? this.baby3Gender,
      baby3Weight: baby3Weight ?? this.baby3Weight,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        ancVisitNo,
        visitType,
        placeOfAnc,
        dateOfInspection,
        houseNumber,
        womanName,
        husbandName,
        rchNumber,
        lmpDate,
        eddDate,
        weeksOfPregnancy,
        gravida,
        isBreastFeeding,
        td1Date,
        td2Date,
        tdBoosterDate,
        folicAcidTablets,
        preExistingDisease,
        weight,
        systolic,
        diastolic,
        hemoglobin,
        highRisk,
        selectedRisks,
        hasAbortionComplication,
        abortionDate,
        beneficiaryAbsent,
        beneficiaryId,
        householdRefKey,
        isSubmitting,
    deliveryOutcome,
    numberOfChildren,

    baby1Name,
    baby1Gender,
    baby1Weight,

    baby2Name,
    baby2Gender,
    baby2Weight,

    baby3Name,
    baby3Gender,
    baby3Weight,
        isSuccess,
        givesBirthToBaby,
        error,
      ];
}

class AnvvisitformInitial extends AnvvisitformState {
  const AnvvisitformInitial();
}
