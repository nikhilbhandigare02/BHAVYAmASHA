part of 'malaria_bloc.dart';

class MalariaState extends Equatable {
  final List<String> values;
  final bool isSaved;

  const MalariaState({
    required this.values,
    this.isSaved = false,
  });

  MalariaState copyWith({
    List<String>? values,
    bool? isSaved,
  }) {
    return MalariaState(
      values: values ?? this.values,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [values, isSaved];
}
