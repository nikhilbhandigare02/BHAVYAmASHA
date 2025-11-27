import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'todays_work_event.dart';
part 'todays_work_state.dart';

class TodaysWorkBloc extends Bloc<TodaysWorkEvent, TodaysWorkState> {
  TodaysWorkBloc() : super(const TodaysWorkState()) {
    on<TwLoad>((event, emit) {
      final toDo = event.toDo < 0 ? 0 : event.toDo;
      // Only clamp completed if toDo is greater than 0
      final completed = toDo > 0 
          ? event.completed.clamp(0, toDo) 
          : event.completed.clamp(0, event.completed);
      emit(state.copyWith(toDo: toDo, completed: completed));
    });
    on<TwUpdateCounts>((event, emit) {
      final toDo = event.toDo < 0 ? 0 : event.toDo;
      // Only clamp completed if toDo is greater than 0
      final completed = toDo > 0 
          ? event.completed.clamp(0, toDo) 
          : event.completed.clamp(0, event.completed);
      emit(state.copyWith(toDo: toDo, completed: completed));
    });
  }
}
