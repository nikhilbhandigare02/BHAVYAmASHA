part of 'addnewfamilymember_bloc.dart';

abstract class AddnewfamilymemberEvent extends Equatable{
  const AddnewfamilymemberEvent();

  List<Object> get props => [];
}

class LoadBeneficiaryData extends AddnewfamilymemberEvent {
  final String beneficiaryId;
  
  const LoadBeneficiaryData(this.beneficiaryId);
  
  @override
  List<Object> get props => [beneficiaryId];
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
final class BirthWeightChange extends AddnewfamilymemberEvent {
  final String value;
  const BirthWeightChange(this.value);
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

final class AnmUpdateOtherOccupation extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateOtherOccupation(this.value);
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

final class AnmUpdateOtherReligion extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateOtherReligion(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateCategory extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateCategory(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateOtherCategory extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateOtherCategory(this.value);
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

final class AnmUpdateMobileOwnerRelation extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateMobileOwnerRelation(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateOtherRelation extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateOtherRelation(this.value);
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
  final BuildContext context;
  final String? hhid;
  final Map<String, dynamic>? extraData;
  const AnmSubmit(this.context, {this.hhid, this.extraData});

  @override
  List<Object> get props => [context, hhid ?? '', extraData ?? {}];
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

final class AnmLMPChange extends AddnewfamilymemberEvent {
  final DateTime? date;
  const AnmLMPChange(this.date);
  @override
  List<Object> get props => [date ?? DateTime(0)];
}

final class AnmEDDChange extends AddnewfamilymemberEvent {
  final DateTime? date;
  const AnmEDDChange(this.date);
  @override
  List<Object> get props => [date ?? DateTime(0)];
}
final class UpdateYearChanged extends AddnewfamilymemberEvent {
  final String value; // 'Yes' | 'No'
  const UpdateYearChanged(this.value);
  @override
  List<Object> get props => [value];
}
final class UpdateMonthChanged extends AddnewfamilymemberEvent {
  final String value; // 'Yes' | 'No'
  const UpdateMonthChanged(this.value);
  @override
  List<Object> get props => [value];
}
final class UpdateDayChanged extends AddnewfamilymemberEvent {
  final String value; // 'Yes' | 'No'
  const UpdateDayChanged(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateFamilyPlanning extends AddnewfamilymemberEvent {
  final String value; // 'Yes' | 'No' | 'Select'
  const AnmUpdateFamilyPlanning(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmUpdateFamilyPlanningMethod extends AddnewfamilymemberEvent {
  final String value;
  const AnmUpdateFamilyPlanningMethod(this.value);
  @override
  List<Object> get props => [value];
}

// Family planning detailed fields
final class AnmFpMethodChanged extends AddnewfamilymemberEvent {
  final String value;
  const AnmFpMethodChanged(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmFpRemovalDateChanged extends AddnewfamilymemberEvent {
  final DateTime value;
  const AnmFpRemovalDateChanged(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmFpDateOfAntraChanged extends AddnewfamilymemberEvent {
  final DateTime value;
  const AnmFpDateOfAntraChanged(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmFpRemovalReasonChanged extends AddnewfamilymemberEvent {
  final String value;
  const AnmFpRemovalReasonChanged(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmFpCondomQuantityChanged extends AddnewfamilymemberEvent {
  final String value;
  const AnmFpCondomQuantityChanged(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmFpMalaQuantityChanged extends AddnewfamilymemberEvent {
  final String value;
  const AnmFpMalaQuantityChanged(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmFpChhayaQuantityChanged extends AddnewfamilymemberEvent {
  final String value;
  const AnmFpChhayaQuantityChanged(this.value);
  @override
  List<Object> get props => [value];
}

final class AnmFpEcpQuantityChanged extends AddnewfamilymemberEvent {
  final String value;
  const AnmFpEcpQuantityChanged(this.value);
  @override
  List<Object> get props => [value];
}


final class UpdateIsMemberStatus extends AddnewfamilymemberEvent{
  final String value;
  const UpdateIsMemberStatus(this.value);

  @override
  List<Object> get props => [value];
}

final class UpdateDateOfDeath extends AddnewfamilymemberEvent{
  final DateTime value;
  const UpdateDateOfDeath(this.value);

  @override
  List<Object> get props => [value];
}
final class UpdateDatePlace extends AddnewfamilymemberEvent{
  final String value;
  const UpdateDatePlace(this.value);

  @override
  List<Object> get props => [value];
}

final class UpdateOtherDeathPlace extends AddnewfamilymemberEvent{
  final String value;
  const UpdateOtherDeathPlace(this.value);

  @override
  List<Object> get props => [value];
}

final class UpdateReasonOfDeath extends AddnewfamilymemberEvent{
  final String value;
  const UpdateReasonOfDeath(this.value);

  @override
  List<Object> get props => [value];
}
final class UpdateOtherReasonOfDeath extends AddnewfamilymemberEvent{
  final String value;
  const UpdateOtherReasonOfDeath(this.value);

  @override
  List<Object> get props => [value];
}

final class AnmClearAllData extends AddnewfamilymemberEvent {}

final class AnmResetDataClearedFlag extends AddnewfamilymemberEvent {}

final class AnmUpdateSubmit extends AddnewfamilymemberEvent {
  final String hhid;
  const AnmUpdateSubmit({required this.hhid});
  
  @override
  List<Object> get props => [hhid];
}
