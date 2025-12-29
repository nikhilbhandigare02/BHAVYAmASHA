part of 'outcome_form_bloc.dart';

// Non-institutional delivery events
class NonInstitutionalPlaceTypeChanged extends OutcomeFormEvent {
  final String value;

  const NonInstitutionalPlaceTypeChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class TransitPlaceChanged extends OutcomeFormEvent {
  final String value;

  const TransitPlaceChanged(this.value);

  @override
  List<Object?> get props => [value];
}

// Institutional delivery events
class InstitutionalPlaceTypeChanged extends OutcomeFormEvent {
  final String value;

  const InstitutionalPlaceTypeChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class InstitutionalPlaceOfDeliveryChanged extends OutcomeFormEvent {
  final String value;

  const InstitutionalPlaceOfDeliveryChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class ConductedByChanged extends OutcomeFormEvent {
  final String value;

  const ConductedByChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class OtherConductedByNameChanged extends OutcomeFormEvent {
  final String value;

  const OtherConductedByNameChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class TypeOfDeliveryChanged extends OutcomeFormEvent {
  final String value;

  const TypeOfDeliveryChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class HadComplicationsChanged extends OutcomeFormEvent {
  final String value;

  const HadComplicationsChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class OtherNonInstitutionalPlaceNameChanged extends OutcomeFormEvent {
  final String value;

  const OtherNonInstitutionalPlaceNameChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class OtherPlaceOfDeliveryNameChanged extends OutcomeFormEvent {
  final String value;

  const OtherPlaceOfDeliveryNameChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class OtherTransitPlaceNameChanged extends OutcomeFormEvent {
  final String value;

  const OtherTransitPlaceNameChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class ComplicationTypeChanged extends OutcomeFormEvent {
  final String value;

  const ComplicationTypeChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class OtherComplicationNameChanged extends OutcomeFormEvent {
  final String value;

  const OtherComplicationNameChanged(this.value);

  @override
  List<Object?> get props => [value];
}

@immutable
abstract class OutcomeFormEvent extends Equatable {
  const OutcomeFormEvent();

  @override
  List<Object?> get props => [];
}

class OutcomeFormInitialized extends OutcomeFormEvent {
  final String? householdId;
  final String? beneficiaryId;

  const OutcomeFormInitialized({this.householdId, this.beneficiaryId});

  @override
  List<Object?> get props => [householdId, beneficiaryId];
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
  final String? time;

  const DeliveryTimeChanged(this.time);

  @override
  List<Object?> get props => [time];
}

class DischargeDateChanged extends OutcomeFormEvent {
  final DateTime? date;

  const DischargeDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class DischargeTimeChanged extends OutcomeFormEvent {
  final String? time;

  const DischargeTimeChanged(this.time);

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

class AdaptFpMethodChanged extends OutcomeFormEvent {
  final String value;

  const AdaptFpMethodChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class FpMethodChanged extends OutcomeFormEvent {
  final String? value;

  const FpMethodChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class RemovalDateChanged extends OutcomeFormEvent {
  final DateTime? date;

  const RemovalDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class AntraDateChanged extends OutcomeFormEvent {
  final DateTime? date;

  const AntraDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class RemovalReasonChanged extends OutcomeFormEvent {
  final String? reason;

  const RemovalReasonChanged(this.reason);

  @override
  List<Object?> get props => [reason];
}

class CondomQuantityChanged extends OutcomeFormEvent {
  final String? quantity;

  const CondomQuantityChanged(this.quantity);

  @override
  List<Object?> get props => [quantity];
}

class MalaQuantityChanged extends OutcomeFormEvent {
  final String? quantity;

  const MalaQuantityChanged(this.quantity);

  @override
  List<Object?> get props => [quantity];
}

class ChhayaQuantityChanged extends OutcomeFormEvent {
  final String? quantity;

  const ChhayaQuantityChanged(this.quantity);

  @override
  List<Object?> get props => [quantity];
}

class ECPQuantityChanged extends OutcomeFormEvent {
  final String? quantity;

  const ECPQuantityChanged(this.quantity);

  @override
  List<Object?> get props => [quantity];
}

class OutcomeFormSubmitted extends OutcomeFormEvent {
  final Map<String, dynamic>? beneficiaryData;
  final Map<String, String>? localizedMessages;
  
  const OutcomeFormSubmitted({this.beneficiaryData, this.localizedMessages});
  
  @override
  List<Object?> get props => [beneficiaryData, localizedMessages];
}
