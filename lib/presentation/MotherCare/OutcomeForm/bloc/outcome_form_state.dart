part of 'outcome_form_bloc.dart';

class OutcomeFormState extends Equatable {
  final DateTime? deliveryDate;
  final String gestationWeeks;
  final String? deliveryTime;
  final String placeOfDelivery;
  final String deliveryType;
  final String complications;
  final String outcomeCount;
  final String familyPlanningCounseling;
  final bool submitting;
  final bool submitted;
  final String? errorMessage;

  const OutcomeFormState({
    required this.deliveryDate,
    required this.gestationWeeks,
    required this.deliveryTime,
    required this.placeOfDelivery,
    required this.deliveryType,
    required this.complications,
    required this.outcomeCount,
    required this.familyPlanningCounseling,
    required this.submitting,
    required this.submitted,
    required this.errorMessage,
  });

  factory OutcomeFormState.initial() => OutcomeFormState(
        deliveryDate: DateTime.now(),
        gestationWeeks: '',
        deliveryTime: null,
        placeOfDelivery: '',
        deliveryType: '',
        complications: '',
        outcomeCount: '',
        familyPlanningCounseling: '',
        submitting: false,
        submitted: false,
        errorMessage: null,
      );

  OutcomeFormState copyWith({
    DateTime? deliveryDate,
    String? gestationWeeks,
    String? deliveryTime,
    String? placeOfDelivery,
    String? deliveryType,
    String? complications,
    String? outcomeCount,
    String? familyPlanningCounseling,
    bool? submitting,
    bool? submitted,
    String? errorMessage,
  }) {
    return OutcomeFormState(
      deliveryDate: deliveryDate ?? this.deliveryDate,
      gestationWeeks: gestationWeeks ?? this.gestationWeeks,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      placeOfDelivery: placeOfDelivery ?? this.placeOfDelivery,
      deliveryType: deliveryType ?? this.deliveryType,
      complications: complications ?? this.complications,
      outcomeCount: outcomeCount ?? this.outcomeCount,
      familyPlanningCounseling:
          familyPlanningCounseling ?? this.familyPlanningCounseling,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        deliveryDate,
        gestationWeeks,
        deliveryTime,
        placeOfDelivery,
        deliveryType,
        complications,
        outcomeCount,
        familyPlanningCounseling,
        submitting,
        submitted,
        errorMessage,
      ];
}
