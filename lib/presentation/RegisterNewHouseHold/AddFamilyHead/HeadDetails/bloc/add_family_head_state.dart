part of 'add_family_head_bloc.dart';

@immutable
class AddFamilyHeadState extends Equatable {
  final String? houseNo;
  final String? headName;
  final String? children;
  final String? fatherName;
  final String? AfhABHAChange;
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
  final String? mobileOwner;
  final String? mobileNo;
  final String? village;
  final String? ward;
  final String? mohalla;
  final String? bankAcc;
  final String? ifsc;
  final String? voterId;
  final String? rationId;
  final String? phId;
  final String? beneficiaryType;
  final String? maritalStatus; // e.g., Married/Unmarried/Widowed/Separated
  final String? ageAtMarriage;
  final String? spouseName;
  final String? AfhRichIdChange;
  final String? hasChildren; // Yes/No
  final String? isPregnant; // Yes/No
  final PostApiStatus postApiStatus;
  final String? errorMessage;

  const AddFamilyHeadState({
    this.houseNo,
    this.headName,
    this.fatherName,
    this.AfhABHAChange,
    this.children,
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
    this.mobileOwner,
    this.mobileNo,
    this.village,
    this.ward,
    this.mohalla,
    this.bankAcc,
    this.ifsc,
    this.voterId,
    this.rationId,
    this.phId,
    this.beneficiaryType,
    this.maritalStatus,
    this.ageAtMarriage,
    this.spouseName,
    this.AfhRichIdChange,
    this.hasChildren,
    this.isPregnant,
    this.postApiStatus = PostApiStatus.initial,
    this.errorMessage,
  });

  AddFamilyHeadState copyWith({
    String? houseNo,
    String? headName,
    String? fatherName,
    String? AfhABHAChange,
    String? children,
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
    String? mobileOwner,
    String? mobileNo,
    String? village,
    String? ward,
    String? mohalla,
    String? bankAcc,
    String? ifsc,
    String? voterId,
    String? rationId,
    String? phId,
    String? beneficiaryType,
    String? maritalStatus,
    String? ageAtMarriage,
    String? spouseName,
    String? hasChildren,
    String? AfhRichIdChange,
    String? isPregnant,
    PostApiStatus? postApiStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddFamilyHeadState(
      houseNo: houseNo ?? this.houseNo,
      headName: headName ?? this.headName,
      AfhABHAChange: AfhABHAChange ?? this.AfhABHAChange,
      children: children ?? this.children,
      fatherName: fatherName ?? this.fatherName,
      useDob: useDob ?? this.useDob,
      dob: dob ?? this.dob,
      edd: edd ?? this.edd,
      lmp: lmp ?? this.lmp,
      approxAge: approxAge ?? this.approxAge,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      religion: religion ?? this.religion,
      category: category ?? this.category,
      mobileOwner: mobileOwner ?? this.mobileOwner,
      mobileNo: mobileNo ?? this.mobileNo,
      village: village ?? this.village,
      ward: ward ?? this.ward,
      mohalla: mohalla ?? this.mohalla,
      bankAcc: bankAcc ?? this.bankAcc,
      ifsc: ifsc ?? this.ifsc,
      voterId: voterId ?? this.voterId,
      rationId: rationId ?? this.rationId,
      phId: phId ?? this.phId,
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      spouseName: spouseName ?? this.spouseName,
      hasChildren: hasChildren ?? this.hasChildren,
      AfhRichIdChange: AfhRichIdChange ?? this.AfhRichIdChange,
      isPregnant: isPregnant ?? this.isPregnant,
      postApiStatus: postApiStatus ?? this.postApiStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    houseNo,
    AfhABHAChange,
    AfhRichIdChange,
    lmp,
    edd,
    headName,
    fatherName,
    useDob,
    dob,
    children,
    approxAge,
    gender,
    occupation,
    education,
    religion,
    category,
    mobileOwner,
    mobileNo,
    village,
    ward,
    mohalla,
    bankAcc,
    ifsc,
    voterId,
    rationId,
    phId,
    beneficiaryType,
    maritalStatus,
    ageAtMarriage,
    spouseName,
    hasChildren,
    isPregnant,
    postApiStatus,
    errorMessage,
  ];
}
