part of 'addnewfamilymember_bloc.dart';

enum AddnewfamilymemberStatus { initial, loading, success, failure }

@immutable
class AddnewfamilymemberState extends Equatable {
  final AddnewfamilymemberStatus status;
  final PostApiStatus postApiStatus;
  final String error;
  final String memberType;
  final String? RichIDChanged;
  final bool isRchIdButtonEnabled;
  final String? BirthCertificateChange;
  final String? relation;
  final String? otherRelation;
  final String? memberStatus;
  final DateTime? dateOfDeath;
  final String? deathReason;
  final String? otherDeathReason;
  final String? deathPlace;
  final String? otherDeathPlace;
  final String? name;
  final String? ChildSchool;
  final String? TypeOfSchool;
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
  final String? isFamilyPlanning; // 'Yes' | 'No' | 'Select'
  final String? familyPlanningMethod;
  final String? fpMethod;
  final DateTime? antraDate;
  final DateTime? removalDate;
  final String? removalReason;
  final String? condomQuantity;
  final String? malaQuantity;
  final String? chhayaQuantity;
  final String? ecpQuantity;
  final DateTime? lmp;       // Last Menstrual Period date
  final DateTime? edd;       // Expected Delivery Date
  final String? errorMessage;



  const AddnewfamilymemberState({
    this.status = AddnewfamilymemberStatus.initial,
    this.postApiStatus = PostApiStatus.initial,
    this.error = '',
    this.memberType = 'Adult',
    this.relation,
    this.otherRelation,
    this.WeightChange,
    this.updateDay,
    this.updateMonth,
    this.updateYear,
    this.RichIDChanged,
    this.isRchIdButtonEnabled = false,
    this.ChildSchool,
    this.TypeOfSchool,
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
    this.isFamilyPlanning,
    this.familyPlanningMethod,
    this.fpMethod,
    this.antraDate,
    this.removalDate,
    this.removalReason,
    this.condomQuantity,
    this.malaQuantity,
    this.chhayaQuantity,
    this.ecpQuantity,
    this.lmp,
    this.edd,
    this.dateOfDeath,
    this.deathPlace,
    this.otherDeathPlace,
    this.deathReason,
    this.otherDeathReason,
    this.memberStatus,
    this.birthWeight,
    this.errorMessage,
  });

  AddnewfamilymemberState copyWith({
    AddnewfamilymemberStatus? status,
    PostApiStatus? postApiStatus,
    String? error,
    String? memberType,
    String? BirthCertificateChange,
    String? WeightChange,
    String? birthWeight,
    String? ChildSchool,
    String? TypeOfSchool,
    String? children,
    String? RichIDChanged,
    bool? isRchIdButtonEnabled,
    String? updateYear,
    String? updateMonth,
    String? updateDay,
    String? relation,
    String? otherRelation,
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
    String? isFamilyPlanning,
    String? familyPlanningMethod,
    String? fpMethod,
    DateTime? antraDate,
    DateTime? removalDate,
    String? removalReason,
    String? condomQuantity,
    String? malaQuantity,
    String? chhayaQuantity,
    String? ecpQuantity,
    DateTime? lmp,
    DateTime? edd,
    bool clearDob = false,
    bool clearError = false,
    final String? memberStatus,
    final DateTime? dateOfDeath,
    final String? deathReason,
    final String? otherDeathReason,
    final String? deathPlace,
    final String? otherDeathPlace,
    String? errorMessage,

  }) {
    return AddnewfamilymemberState(
      status: status ?? this.status,
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
      TypeOfSchool: TypeOfSchool ?? this.TypeOfSchool,
      RichIDChanged: RichIDChanged ?? this.RichIDChanged,
      isRchIdButtonEnabled: isRchIdButtonEnabled ?? this.isRchIdButtonEnabled,
      relation: relation ?? this.relation,
      otherRelation: otherRelation ?? this.otherRelation,
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
      isFamilyPlanning: isFamilyPlanning ?? this.isFamilyPlanning,
      familyPlanningMethod: familyPlanningMethod ?? this.familyPlanningMethod,
      fpMethod: fpMethod ?? this.fpMethod,
      antraDate: antraDate ?? this.antraDate,
      removalDate: removalDate ?? this.removalDate,
      removalReason: removalReason ?? this.removalReason,
      condomQuantity: condomQuantity ?? this.condomQuantity,
      malaQuantity: malaQuantity ?? this.malaQuantity,
      chhayaQuantity: chhayaQuantity ?? this.chhayaQuantity,
      ecpQuantity: ecpQuantity ?? this.ecpQuantity,
      lmp: lmp ?? this.lmp,
      edd: edd ?? this.edd,
      deathReason: deathReason ?? this.deathReason,
      otherDeathReason: otherDeathReason ?? this.otherDeathReason,
      deathPlace: deathPlace ?? this.deathPlace,
      otherDeathPlace: otherDeathPlace ?? this.otherDeathPlace,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      memberStatus: memberStatus ?? this.memberStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),

    );
  }

  @override
  List<Object?> get props => [
    status,
    postApiStatus,
    error,
    memberType,
    relation,
    otherRelation,
    WeightChange,
    birthWeight,
    name,
    RichIDChanged,
    isRchIdButtonEnabled,
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
    TypeOfSchool,
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
    isFamilyPlanning,
    fpMethod,
    deathPlace,
    otherDeathPlace,
    dateOfDeath,
    deathReason,
    memberStatus,
    isPregnant,
    familyPlanningMethod,
    antraDate,
    removalDate,
    removalReason,
    condomQuantity,
    malaQuantity,
    chhayaQuantity,
    ecpQuantity,
    lmp,
    edd,
  ];

  Map<String, dynamic> toJson() {
    return {
      'postApiStatus': postApiStatus.toString(),
      'error': error,
      'memberType': memberType,
      'relation': relation,
      'otherRelation': otherRelation,
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
      'isFamilyPlanning': isFamilyPlanning,
      'familyPlanningMethod': familyPlanningMethod,
      'fpMethod': fpMethod,
      'antraDate': antraDate?.toIso8601String(),
      'removalDate': removalDate?.toIso8601String(),
      'removalReason': removalReason,
      'condomQuantity': condomQuantity,
      'malaQuantity': malaQuantity,
      'chhayaQuantity': chhayaQuantity,
      'ecpQuantity': ecpQuantity,
      'memberStatus': memberStatus,
      'dateOfDeath': dateOfDeath,
      'deathReason': deathReason,
      'deathPlace': deathPlace,
      'otherDeathPlace': otherDeathPlace,
      'errorMessage': errorMessage,
      'RichIDChanged': RichIDChanged,
      'isRchIdButtonEnabled': isRchIdButtonEnabled,
      'BirthCertificateChange': BirthCertificateChange,
      'ChildSchool': ChildSchool,
      'TypeOfSchool': TypeOfSchool,
      'WeightChange': WeightChange,
      'birthWeight': birthWeight,
      'otherDeathReason': otherDeathReason,
      'children': children,
    };
  }
}
