part of 'outcome_form_bloc.dart';

abstract class OutcomeFormEvent extends Equatable {
  const OutcomeFormEvent();

  @override
  List<Object?> get props => [];
}

class DeliveryDateChanged extends OutcomeFormEvent {
  final DateTime? date;
  const DeliveryDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class GestationWeeksChanged extends OutcomeFormEvent {
  final String weeks;
  const GestationWeeksChanged(this.weeks);

  @override
  List<Object?> get props => [weeks];
}

class DeliveryTimeChanged extends OutcomeFormEvent {
  final String? time; // hh:mm
  const DeliveryTimeChanged(this.time);

  @override
  List<Object?> get props => [time];
}

class PlaceOfDeliveryChanged extends OutcomeFormEvent {
  final String value;
  const PlaceOfDeliveryChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class DeliveryTypeChanged extends OutcomeFormEvent {
  final String value;
  const DeliveryTypeChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class ComplicationsChanged extends OutcomeFormEvent {
  final String value;
  const ComplicationsChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class OutcomeCountChanged extends OutcomeFormEvent {
  final String value;
  const OutcomeCountChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class FamilyPlanningCounselingChanged extends OutcomeFormEvent {
  final String value;
  const FamilyPlanningCounselingChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class OutcomeFormSubmitted extends OutcomeFormEvent {
  const OutcomeFormSubmitted();
}
