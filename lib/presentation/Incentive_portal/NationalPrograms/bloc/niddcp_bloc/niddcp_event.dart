part of 'niddcp_bloc.dart';

abstract class NiddcpEvent extends Equatable {
  const NiddcpEvent();

  @override
  List<Object> get props => [];
}

class UpdateNiddcpValue extends NiddcpEvent {
  final String value;

  const UpdateNiddcpValue(this.value);

  @override
  List<Object> get props => [value];
}

class SaveNiddcpData extends NiddcpEvent {
  const SaveNiddcpData();
}
