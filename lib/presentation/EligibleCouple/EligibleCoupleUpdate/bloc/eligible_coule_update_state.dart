part of 'eligible_coule_update_bloc.dart';

class EligibleCouleUpdateState extends Equatable {
  final String rchId;
  final String womanName;
  final String currentAge;
  final String ageAtMarriage;
  final String address;
  final String whoseMobile; // Husband/Wife/Other
  final String mobileNo;
  final String religion;
  final String category;
  final String totalChildrenBorn;
  final String totalLiveChildren;
  final String totalMaleChildren;
  final String totalFemaleChildren;
  final String youngestChildAge;
  final String youngestChildAgeUnit; // Years/Months
  final String youngestChildGender; // Male/Female
  final DateTime? registrationDate;

  // Database tracking fields
  final int? dbRowId;
  final String? householdRefKey;
  final String? beneficiaryName;
  final String? uniqueKey;

  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  const EligibleCouleUpdateState({
    this.rchId = '',
    this.womanName = '',
    this.currentAge = '',
    this.ageAtMarriage = '',
    this.address = '',
    this.whoseMobile = '',
    this.mobileNo = '',
    this.religion = '',
    this.category = '',
    this.totalChildrenBorn = '0',
    this.totalLiveChildren = '0',
    this.totalMaleChildren = '0',
    this.totalFemaleChildren = '0',
    this.youngestChildAge = '0',
    this.youngestChildAgeUnit = '',
    this.youngestChildGender = '',
    this.registrationDate,
    this.dbRowId,
    this.householdRefKey,
    this.beneficiaryName,
    this.uniqueKey,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  factory EligibleCouleUpdateState.initial() => const EligibleCouleUpdateState();

  EligibleCouleUpdateState copyWith({
    String? rchId,
    String? womanName,
    String? currentAge,
    String? ageAtMarriage,
    String? address,
    String? whoseMobile,
    String? mobileNo,
    String? religion,
    String? category,
    String? totalChildrenBorn,
    String? totalLiveChildren,
    String? totalMaleChildren,
    String? totalFemaleChildren,
    String? youngestChildAge,
    String? youngestChildAgeUnit,
    String? youngestChildGender,
    DateTime? registrationDate,
    int? dbRowId,
    String? householdRefKey,
    String? beneficiaryName,
    String? uniqueKey,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return EligibleCouleUpdateState(
      rchId: rchId ?? this.rchId,
      womanName: womanName ?? this.womanName,
      currentAge: currentAge ?? this.currentAge,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      address: address ?? this.address,
      whoseMobile: whoseMobile ?? this.whoseMobile,
      mobileNo: mobileNo ?? this.mobileNo,
      religion: religion ?? this.religion,
      category: category ?? this.category,
      totalChildrenBorn: totalChildrenBorn ?? this.totalChildrenBorn,
      totalLiveChildren: totalLiveChildren ?? this.totalLiveChildren,
      totalMaleChildren: totalMaleChildren ?? this.totalMaleChildren,
      totalFemaleChildren: totalFemaleChildren ?? this.totalFemaleChildren,
      youngestChildAge: youngestChildAge ?? this.youngestChildAge,
      youngestChildAgeUnit: youngestChildAgeUnit ?? this.youngestChildAgeUnit,
      youngestChildGender: youngestChildGender ?? this.youngestChildGender,
      registrationDate: registrationDate ?? this.registrationDate,
      dbRowId: dbRowId ?? this.dbRowId,
      householdRefKey: householdRefKey ?? this.householdRefKey,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isValid => womanName.isNotEmpty && currentAge.isNotEmpty && mobileNo.length >= 10;

  @override
  List<Object?> get props => [
        rchId,
        womanName,
        currentAge,
        ageAtMarriage,
        address,
        whoseMobile,
        mobileNo,
        religion,
        category,
        totalChildrenBorn,
        totalLiveChildren,
        totalMaleChildren,
        totalFemaleChildren,
        youngestChildAge,
        youngestChildAgeUnit,
        youngestChildGender,
        registrationDate,
        dbRowId,
        householdRefKey,
        beneficiaryName,
        uniqueKey,
        isSubmitting,
        isSuccess,
        error,
      ];
}