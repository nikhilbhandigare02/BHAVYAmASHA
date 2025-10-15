import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:medixcel_new/data/repositories/GuestBeneficiaryRepository.dart';
import 'guest_beneficiary_search_event.dart';
import 'guest_beneficiary_search_state.dart';

class GuestBeneficiarySearchBloc extends Bloc<GuestBeneficiarySearchEvent, GuestBeneficiarySearchState> {
  final GuestBeneficiaryRepository _repo;

  GuestBeneficiarySearchBloc({required GuestBeneficiaryRepository repo})
      : _repo = repo,
        super(const GuestBeneficiarySearchState()) {
    on<GbsToggleAdvanced>((event, emit) {
      emit(state.copyWith(showAdvanced: !state.showAdvanced));
    });

    on<GbsUpdateBeneficiaryNo>((event, emit) {
      print(event.value);
      emit(state.copyWith(beneficiaryNo: event.value));
    });

    on<GbsUpdateDistrict>((event, emit) {
      print(event.value);
      emit(state.copyWith(district: event.value));
    });

    on<GbsUpdateBlock>((event, emit) {
      emit(state.copyWith(block: event.value));
    });

    on<GbsUpdateCategory>((event, emit) {
      emit(state.copyWith(category: event.value));
    });

    on<GbsUpdateGender>((event, emit) {
      emit(state.copyWith(gender: event.value));
    });

    on<GbsUpdateAge>((event, emit) {
      emit(state.copyWith(age: event.value));
    });

    on<GbsUpdateMobile>((event, emit) {
      emit(state.copyWith(mobileNo: event.value));
    });

    on<GbsSubmitSearch>((event, emit) async {
      emit(state.copyWith(status: GbsStatus.submitting, clearError: true));
      try {
        final payload = <String, dynamic>{
          'beneficiaryNo': state.beneficiaryNo,
          'district': state.district,
          'block': state.block,
          'category': state.category,
          'gender': state.gender,
          'age': state.age,
          'mobileNo': state.mobileNo,
        }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

        await _repo.searchGuestBeneficiaries(payload);
        emit(state.copyWith(status: GbsStatus.success));
      } catch (e) {
        emit(state.copyWith(status: GbsStatus.failure, errorMessage: e.toString()));
      }
    });
  }

}
