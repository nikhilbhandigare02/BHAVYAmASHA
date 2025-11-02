import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'abpmjay_event.dart';
part 'abpmjay_state.dart';

class AbpmjayBloc extends Bloc<AbpmjayEvent, AbpmjayState> {
  AbpmjayBloc() : super(const AbpmjayState(value: '0')) {
    on<UpdateAbpmjayValue>((event, emit) {
      emit(state.copyWith(value: event.value));
    });

    on<SaveAbpmjayData>((event, emit) {
      emit(state.copyWith(isSaved: true));
    });
  }
}
