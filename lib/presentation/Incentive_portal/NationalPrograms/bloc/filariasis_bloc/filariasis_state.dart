part of 'filariasis_bloc.dart';

class FilariasisState extends Equatable {
  final List<String> values;
  final bool isSaved;

  const FilariasisState({
    required this.values,
    this.isSaved = false,
  });

  FilariasisState copyWith({
    List<String>? values,
    bool? isSaved,
  }) {
    return FilariasisState(
      values: values ?? this.values,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object> get props => [values, isSaved];
}
