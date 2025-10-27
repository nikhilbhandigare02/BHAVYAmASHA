part of 'training_bloc.dart';


class TrainingState extends Equatable {
  final List<String> trainingTypes;
  final List<String> trainingNames;
  final String? trainingType;
  final String? trainingName;
  final DateTime? date;
  final String? place;
  final String? days;
  final FormStatus status;
  final String? error;

  const TrainingState({
    required this.trainingTypes,
    required this.trainingNames,
    this.trainingType,
    this.trainingName,
    this.date,
    this.place,
    this.days,
    this.status = FormStatus.initial,
    this.error,
  });

  factory TrainingState.initial() => TrainingState(
        trainingTypes: const ['Select', 'Orientation', 'Refresher', 'Other'],
        trainingNames: const ['Select', 'Immunization', 'ANC', 'PNC', 'Nutrition'],
        trainingType: null,
        trainingName: null,
        date: null,
        place: null,
        days: null,
        status: FormStatus.initial,
        error: null,
      );

  bool get isValid {
    final d = int.tryParse(days ?? '');
    return (trainingType != null && trainingType!.isNotEmpty && trainingType != 'Select') &&
        (trainingName != null && trainingName!.isNotEmpty && trainingName != 'Select') &&
        date != null &&
        (place != null && place!.trim().isNotEmpty) &&
        d != null && d > 0;
  }

  TrainingState copyWith({
    List<String>? trainingTypes,
    List<String>? trainingNames,
    String? trainingType,
    String? trainingName,
    DateTime? date,
    String? place,
    String? days,
    FormStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return TrainingState(
      trainingTypes: trainingTypes ?? this.trainingTypes,
      trainingNames: trainingNames ?? this.trainingNames,
      trainingType: trainingType ?? this.trainingType,
      trainingName: trainingName ?? this.trainingName,
      date: date ?? this.date,
      place: place ?? this.place,
      days: days ?? this.days,
      status: status ?? (isValid ? FormStatus.valid : this.status),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        trainingTypes,
        trainingNames,
        trainingType,
        trainingName,
        date,
        place,
        days,
        status,
        error,
      ];
}
