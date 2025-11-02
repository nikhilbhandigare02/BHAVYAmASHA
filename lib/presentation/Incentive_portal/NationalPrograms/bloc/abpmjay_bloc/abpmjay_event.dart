part of 'abpmjay_bloc.dart';

abstract class AbpmjayEvent extends Equatable {
  const AbpmjayEvent();

  @override
  List<Object> get props => [];
}

class UpdateAbpmjayValue extends AbpmjayEvent {
  final String value;

  const UpdateAbpmjayValue(this.value);

  @override
  List<Object> get props => [value];
}

class SaveAbpmjayData extends AbpmjayEvent {
  const SaveAbpmjayData();
}
