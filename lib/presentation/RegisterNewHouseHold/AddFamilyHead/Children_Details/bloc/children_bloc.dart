import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'children_event.dart';
part 'children_state.dart';

class ChildrenBloc extends Bloc<ChildrenEvent, ChildrenState> {
  ChildrenBloc() : super(const ChildrenState()) {
    // born
    on<ChIncrementBorn>((event, emit) {
      final born = (state.totalBorn + 1).clamp(0, 999);
      emit(state.copyWith(totalBorn: born));
    });
    on<ChDecrementBorn>((event, emit) {
      final born = (state.totalBorn - 1).clamp(0, 999);
      emit(state.copyWith(totalBorn: born));
    });

    // live
    on<ChIncrementLive>((event, emit) {
      final live = (state.totalLive + 1).clamp(0, 999);
      emit(state.copyWith(totalLive: live));
    });
    on<ChDecrementLive>((event, emit) {
      final live = (state.totalLive - 1).clamp(0, 999);
      emit(state.copyWith(totalLive: live));
    });

    // male
    on<ChIncrementMale>((event, emit) {
      final male = (state.totalMale + 1).clamp(0, 999);
      emit(state.copyWith(totalMale: male));
    });
    on<ChDecrementMale>((event, emit) {
      final male = (state.totalMale - 1).clamp(0, 999);
      emit(state.copyWith(totalMale: male));
    });

    // female
    on<ChIncrementFemale>((event, emit) {
      final female = (state.totalFemale + 1).clamp(0, 999);
      emit(state.copyWith(totalFemale: female));
    });
    on<ChDecrementFemale>((event, emit) {
      final female = (state.totalFemale - 1).clamp(0, 999);
      emit(state.copyWith(totalFemale: female));
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
