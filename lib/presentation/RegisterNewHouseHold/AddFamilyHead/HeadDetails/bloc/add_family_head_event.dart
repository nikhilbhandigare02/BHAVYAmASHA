part of 'add_family_head_bloc.dart';

@immutable
sealed class AddFamilyHeadEvent {}

final class AfhToggleUseDob extends AddFamilyHeadEvent {}

final class AfhUpdateHouseNo extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateHouseNo(this.value);
}

final class AfhUpdateHeadName extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateHeadName(this.value);
}
final class AfhABHAChange extends AddFamilyHeadEvent {
  final String value;
  AfhABHAChange(this.value);
}
final class AfhRichIdChange extends AddFamilyHeadEvent {
  final String value;
  AfhRichIdChange(this.value);
}

final class AfhUpdateFatherName extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateFatherName(this.value);
}

final class AfhUpdateDob extends AddFamilyHeadEvent {
  final DateTime? value;
  AfhUpdateDob(this.value);
}
final class EDDChange extends AddFamilyHeadEvent {
  final DateTime? value;
  EDDChange(this.value);
}final class LMPChange extends AddFamilyHeadEvent {
  final DateTime? value;
  LMPChange(this.value);
}

final class AfhUpdateApproxAge extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateApproxAge(this.value);
}

final class UpdateYears extends AddFamilyHeadEvent {
  final String value;
  UpdateYears(this.value);
}

final class UpdateMonths extends AddFamilyHeadEvent {
  final String value;
  UpdateMonths(this.value);
}

final class UpdateDays extends AddFamilyHeadEvent {
  final String value;
  UpdateDays(this.value);
}

final class AfhUpdateGender extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateGender(this.value);
}

final class AfhUpdateOccupation extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateOccupation(this.value);
}

final class AfhUpdateEducation extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateEducation(this.value);
}

final class AfhUpdateReligion extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateReligion(this.value);
}

final class AfhUpdateCategory extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateCategory(this.value);
}

final class AfhUpdateMobileOwner extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateMobileOwner(this.value);
}

final class AfhUpdateMobileNo extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateMobileNo(this.value);
}

final class AfhUpdateVillage extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateVillage(this.value);
}

final class AfhUpdateWard extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateWard(this.value);
}

final class AfhUpdateMohalla extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateMohalla(this.value);
}

final class AfhUpdateBankAcc extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateBankAcc(this.value);
}

final class AfhUpdateIfsc extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateIfsc(this.value);
}

final class AfhUpdateVoterId extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateVoterId(this.value);
}

final class AfhUpdateRationId extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateRationId(this.value);
}

final class AfhUpdatePhId extends AddFamilyHeadEvent {
  final String value;
  AfhUpdatePhId(this.value);
}

final class AfhUpdateBeneficiaryType extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateBeneficiaryType(this.value);
}

final class AfhUpdateMaritalStatus extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateMaritalStatus(this.value);
}
final class ChildrenChanged extends AddFamilyHeadEvent {
  final String? value;
  ChildrenChanged(this.value);
}

final class AfhUpdateAgeAtMarriage extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateAgeAtMarriage(this.value);
}

final class AfhUpdateSpouseName extends AddFamilyHeadEvent {
  final String value;
  AfhUpdateSpouseName(this.value);
}

final class AfhUpdateHasChildren extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateHasChildren(this.value);
}

final class AfhUpdateIsPregnant extends AddFamilyHeadEvent {
  final String? value;
  AfhUpdateIsPregnant(this.value);
}

final class AfhSubmit extends AddFamilyHeadEvent {}

final class AfhHydrate extends AddFamilyHeadEvent {
  final AddFamilyHeadState value;
  AfhHydrate(this.value);
}
