part of 'malaria_bloc.dart';

abstract class MalariaEvent extends Equatable {
  const MalariaEvent();

  @override
  List<Object?> get props => [];
}

class UpdateMalariaField extends MalariaEvent {
  final int index;
  final String value;

  const UpdateMalariaField(this.index, this.value);

  @override
  List<Object?> get props => [index, value];
}

class SaveMalariaData extends MalariaEvent {
  const SaveMalariaData();
}
