part of 'abha_generation_bloc.dart';

abstract class AbhaGenerationEvent extends Equatable {
  const AbhaGenerationEvent();
  @override
  List<Object?> get props => [];
}

class AbhaUpdateMobile extends AbhaGenerationEvent {
  final String value;
  const AbhaUpdateMobile(this.value);
  @override
  List<Object?> get props => [value];
}

class AbhaUpdateAadhaar extends AbhaGenerationEvent {
  final String value;
  const AbhaUpdateAadhaar(this.value);
  @override
  List<Object?> get props => [value];
}

class AbhaToggleConsent extends AbhaGenerationEvent {
  final int index;
  const AbhaToggleConsent(this.index);
  @override
  List<Object?> get props => [index];
}

class AbhaGenerateOtp extends AbhaGenerationEvent {}
