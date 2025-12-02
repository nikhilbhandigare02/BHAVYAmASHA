part of 'register_child_form_bloc.dart';

abstract class RegisterChildFormEvent extends Equatable {
  const RegisterChildFormEvent();
  @override
  List<Object?> get props => [];
}

class RchIdChildChanged extends RegisterChildFormEvent {
  final String value;
  const RchIdChildChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class SerialNumberChanged extends RegisterChildFormEvent {
  final String value;
  const SerialNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DateOfBirthChanged extends RegisterChildFormEvent {
  final DateTime? value;
  const DateOfBirthChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DateOfRegistrationChanged extends RegisterChildFormEvent {
  final DateTime? value;
  const DateOfRegistrationChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class ChildNameChanged extends RegisterChildFormEvent {
  final String value;
  const ChildNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class GenderChanged extends RegisterChildFormEvent {
  final String value;
  const GenderChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class MotherNameChanged extends RegisterChildFormEvent {
  final String value;
  const MotherNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class FatherNameChanged extends RegisterChildFormEvent {
  final String value;
  const FatherNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AddressChanged extends RegisterChildFormEvent {
  final String value;
  const AddressChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class WhoseMobileNumberChanged extends RegisterChildFormEvent {
  final String value;
  const WhoseMobileNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class MobileNumberChanged extends RegisterChildFormEvent {
  final String value;
  const MobileNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class MothersRchIdNumberChanged extends RegisterChildFormEvent {
  final String value;
  const MothersRchIdNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BirthCertificateIssuedChanged extends RegisterChildFormEvent {
  final String value;
  const BirthCertificateIssuedChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BirthCertificateNumberChanged extends RegisterChildFormEvent {
  final String value;
  const BirthCertificateNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class WeightGramsChanged extends RegisterChildFormEvent { 
  final String value;
  const WeightGramsChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BirthWeightGramsChanged extends RegisterChildFormEvent {
  final String value;
  const BirthWeightGramsChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class ReligionChanged extends RegisterChildFormEvent {
  final String value;
  const ReligionChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class CustomReligionChanged extends RegisterChildFormEvent {
  final String value;
  const CustomReligionChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class CasteChanged extends RegisterChildFormEvent {
  final String value;
  const CasteChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class CustomCasteChanged extends RegisterChildFormEvent {
  final String value;
  const CustomCasteChanged(this.value);
  @override
  List<Object?> get props => [value];
}
class SerialNumberOFRegister extends RegisterChildFormEvent {
  final String value;
  const SerialNumberOFRegister(this.value);
  @override
  List<Object?> get props => [value];
}

class SubmitPressed extends RegisterChildFormEvent {
  const SubmitPressed();
}
