import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'spous_event.dart';
part 'spous_state.dart';

class SpousBloc extends Bloc<SpousEvent, SpousState> {
  SpousBloc({SpousState? initial}) : super(initial ?? const SpousState()) {
    on<SpHydrate>((event, emit) => emit(event.value));
    on<SpToggleUseDob>((event, emit) => emit(state.copyWith(useDob: !state.useDob)));

    on<SpUpdateRelation>((event, emit) => emit(state.copyWith(relation: event.value)));
    on<UpdateYearsChanged>((event, emit) => emit(state.copyWith(UpdateYears: event.value)));
    on<UpdateMonthsChanged>((event, emit) => emit(state.copyWith(UpdateMonths: event.value)));
    on<UpdateDaysChanged>((event, emit) => emit(state.copyWith(UpdateDays: event.value)));
    on<SpUpdateMemberName>((event, emit) => emit(state.copyWith(memberName: event.value)));
    on<SpUpdateAgeAtMarriage>((event, emit) => emit(state.copyWith(ageAtMarriage: event.value)));
    on<SpUpdateSpouseName>((event, emit) => emit(state.copyWith(spouseName: event.value)));
    on<SpUpdateFatherName>((event, emit) => emit(state.copyWith(fatherName: event.value)));
    on<SpUpdateDob>((event, emit) => emit(state.copyWith(dob: event.value)));
    on<SpUpdateApproxAge>((event, emit) => emit(state.copyWith(approxAge: event.value)));
    on<SpUpdateGender>((event, emit) => emit(state.copyWith(gender: event.value)));
    on<SpUpdateOccupation>((event, emit) => emit(state.copyWith(occupation: event.value)));
    on<SpUpdateOtherOccupation>((event, emit) =>
        emit(state.copyWith(otherOccupation: event.value)));
    on<SpUpdateEducation>((event, emit) => emit(state.copyWith(education: event.value)));
    on<SpUpdateReligion>((event, emit) => emit(state.copyWith(religion: event.value)));
    on<SpUpdateOtherReligion>((event, emit) =>
        emit(state.copyWith(otherReligion: event.value)));
    on<SpUpdateCategory>((event, emit) => emit(state.copyWith(category: event.value)));
    on<SpUpdateOtherCategory>((event, emit) =>
        emit(state.copyWith(otherCategory: event.value)));
    on<SpUpdateAbhaAddress>((event, emit) => emit(state.copyWith(abhaAddress: event.value)));
    on<SpUpdateMobileOwner>((event, emit) => emit(state.copyWith(mobileOwner: event.value)));
    on<SpUpdateMobileOwnerOtherRelation>((event, emit) =>
        emit(state.copyWith(mobileOwnerOtherRelation: event.value)));
    on<SpUpdateMobileNo>((event, emit) => emit(state.copyWith(mobileNo: event.value)));
    on<SpUpdateBankAcc>((event, emit) => emit(state.copyWith(bankAcc: event.value)));
    on<SpUpdateIfsc>((event, emit) => emit(state.copyWith(ifsc: event.value)));
    on<SpUpdateVoterId>((event, emit) => emit(state.copyWith(voterId: event.value)));
    on<SpUpdateRationId>((event, emit) => emit(state.copyWith(rationId: event.value)));
    on<SpUpdatePhId>((event, emit) => emit(state.copyWith(phId: event.value)));
    on<SpUpdateBeneficiaryType>((event, emit) => emit(state.copyWith(beneficiaryType: event.value)));

    on<SpUpdateIsPregnant>((event, emit) => emit(state.copyWith(isPregnant: event.value)));

    on<SpLMPChange>((event, emit) {
      final lmp = event.value;
      final edd = lmp != null ? lmp.add(const Duration(days: 5)) : null;
      emit(state.copyWith(lmp: lmp, edd: edd));
    });

    on<SpEDDChange>((event, emit) => emit(state.copyWith(edd: event.value)));

    // Family planning fields
    on<FamilyPlanningCounselingChanged>(
        (event, emit) => emit(state.copyWith(familyPlanningCounseling: event.value)));
    on<FpMethodChanged>((event, emit) => emit(state.copyWith(fpMethod: event.value)));
    on<RemovalDateChanged>((event, emit) => emit(state.copyWith(removalDate: event.value)));
    on<DateofAntraChanged>((event, emit) => emit(state.copyWith(antraDate: event.value)));
    on<RemovalReasonChanged>((event, emit) => emit(state.copyWith(removalReason: event.value)));
    on<CondomQuantityChanged>((event, emit) => emit(state.copyWith(condomQuantity: event.value)));
    on<MalaQuantityChanged>((event, emit) => emit(state.copyWith(malaQuantity: event.value)));
    on<ChhayaQuantityChanged>((event, emit) => emit(state.copyWith(chhayaQuantity: event.value)));
    on<ECPQuantityChanged>((event, emit) => emit(state.copyWith(ecpQuantity: event.value)));
  }
}
