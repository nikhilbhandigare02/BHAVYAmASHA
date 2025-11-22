part of 'anvvisitform_bloc.dart';

abstract class AnvvisitformEvent extends Equatable {
  const AnvvisitformEvent();

  @override
  List<Object?> get props => [];
}

class VisitTypeChanged extends AnvvisitformEvent {
  final String value;
  const VisitTypeChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class PlaceOfAncChanged extends AnvvisitformEvent {
  final String value;
  const PlaceOfAncChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DateOfInspectionChanged extends AnvvisitformEvent {
  final DateTime? value;
  const DateOfInspectionChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class HouseNumberChanged extends AnvvisitformEvent {
  final String value;
  const HouseNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class WomanNameChanged extends AnvvisitformEvent {
  final String value;
  const WomanNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class HusbandNameChanged extends AnvvisitformEvent {
  final String value;
  const HusbandNameChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class RchNumberChanged extends AnvvisitformEvent {
  final String value;
  const RchNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class LmpDateChanged extends AnvvisitformEvent {
  final DateTime? value;
  const LmpDateChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class EddDateChanged extends AnvvisitformEvent {
  final DateTime? value;
  const EddDateChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class WeeksOfPregnancyChanged extends AnvvisitformEvent {
  final String value;
  const WeeksOfPregnancyChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class GravidaDecremented extends AnvvisitformEvent {
  const GravidaDecremented();
}

class GravidaIncremented extends AnvvisitformEvent {
  const GravidaIncremented();
}

class IsBreastFeedingChanged extends AnvvisitformEvent {
  final String value;
  const IsBreastFeedingChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class Td1DateChanged extends AnvvisitformEvent {
  final DateTime? value;
  const Td1DateChanged(this.value);
}

class Td2DateChanged extends AnvvisitformEvent {
  final DateTime? value;
  const Td2DateChanged(this.value);
}

class TdBoosterDateChanged extends AnvvisitformEvent {
  final DateTime? value;
  const TdBoosterDateChanged(this.value);
}

class FolicAcidTabletsChanged extends AnvvisitformEvent {
  final String value;
  const FolicAcidTabletsChanged(this.value);
}

class PreExistingDiseasesChanged extends AnvvisitformEvent {
  final List<String> selectedDiseases;
  const PreExistingDiseasesChanged(this.selectedDiseases);
  
  @override
  List<Object?> get props => [selectedDiseases];
}

class OtherDiseaseChanged extends AnvvisitformEvent {
  final String value;
  const OtherDiseaseChanged(this.value);
  
  @override
  List<Object?> get props => [value];
}

class WeightChanged extends AnvvisitformEvent {
  final String value;
  const WeightChanged(this.value);
}

class SystolicChanged extends AnvvisitformEvent {
  final String value;
  const SystolicChanged(this.value);
}

class DiastolicChanged extends AnvvisitformEvent {
  final String value;
  const DiastolicChanged(this.value);
}

class HemoglobinChanged extends AnvvisitformEvent {
  final String value;
  const HemoglobinChanged(this.value);
}

class HighRiskChanged extends AnvvisitformEvent {
  final String value;
  const HighRiskChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class SelectedRisksChanged extends AnvvisitformEvent {
  final List<String> selectedRisks;
  const SelectedRisksChanged(this.selectedRisks);
  @override
  List<Object?> get props => [selectedRisks];
}

class HasAbortionComplicationChanged extends AnvvisitformEvent {
  final String value;
  const HasAbortionComplicationChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AbortionDateChanged extends AnvvisitformEvent {
  final DateTime? value;
  const AbortionDateChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BeneficiaryAbsentChanged extends AnvvisitformEvent {
  final String value;
  const BeneficiaryAbsentChanged(this.value);
  
  @override
  List<Object?> get props => [value];
}

class AbsenceReasonChanged extends AnvvisitformEvent {
  final String value;
  const AbsenceReasonChanged(this.value);
  
  @override
  List<Object?> get props => [value];
}

class GivesBirthToBaby extends AnvvisitformEvent {
  final String value;
  const GivesBirthToBaby(this.value);
  
  @override
  List<Object?> get props => [value];
}

class VisitNumberChanged extends AnvvisitformEvent {
  final String visitNumber;
  const VisitNumberChanged(this.visitNumber);
  @override
  List<Object?> get props => [visitNumber];
}

class BeneficiaryIdSet extends AnvvisitformEvent {
  final String beneficiaryId;
  const BeneficiaryIdSet(this.beneficiaryId);

  @override
  List<Object?> get props => [beneficiaryId];
}


class NumberOfChildrenChanged extends AnvvisitformEvent {
  final String value;
  NumberOfChildrenChanged(this.value);
}

class Baby1NameChanged extends AnvvisitformEvent { final String value; Baby1NameChanged(this.value); }
class Baby1GenderChanged extends AnvvisitformEvent { final String value; Baby1GenderChanged(this.value); }
class Baby1WeightChanged extends AnvvisitformEvent { final String value; Baby1WeightChanged(this.value); }

class Baby2NameChanged extends AnvvisitformEvent { final String value; Baby2NameChanged(this.value); }
class Baby2GenderChanged extends AnvvisitformEvent { final String value; Baby2GenderChanged(this.value); }
class Baby2WeightChanged extends AnvvisitformEvent { final String value; Baby2WeightChanged(this.value); }

class Baby3NameChanged extends AnvvisitformEvent { final String value; Baby3NameChanged(this.value); }
class Baby3GenderChanged extends AnvvisitformEvent { final String value; Baby3GenderChanged(this.value); }
class Baby3WeightChanged extends AnvvisitformEvent { final String value; Baby3WeightChanged(this.value); }

class DeliveryOutcomeChanged extends AnvvisitformEvent {
  final String? value;
  const DeliveryOutcomeChanged(this.value);

  @override
  List<Object?> get props => [value];
}

class SubmitPressed extends AnvvisitformEvent {
  const SubmitPressed();
}
