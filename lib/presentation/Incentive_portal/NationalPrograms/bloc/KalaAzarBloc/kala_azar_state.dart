part of 'kala_azar_bloc.dart';

class KalaAzarState extends Equatable {
  final List<String> values;
  final bool isSaved;

  const KalaAzarState({
    required this.values,
    this.isSaved = false,
  });

  KalaAzarState copyWith({
    List<String>? values,
    bool? isSaved,
  }) {
    return KalaAzarState(
      values: values ?? this.values,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [values, isSaved];
}
