part of 'leprosy_bloc.dart';

class LeprosyState extends Equatable {
  final List<String> values;
  final bool isSaved;

  const LeprosyState({
    required this.values,
    this.isSaved = false,
  });

  LeprosyState copyWith({
    List<String>? values,
    bool? isSaved,
  }) {
    return LeprosyState(
      values: values ?? this.values,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [values, isSaved];
}
