part of 'addnewfamilymember_bloc.dart';

abstract class AddnewfamilymemberEvent extends Equatable{
  const AddnewfamilymemberEvent();

  List<Object> get props => [];
}

final class AnmUpdateMemberType extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateMemberType(this.value);
  @override
  List<Object> get props => [value];
}
final class RichIDChanged extends AddnewfamilymemberEvent {
  final String value;
  const RichIDChanged(this.value);
  @override
  List<Object> get props => [value];
}
final class WeightChange extends AddnewfamilymemberEvent {
  final String value;
  const WeightChange(this.value);
  @override
  List<Object> get props => [value];
}
final class BirthCertificateChange extends AddnewfamilymemberEvent {
  final String value;
  const BirthCertificateChange(this.value);
  @override
  List<Object> get props => [value];
}
final class ChildSchoolChange extends AddnewfamilymemberEvent {
  final String value;
  const ChildSchoolChange(this.value);
  @override
  List<Object> get props => [value];
}
final class ChildrenChanged extends AddnewfamilymemberEvent {
  final String value;
  const ChildrenChanged(this.value);
  @override
  List<Object> get props => [value];
}
final class AnmUpdateRelation extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateRelation(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateName extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateName(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateFatherName extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateFatherName(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateMotherName extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateMotherName(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmToggleUseDob extends AddnewfamilymemberEvent {}

final class AnmUpdateDob extends AddnewfamilymemberEvent {
  final DateTime value;
  const AnmUpdateDob(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateApproxAge extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateApproxAge(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateBirthOrder extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateBirthOrder(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateGender extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateGender(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateBankAcc extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateBankAcc(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateIfsc extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateIfsc(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateOccupation extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateOccupation(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateEducation extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateEducation(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateReligion extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateReligion(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateCategory extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateCategory(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateAbhaAddress extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateAbhaAddress(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateMobileOwner extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateMobileOwner(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateMobileNo extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateMobileNo(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateVoterId extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateVoterId(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateRationId extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateRationId(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdatePhId extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdatePhId(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateBeneficiaryType extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateBeneficiaryType(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateMaritalStatus extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateMaritalStatus(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmSubmit extends AddnewfamilymemberEvent {
  const AnmSubmit();
}

// Marital status dependent fields
final class AnmUpdateAgeAtMarriage extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateAgeAtMarriage(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateSpouseName extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateSpouseName(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateHasChildren extends AddnewfamilymemberEvent {
  final String value; // 'Yes' | 'No'
  const AnmUpdateHasChildren(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateIsPregnant extends AddnewfamilymemberEvent {
  final String value; // 'Yes' | 'No'
  const AnmUpdateIsPregnant(this.value);
  @override
  List<Object> get props => [value];
}

// Separate submit for update flow
final class AnmUpdateSubmit extends AddnewfamilymemberEvent {
  const AnmUpdateSubmit();
}
