part of 'eligible_coule_update_bloc.dart';

abstract class EligibleCouleUpdateEvent extends Equatable {
  const EligibleCouleUpdateEvent();

  @override
  List<Object?> get props => [];
}

class RegistrationDateChanged extends EligibleCouleUpdateEvent {
  final DateTime? date;
  const RegistrationDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class RchIdChanged extends EligibleCouleUpdateEvent {
  final String rchId;
  const RchIdChanged(this.rchId);
  @override
  List<Object?> get props => [rchId];
}

class WomanNameChanged extends EligibleCouleUpdateEvent {
  final String name;
  const WomanNameChanged(this.name);
  @override
  List<Object?> get props => [name];
}

class CurrentAgeChanged extends EligibleCouleUpdateEvent {
  final String age; // keep as string from UI, parse in bloc if needed
  const CurrentAgeChanged(this.age);
  @override
  List<Object?> get props => [age];
}

class AgeAtMarriageChanged extends EligibleCouleUpdateEvent {
  final String age;
  const AgeAtMarriageChanged(this.age);
  @override
  List<Object?> get props => [age];
}

class AddressChanged extends EligibleCouleUpdateEvent {
  final String address;
  const AddressChanged(this.address);
  @override
  List<Object?> get props => [address];
}

class WhoseMobileChanged extends EligibleCouleUpdateEvent {
  final String whose; // Husband/Wife/Other
  const WhoseMobileChanged(this.whose);
  @override
  List<Object?> get props => [whose];
}

class MobileNoChanged extends EligibleCouleUpdateEvent {
  final String mobile;
  const MobileNoChanged(this.mobile);
  @override
  List<Object?> get props => [mobile];
}

class ReligionChanged extends EligibleCouleUpdateEvent {
  final String religion;
  const ReligionChanged(this.religion);
  @override
  List<Object?> get props => [religion];
}

class CategoryChanged extends EligibleCouleUpdateEvent {
  final String category;
  const CategoryChanged(this.category);
  @override
  List<Object?> get props => [category];
}

class TotalChildrenBornChanged extends EligibleCouleUpdateEvent {
  final String value;
  const TotalChildrenBornChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class TotalLiveChildrenChanged extends EligibleCouleUpdateEvent {
  final String value;
  const TotalLiveChildrenChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class TotalMaleChildrenChanged extends EligibleCouleUpdateEvent {
  final String value;
  const TotalMaleChildrenChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class TotalFemaleChildrenChanged extends EligibleCouleUpdateEvent {
  final String value;
  const TotalFemaleChildrenChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class YoungestChildAgeChanged extends EligibleCouleUpdateEvent {
  final String value;
  const YoungestChildAgeChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class YoungestChildAgeUnitChanged extends EligibleCouleUpdateEvent {
  final String unit; // Years/Months
  const YoungestChildAgeUnitChanged(this.unit);
  @override
  List<Object?> get props => [unit];
}

class YoungestChildGenderChanged extends EligibleCouleUpdateEvent {
  final String gender; // Male/Female
  const YoungestChildGenderChanged(this.gender);
  @override
  List<Object?> get props => [gender];
}

class SubmitPressed extends EligibleCouleUpdateEvent {
  const SubmitPressed();
}
