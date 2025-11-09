part of 'child_tracking_form_bloc.dart';

@immutable
abstract class ChildTrackingFormEvent extends Equatable {
  const ChildTrackingFormEvent();

  @override
  List<Object?> get props => [];
}

class LoadFormData extends ChildTrackingFormEvent {
  final Map<String, dynamic> formData;

  const LoadFormData(this.formData);

  @override
  List<Object?> get props => [formData];
}

class WeightChanged extends ChildTrackingFormEvent {
  final String weightKg;

  const WeightChanged(this.weightKg);

  @override
  List<Object?> get props => [weightKg];
}

class TabChanged extends ChildTrackingFormEvent {
  final int tabIndex;

  const TabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class CaseClosureToggled extends ChildTrackingFormEvent {
  final int tabIndex;
  final bool isChecked;

  const CaseClosureToggled(this.tabIndex, this.isChecked);

  @override
  List<Object?> get props => [tabIndex, isChecked];
}

class ClosureReasonChanged extends ChildTrackingFormEvent {
  final int tabIndex;
  final String? reason;

  const ClosureReasonChanged(this.tabIndex, this.reason);

  @override
  List<Object?> get props => [tabIndex, reason];
}

class MigrationTypeChanged extends ChildTrackingFormEvent {
  final int tabIndex;
  final String? migrationType;

  const MigrationTypeChanged(this.tabIndex, this.migrationType);

  @override
  List<Object?> get props => [tabIndex, migrationType];
}

class DateOfDeathChanged extends ChildTrackingFormEvent {
  final int tabIndex;
  final DateTime? date;

  const DateOfDeathChanged(this.tabIndex, this.date);

  @override
  List<Object?> get props => [tabIndex, date];
}

class ProbableCauseOfDeathChanged extends ChildTrackingFormEvent {
  final int tabIndex;
  final String? cause;

  const ProbableCauseOfDeathChanged(this.tabIndex, this.cause);

  @override
  List<Object?> get props => [tabIndex, cause];
}

class DeathPlaceChanged extends ChildTrackingFormEvent {
  final int tabIndex;
  final String? place;

  const DeathPlaceChanged(this.tabIndex, this.place);

  @override
  List<Object?> get props => [tabIndex, place];
}

class ReasonOfDeathChanged extends ChildTrackingFormEvent {
  final int tabIndex;
  final String? reason;

  const ReasonOfDeathChanged(this.tabIndex, this.reason);

  @override
  List<Object?> get props => [tabIndex, reason];
}

class OtherCauseChanged extends ChildTrackingFormEvent {
  final int tabIndex;
  final String otherCause;

  const OtherCauseChanged(this.tabIndex, this.otherCause);

  @override
  List<Object?> get props => [tabIndex, otherCause];
}

class OtherReasonChanged extends ChildTrackingFormEvent {
  final int tabIndex;
  final String otherReason;

  const OtherReasonChanged(this.tabIndex, this.otherReason);

  @override
  List<Object?> get props => [tabIndex, otherReason];
}

class SubmitForm extends ChildTrackingFormEvent {
  final int currentTabIndex;

  const SubmitForm(this.currentTabIndex);

  @override
  List<Object?> get props => [currentTabIndex];
}
