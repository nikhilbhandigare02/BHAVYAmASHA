part of 'leprosy_bloc.dart';

abstract class LeprosyEvent extends Equatable {
  const LeprosyEvent();

  @override
  List<Object?> get props => [];
}

class UpdateLeprosyField extends LeprosyEvent {
  final int index;
  final String value;

  const UpdateLeprosyField(this.index, this.value);

  @override
  List<Object?> get props => [index, value];
}

class SaveLeprosyData extends LeprosyEvent {
  const SaveLeprosyData();
}
