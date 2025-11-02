import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'filariasis_event.dart';
part 'filariasis_state.dart';

class FilariasisBloc extends Bloc<FilariasisEvent, FilariasisState> {
  FilariasisBloc() : super(const FilariasisState(values: ["0", "0"])) {
    on<UpdateFilariasisField>((event, emit) {
      final updatedValues = List<String>.from(state.values);
      updatedValues[event.index] = event.value;
      emit(state.copyWith(values: updatedValues, isSaved: false));
    });

    on<SaveFilariasisData>((event, emit) {
      emit(state.copyWith(isSaved: true));
    });
  }
}
