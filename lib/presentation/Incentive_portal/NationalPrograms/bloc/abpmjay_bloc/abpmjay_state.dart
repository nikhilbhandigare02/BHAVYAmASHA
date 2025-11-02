part of 'abpmjay_bloc.dart';

class AbpmjayState extends Equatable {
  final String value;
  final bool isSaved;

  const AbpmjayState({
    required this.value,
    this.isSaved = false,
  });

  AbpmjayState copyWith({
    String? value,
    bool? isSaved,
  }) {
    return AbpmjayState(
      value: value ?? this.value,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object> get props => [value, isSaved];
}
