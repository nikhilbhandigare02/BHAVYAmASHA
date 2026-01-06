part of 'todays_work_bloc.dart';

class TodaysWorkState extends Equatable {
  const TodaysWorkState({
    this.toDo = 0,
    this.completed = 0,
  });

  final int toDo;
  final int completed;

  int get pending => toDo; // Show to-do count directly as pending visits
  double get progress => toDo == 0 ? 0.0 : (completed / toDo).clamp(0.0, 1.0);

  TodaysWorkState copyWith({int? toDo, int? completed}) {
    return TodaysWorkState(
      toDo: toDo ?? this.toDo,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [toDo, completed];
}
