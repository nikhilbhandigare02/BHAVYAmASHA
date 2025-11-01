part of 'TB_Bloc.dart';

abstract class TbEvent extends Equatable {
  const TbEvent();

  @override
  List<Object?> get props => [];
}

class UpdateTbField extends TbEvent {
  final int index;
  final String value;

  const UpdateTbField(this.index, this.value);

  @override
  List<Object?> get props => [index, value];
}

class SaveTbData extends TbEvent {}
