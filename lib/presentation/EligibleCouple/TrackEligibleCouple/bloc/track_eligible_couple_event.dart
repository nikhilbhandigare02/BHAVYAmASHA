part of 'track_eligible_couple_bloc.dart';

abstract class TrackEligibleCoupleEvent extends Equatable {
  const TrackEligibleCoupleEvent();
  @override
  List<Object?> get props => [];
}

class VisitDateChanged extends TrackEligibleCoupleEvent {
  final DateTime? date;
  const VisitDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class IsPregnantChanged extends TrackEligibleCoupleEvent {
  final bool isPregnant;
  const IsPregnantChanged(this.isPregnant);
  @override
  List<Object?> get props => [isPregnant];
}

class LmpDateChanged extends TrackEligibleCoupleEvent {
  final DateTime? date;
  const LmpDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class EddDateChanged extends TrackEligibleCoupleEvent {
  final DateTime? date;
  const EddDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class FpMethodChanged extends TrackEligibleCoupleEvent {
  final String method;
  const FpMethodChanged(this.method);
  @override
  List<Object?> get props => [method];
}
class CondomQuantity extends TrackEligibleCoupleEvent {
  final String value;
  const CondomQuantity(this.value);
  @override
  List<Object?> get props => [value];
}
class ChayaQuantity extends TrackEligibleCoupleEvent {
  final String value;
  const ChayaQuantity(this.value);
  @override
  List<Object?> get props => [value];
}
class MalaQuantity extends TrackEligibleCoupleEvent {
  final String value;
  const MalaQuantity(this.value);
  @override
  List<Object?> get props => [value];
}
class ECPQuantity extends TrackEligibleCoupleEvent {
  final String value;
  const ECPQuantity(this.value);
  @override
  List<Object?> get props => [value];
}
class RemovalReasonChanged extends TrackEligibleCoupleEvent {
  final String method;
  const RemovalReasonChanged(this.method);
  @override
  List<Object?> get props => [method];
}

class FpAdoptingChanged extends TrackEligibleCoupleEvent {
  final bool? adopting;
  const FpAdoptingChanged(this.adopting);
  @override
  List<Object?> get props => [adopting];
}
class BeneficiaryAbsentCHanged extends TrackEligibleCoupleEvent {
  final bool? value;
  const BeneficiaryAbsentCHanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BeneficiaryAbsentReasonChanged extends TrackEligibleCoupleEvent {
  final String reason;
  const BeneficiaryAbsentReasonChanged(this.reason);
  @override
  List<Object?> get props => [reason];
}

class FpAdoptionDateChanged extends TrackEligibleCoupleEvent {
  final DateTime? date;
  const FpAdoptionDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class FpAntraInjectionDateChanged extends TrackEligibleCoupleEvent {
  final DateTime? date;
  const FpAntraInjectionDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}
class RemovalDAteChange extends TrackEligibleCoupleEvent {
  final DateTime? date;
  const RemovalDAteChange(this.date);
  @override
  List<Object?> get props => [date];
}

class SubmitTrackForm extends TrackEligibleCoupleEvent {
  const SubmitTrackForm();
  @override
  List<Object?> get props => [];
}

class LoadPreviousFormData extends TrackEligibleCoupleEvent {
  final Map<String, dynamic> formData;
  const LoadPreviousFormData(this.formData);
  @override
  List<Object?> get props => [formData];
}