part of 'training_bloc.dart';

abstract class TrainingEvent extends Equatable {
  const TrainingEvent();
  @override
  List<Object?> get props => [];
}

class InitializeWithLocalization extends TrainingEvent {
  final AppLocalizations l10n;
  const InitializeWithLocalization(this.l10n);
  @override
  List<Object?> get props => [l10n];
}

class TrainingTypeChanged extends TrainingEvent {
  final String type;
  const TrainingTypeChanged(this.type);
  @override
  List<Object?> get props => [type];
}

class TrainingNameChanged extends TrainingEvent {
  final String name;
  const TrainingNameChanged(this.name);
  @override
  List<Object?> get props => [name];
}

class TrainingDateChanged extends TrainingEvent {
  final DateTime? date;
  const TrainingDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class TrainingPlaceChanged extends TrainingEvent {
  final String place;
  const TrainingPlaceChanged(this.place);
  @override
  List<Object?> get props => [place];
}

class TrainingDaysChanged extends TrainingEvent {
  final String days;
  const TrainingDaysChanged(this.days);
  @override
  List<Object?> get props => [days];
}

class TrainingHouseholdChanged extends TrainingEvent {
  final String householdNumber;
  const TrainingHouseholdChanged(this.householdNumber);
  @override
  List<Object?> get props => [householdNumber];
}

class SubmitTraining extends TrainingEvent {
  const SubmitTraining();
}
