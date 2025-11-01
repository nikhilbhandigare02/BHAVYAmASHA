part of 'kala_azar_bloc.dart';

abstract class KalaAzarEvent extends Equatable {
  const KalaAzarEvent();

  @override
  List<Object?> get props => [];
}

class UpdateKalaAzarField extends KalaAzarEvent {
  final int index;
  final String value;

  const UpdateKalaAzarField(this.index, this.value);

  @override
  List<Object?> get props => [index, value];
}

class SaveKalaAzarData extends KalaAzarEvent {
  const SaveKalaAzarData();
}
