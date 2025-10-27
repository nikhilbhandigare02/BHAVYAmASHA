import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'hbyc_child_care_event.dart';
part 'hbyc_child_care_state.dart';

class HbycChildCareBloc extends Bloc<HbycChildCareEvent, HbycChildCareState> {
  HbycChildCareBloc() : super(const HbycChildCareInitial()) {
    on<HbycBhramanChanged>((event, emit) => emit(state.copyWith(hbycBhraman: event.value)));
    on<IsChildSickChanged>((event, emit) => emit(state.copyWith(isChildSick: event.value)));
    on<BreastfeedingContinuingChanged>((event, emit) => emit(state.copyWith(breastfeedingContinuing: event.value)));
    on<CompleteDietProvidedChanged>((event, emit) => emit(state.copyWith(completeDietProvided: event.value)));
    on<WeighedByAwwChanged>((event, emit) => emit(state.copyWith(weighedByAww: event.value)));
    on<LengthHeightRecordedChanged>((event, emit) => emit(state.copyWith(lengthHeightRecorded: event.value)));
    on<WeightLessThan3sdReferredChanged>((event, emit) => emit(state.copyWith(weightLessThan3sdReferred: event.value)));
    on<DevelopmentDelaysObservedChanged>((event, emit) => emit(state.copyWith(developmentDelaysObserved: event.value)));
    on<FullyVaccinatedAsPerMcpChanged>((event, emit) => emit(state.copyWith(fullyVaccinatedAsPerMcp: event.value)));
    on<MeaslesVaccineGivenChanged>((event, emit) => emit(state.copyWith(measlesVaccineGiven: event.value)));
    on<VitaminADosageGivenChanged>((event, emit) => emit(state.copyWith(vitaminADosageGiven: event.value)));
    on<OrsPacketAvailableChanged>((event, emit) => emit(state.copyWith(orsPacketAvailable: event.value)));
    on<IronFolicSyrupAvailableChanged>((event, emit) => emit(state.copyWith(ironFolicSyrupAvailable: event.value)));
    on<CounselingExclusiveBf6mChanged>((event, emit) => emit(state.copyWith(counselingExclusiveBf6m: event.value)));
    on<AdviceComplementaryFoodsChanged>((event, emit) => emit(state.copyWith(adviceComplementaryFoods: event.value)));
    on<AdviceHandWashingHygieneChanged>((event, emit) => emit(state.copyWith(adviceHandWashingHygiene: event.value)));
    on<AdviceParentingSupportChanged>((event, emit) => emit(state.copyWith(adviceParentingSupport: event.value)));
    on<CounselingFamilyPlanningChanged>((event, emit) => emit(state.copyWith(counselingFamilyPlanning: event.value)));
    on<AdvicePreparingAdministeringOrsChanged>((event, emit) => emit(state.copyWith(advicePreparingAdministeringOrs: event.value)));
    on<AdviceAdministeringIfaSyrupChanged>((event, emit) => emit(state.copyWith(adviceAdministeringIfaSyrup: event.value)));
    on<CompletionDateChanged>((event, emit) => emit(state.copyWith(completionDate: event.value)));

    on<SubmitForm>((event, emit) async {
      emit(state.copyWith(status: HbycFormStatus.submitting, error: null));
      final errors = <String>[];
      if (state.hbycBhraman.trim().isEmpty) {
        errors.add('hbycBhramanRequired');
      }
      if (errors.isNotEmpty) {
        emit(state.copyWith(status: HbycFormStatus.failure, error: errors.join('\n')));
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      emit(state.copyWith(status: HbycFormStatus.success));
    });
  }
}
