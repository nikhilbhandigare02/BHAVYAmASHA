part of 'amb_bloc.dart';

class AmbState extends Equatable {
  final List<String> values;
  final bool isSaved;

  const AmbState({
    required this.values,
    this.isSaved = false,
  });

  AmbState copyWith({
    List<String>? values,
    bool? isSaved,
  }) {
    return AmbState(
      values: values ?? this.values,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object> get props => [values, isSaved];
}
