import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'malaria_event.dart';
part 'malaria_state.dart';

class MalariaBloc extends Bloc<MalariaEvent, MalariaState> {
  MalariaBloc() : super(const MalariaState(values: ["", ""])) {
    on<UpdateMalariaField>((event, emit) {
      final updatedValues = List<String>.from(state.values);
      updatedValues[event.index] = event.value;
      emit(state.copyWith(values: updatedValues, isSaved: false));
    });

    on<SaveMalariaData>((event, emit) {
      emit(state.copyWith(isSaved: true));
    });
  }
}
