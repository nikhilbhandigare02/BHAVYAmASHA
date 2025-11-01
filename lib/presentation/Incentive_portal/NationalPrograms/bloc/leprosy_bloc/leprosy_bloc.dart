import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'leprosy_event.dart';
part 'leprosy_state.dart';

class LeprosyBloc extends Bloc<LeprosyEvent, LeprosyState> {
  LeprosyBloc() : super(const LeprosyState(values: ["0", "0", "0", "0"])) {
    on<UpdateLeprosyField>((event, emit) {
      final updatedValues = List<String>.from(state.values);
      updatedValues[event.index] = event.value;
      emit(state.copyWith(values: updatedValues, isSaved: false));
    });

    on<SaveLeprosyData>((event, emit) {
      emit(state.copyWith(isSaved: true));
    });
  }
}
