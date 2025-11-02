part of 'aes_je_bloc.dart';

class AesJeState extends Equatable {
  final List<String> values;
  final bool isSaved;

  const AesJeState({
    required this.values,
    this.isSaved = false,
  });

  AesJeState copyWith({
    List<String>? values,
    bool? isSaved,
  }) {
    return AesJeState(
      values: values ?? this.values,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object> get props => [values, isSaved];
}
