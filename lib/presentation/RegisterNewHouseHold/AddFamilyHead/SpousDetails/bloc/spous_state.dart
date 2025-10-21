part of 'spous_bloc.dart';

class SpousState extends Equatable {
  const SpousState({
    this.relation,
    this.memberName,
    this.ageAtMarriage,
    this.spouseName,
    this.fatherName,
    this.useDob = true,
    this.dob,
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
  });

  final String? relation;
  final String? memberName;
  final String? ageAtMarriage;
  final String? spouseName;
  final String? fatherName;
  final bool useDob;
  final DateTime? dob;
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

  SpousState copyWith({
    String? relation,
    String? memberName,
    String? ageAtMarriage,
    String? spouseName,
    String? fatherName,
    bool? useDob,
    DateTime? dob,
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
  }) {
    return SpousState(
      relation: relation ?? this.relation,
      memberName: memberName ?? this.memberName,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      spouseName: spouseName ?? this.spouseName,
      fatherName: fatherName ?? this.fatherName,
      useDob: useDob ?? this.useDob,
      dob: dob ?? this.dob,
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
        approxAge,
        gender,
        occupation,
        education,
        religion,
        category,
        abhaAddress,
        mobileOwner,
        mobileNo,
        bankAcc,
        ifsc,
        voterId,
        rationId,
        phId,
        beneficiaryType,
      ];
}
