import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/utils/enums.dart' show FormStatus;

part 'training_event.dart';
part 'training_state.dart';

class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  TrainingBloc() : super(TrainingState.initial()) {
    on<TrainingTypeChanged>((event, emit) {
      emit(state.copyWith(trainingType: event.type, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<TrainingNameChanged>((event, emit) {
      emit(state.copyWith(trainingName: event.name, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<TrainingDateChanged>((event, emit) {
      emit(state.copyWith(date: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<TrainingPlaceChanged>((event, emit) {
      emit(state.copyWith(place: event.place, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<TrainingDaysChanged>((event, emit) {
      emit(state.copyWith(days: event.days, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<SubmitTraining>((event, emit) async {
      if (!state.isValid) {
        emit(state.copyWith(status: FormStatus.failure, error: 'Please complete all fields correctly.'));
        return;
      }
      emit(state.copyWith(status: FormStatus.submitting, clearError: true));
      // Simulate network call
      await Future.delayed(const Duration(milliseconds: 800));
      emit(state.copyWith(status: FormStatus.success));
    });
  }
}
