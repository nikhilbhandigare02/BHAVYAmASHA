import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'aes_je_event.dart';
part 'aes_je_state.dart';

class AesJeBloc extends Bloc<AesJeEvent, AesJeState> {
  AesJeBloc() : super(const AesJeState(values: ["0", "0"])) {
    on<UpdateAesJeField>((event, emit) {
      final updatedValues = List<String>.from(state.values);
      updatedValues[event.index] = event.value;
      emit(state.copyWith(values: updatedValues, isSaved: false));
    });

    on<SaveAesJeData>((event, emit) {
      emit(state.copyWith(isSaved: true));
    });
  }
}
