part of 'filariasis_bloc.dart';

abstract class FilariasisEvent extends Equatable {
  const FilariasisEvent();

  @override
  List<Object?> get props => [];
}

class UpdateFilariasisField extends FilariasisEvent {
  final int index;
  final String value;

  const UpdateFilariasisField(this.index, this.value);

  @override
  List<Object?> get props => [index, value];
}

class SaveFilariasisData extends FilariasisEvent {
  const SaveFilariasisData();
}
