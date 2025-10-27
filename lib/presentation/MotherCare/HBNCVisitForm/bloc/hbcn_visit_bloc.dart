import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'hbcn_visit_event.dart';
import 'hbcn_visit_state.dart';

class HbncVisitBloc extends Bloc<HbncVisitEvent, HbncVisitState> {
  HbncVisitBloc() : super(const HbncVisitState()) {
    on<TabChanged>(_onTabChanged);
    on<MotherDetailsChanged>(_onMotherDetailsChanged);
    on<NewbornDetailsChanged>(_onNewbornDetailsChanged);
    on<VisitDetailsChanged>(_onVisitDetailsChanged);
    on<SubmitHbncVisit>(_onSubmitHbncVisit);
    on<SaveHbncVisit>(_onSaveHbncVisit);
    on<ResetHbncVisitForm>(_onResetHbncVisitForm);
    on<ValidateSection>(_onValidateSection);
  }

  Future<void> _onSaveHbncVisit(
      SaveHbncVisit event, Emitter<HbncVisitState> emit) async {
    emit(state.copyWith(isSaving: true, saveSuccess: false, errorMessage: null));

    try {
      // Simulate a quick local save/draft
      print('Saving HBNC visit (draft)');
      await Future.delayed(const Duration(milliseconds: 800));
      emit(state.copyWith(isSaving: false, saveSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: 'Failed to save HBNC visit: $e'));
    }
  }

  void _onTabChanged(TabChanged event, Emitter<HbncVisitState> emit) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  void _onMotherDetailsChanged(

      MotherDetailsChanged event, Emitter<HbncVisitState> emit) {
    final updatedDetails = Map<String, dynamic>.from(state.motherDetails);
    updatedDetails[event.field] = event.value;
    emit(state.copyWith(motherDetails: updatedDetails));
  }

  void _onNewbornDetailsChanged(
      NewbornDetailsChanged event, Emitter<HbncVisitState> emit) {
    final updatedDetails = Map<String, dynamic>.from(state.newbornDetails);
    updatedDetails[event.field] = event.value;
    emit(state.copyWith(newbornDetails: updatedDetails));
  }

  void _onVisitDetailsChanged(
      VisitDetailsChanged event, Emitter<HbncVisitState> emit) {
    final updatedDetails = Map<String, dynamic>.from(state.visitDetails);
    updatedDetails[event.field] = event.value;
    emit(state.copyWith(visitDetails: updatedDetails));
  }

  Future<void> _onSubmitHbncVisit(
      SubmitHbncVisit event, Emitter<HbncVisitState> emit) async {
    emit(state.copyWith(isSubmitting: true));

    try {
      print('Mother Details: ' + jsonEncode(state.motherDetails));
      print('Visit Details: ' + jsonEncode(state.visitDetails));
      print('Newborn Details: ' + jsonEncode(state.newbornDetails));
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit HBNC visit: $e',
      ));
    }
  }

  void _onResetHbncVisitForm(
      ResetHbncVisitForm event, Emitter<HbncVisitState> emit) {
    emit(const HbncVisitState());
  }

  void _onValidateSection(
      ValidateSection event, Emitter<HbncVisitState> emit) {
    final List<String> errors = [];
    final idx = event.index;

    if (idx == 0) {
      final v = state.visitDetails;
      if (v['visitNumber'] == null || (v['visitNumber'].toString()).isEmpty) {
        errors.add('Home Visit Day is required');
      }
      if (v['visitDate'] == null) {
        errors.add('Date of home visit is required');
      }
    } else if (idx == 1) {
      final m = state.motherDetails;
      void req(String key, String label) {
        final val = m[key];
        if (val == null || (val is String && val.trim().isEmpty)) {
          errors.add(label);
        }
      }
      req('motherStatus', "Mother's status is required");
      req('mcpCardAvailable', 'MCP card availability is required');
      req('postDeliveryProblems', 'Post-delivery problems is required');
      req('breastfeedingProblems', 'Breastfeeding problems is required');
      req('padsPerDay', 'Pads changed per day is required');
      req('temperature', "Mother's temperature is required");
      req('foulDischargeHighFever', 'Foul discharge/high fever selection is required');
      req('abnormalSpeechOrSeizure', 'Abnormal speech or seizures selection is required');
    } else if (idx == 2) {
      final c = state.newbornDetails;
      void req(String key, String label) {
        final val = c[key];
        if (val == null || (val is String && val.trim().isEmpty)) {
          errors.add(label);
        }
      }
      req('babyCondition', "Baby's condition is required");
      req('babyName', "Baby's name is required");
      req('gender', "Baby's gender is required");
      req('weightAtBirth', "Baby's weight (g) is required");
      req('temperature', 'Temperature is required');
      req('tempUnit', "Infant's temperature unit is required");
      req('weighingScaleColor', 'Weighing Scale Color is required');
    }

    emit(state.copyWith(
      lastValidatedIndex: idx,
      lastValidationWasSave: event.isSave,
      validationErrors: errors,
      validationTick: state.validationTick + 1,
    ));
  }
}
