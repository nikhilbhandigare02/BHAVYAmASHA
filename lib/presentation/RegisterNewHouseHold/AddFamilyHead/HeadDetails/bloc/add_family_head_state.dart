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
  final String? years;
  final String? months;
  final String? days;
  final String? gender;
  final String? occupation;
  final String? education;
  final String? religion;
  final String? category;
  final String? mobileOwner;
  final String? mobileNo;
  final String? village;
  final String? ward;
  final String? wardNo; // Added for consistency with payload
  final String? mohalla;
  final String? mohallaTola; // Added for consistency with payload
  final String? bankAcc;
  final String? bankAccountNumber; // Added for consistency with payload
  final String? ifsc;
  final String? ifscCode; // Added for consistency with payload
  final String? voterId;
  final String? rationId;
  final String? rationCardId; // Added for consistency with payload
  final String? phId;
  final String? personalHealthId; // Added for consistency with payload
  final String? abhaNumber; // Added for ABHA number
  final String? abhaAddress; // Added for ABHA address
  final String? beneficiaryType;
  final String? maritalStatus; // e.g., Married/Unmarried/Widowed/Separated
  final String? ageAtMarriage;
  final String? spouseName;
  final String? AfhRichIdChange;
  final String? hasChildren; // Yes/No
  final String? isPregnant; // Yes/No
  // Verification status fields
  final bool? abhaVerified;
  final bool? voterIdVerified;
  final bool? rationCardVerified;
  final bool? bankAccountVerified;
  // Migrant worker fields
  final bool? isMigrantWorker;
  final String? migrantState;
  final String? migrantDistrict;
  final String? migrantBlock;
  final String? migrantPanchayat;
  final String? migrantVillage;
  final String? migrantContactNo;
  final String? migrantDuration;
  final String? migrantWorkType;
  final String? migrantWorkPlace;
  final String? migrantRemarks;
  // Technical identifiers for edit/update flow
  final String? householdRefKey; // households.unique_key
  final String? headUniqueKey; // beneficiaries.unique_key for head
  final String? spouseUniqueKey; // beneficiaries.unique_key for spouse (if any)
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
    this.years,
    this.months,
    this.days,
    this.gender,
    this.occupation,
    this.education,
    this.religion,
    this.category,
    this.mobileOwner,
    this.mobileNo,
    this.village,
    this.ward,
    this.wardNo,
    this.mohalla,
    this.mohallaTola,
    this.bankAcc,
    this.bankAccountNumber,
    this.ifsc,
    this.ifscCode,
    this.voterId,
    this.rationId,
    this.rationCardId,
    this.phId,
    this.personalHealthId,
    this.abhaNumber,
    this.abhaAddress,
    this.beneficiaryType,
    this.maritalStatus,
    this.ageAtMarriage,
    this.spouseName,
    this.AfhRichIdChange,
    this.hasChildren,
    this.isPregnant,
    this.abhaVerified = false,
    this.voterIdVerified = false,
    this.rationCardVerified = false,
    this.bankAccountVerified = false,
    this.isMigrantWorker = false,
    this.migrantState,
    this.migrantDistrict,
    this.migrantBlock,
    this.migrantPanchayat,
    this.migrantVillage,
    this.migrantContactNo,
    this.migrantDuration,
    this.migrantWorkType,
    this.migrantWorkPlace,
    this.migrantRemarks,
    this.householdRefKey,
    this.headUniqueKey,
    this.spouseUniqueKey,
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
    String? years,
    String? months,
    String? days,
    String? gender,
    String? occupation,
    String? education,
    String? religion,
    String? category,
    String? mobileOwner,
    String? mobileNo,
    String? village,
    String? ward,
    String? wardNo,
    String? mohalla,
    String? mohallaTola,
    String? bankAcc,
    String? bankAccountNumber,
    String? ifsc,
    String? ifscCode,
    String? voterId,
    String? rationId,
    String? rationCardId,
    String? phId,
    String? personalHealthId,
    String? abhaNumber,
    String? abhaAddress,
    String? beneficiaryType,
    String? maritalStatus,
    String? ageAtMarriage,
    String? spouseName,
    String? hasChildren,
    String? AfhRichIdChange,
    String? isPregnant,
    bool? abhaVerified,
    bool? voterIdVerified,
    bool? rationCardVerified,
    bool? bankAccountVerified,
    bool? isMigrantWorker,
    String? migrantState,
    String? migrantDistrict,
    String? migrantBlock,
    String? migrantPanchayat,
    String? migrantVillage,
    String? migrantContactNo,
    String? migrantDuration,
    String? migrantWorkType,
    String? migrantWorkPlace,
    String? migrantRemarks,
    String? householdRefKey,
    String? headUniqueKey,
    String? spouseUniqueKey,
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
      years: years ?? this.years,
      months: months ?? this.months,
      days: days ?? this.days,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      religion: religion ?? this.religion,
      category: category ?? this.category,
      mobileOwner: mobileOwner ?? this.mobileOwner,
      mobileNo: mobileNo ?? this.mobileNo,
      village: village ?? this.village,
      ward: ward ?? this.ward,
      wardNo: wardNo ?? this.wardNo,
      mohalla: mohalla ?? this.mohalla,
      mohallaTola: mohallaTola ?? this.mohallaTola,
      bankAcc: bankAcc ?? this.bankAcc,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      ifsc: ifsc ?? this.ifsc,
      ifscCode: ifscCode ?? this.ifscCode,
      voterId: voterId ?? this.voterId,
      rationId: rationId ?? this.rationId,
      rationCardId: rationCardId ?? this.rationCardId,
      phId: phId ?? this.phId,
      personalHealthId: personalHealthId ?? this.personalHealthId,
      abhaNumber: abhaNumber ?? this.abhaNumber,
      abhaAddress: abhaAddress ?? this.abhaAddress,
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      spouseName: spouseName ?? this.spouseName,
      hasChildren: hasChildren ?? this.hasChildren,
      AfhRichIdChange: AfhRichIdChange ?? this.AfhRichIdChange,
      isPregnant: isPregnant ?? this.isPregnant,
      abhaVerified: abhaVerified ?? this.abhaVerified,
      voterIdVerified: voterIdVerified ?? this.voterIdVerified,
      rationCardVerified: rationCardVerified ?? this.rationCardVerified,
      bankAccountVerified: bankAccountVerified ?? this.bankAccountVerified,
      isMigrantWorker: isMigrantWorker ?? this.isMigrantWorker,
      migrantState: migrantState ?? this.migrantState,
      migrantDistrict: migrantDistrict ?? this.migrantDistrict,
      migrantBlock: migrantBlock ?? this.migrantBlock,
      migrantPanchayat: migrantPanchayat ?? this.migrantPanchayat,
      migrantVillage: migrantVillage ?? this.migrantVillage,
      migrantContactNo: migrantContactNo ?? this.migrantContactNo,
      migrantDuration: migrantDuration ?? this.migrantDuration,
      migrantWorkType: migrantWorkType ?? this.migrantWorkType,
      migrantWorkPlace: migrantWorkPlace ?? this.migrantWorkPlace,
      migrantRemarks: migrantRemarks ?? this.migrantRemarks,
      householdRefKey: householdRefKey ?? this.householdRefKey,
      headUniqueKey: headUniqueKey ?? this.headUniqueKey,
      spouseUniqueKey: spouseUniqueKey ?? this.spouseUniqueKey,
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
    years,
    months,
    days,
    gender,
    occupation,
    education,
    religion,
    category,
    mobileOwner,
    mobileNo,
    village,
    ward,
    wardNo,
    mohalla,
    mohallaTola,
    bankAcc,
    bankAccountNumber,
    ifsc,
    ifscCode,
    voterId,
    rationId,
    rationCardId,
    phId,
    personalHealthId,
    abhaNumber,
    abhaAddress,
    beneficiaryType,
    maritalStatus,
    ageAtMarriage,
    spouseName,
    hasChildren,
    isPregnant,
    abhaVerified,
    voterIdVerified,
    rationCardVerified,
    bankAccountVerified,
    isMigrantWorker,
    migrantState,
    migrantDistrict,
    migrantBlock,
    migrantPanchayat,
    migrantVillage,
    migrantContactNo,
    migrantDuration,
    migrantWorkType,
    migrantWorkPlace,
    migrantRemarks,
    householdRefKey,
    headUniqueKey,
    spouseUniqueKey,
    postApiStatus,
    errorMessage,
  ];

  Map<String, dynamic> toJson() {
    return {
      'houseNo': houseNo,
      'headName': headName,
      'children': children,
      'fatherName': fatherName,
      'AfhABHAChange': AfhABHAChange,
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
      'mobileOwner': mobileOwner,
      'mobileNo': mobileNo,
      'village': village,
      'ward': ward,
      'mohalla': mohalla,
      'bankAcc': bankAcc,
      'ifsc': ifsc,
      'voterId': voterId,
      'rationId': rationId,
      'phId': phId,
      'beneficiaryType': beneficiaryType,
      'maritalStatus': maritalStatus,
      'ageAtMarriage': ageAtMarriage,
      'spouseName': spouseName,
      'AfhRichIdChange': AfhRichIdChange,
      'hasChildren': hasChildren,
      'isPregnant': isPregnant,
      'postApiStatus': postApiStatus.toString(),
      'errorMessage': errorMessage,
    };
  }
}
