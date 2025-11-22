part of 'spous_bloc.dart';

class SpousState extends Equatable {
  const SpousState({
    this.relation,
    this.memberName,
    this.ageAtMarriage,
    this.RichIDChanged,
    this.spouseName,
    this.UpdateYears,
    this.UpdateMonths,
    this.UpdateDays,
    this.fatherName,
    this.useDob = true,
    this.dob,
    this.edd,
    this.lmp,
    this.approxAge,
    this.gender,
    this.occupation,
    this.otherOccupation,
    this.education,
    this.religion,
    this.otherReligion,
    this.category,
    this.otherCategory,
    this.abhaAddress,
    this.mobileOwner,
    this.mobileOwnerRelation,
    this.mobileNo,
    this.bankAcc,
    this.ifsc,
    this.voterId,
    this.rationId,
    this.phId,
    this.beneficiaryType,
    this.isPregnant,
    this.familyPlanningCounseling,
    this.fpMethod,
    this.removalDate,
    this.removalReason,
    this.condomQuantity,
    this.malaQuantity,
    this.chhayaQuantity,
    this.ecpQuantity,
  });

  final String? relation;
  final String? memberName;
  final String? ageAtMarriage;
  final String? RichIDChanged;
  final String? spouseName;
  final String? UpdateYears;
  final String? UpdateMonths;
  final String? UpdateDays;
  final String? fatherName;
  final bool useDob;
  final DateTime? dob;
  final DateTime? edd;
  final DateTime? lmp;
  final String? approxAge;
  final String? gender;
  final String? occupation;
  final String? otherOccupation;
  final String? education;
  final String? religion;
  final String? otherReligion;
  final String? category;
  final String? otherCategory;
  final String? abhaAddress;
  final String? mobileOwner;
  final String? mobileOwnerRelation;
  final String? mobileNo;
  final String? bankAcc;
  final String? ifsc;
  final String? voterId;
  final String? rationId;
  final String? phId;
  final String? beneficiaryType;
  final String? isPregnant; // Yes/No
  final String? familyPlanningCounseling; // Yes/No/Select
  final String? fpMethod; // Selected FP method
  final DateTime? removalDate;
  final String? removalReason;
  final String? condomQuantity;
  final String? malaQuantity;
  final String? chhayaQuantity;
  final String? ecpQuantity;

