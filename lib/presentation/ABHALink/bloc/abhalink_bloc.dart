import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'abhalink_event.dart';
part 'abhalink_state.dart';

class AbhalinkBloc extends Bloc<AbhaLinkEvent, AbhaLinkState> {
  AbhalinkBloc() : super(const AbhalinkInitial()) {
    on<AbhaAddressChanged>((event, emit) {
      emit(state.copyWith(address: event.value, clearError: true, success: false));
    });

    on<AbhaSubmitPressed>((event, emit) async {
      emit(state.copyWith(submitting: true, clearError: true));
      final address = (state.address ?? '').trim();
      if (address.isEmpty) {
        emit(state.copyWith(submitting: false, errorMessage: 'Please enter ABHA Address'));
        return;
      }
      if (address.contains('@')) {
        emit(state.copyWith(submitting: false, errorMessage: 'Enter ABHA without domain'));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
      emit(state.copyWith(submitting: false, success: true));
    });
  }
}
