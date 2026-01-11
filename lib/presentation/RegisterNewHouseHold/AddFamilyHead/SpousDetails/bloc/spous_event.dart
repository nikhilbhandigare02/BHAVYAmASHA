part of 'spous_bloc.dart';

abstract class SpousEvent extends Equatable {
  const SpousEvent();
  @override
  List<Object?> get props => [];
}

class SpToggleUseDob extends SpousEvent {}

class SpUpdateRelation extends SpousEvent {
  final String? value;
  const SpUpdateRelation(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateMemberName extends SpousEvent {
  final String value;
  const SpUpdateMemberName(this.value);
  @override
  List<Object?> get props => [value];
}

class RchIDChanged extends SpousEvent {
  final String value;
  const RchIDChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateAgeAtMarriage extends SpousEvent {
  final String value;
  const SpUpdateAgeAtMarriage(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateSpouseName extends SpousEvent {
  final String value;
  const SpUpdateSpouseName(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateFatherName extends SpousEvent {
  final String value;
  const SpUpdateFatherName(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateDob extends SpousEvent {
  final DateTime? value;
  const SpUpdateDob(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateApproxAge extends SpousEvent {
  final String value;
  const SpUpdateApproxAge(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateGender extends SpousEvent {
  final String? value;
  const SpUpdateGender(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateOccupation extends SpousEvent {
  final String? value;
  const SpUpdateOccupation(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateOtherOccupation extends SpousEvent {
  final String? value;
  const SpUpdateOtherOccupation(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateEducation extends SpousEvent {
  final String? value;
  const SpUpdateEducation(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateReligion extends SpousEvent {
  final String? value;
  const SpUpdateReligion(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateOtherReligion extends SpousEvent {
  final String? value;
  const SpUpdateOtherReligion(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateCategory extends SpousEvent {
  final String? value;
  const SpUpdateCategory(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateOtherCategory extends SpousEvent {
  final String? value;
  const SpUpdateOtherCategory(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateAbhaAddress extends SpousEvent {
  final String value;
  const SpUpdateAbhaAddress(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateMobileOwner extends SpousEvent {
  final String? value;
  const SpUpdateMobileOwner(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateMobileOwnerOtherRelation extends SpousEvent {
  final String? value;
  const SpUpdateMobileOwnerOtherRelation(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateMobileNo extends SpousEvent {
  final String value;
  const SpUpdateMobileNo(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateBankAcc extends SpousEvent {
  final String value;
  const SpUpdateBankAcc(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateIfsc extends SpousEvent {
  final String value;
  const SpUpdateIfsc(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateVoterId extends SpousEvent {
  final String value;
  const SpUpdateVoterId(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateRationId extends SpousEvent {
  final String value;
  const SpUpdateRationId(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdatePhId extends SpousEvent {
  final String value;
  const SpUpdatePhId(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateBeneficiaryType extends SpousEvent {
  final String? value;
  const SpUpdateBeneficiaryType(this.value);
  @override
  List<Object?> get props => [value];
}

class SpUpdateIsPregnant extends SpousEvent {
  final String? value;
  const SpUpdateIsPregnant(this.value);
  @override
  List<Object?> get props => [value];
}

class FamilyPlanningCounselingChanged extends SpousEvent {
  final String value;
  const FamilyPlanningCounselingChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class FpMethodChanged extends SpousEvent {
  final String value;
  const FpMethodChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class RemovalDateChanged extends SpousEvent {
  final DateTime value;
  const RemovalDateChanged(this.value);
  @override
  List<Object?> get props => [value];
}
class DateofAntraChanged extends SpousEvent {
  final DateTime value;
  const DateofAntraChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class RemovalReasonChanged extends SpousEvent {
  final String value;
  const RemovalReasonChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class CondomQuantityChanged extends SpousEvent {
  final String value;
  const CondomQuantityChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class MalaQuantityChanged extends SpousEvent {
  final String value;
  const MalaQuantityChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class ChhayaQuantityChanged extends SpousEvent {
  final String value;
  const ChhayaQuantityChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class ECPQuantityChanged extends SpousEvent {
  final String value;
  const ECPQuantityChanged(this.value);
  @override
  List<Object?> get props => [value];
}
class UpdateYearsChanged extends SpousEvent {
  final String? value;
  const UpdateYearsChanged(this.value);
  @override
  List<Object?> get props => [value];
}
class UpdateMonthsChanged extends SpousEvent {
  final String? value;
  const UpdateMonthsChanged(this.value);
  @override
  List<Object?> get props => [value];
}
class UpdateDaysChanged extends SpousEvent {
  final String? value;
  const UpdateDaysChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class SpLMPChange extends SpousEvent {
  final DateTime? value;
  const SpLMPChange(this.value);
  @override
  List<Object?> get props => [value];
}

class SpEDDChange extends SpousEvent {
  final DateTime? value;
  const SpEDDChange(this.value);
  @override
  List<Object?> get props => [value];
}

/// Hydrate the spouse state in a single event
class SpHydrate extends SpousEvent {
  final SpousState value;
  const SpHydrate(this.value);
  @override
  List<Object?> get props => [value];
}
