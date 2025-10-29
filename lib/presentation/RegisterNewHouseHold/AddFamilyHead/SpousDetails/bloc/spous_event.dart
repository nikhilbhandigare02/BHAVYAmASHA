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

class RichIDChanged extends SpousEvent {
  final String value;
  const RichIDChanged(this.value);
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

class SpUpdateCategory extends SpousEvent {
  final String? value;
  const SpUpdateCategory(this.value);
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
