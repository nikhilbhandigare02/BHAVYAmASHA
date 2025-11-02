part of 'niddcp_bloc.dart';

class NiddcpState extends Equatable {
  final String value;
  final bool isSaved;

  const NiddcpState({
    required this.value,
    this.isSaved = false,
  });

  NiddcpState copyWith({
    String? value,
    bool? isSaved,
  }) {
    return NiddcpState(
      value: value ?? this.value,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object> get props => [value, isSaved];
}
