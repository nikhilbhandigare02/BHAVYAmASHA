part of 'update_member_detail_bloc.dart';

abstract class UpdateMemberDetailEvent {
  const UpdateMemberDetailEvent();
}

// Initial Event
class UpdateMemberDetailInitialEvent extends UpdateMemberDetailEvent {
  final int memberId;
  const UpdateMemberDetailInitialEvent(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

// Basic Information Events
class UpdateMemberDetailNameChanged extends UpdateMemberDetailEvent {
  final String name;
  const UpdateMemberDetailNameChanged(this.name);
}

class UpdateMemberDetailGenderChanged extends UpdateMemberDetailEvent {
  final String gender;
  const UpdateMemberDetailGenderChanged(this.gender);
}

class UpdateMemberDetailDobChanged extends UpdateMemberDetailEvent {
  final DateTime dob;
  const UpdateMemberDetailDobChanged(this.dob);
}

class UpdateMemberDetailAgeChanged extends UpdateMemberDetailEvent {
  final String age;
  const UpdateMemberDetailAgeChanged(this.age);
}

class UpdateMemberDetailRelationChanged extends UpdateMemberDetailEvent {
  final String relation;
  const UpdateMemberDetailRelationChanged(this.relation);
}

class UpdateMemberDetailFatherNameChanged extends UpdateMemberDetailEvent {
  final String fatherName;
  const UpdateMemberDetailFatherNameChanged(this.fatherName);
}

class UpdateMemberDetailMotherNameChanged extends UpdateMemberDetailEvent {
  final String motherName;
  const UpdateMemberDetailMotherNameChanged(this.motherName);
}

class UpdateMemberDetailMobileNumberChanged extends UpdateMemberDetailEvent {
  final String mobileNumber;
  const UpdateMemberDetailMobileNumberChanged(this.mobileNumber);
}

class UpdateMemberDetailAadharNumberChanged extends UpdateMemberDetailEvent {
  final String aadharNumber;
  const UpdateMemberDetailAadharNumberChanged(this.aadharNumber);
}

class UpdateMemberDetailMemberTypeChanged extends UpdateMemberDetailEvent {
  final String memberType;
  const UpdateMemberDetailMemberTypeChanged(this.memberType);
}

class UpdateMemberDetailRichIDChanged extends UpdateMemberDetailEvent {
  final String richID;
  const UpdateMemberDetailRichIDChanged(this.richID);
}

class UpdateMemberDetailMaritalStatusChanged extends UpdateMemberDetailEvent {
  final String maritalStatus;
  const UpdateMemberDetailMaritalStatusChanged(this.maritalStatus);
}

class UpdateMemberDetailMobileOwnerChanged extends UpdateMemberDetailEvent {
  final String mobileOwner;
  const UpdateMemberDetailMobileOwnerChanged(this.mobileOwner);
}

// Additional Fields Events
class UpdateMemberDetailToggleUseDob extends UpdateMemberDetailEvent {
  const UpdateMemberDetailToggleUseDob();
}

class UpdateMemberDetailYearChanged extends UpdateMemberDetailEvent {
  final String year;
  const UpdateMemberDetailYearChanged(this.year);
}

class UpdateMemberDetailMonthChanged extends UpdateMemberDetailEvent {
  final String month;
  const UpdateMemberDetailMonthChanged(this.month);
}

class UpdateMemberDetailDayChanged extends UpdateMemberDetailEvent {
  final String day;
  const UpdateMemberDetailDayChanged(this.day);
}

class UpdateMemberDetailBirthOrderChanged extends UpdateMemberDetailEvent {
  final String birthOrder;
  const UpdateMemberDetailBirthOrderChanged(this.birthOrder);
}

class UpdateMemberDetailWeightChanged extends UpdateMemberDetailEvent {
  final String weight;
  const UpdateMemberDetailWeightChanged(this.weight);
}

class UpdateMemberDetailCategoryChanged extends UpdateMemberDetailEvent {
  final String category;
  const UpdateMemberDetailCategoryChanged(this.category);
}

class UpdateMemberDetailAbhaAddressChanged extends UpdateMemberDetailEvent {
  final String abhaAddress;
  const UpdateMemberDetailAbhaAddressChanged(this.abhaAddress);
}

class UpdateMemberDetailBankAccountChanged extends UpdateMemberDetailEvent {
  final String bankAccount;
  const UpdateMemberDetailBankAccountChanged(this.bankAccount);
}

class UpdateMemberDetailIfscChanged extends UpdateMemberDetailEvent {
  final String ifsc;
  const UpdateMemberDetailIfscChanged(this.ifsc);
}

class UpdateMemberDetailOccupationChanged extends UpdateMemberDetailEvent {
  final String occupation;
  const UpdateMemberDetailOccupationChanged(this.occupation);
}

class UpdateMemberDetailEducationChanged extends UpdateMemberDetailEvent {
  final String education;
  const UpdateMemberDetailEducationChanged(this.education);
}

class UpdateMemberDetailVoterIdChanged extends UpdateMemberDetailEvent {
  final String voterId;
  const UpdateMemberDetailVoterIdChanged(this.voterId);
}

class UpdateMemberDetailRationIdChanged extends UpdateMemberDetailEvent {
  final String rationId;
  const UpdateMemberDetailRationIdChanged(this.rationId);
}

class UpdateMemberDetailPhIdChanged extends UpdateMemberDetailEvent {
  final String phId;
  const UpdateMemberDetailPhIdChanged(this.phId);
}

class UpdateMemberDetailBeneficiaryTypeChanged extends UpdateMemberDetailEvent {
  final String beneficiaryType;
  const UpdateMemberDetailBeneficiaryTypeChanged(this.beneficiaryType);
}

class UpdateMemberDetailAgeAtMarriageChanged extends UpdateMemberDetailEvent {
  final String ageAtMarriage;
  const UpdateMemberDetailAgeAtMarriageChanged(this.ageAtMarriage);
}

class UpdateMemberDetailSpouseNameChanged extends UpdateMemberDetailEvent {
  final String spouseName;
  const UpdateMemberDetailSpouseNameChanged(this.spouseName);
}

class UpdateMemberDetailHasChildrenChanged extends UpdateMemberDetailEvent {
  final String hasChildren;
  const UpdateMemberDetailHasChildrenChanged(this.hasChildren);
}

class UpdateMemberDetailIsPregnantChanged extends UpdateMemberDetailEvent {
  final String isPregnant;
  const UpdateMemberDetailIsPregnantChanged(this.isPregnant);
}

class UpdateMemberDetailChildrenChanged extends UpdateMemberDetailEvent {
  final String children;
  const UpdateMemberDetailChildrenChanged(this.children);
}

class UpdateMemberDetailReligionChanged extends UpdateMemberDetailEvent {
  final String religion;
  const UpdateMemberDetailReligionChanged(this.religion);
}

class UpdateMemberDetailChildSchoolChanged extends UpdateMemberDetailEvent {
  final String childSchool;
  const UpdateMemberDetailChildSchoolChanged(this.childSchool);
}

class UpdateMemberDetailBirthCertificateChanged extends UpdateMemberDetailEvent {
  final String birthCertificate;
  const UpdateMemberDetailBirthCertificateChanged(this.birthCertificate);
}

// Form Submission Event
class UpdateMemberDetailSubmitEvent extends UpdateMemberDetailEvent {
  const UpdateMemberDetailSubmitEvent();
}
