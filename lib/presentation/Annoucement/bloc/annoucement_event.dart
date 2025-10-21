part of 'annoucement_bloc.dart';

abstract class AnnoucementEvent extends Equatable {
  const AnnoucementEvent();
  @override
  List<Object?> get props => [];
}

class AnLoad extends AnnoucementEvent {
  const AnLoad();
}

class AnToggleExpand extends AnnoucementEvent {
  final int index;
  const AnToggleExpand(this.index);
  @override
  List<Object?> get props => [index];
}
