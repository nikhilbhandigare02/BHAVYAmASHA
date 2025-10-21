part of 'children_bloc.dart';

abstract class ChildrenEvent extends Equatable {
  const ChildrenEvent();
  @override
  List<Object?> get props => [];
}

class ChIncrementBorn extends ChildrenEvent {}
class ChDecrementBorn extends ChildrenEvent {}

class ChIncrementLive extends ChildrenEvent {}
class ChDecrementLive extends ChildrenEvent {}

class ChIncrementMale extends ChildrenEvent {}
class ChDecrementMale extends ChildrenEvent {}

class ChIncrementFemale extends ChildrenEvent {}
class ChDecrementFemale extends ChildrenEvent {}

class ChUpdateYoungestAge extends ChildrenEvent {
  final String value;
  const ChUpdateYoungestAge(this.value);
  @override
  List<Object?> get props => [value];
}

class ChUpdateAgeUnit extends ChildrenEvent {
  final String? value;
  const ChUpdateAgeUnit(this.value);
  @override
  List<Object?> get props => [value];
}

class ChUpdateYoungestGender extends ChildrenEvent {
  final String? value;
  const ChUpdateYoungestGender(this.value);
  @override
  List<Object?> get props => [value];
}
