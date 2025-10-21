import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'todays_work_event.dart';
part 'todays_work_state.dart';

class TodaysWorkBloc extends Bloc<TodaysWorkEvent, TodaysWorkState> {
  TodaysWorkBloc() : super(const TodaysWorkState()) {
    on<TwLoad>((event, emit) {
      final toDo = event.toDo < 0 ? 0 : event.toDo;
      final completed = event.completed.clamp(0, toDo);
      emit(state.copyWith(toDo: toDo, completed: completed));
    });
    on<TwUpdateCounts>((event, emit) {
      final toDo = event.toDo < 0 ? 0 : event.toDo;
      final completed = event.completed.clamp(0, toDo);
      emit(state.copyWith(toDo: toDo, completed: completed));
    });
  }
}
