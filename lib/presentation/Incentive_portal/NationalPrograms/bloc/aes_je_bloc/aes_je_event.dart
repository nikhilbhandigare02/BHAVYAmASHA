part of 'aes_je_bloc.dart';

abstract class AesJeEvent extends Equatable {
  const AesJeEvent();

  @override
  List<Object?> get props => [];
}

class UpdateAesJeField extends AesJeEvent {
  final int index;
  final String value;

  const UpdateAesJeField(this.index, this.value);

  @override
  List<Object?> get props => [index, value];
}

class SaveAesJeData extends AesJeEvent {
  const SaveAesJeData();
}
