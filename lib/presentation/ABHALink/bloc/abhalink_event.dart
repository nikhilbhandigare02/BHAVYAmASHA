part of 'abhalink_bloc.dart';

abstract class AbhaLinkEvent extends Equatable {
  const AbhaLinkEvent();
  @override
  List<Object?> get props => [];
}

class AbhaAddressChanged extends AbhaLinkEvent {
  final String value;
  const AbhaAddressChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class AbhaSubmitPressed extends AbhaLinkEvent {
  const AbhaSubmitPressed();
}
