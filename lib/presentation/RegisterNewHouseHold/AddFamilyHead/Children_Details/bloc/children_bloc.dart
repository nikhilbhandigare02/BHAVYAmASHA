import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'children_event.dart';
part 'children_state.dart';

class ChildrenBloc extends Bloc<ChildrenEvent, ChildrenState> {
  ChildrenBloc() : super(const ChildrenState()) {
    // born
    on<ChIncrementBorn>((event, emit) {
      final born = state.totalBorn + 1;
      // Ensure live and gender counts do not exceed born
      final live = state.totalLive.clamp(0, born);
      final male = state.totalMale.clamp(0, live);
      final female = state.totalFemale.clamp(0, live - male);
      emit(state.copyWith(totalBorn: born, totalLive: live, totalMale: male, totalFemale: female));
    });
    on<ChDecrementBorn>((event, emit) {
      final born = (state.totalBorn - 1).clamp(0, 999);
      final live = state.totalLive.clamp(0, born);
      final male = state.totalMale.clamp(0, live);
      final female = state.totalFemale.clamp(0, live - male);
      emit(state.copyWith(totalBorn: born, totalLive: live, totalMale: male, totalFemale: female));
    });

    // live
    on<ChIncrementLive>((event, emit) {
      final live = (state.totalLive + 1).clamp(0, state.totalBorn);
      final male = state.totalMale.clamp(0, live);
      final female = state.totalFemale.clamp(0, live - male);
      emit(state.copyWith(totalLive: live, totalMale: male, totalFemale: female));
    });
    on<ChDecrementLive>((event, emit) {
      final live = (state.totalLive - 1).clamp(0, state.totalBorn);
      final male = state.totalMale.clamp(0, live);
      final female = state.totalFemale.clamp(0, live - male);
      emit(state.copyWith(totalLive: live, totalMale: male, totalFemale: female));
    });

    // male
    on<ChIncrementMale>((event, emit) {
      // Allow male to grow up to totalBorn - totalFemale
      final maxMaleByBorn = state.totalBorn - state.totalFemale;
      final male = (state.totalMale + 1).clamp(0, maxMaleByBorn.clamp(0, 999));
      // Ensure totalLive is at least male + female, but not beyond totalBorn
      final desiredLive = (male + state.totalFemale).clamp(0, state.totalBorn);
      final live = state.totalLive < desiredLive ? desiredLive : state.totalLive;
      emit(state.copyWith(totalMale: male, totalLive: live));
    });
    on<ChDecrementMale>((event, emit) {
      final male = (state.totalMale - 1).clamp(0, 999);
      // Keep totalLive not less than male + female
      final desiredLive = (male + state.totalFemale).clamp(0, state.totalBorn);
      final live = state.totalLive < desiredLive ? desiredLive : state.totalLive;
      emit(state.copyWith(totalMale: male, totalLive: live));
    });

    // female
    on<ChIncrementFemale>((event, emit) {
      // Allow female to grow up to totalBorn - totalMale
      final maxFemaleByBorn = state.totalBorn - state.totalMale;
      final female = (state.totalFemale + 1).clamp(0, maxFemaleByBorn.clamp(0, 999));
      // Ensure totalLive is at least male + female, but not beyond totalBorn
      final desiredLive = (state.totalMale + female).clamp(0, state.totalBorn);
      final live = state.totalLive < desiredLive ? desiredLive : state.totalLive;
      emit(state.copyWith(totalFemale: female, totalLive: live));
    });
    on<ChDecrementFemale>((event, emit) {
      final female = (state.totalFemale - 1).clamp(0, 999);
      // Keep totalLive not less than male + female
      final desiredLive = (state.totalMale + female).clamp(0, state.totalBorn);
      final live = state.totalLive < desiredLive ? desiredLive : state.totalLive;
      emit(state.copyWith(totalFemale: female, totalLive: live));
    });

    // youngest fields
    on<ChUpdateYoungestAge>((event, emit) {
      emit(state.copyWith(youngestAge: event.value));
    });
    on<ChUpdateAgeUnit>((event, emit) {
      emit(state.copyWith(ageUnit: event.value));
    });
    on<ChUpdateYoungestGender>((event, emit) {
      emit(state.copyWith(youngestGender: event.value));
    });
  }
}
