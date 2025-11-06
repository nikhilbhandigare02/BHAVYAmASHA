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

class FpAdoptingChanged extends TrackEligibleCoupleEvent {
  final bool? adopting;
  const FpAdoptingChanged(this.adopting);
  @override
  List<Object?> get props => [adopting];
}

class FpAdoptionDateChanged extends TrackEligibleCoupleEvent {
  final DateTime? date;
  const FpAdoptionDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class SubmitTrackForm extends TrackEligibleCoupleEvent {
  const SubmitTrackForm();
  
  @override
  List<Object?> get props => [];
}
