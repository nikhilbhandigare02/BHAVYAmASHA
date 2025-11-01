import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'kala_azar_event.dart';
part 'kala_azar_state.dart';

class KalaAzarBloc extends Bloc<KalaAzarEvent, KalaAzarState> {
  KalaAzarBloc() : super(const KalaAzarState(values: ["", "", ""])) {
    on<UpdateKalaAzarField>((event, emit) {
      final updatedValues = List<String>.from(state.values);
      updatedValues[event.index] = event.value;
      emit(state.copyWith(values: updatedValues, isSaved: false));
    });

    on<SaveKalaAzarData>((event, emit) {
      emit(state.copyWith(isSaved: true));
    });
  }
}
