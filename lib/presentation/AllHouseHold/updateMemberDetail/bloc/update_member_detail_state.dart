part of 'update_member_detail_bloc.dart';

class UpdateMemberDetailState {
  // Basic Information
  final String name;
  final String gender;
  final DateTime? dob;
  final String age;
  final String relation;
  final String fatherName;
  final String motherName;
  final String mobileNumber;
  final String aadharNumber;
  final String memberType;
  final String richID;
  final String maritalStatus;
  final String mobileOwner;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final int? memberId;
  
  // Additional Fields
  final bool? useDob;
  final String? updateYear;
  final String? updateMonth;
  final String? updateDay;
  final String? birthOrder;
  final String? weight;
  final String? category;
  final String? abhaAddress;
  final String? bankAccount;
  final String? ifsc;
  final String? occupation;
  final String? education;
  final String? voterId;
  final String? rationId;
  final String? phId;
  final String? beneficiaryType;
  final String? ageAtMarriage;
  final String? spouseName;
  final String? hasChildren;
  final String? isPregnant;
  final String? children;
  final String? religion;
  final String? childSchool;
  final String? birthCertificate;

  const UpdateMemberDetailState({
    // Basic Information
    this.name = '',
    this.gender = '',
    this.dob,
    this.age = '',
    this.relation = '',
    this.fatherName = '',
    this.motherName = '',
    this.mobileNumber = '',
    this.aadharNumber = '',
    this.memberType = 'Adult',
    this.richID = '',
    this.maritalStatus = '',
    this.mobileOwner = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.memberId,
    
    // Additional Fields
    this.useDob = true,
    this.updateYear = '',
    this.updateMonth = '',
    this.updateDay = '',
    this.birthOrder,
    this.weight,
    this.category,
    this.abhaAddress = '',
    this.bankAccount = '',
    this.ifsc = '',
    this.occupation,
    this.education,
    this.voterId = '',
    this.rationId = '',
    this.phId = '',
    this.beneficiaryType,
    this.ageAtMarriage,
    this.spouseName = '',
    this.hasChildren,
    this.isPregnant,
    this.children,
    this.religion,
    this.childSchool,
    this.birthCertificate,
  });

  UpdateMemberDetailState copyWith({
    // Basic Information
    String? name,
    String? gender,
    DateTime? dob,
    String? age,
    String? relation,
    String? fatherName,
    String? motherName,
    String? mobileNumber,
    String? aadharNumber,
    String? memberType,
    String? richID,
    String? maritalStatus,
    String? mobileOwner,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    int? memberId,
    
    // Additional Fields
    bool? useDob,
    String? updateYear,
    String? updateMonth,
    String? updateDay,
    String? birthOrder,
    String? weight,
    String? category,
    String? abhaAddress,
    String? bankAccount,
    String? ifsc,
    String? occupation,
    String? education,
    String? voterId,
    String? rationId,
    String? phId,
    String? beneficiaryType,
    String? ageAtMarriage,
    String? spouseName,
    String? hasChildren,
    String? isPregnant,
    String? children,
    String? religion,
    String? childSchool,
    String? birthCertificate,
  }) {
    return UpdateMemberDetailState(
      // Basic Information
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      age: age ?? this.age,
      relation: relation ?? this.relation,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      memberType: memberType ?? this.memberType,
      richID: richID ?? this.richID,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      mobileOwner: mobileOwner ?? this.mobileOwner,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      memberId: memberId ?? this.memberId,
      
      // Additional Fields
      useDob: useDob ?? this.useDob,
      updateYear: updateYear ?? this.updateYear,
      updateMonth: updateMonth ?? this.updateMonth,
      updateDay: updateDay ?? this.updateDay,
      birthOrder: birthOrder ?? this.birthOrder,
      weight: weight ?? this.weight,
      category: category ?? this.category,
      abhaAddress: abhaAddress ?? this.abhaAddress,
      bankAccount: bankAccount ?? this.bankAccount,
      ifsc: ifsc ?? this.ifsc,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      voterId: voterId ?? this.voterId,
      rationId: rationId ?? this.rationId,
      phId: phId ?? this.phId,
      beneficiaryType: beneficiaryType ?? this.beneficiaryType,
      ageAtMarriage: ageAtMarriage ?? this.ageAtMarriage,
      spouseName: spouseName ?? this.spouseName,
      hasChildren: hasChildren ?? this.hasChildren,
      isPregnant: isPregnant ?? this.isPregnant,
      children: children ?? this.children,
      religion: religion ?? this.religion,
      childSchool: childSchool ?? this.childSchool,
      birthCertificate: birthCertificate ?? this.birthCertificate,
    );
  }
}
