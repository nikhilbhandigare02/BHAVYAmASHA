part of 'amb_bloc.dart';

abstract class AmbEvent extends Equatable {
  const AmbEvent();

  @override
  List<Object?> get props => [];
}

class UpdateAmbField extends AmbEvent {
  final int index;
  final String value;

  const UpdateAmbField(this.index, this.value);

  @override
  List<Object?> get props => [index, value];
}

class SaveAmbData extends AmbEvent {
  const SaveAmbData();
}
