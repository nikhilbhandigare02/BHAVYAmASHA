import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'outcome_form_event.dart';
part 'outcome_form_state.dart';

class OutcomeFormBloc extends Bloc<OutcomeFormEvent, OutcomeFormState> {
  OutcomeFormBloc() : super(OutcomeFormState.initial()) {
    on<DeliveryDateChanged>((event, emit) {
      emit(state.copyWith(deliveryDate: event.date, errorMessage: null));
    });
    on<GestationWeeksChanged>((event, emit) {
      emit(state.copyWith(gestationWeeks: event.weeks, errorMessage: null));
    });
    on<DeliveryTimeChanged>((event, emit) {
      emit(state.copyWith(deliveryTime: event.time, errorMessage: null));
    });
    on<PlaceOfDeliveryChanged>((event, emit) {
      emit(state.copyWith(placeOfDelivery: event.value, errorMessage: null));
    });
    on<DeliveryTypeChanged>((event, emit) {
      emit(state.copyWith(deliveryType: event.value, errorMessage: null));
    });
    on<ComplicationsChanged>((event, emit) {
      emit(state.copyWith(complications: event.value, errorMessage: null));
    });
    on<OutcomeCountChanged>((event, emit) {
      emit(state.copyWith(outcomeCount: event.value, errorMessage: null));
    });
    on<FamilyPlanningCounselingChanged>((event, emit) {
      emit(state.copyWith(familyPlanningCounseling: event.value, errorMessage: null));
    });
    on<OutcomeFormSubmitted>((event, emit) async {
      // Clear any previous submission state
      emit(state.copyWith(submitted: false));

      // Validate mandatory fields
      final isPlaceInvalid = state.placeOfDelivery.isEmpty || state.placeOfDelivery == 'चुनें';
      final isCompInvalid = state.complications.isEmpty || state.complications == 'चुनें';
      final isOutcomeInvalid = state.outcomeCount.isEmpty || int.tryParse(state.outcomeCount) == null;

      // Check all validations and collect all errors
      String? errorMessage;
      if (state.deliveryDate == null) {
        errorMessage = 'प्रसव की तिथि आवश्यक है।';
      } else if (isPlaceInvalid) {
        errorMessage = 'डिलिवरी का स्थान आवश्यक है।';
      } else if (isCompInvalid) {
        errorMessage = 'जटिलता चयन आवश्यक है।';
      } else if (isOutcomeInvalid) {
        errorMessage = 'प्रसव का परिणाम (संख्या) आवश्यक है।';
      }

      // If there are validation errors, show them and stop submission
      if (errorMessage != null) {
        emit(state.copyWith(
          errorMessage: errorMessage,
          submitted: false,
          submitting: false,
        ));
        return;
      }

      // If validation passes, proceed with form submission
      emit(state.copyWith(submitting: true, errorMessage: null));

      try {
        // Simulate API call
        await Future<void>.delayed(const Duration(milliseconds: 300));

        // On success
        emit(state.copyWith(
          submitting: false,
          submitted: true,
          errorMessage: null,
        ));
      } catch (e) {
        // On error
        emit(state.copyWith(
          submitting: false,
          errorMessage: 'An error occurred: $e',
        ));
      }
    });
  }
}
