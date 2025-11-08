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
  final String beneficiaryAbsent;
  final String beneficiaryId;

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
    this.beneficiaryAbsent = '',
    this.beneficiaryId = '',
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
    String? beneficiaryAbsent,
    String? beneficiaryId,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return AnvvisitformState(
      ancVisitNo: ancVisitNo ?? this.ancVisitNo,
      visitType: visitType ?? this.visitType,
      placeOfAnc: placeOfAnc ?? this.placeOfAnc,
      givesBirthToBaby: givesBirthToBaby ?? this.givesBirthToBaby,
      dateOfInspection: dateOfInspection ?? this.dateOfInspection,
      houseNumber: houseNumber ?? this.houseNumber,
      womanName: womanName ?? this.womanName,
      husbandName: husbandName ?? this.husbandName,
      rchNumber: rchNumber ?? this.rchNumber,
      lmpDate: lmpDate ?? this.lmpDate,
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
      beneficiaryAbsent: beneficiaryAbsent ?? this.beneficiaryAbsent,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
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
        beneficiaryAbsent,
        beneficiaryId,
        isSubmitting,
        isSuccess,
    givesBirthToBaby,
        error,
      ];
}

class AnvvisitformInitial extends AnvvisitformState {
  const AnvvisitformInitial();
}
