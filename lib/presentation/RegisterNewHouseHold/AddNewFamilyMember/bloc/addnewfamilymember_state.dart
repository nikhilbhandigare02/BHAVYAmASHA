part of 'addnewfamilymember_bloc.dart';

@immutable
class AddnewfamilymemberState extends Equatable {
  final PostApiStatus postApiStatus;
  final String error;
  final String memberType;
  final String? RichIDChanged;
  final String? BirthCertificateChange;
  final String? relation;
  final String? memberStatus;
  final DateTime? dateOfDeath;
  final String? deathReason;
  final String? otherDeathReason;
  final String? deathPlace;
  final String? name;
  final String? ChildSchool;
  final String? WeightChange;
  final String? birthWeight;
  final String? fatherName;
  final String? motherName;
  final String? updateYear;
  final String? updateMonth;
  final String? updateDay;

  final bool useDob;
  final DateTime? dob;
  final String? approxAge;
  final String? children;
  final String? birthOrder;
  final String? gender;

  final String? bankAcc;
  final String? ifsc;
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
    this.WeightChange,
    this.updateDay,
    this.updateMonth,
    this.updateYear,
    this.RichIDChanged,
    this.ChildSchool,
    this.name,
    this.BirthCertificateChange,
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
    this.voterId,
    this.rationId,
    this.phId,
    this.beneficiaryType,
    this.maritalStatus,
    this.ageAtMarriage,
    this.spouseName,
    this.hasChildren,
    this.isPregnant,
    this.dateOfDeath,
    this.deathPlace,
    this.deathReason,
    this.otherDeathReason,
    this.memberStatus,
    this.birthWeight,
    this.errorMessage,

  });

  AddnewfamilymemberState copyWith({
    PostApiStatus? postApiStatus,
    String? error,
    String? memberType,
    String? BirthCertificateChange,
    String? WeightChange,
    String? birthWeight,
    String? ChildSchool,
    String? children,
    String? RichIDChanged,
    String? updateYear,
    String? updateMonth,
    String? updateDay,
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
    final String? memberStatus,
    final DateTime? dateOfDeath,
    final String? deathReason,
    final String? otherDeathReason,
    final String? deathPlace,
    String? errorMessage,

  }) {
    return AddnewfamilymemberState(
      postApiStatus: postApiStatus ?? this.postApiStatus,
      error: error ?? this.error,
      WeightChange: WeightChange ?? this.WeightChange,
      birthWeight: birthWeight ?? this.birthWeight,
      updateDay: updateDay ?? this.updateDay,
      updateMonth: updateMonth ?? this.updateMonth,
      updateYear: updateYear ?? this.updateYear,
      memberType: memberType ?? this.memberType,
      children: children ?? this.children,
      ChildSchool: ChildSchool ?? this.ChildSchool,
      RichIDChanged: RichIDChanged ?? this.RichIDChanged,
      relation: relation ?? this.relation,
      BirthCertificateChange: BirthCertificateChange ?? this.BirthCertificateChange,
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
      voterId: voterId ?? this.voterId,
      rationId: rationId ?? this.rationId,
      phId: phId ?? this.phId,
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      spouseName: spouseName ?? this.spouseName,
      hasChildren: hasChildren ?? this.hasChildren,
      isPregnant: isPregnant ?? this.isPregnant,
      deathReason: deathReason ?? this.deathReason,
      otherDeathReason: otherDeathReason ?? this.otherDeathReason,
      deathPlace: deathPlace ?? this.deathPlace,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      memberStatus: memberStatus ?? this.memberStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),

    );
  }

  @override
  List<Object?> get props => [
    postApiStatus,
    error,
    memberType,
    relation,
    WeightChange,
    birthWeight,
    name,
    RichIDChanged,
    fatherName,
    motherName,
    useDob,
    otherDeathReason,
    updateYear,
    updateMonth,
    updateDay,
    dob,
    BirthCertificateChange,
    ChildSchool,
    children,
    approxAge,
    birthOrder,
    gender,
    bankAcc,
    ifsc,
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
    deathPlace,
    dateOfDeath,
    deathReason,
    memberStatus,
    isPregnant,
  ];

  Map<String, dynamic> toJson() {
    return {
      'postApiStatus': postApiStatus.toString(),
      'error': error,
      'memberType': memberType,
      'relation': relation,
      'name': name,
      'fatherName': fatherName,
      'motherName': motherName,
      'useDob': useDob,
      'dob': dob?.toIso8601String(),
      'approxAge': approxAge,
      'birthOrder': birthOrder,
      'gender': gender,
      'bankAcc': bankAcc,
      'ifsc': ifsc,
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
      'voterId': voterId,
      'rationId': rationId,
      'phId': phId,
      'beneficiaryType': beneficiaryType,
      'maritalStatus': maritalStatus,
      'ageAtMarriage': ageAtMarriage,
      'spouseName': spouseName,
      'hasChildren': hasChildren,
      'isPregnant': isPregnant,
      'memberStatus': memberStatus,
      'dateOfDeath': dateOfDeath,
      'deathReason': deathReason,
      'deathPlace': deathPlace,
      'errorMessage': errorMessage,
      'RichIDChanged': RichIDChanged,
      'BirthCertificateChange': BirthCertificateChange,
      'ChildSchool': ChildSchool,
      'WeightChange': WeightChange,
      'birthWeight': birthWeight,
      'otherDeathReason': otherDeathReason,
      'children': children,
    };
  }
}
