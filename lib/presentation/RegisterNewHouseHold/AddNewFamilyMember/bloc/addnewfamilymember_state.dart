part of 'addnewfamilymember_bloc.dart';

@immutable
class AddnewfamilymemberState extends Equatable {
  final PostApiStatus postApiStatus;
  final String error;
  final String memberType;
  final String? relation;
  final String? name;
  final String? fatherName;
  final String? motherName;

  final bool useDob;
  final DateTime? dob;
  final String? approxAge;
  final String? children;
  final String? birthOrder;
  final String? gender;

  final String? bankAcc;
  final String? ifsc;
  final String? occupation;
  final String? education;
  final String? religion;
  final String? category;
  final String? abhaAddress;

  final String? mobileOwner;
  final String? mobileNo;

  final String? voterId;
  final String? rationId;
  final String? phId;
  final String? beneficiaryType;
  final String? maritalStatus;
  final String? ageAtMarriage;
  final String? spouseName;
  final String? hasChildren; // 'Yes' | 'No'
  final String? isPregnant;  // 'Yes' | 'No'
  final String? errorMessage;


  const AddnewfamilymemberState({
    this.postApiStatus = PostApiStatus.initial,
    this.error = '',
    this.memberType = 'Adult',
    this.relation,
    this.name,
    this.fatherName,
    this.motherName,
    this.children,
    this.useDob = true,
    this.dob,
    this.approxAge,
    this.birthOrder,
    this.gender,
    this.bankAcc,
    this.ifsc,
    this.occupation,
    this.education,
    this.religion,
    this.category,
    this.abhaAddress,
    this.mobileOwner,
    this.mobileNo,
    this.voterId,
    this.rationId,
    this.phId,
    this.beneficiaryType,
    this.maritalStatus,
    this.ageAtMarriage,
    this.spouseName,
    this.hasChildren,
    this.isPregnant,
    this.errorMessage,

  });

  AddnewfamilymemberState copyWith({
    PostApiStatus? postApiStatus,
    String? error,
    String? memberType,
    String? children,
    String? relation,
    String? name,
    String? fatherName,
    String? motherName,
    bool? useDob,
    DateTime? dob,
    String? approxAge,
    String? birthOrder,
    String? gender,
    String? bankAcc,
    String? ifsc,
    String? occupation,
    String? education,
    String? religion,
    String? category,
    String? abhaAddress,
    String? mobileOwner,
    String? mobileNo,
    String? voterId,
    String? rationId,
    String? phId,
    String? beneficiaryType,
    String? maritalStatus,
    String? ageAtMarriage,
    String? spouseName,
    String? hasChildren,
    String? isPregnant,
    bool clearDob = false,
    bool clearError = false,
    String? errorMessage,

  }) {
    return AddnewfamilymemberState(
      postApiStatus: postApiStatus ?? this.postApiStatus,
      error: error ?? this.error,
      memberType: memberType ?? this.memberType,
      children: children ?? this.children,
      relation: relation ?? this.relation,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      useDob: useDob ?? this.useDob,
      dob: clearDob ? null : (dob ?? this.dob),
      approxAge: approxAge ?? this.approxAge,
      birthOrder: birthOrder ?? this.birthOrder,
      gender: gender ?? this.gender,
      bankAcc: bankAcc ?? this.bankAcc,
      ifsc: ifsc ?? this.ifsc,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      religion: religion ?? this.religion,
      category: category ?? this.category,
      abhaAddress: abhaAddress ?? this.abhaAddress,
      mobileOwner: mobileOwner ?? this.mobileOwner,
      mobileNo: mobileNo ?? this.mobileNo,
      voterId: voterId ?? this.voterId,
      rationId: rationId ?? this.rationId,
      phId: phId ?? this.phId,
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      spouseName: spouseName ?? this.spouseName,
      hasChildren: hasChildren ?? this.hasChildren,
      isPregnant: isPregnant ?? this.isPregnant,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),

    );
  }

  @override
  List<Object?> get props => [
    postApiStatus,
    error,
    memberType,
    relation,
    name,
    fatherName,
    motherName,
    useDob,
    dob,
    children,
    approxAge,
    birthOrder,
    gender,
    bankAcc,
    ifsc,
    occupation,
    education,
    religion,
    category,
    abhaAddress,
    mobileOwner,
    mobileNo,
    voterId,
    rationId,
    phId,
    beneficiaryType,
    errorMessage,
    maritalStatus,
    ageAtMarriage,
    spouseName,
    hasChildren,
    isPregnant,
  ];
}
