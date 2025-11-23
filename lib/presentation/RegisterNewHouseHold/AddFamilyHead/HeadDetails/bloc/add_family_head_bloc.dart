import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import '../../../../../core/utils/device_info_utils.dart';
import '../../../../../core/utils/enums.dart';
import '../../../../../core/utils/geolocation_utils.dart';
import '../../../../../core/utils/id_generator_utils.dart';
import '../../../../../data/Local_Storage/User_Info.dart';
import '../../../../../data/Local_Storage/local_storage_dao.dart';
import '../../../../../data/repositories/AddBeneficiary/AddBeneficiaryRepository.dart';
import '../../Children_Details/bloc/children_bloc.dart';
import '../../SpousDetails/bloc/spous_bloc.dart';

part 'add_family_head_event.dart';
part 'add_family_head_state.dart';

class AddFamilyHeadBloc extends Bloc<AddFamilyHeadEvent, AddFamilyHeadState> {
  AddFamilyHeadBloc() : super(AddFamilyHeadState()) {
    on<AfhHydrate>((event, emit) => emit(event.value));
    on<AfhToggleUseDob>((event, emit) {
      emit(state.copyWith(useDob: !state.useDob));
    });

    on<AfhUpdateHouseNo>(
          (event, emit) => emit(state.copyWith(houseNo: event.value)),
    );
    on<AfhUpdateHeadName>(
          (event, emit) => emit(state.copyWith(headName: event.value)),
    );
    on<AfhUpdateFatherName>(
          (event, emit) => emit(state.copyWith(fatherName: event.value)),
    );
    on<AfhUpdateDob>((event, emit) => emit(state.copyWith(dob: event.value)));
    on<AfhUpdateApproxAge>(
          (event, emit) => emit(state.copyWith(approxAge: event.value)),
    );
    on<AfhUpdateGender>(
          (event, emit) => emit(state.copyWith(gender: event.value)),
    );
    on<AfhABHAChange>(
          (event, emit) => emit(state.copyWith(AfhABHAChange: event.value)),
    );
    on<AfhUpdateOccupation>(
          (event, emit) => emit(state.copyWith(occupation: event.value)),
    );
    on<AfhUpdateOtherOccupation>(
          (event, emit) => emit(state.copyWith(otherOccupation: event.value)),
    );
    on<AfhRichIdChange>(
          (event, emit) => emit(state.copyWith(AfhRichIdChange: event.value)),
    );
    on<AfhUpdateEducation>(
          (event, emit) => emit(state.copyWith(education: event.value)),
    );
    on<AfhUpdateReligion>(
          (event, emit) => emit(state.copyWith(religion: event.value)),
    );
    on<AfhUpdateOtherReligion>(
          (event, emit) => emit(state.copyWith(otherReligion: event.value)),
    );
    on<AfhUpdateCategory>(
          (event, emit) => emit(state.copyWith(category: event.value)),
    );
    on<AfhUpdateOtherCategory>(
          (event, emit) => emit(state.copyWith(otherCategory: event.value)),
    );
    on<AfhUpdateMobileOwner>(
          (event, emit) => emit(state.copyWith(mobileOwner: event.value)),
    );
    on<AfhUpdateMobileOwnerOtherRelation>(
          (event, emit) =>
          emit(state.copyWith(mobileOwnerOtherRelation: event.value)),
    );
    on<AfhUpdateMobileNo>(
          (event, emit) => emit(state.copyWith(mobileNo: event.value)),
    );
    on<AfhUpdateVillage>(
          (event, emit) => emit(state.copyWith(village: event.value)),
    );
    on<AfhUpdateWard>((event, emit) => emit(state.copyWith(ward: event.value)));
    on<AfhUpdateMohalla>(
          (event, emit) => emit(state.copyWith(mohalla: event.value)),
    );
    on<AfhUpdateBankAcc>(
          (event, emit) => emit(state.copyWith(bankAcc: event.value)),
    );
    on<AfhUpdateIfsc>((event, emit) => emit(state.copyWith(ifsc: event.value)));
    on<AfhUpdateVoterId>(
          (event, emit) => emit(state.copyWith(voterId: event.value)),
    );
    on<AfhUpdateRationId>(
          (event, emit) => emit(state.copyWith(rationId: event.value)),
    );
    on<AfhUpdatePhId>((event, emit) => emit(state.copyWith(phId: event.value)));
    on<AfhUpdateBeneficiaryType>(
          (event, emit) => emit(state.copyWith(beneficiaryType: event.value)),
    );
    on<AfhUpdateMaritalStatus>(
          (event, emit) => emit(state.copyWith(maritalStatus: event.value)),
    );
    on<ChildrenChanged>(
          (event, emit) => emit(state.copyWith(children: event.value)),
    );
    on<AfhUpdateAgeAtMarriage>(
          (event, emit) => emit(state.copyWith(ageAtMarriage: event.value)),
    );
    on<AfhUpdateSpouseName>(
          (event, emit) => emit(state.copyWith(spouseName: event.value)),
    );
    on<AfhUpdateHasChildren>(
          (event, emit) => emit(state.copyWith(hasChildren: event.value)),
    );
    on<AfhUpdateIsPregnant>(
          (event, emit) => emit(state.copyWith(isPregnant: event.value)),
    );

    on<LMPChange>((event, emit) {
      final lmp = event.value;
      final edd = lmp != null ? lmp.add(const Duration(days: 5)) : null;
      emit(state.copyWith(lmp: lmp, edd: edd));
    });

    on<UpdateYears>((event, emit) {
      emit(state.copyWith(years: event.value));

      final years = event.value;
      final months = state.months ?? '0';
      final days = state.days ?? '0';
      emit(state.copyWith(
        years: years,
        approxAge: '$years years $months months $days days'.trim(),
      ));
    });

    on<UpdateMonths>((event, emit) {
      final months = event.value;
      final years = state.years ?? '0';
      final days = state.days ?? '0';
      emit(state.copyWith(
        months: months,
        approxAge: '$years years $months months $days days'.trim(),
      ));
    });

    on<UpdateDays>((event, emit) {
      final days = event.value;
      final years = state.years ?? '0';
      final months = state.months ?? '0';
      emit(state.copyWith(
        days: days,
        approxAge: '$years years $months months $days days'.trim(),
      ));
    });}
  }
