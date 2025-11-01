import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'TB_Event.dart';
part 'TB_State.dart';

class TbBloc extends Bloc<TbEvent, TbState> {
  TbBloc() : super(const TbState(values: ["0", "0", "0", "0"])) {
    on<UpdateTbField>((event, emit) {
      final updatedValues = List<String>.from(state.values);
      updatedValues[event.index] = event.value;
      emit(state.copyWith(values: updatedValues, isSaved: false));
    });

    on<SaveTbData>((event, emit) {
      emit(state.copyWith(isSaved: true));
    });
  }
}
