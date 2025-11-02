import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'amb_event.dart';
part 'amb_state.dart';

class AmbBloc extends Bloc<AmbEvent, AmbState> {
  AmbBloc() : super(const AmbState(values: ["0", "0"])) {
    on<UpdateAmbField>((event, emit) {
      final updatedValues = List<String>.from(state.values);
      updatedValues[event.index] = event.value;
      emit(state.copyWith(values: updatedValues, isSaved: false));
    });

    on<SaveAmbData>((event, emit) {
      emit(state.copyWith(isSaved: true));
    });
  }
}
