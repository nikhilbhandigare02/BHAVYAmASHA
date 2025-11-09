part of 'child_tracking_form_bloc.dart';

enum FormStatus { initial, loading, success, failure }

@immutable
class ChildTrackingFormState extends Equatable {
  final FormStatus status;
  final Map<String, dynamic> formData;
  final DateTime birthDate;
  final int currentTabIndex;
  final Map<int, CaseClosureData> tabCaseClosureData;
  final String? errorMessage;
  final int? savedFormId;

  const ChildTrackingFormState({
    required this.status,
    required this.formData,
    required this.birthDate,
    required this.currentTabIndex,
    required this.tabCaseClosureData,
    this.errorMessage,
    this.savedFormId,
  });

  factory ChildTrackingFormState.initial() {
    return ChildTrackingFormState(
      status: FormStatus.initial,
      formData: {},
      birthDate: DateTime.now(),
      currentTabIndex: 0,
      tabCaseClosureData: {},
      errorMessage: null,
      savedFormId: null,
    );
  }

  ChildTrackingFormState copyWith({
    FormStatus? status,
    Map<String, dynamic>? formData,
    DateTime? birthDate,
    int? currentTabIndex,
    Map<int, CaseClosureData>? tabCaseClosureData,
    String? errorMessage,
    int? savedFormId,
    bool clearError = false,
  }) {
    return ChildTrackingFormState(
      status: status ?? this.status,
      formData: formData ?? this.formData,
      birthDate: birthDate ?? this.birthDate,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      tabCaseClosureData: tabCaseClosureData ?? this.tabCaseClosureData,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      savedFormId: savedFormId ?? this.savedFormId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        formData,
        birthDate,
        currentTabIndex,
        tabCaseClosureData,
        errorMessage,
        savedFormId,
      ];
}

class CaseClosureData extends Equatable {
  final bool isCaseClosureChecked;
  final String? selectedClosureReason;
  final String? migrationType;
  final DateTime? dateOfDeath;
  final String? probableCauseOfDeath;
  final String? deathPlace;
  final String? reasonOfDeath;
  final String? otherCause;
  final String? otherReason;
  final bool showOtherCauseField;

  const CaseClosureData({
    this.isCaseClosureChecked = false,
    this.selectedClosureReason,
    this.migrationType,
    this.dateOfDeath,
    this.probableCauseOfDeath,
    this.deathPlace,
    this.reasonOfDeath,
    this.otherCause,
    this.otherReason,
    this.showOtherCauseField = false,
  });

  CaseClosureData copyWith({
    bool? isCaseClosureChecked,
    String? selectedClosureReason,
    String? migrationType,
    DateTime? dateOfDeath,
    String? probableCauseOfDeath,
    String? deathPlace,
    String? reasonOfDeath,
    String? otherCause,
    String? otherReason,
    bool? showOtherCauseField,
  }) {
    return CaseClosureData(
      isCaseClosureChecked: isCaseClosureChecked ?? this.isCaseClosureChecked,
      selectedClosureReason: selectedClosureReason ?? this.selectedClosureReason,
      migrationType: migrationType ?? this.migrationType,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      probableCauseOfDeath: probableCauseOfDeath ?? this.probableCauseOfDeath,
      deathPlace: deathPlace ?? this.deathPlace,
      reasonOfDeath: reasonOfDeath ?? this.reasonOfDeath,
      otherCause: otherCause ?? this.otherCause,
      otherReason: otherReason ?? this.otherReason,
      showOtherCauseField: showOtherCauseField ?? this.showOtherCauseField,
    );
  }

  Map<String, dynamic> toJson() {
    if (!isCaseClosureChecked) {
      return {'is_case_closure': false};
    }

    return {
      'is_case_closure': true,
      'closure_reason': selectedClosureReason,
      'migration_type': migrationType,
      'date_of_death': dateOfDeath?.toIso8601String(),
      'probable_cause_of_death': probableCauseOfDeath,
      'other_cause_of_death': otherCause,
      'death_place': deathPlace,
      'reason_of_death': reasonOfDeath,
      'other_reason': otherReason,
    };
  }

  @override
  List<Object?> get props => [
        isCaseClosureChecked,
        selectedClosureReason,
        migrationType,
        dateOfDeath,
        probableCauseOfDeath,
        deathPlace,
        reasonOfDeath,
        otherCause,
        otherReason,
        showOtherCauseField,
      ];
}
