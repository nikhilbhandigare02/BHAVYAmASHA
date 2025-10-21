import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:medixcel_new/core/utils/enums.dart';

part 'abha_generation_event.dart';
part 'abha_generation_state.dart';

class AbhaGenerationBloc extends Bloc<AbhaGenerationEvent, AbhaGenerationState> {
  static const int consentCount = 7;

  AbhaGenerationBloc()
      : super( AbhaGenerationState(consents: List<bool>.filled(consentCount, false))) {
    on<AbhaUpdateMobile>((event, emit) {
      emit(state.copyWith(mobile: event.value));
    });
    on<AbhaUpdateAadhaar>((event, emit) {
      emit(state.copyWith(aadhaar: event.value));
    });
    on<AbhaToggleConsent>((event, emit) {
      final list = List<bool>.from(state.consents);
      if (event.index >= 0 && event.index < list.length) {
        list[event.index] = !list[event.index];
      }
      emit(state.copyWith(consents: list));
    });

    on<AbhaGenerateOtp>((event, emit) async {
      if (!state.isFormValid) {
        emit(state.copyWith(postApiStatus: PostApiStatus.error, errorMessage: 'Please complete all fields and consents.'));
        return;
      }
      emit(state.copyWith(postApiStatus: PostApiStatus.loading, clearError: true));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      emit(state.copyWith(postApiStatus: PostApiStatus.success));
    });
  }
}
