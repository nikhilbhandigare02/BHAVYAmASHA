part of 'TB_Bloc.dart';
class TbState extends Equatable {
  final List<String> values;
  final bool isSaved;

  const TbState({
    required this.values,
    this.isSaved = false,
  });

  TbState copyWith({
    List<String>? values,
    bool? isSaved,
  }) {
    return TbState(
      values: values ?? this.values,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [values, isSaved];
}