  SpousState copyWith({
    String? relation,
    String? memberName,
    String? ageAtMarriage,
    String? spouseName,
    String? fatherName,
    String? UpdateYears,
    String? UpdateMonths,
    String? UpdateDays,
    String? RichIDChanged,
    bool? useDob,
    DateTime? dob,
    DateTime? edd,
    DateTime? lmp,
    String? approxAge,
    String? gender,
    String? occupation,
    String? otherOccupation,
    String? education,
    String? religion,
    String? otherReligion,
    String? category,
    String? otherCategory,
    String? abhaAddress,
    String? mobileOwner,
    String? mobileOwnerRelation,
    String? mobileNo,
    String? bankAcc,
    String? ifsc,
    String? voterId,
    String? rationId,
    String? phId,
    String? beneficiaryType,
    String? isPregnant,
    String? familyPlanningCounseling,
    String? fpMethod,
    DateTime? removalDate,
    String? removalReason,
    String? condomQuantity,
    String? malaQuantity,
    String? chhayaQuantity,
    String? ecpQuantity,
  }) {
    return SpousState(
      relation: relation ?? this.relation,
      memberName: memberName ?? this.memberName,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      spouseName: spouseName ?? this.spouseName,
      UpdateYears: UpdateYears ?? this.UpdateYears,
      UpdateMonths: UpdateMonths ?? this.UpdateMonths,
      UpdateDays: UpdateDays ?? this.UpdateDays,
      fatherName: fatherName ?? this.fatherName,
      useDob: useDob ?? this.useDob,
      RichIDChanged: RichIDChanged ?? this.RichIDChanged,
      dob: dob ?? this.dob,
      edd: edd ?? this.edd,
      lmp: lmp ?? this.lmp,
      approxAge: approxAge ?? this.approxAge,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      otherOccupation: otherOccupation ?? this.otherOccupation,
      education: education ?? this.education,
      religion: religion ?? this.religion,
      otherReligion: otherReligion ?? this.otherReligion,
      category: category ?? this.category,
      otherCategory: otherCategory ?? this.otherCategory,
      abhaAddress: abhaAddress ?? this.abhaAddress,
      mobileOwner: mobileOwner ?? this.mobileOwner,
      mobileOwnerRelation: mobileOwnerRelation ?? this.mobileOwnerRelation,
      mobileNo: mobileNo ?? this.mobileNo,
      bankAcc: bankAcc ?? this.bankAcc,
      ifsc: ifsc ?? this.ifsc,
      voterId: voterId ?? this.voterId,
      rationId: rationId ?? this.rationId,
      phId: phId ?? this.phId,
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      isPregnant: isPregnant ?? this.isPregnant,
      familyPlanningCounseling:
          familyPlanningCounseling ?? this.familyPlanningCounseling,
      fpMethod: fpMethod ?? this.fpMethod,
      removalDate: removalDate ?? this.removalDate,
      removalReason: removalReason ?? this.removalReason,
      condomQuantity: condomQuantity ?? this.condomQuantity,
      malaQuantity: malaQuantity ?? this.malaQuantity,
      chhayaQuantity: chhayaQuantity ?? this.chhayaQuantity,
      ecpQuantity: ecpQuantity ?? this.ecpQuantity,
    );
  }

  @override
  List<Object?> get props => [
        relation,
        memberName,
        ageAtMarriage,
        spouseName,
        fatherName,
        useDob,
        dob,
        UpdateYears,
        lmp,
        edd,
        approxAge,
        gender,
        occupation,
        otherOccupation,
        education,
        religion,
        otherReligion,
        category,
        otherCategory,
        abhaAddress,
        mobileOwner,
        mobileOwnerRelation,
        RichIDChanged,
        mobileNo,
        bankAcc,
        ifsc,
        voterId,
        rationId,
        phId,
        beneficiaryType,
        isPregnant,
        familyPlanningCounseling,
        fpMethod,
        removalDate,
        removalReason,
        condomQuantity,
        malaQuantity,
        chhayaQuantity,
        ecpQuantity,
      ];

  Map<String, dynamic> toJson() {
    return {
      'relation': relation,
      'memberName': memberName,
      'ageAtMarriage': ageAtMarriage,
      'RichIDChanged': RichIDChanged,
      'spouseName': spouseName,
      'fatherName': fatherName,
      'useDob': useDob,
      'dob': dob?.toIso8601String(),
      'edd': edd?.toIso8601String(),
      'lmp': lmp?.toIso8601String(),
      'approxAge': approxAge,
      'gender': gender,
      'occupation': occupation,
      'otherOccupation': otherOccupation,
      'education': education,
      'religion': religion,
      'otherReligion': otherReligion,
      'category': category,
      'otherCategory': otherCategory,
      'abhaAddress': abhaAddress,
      'mobileOwner': mobileOwner,
      'mobileOwnerRelation': mobileOwnerRelation,
      'mobileNo': mobileNo,
      'bankAcc': bankAcc,
      'ifsc': ifsc,
      'voterId': voterId,
      'rationId': rationId,
      'phId': phId,
      'beneficiaryType': beneficiaryType,
      'isPregnant': isPregnant,
      'familyPlanningCounseling': familyPlanningCounseling,
      'fpMethod': fpMethod,
      'removalDate': removalDate?.toIso8601String(),
      'removalReason': removalReason,
      'condomQuantity': condomQuantity,
      'malaQuantity': malaQuantity,
      'chhayaQuantity': chhayaQuantity,
      'ecpQuantity': ecpQuantity,
    };
  }
}
