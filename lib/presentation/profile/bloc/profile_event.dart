part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}
class RoleIdChanged extends ProfileEvent {
  final int value;
  const RoleIdChanged(this.value);
}
class AshaListCountChanged extends ProfileEvent {
  final int count;
  AshaListCountChanged(this.count);

  @override
  List<Object?> get props => [count];
}


class AreaOfWorkingChanged extends ProfileEvent {
  final String value;
  const AreaOfWorkingChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AshaIdChanged extends ProfileEvent {
  final String value;
  const AshaIdChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AshaNameChanged extends ProfileEvent {
  final String value;
  const AshaNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DobChanged extends ProfileEvent {
  final DateTime? value;
  const DobChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class MobileChanged extends ProfileEvent {
  final String value;
  const MobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AltMobileChanged extends ProfileEvent {
  final String value;
  const AltMobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class FatherSpouseChanged extends ProfileEvent {
  final String value;
  const FatherSpouseChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DojChanged extends ProfileEvent {
  final DateTime? value;
  const DojChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AccountNumberChanged extends ProfileEvent {
  final String value;
  const AccountNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class IfscChanged extends ProfileEvent {
  final String value;
  const IfscChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class StateChanged extends ProfileEvent {
  final String value;
  const StateChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DivisionChanged extends ProfileEvent {
  final String value;
  const DivisionChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DistrictChanged extends ProfileEvent {
  final String value;
  const DistrictChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BlockChanged extends ProfileEvent {
  final String value;
  const BlockChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class PanchayatChanged extends ProfileEvent {
  final String value;
  const PanchayatChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class VillageChanged extends ProfileEvent {
  final String value;
  const VillageChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class TolaChanged extends ProfileEvent {
  final String value;
  const TolaChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class MukhiyaNameChanged extends ProfileEvent {
  final String value;
  const MukhiyaNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class MukhiyaMobileChanged extends ProfileEvent {
  final String value;
  const MukhiyaMobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class HwcNameChanged extends ProfileEvent {
  final String value;
  const HwcNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class HscNameChanged extends ProfileEvent {
  final String value;
  const HscNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class FruNameChanged extends ProfileEvent {
  final String value;
  const FruNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class PhcChcChanged extends ProfileEvent {
  final String value;
  const PhcChcChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class RhSdhDhChanged extends ProfileEvent {
  final String value;
  const RhSdhDhChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class SubmitProfile extends ProfileEvent {
  const SubmitProfile();
}

// Additional fields
class PopulationCoveredChanged extends ProfileEvent {
  final String value;
  const PopulationCoveredChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AshaFacilitatorNameChanged extends ProfileEvent {
  final String value;
  const AshaFacilitatorNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AshaFacilitatorMobileChanged extends ProfileEvent {
  final String value;
  const AshaFacilitatorMobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class ChoNameChanged extends ProfileEvent {
  final String value;
  const ChoNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class ChoMobileChanged extends ProfileEvent {
  final String value;
  const ChoMobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AwwNameChanged extends ProfileEvent {
  final String value;
  const AwwNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AwwMobileChanged extends ProfileEvent {
  final String value;
  const AwwMobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AnganwadiCenterNoChanged extends ProfileEvent {
  final String value;
  const AnganwadiCenterNoChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class Anm1NameChanged extends ProfileEvent {
  final String value;
  const Anm1NameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class Anm1MobileChanged extends ProfileEvent {
  final String value;
  const Anm1MobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class Anm2NameChanged extends ProfileEvent {
  final String value;
  const Anm2NameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class Anm2MobileChanged extends ProfileEvent {
  final String value;
  const Anm2MobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BcmNameChanged extends ProfileEvent {
  final String value;
  const BcmNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BcmMobileChanged extends ProfileEvent {
  final String value;
  const BcmMobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DcmNameChanged extends ProfileEvent {
  final String value;
  const DcmNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DcmMobileChanged extends ProfileEvent {
  final String value;
  const DcmMobileChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class UpdateProfileState extends ProfileEvent {
  final ProfileState newState;
  const UpdateProfileState(this.newState);
  @override
  List<Object?> get props => [newState];
}
