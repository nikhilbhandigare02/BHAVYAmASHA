part of 'hbyc_child_care_bloc.dart';

class BeneficiaryAbsentChanged extends HbycChildCareEvent {
  final String value;
  const BeneficiaryAbsentChanged(this.value);
  @override
  List<Object?> get props => [value];
}
// In hbyc_child_care_event.dart
class WeightForAgeChanged extends HbycChildCareEvent {
  final String value;
  const WeightForAgeChanged(this.value);
  @override List<Object?> get props => [value];
}

class WeightForLengthChanged extends HbycChildCareEvent {
  final String value;
  const WeightForLengthChanged(this.value);
  @override List<Object?> get props => [value];
}

class OrsGivenChanged extends HbycChildCareEvent {
  final String value;
  const OrsGivenChanged(this.value);
  @override List<Object?> get props => [value];
}

class OrsCountChanged extends HbycChildCareEvent {
  final String value;
  const OrsCountChanged(this.value);
  @override List<Object?> get props => [value];
}

class IfaSyrupGivenChanged extends HbycChildCareEvent {
  final String value;
  const IfaSyrupGivenChanged(this.value);
  @override List<Object?> get props => [value];
}

class IfaSyrupCountChanged extends HbycChildCareEvent {
  final String value;
  const IfaSyrupCountChanged(this.value);
  @override List<Object?> get props => [value];
}

class BeneficiaryAbsentReasonChanged extends HbycChildCareEvent {
  final String value;
  const BeneficiaryAbsentReasonChanged(this.value);
  @override
  List<Object?> get props => [value];
}

abstract class HbycChildCareEvent extends Equatable {
  const HbycChildCareEvent();

  @override
  List<Object?> get props => [];
}

class HbycBhramanChanged extends HbycChildCareEvent {
  final String value;
  const HbycBhramanChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class IsChildSickChanged extends HbycChildCareEvent {
  final String value;
  const IsChildSickChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class BreastfeedingContinuingChanged extends HbycChildCareEvent {
  final String value;
  const BreastfeedingContinuingChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class CompleteDietProvidedChanged extends HbycChildCareEvent {
  final String value;
  const CompleteDietProvidedChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class WeighedByAwwChanged extends HbycChildCareEvent {
  final String value;
  const WeighedByAwwChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class LengthHeightRecordedChanged extends HbycChildCareEvent {
  final String value;
  const LengthHeightRecordedChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class WeightLessThan3sdReferredChanged extends HbycChildCareEvent {
  final String value;
  const WeightLessThan3sdReferredChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DevelopmentDelaysObservedChanged extends HbycChildCareEvent {
  final String value;
  const DevelopmentDelaysObservedChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class FullyVaccinatedAsPerMcpChanged extends HbycChildCareEvent {
  final String value;
  const FullyVaccinatedAsPerMcpChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class MeaslesVaccineGivenChanged extends HbycChildCareEvent {
  final String value;
  const MeaslesVaccineGivenChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class VitaminADosageGivenChanged extends HbycChildCareEvent {
  final String value;
  const VitaminADosageGivenChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class OrsPacketAvailableChanged extends HbycChildCareEvent {
  final String value;
  const OrsPacketAvailableChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class IronFolicSyrupAvailableChanged extends HbycChildCareEvent {
  final String value;
  const IronFolicSyrupAvailableChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class CounselingExclusiveBf6mChanged extends HbycChildCareEvent {
  final String value;
  const CounselingExclusiveBf6mChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AdviceComplementaryFoodsChanged extends HbycChildCareEvent {
  final String value;
  const AdviceComplementaryFoodsChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AdviceHandWashingHygieneChanged extends HbycChildCareEvent {
  final String value;
  const AdviceHandWashingHygieneChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AdviceParentingSupportChanged extends HbycChildCareEvent {
  final String value;
  const AdviceParentingSupportChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class CounselingFamilyPlanningChanged extends HbycChildCareEvent {
  final String value;
  const CounselingFamilyPlanningChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AdvicePreparingAdministeringOrsChanged extends HbycChildCareEvent {
  final String value;
  const AdvicePreparingAdministeringOrsChanged(this.value);
  @override
  List<Object?> get props => [value];
}
class FoodFrequency1Changed extends HbycChildCareEvent {
  final String value;
  const FoodFrequency1Changed(this.value);
  @override List<Object?> get props => [value];
}

class FoodFrequency2Changed extends HbycChildCareEvent {
  final String value;
  const FoodFrequency2Changed(this.value);
  @override List<Object?> get props => [value];
}

class FoodFrequency3Changed extends HbycChildCareEvent {
  final String value;
  const FoodFrequency3Changed(this.value);
  @override List<Object?> get props => [value];
}

class FoodFrequency4Changed extends HbycChildCareEvent {
  final String value;
  const FoodFrequency4Changed(this.value);
  @override List<Object?> get props => [value];
}

class AdviceAdministeringIfaSyrupChanged extends HbycChildCareEvent {
  final String value;
  const AdviceAdministeringIfaSyrupChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class CompletionDateChanged extends HbycChildCareEvent {
  final String value; // dd-MM-yyyy
  const CompletionDateChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class SubmitForm extends HbycChildCareEvent {
  final String beneficiaryRefKey;
  final String householdRefKey;
  final String? sicknessDetails;
  final String? referralDetails;
  final String? developmentDelaysDetails;
  
  const SubmitForm({
    required this.beneficiaryRefKey,
    required this.householdRefKey,
    this.sicknessDetails,
    this.referralDetails,
    this.developmentDelaysDetails,
  });
  
  @override
  List<Object?> get props => [
    beneficiaryRefKey, 
    householdRefKey,
    sicknessDetails,
    referralDetails,
    developmentDelaysDetails,
  ];
}
