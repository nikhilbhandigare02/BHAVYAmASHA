part of 'todays_work_bloc.dart';

abstract class TodaysWorkEvent extends Equatable {
  const TodaysWorkEvent();
  @override
  List<Object?> get props => [];
}

class TwLoad extends TodaysWorkEvent {
  final int toDo;
  final int completed;
  const TwLoad({required this.toDo, required this.completed});
  @override
  List<Object?> get props => [toDo, completed];
}

class TwUpdateCounts extends TodaysWorkEvent {
  final int toDo;
  final int completed;
  const TwUpdateCounts({required this.toDo, required this.completed});
  @override
  List<Object?> get props => [toDo, completed];
}
