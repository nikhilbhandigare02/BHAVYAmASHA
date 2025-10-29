part of 'spous_bloc.dart';

class SpousState extends Equatable {
  const SpousState({
    this.relation,
    this.memberName,
    this.ageAtMarriage,
    this.RichIDChanged,
    this.spouseName,
    this.fatherName,
    this.useDob = true,
    this.dob,
    this.edd,
    this.lmp,
    this.approxAge,
    this.gender,
    this.occupation,
    this.education,
    this.religion,
    this.category,
    this.abhaAddress,
    this.mobileOwner,
    this.mobileNo,
    this.bankAcc,
    this.ifsc,
    this.voterId,
    this.rationId,
    this.phId,
    this.beneficiaryType,
    this.isPregnant,
  });

  final String? relation;
  final String? memberName;
  final String? ageAtMarriage;
  final String? RichIDChanged;
  final String? spouseName;
  final String? fatherName;
  final bool useDob;
  final DateTime? dob;
  final DateTime? edd;
  final DateTime? lmp;
  final String? approxAge;
  final String? gender;
  final String? occupation;
  final String? education;
  final String? religion;
  final String? category;
  final String? abhaAddress;
  final String? mobileOwner;
  final String? mobileNo;
  final String? bankAcc;
  final String? ifsc;
  final String? voterId;
  final String? rationId;
  final String? phId;
  final String? beneficiaryType;
  final String? isPregnant; // Yes/No

  SpousState copyWith({
    String? relation,
    String? memberName,
    String? ageAtMarriage,
    String? spouseName,
    String? fatherName,
    String? RichIDChanged,
    bool? useDob,
    DateTime? dob,
    DateTime? edd,
    DateTime? lmp,
    String? approxAge,
    String? gender,
    String? occupation,
    String? education,
    String? religion,
    String? category,
    String? abhaAddress,
    String? mobileOwner,
    String? mobileNo,
    String? bankAcc,
    String? ifsc,
    String? voterId,
    String? rationId,
    String? phId,
    String? beneficiaryType,
    String? isPregnant,
  }) {
    return SpousState(
      relation: relation ?? this.relation,
      memberName: memberName ?? this.memberName,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      spouseName: spouseName ?? this.spouseName,
      fatherName: fatherName ?? this.fatherName,
      useDob: useDob ?? this.useDob,
      RichIDChanged: RichIDChanged ?? this.RichIDChanged,
      dob: dob ?? this.dob,
      edd: edd ?? this.edd,
      lmp: lmp ?? this.lmp,
      approxAge: approxAge ?? this.approxAge,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      religion: religion ?? this.religion,
      category: category ?? this.category,
      abhaAddress: abhaAddress ?? this.abhaAddress,
      mobileOwner: mobileOwner ?? this.mobileOwner,
      mobileNo: mobileNo ?? this.mobileNo,
      bankAcc: bankAcc ?? this.bankAcc,
      ifsc: ifsc ?? this.ifsc,
      voterId: voterId ?? this.voterId,
      rationId: rationId ?? this.rationId,
      phId: phId ?? this.phId,
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      isPregnant: isPregnant ?? this.isPregnant,
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
        lmp,
        edd,
        approxAge,
        gender,
        occupation,
        education,
        religion,
        category,
        abhaAddress,
        mobileOwner,
        RichIDChanged,
        mobileNo,
        bankAcc,
        ifsc,
        voterId,
        rationId,
        phId,
        beneficiaryType,
        isPregnant,
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
      'education': education,
      'religion': religion,
      'category': category,
      'abhaAddress': abhaAddress,
      'mobileOwner': mobileOwner,
      'mobileNo': mobileNo,
      'bankAcc': bankAcc,
      'ifsc': ifsc,
      'voterId': voterId,
      'rationId': rationId,
      'phId': phId,
      'beneficiaryType': beneficiaryType,
      'isPregnant': isPregnant,
    };
  }
}
