import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import '../../../../core/utils/enums.dart';

part 'addnewfamilymember_event.dart';
part 'addnewfamilymember_state.dart';
class AddnewfamilymemberBloc
    extends Bloc<AddnewfamilymemberEvent, AddnewfamilymemberState> {
  AddnewfamilymemberBloc() : super( AddnewfamilymemberState()) {
    on<AnmUpdateMemberType>((e, emit) => emit(state.copyWith(memberType: e.value)));
    on<AnmUpdateRelation>((e, emit) => emit(state.copyWith(relation: e.value)));
    on<AnmUpdateName>((e, emit) => emit(state.copyWith(name: e.value)));
    on<AnmUpdateFatherName>((e, emit) => emit(state.copyWith(fatherName: e.value)));
    on<AnmUpdateMotherName>((e, emit) => emit(state.copyWith(motherName: e.value)));
    on<AnmToggleUseDob>((e, emit) {
      final toggled = !(state.useDob);
      emit(state.copyWith(useDob: toggled, clearDob: toggled ? false : false));
    });
    on<AnmUpdateDob>((e, emit) => emit(state.copyWith(dob: e.value)));
    on<AnmUpdateApproxAge>((e, emit) => emit(state.copyWith(approxAge: e.value)));
    on<UpdateDayChanged>((e, emit) => emit(state.copyWith(updateDay: e.value)));
    on<UpdateMonthChanged>((e, emit) => emit(state.copyWith(updateMonth: e.value)));
    on<UpdateYearChanged>((e, emit) => emit(state.copyWith(updateYear: e.value)));
    on<ChildrenChanged>((e, emit) => emit(state.copyWith(children: e.value)));
    on<AnmUpdateBirthOrder>((e, emit) => emit(state.copyWith(birthOrder: e.value)));
    on<AnmUpdateGender>((e, emit) => emit(state.copyWith(gender: e.value)));
    on<AnmUpdateBankAcc>((e, emit) => emit(state.copyWith(bankAcc: e.value)));
    on<RichIDChanged>((e, emit) => emit(state.copyWith(RichIDChanged: e.value)));
    on<AnmUpdateIfsc>((e, emit) => emit(state.copyWith(ifsc: e.value)));
    on<AnmUpdateOccupation>((e, emit) => emit(state.copyWith(occupation: e.value)));
    on<AnmUpdateEducation>((e, emit) => emit(state.copyWith(education: e.value)));
    on<AnmUpdateReligion>((e, emit) => emit(state.copyWith(religion: e.value)));
    on<AnmUpdateCategory>((e, emit) => emit(state.copyWith(category: e.value)));
    on<WeightChange>((e, emit) => emit(state.copyWith(WeightChange: e.value)));
    on<ChildSchoolChange>((e, emit) => emit(state.copyWith(ChildSchool: e.value)));
    on<BirthCertificateChange>((e, emit) => emit(state.copyWith(BirthCertificateChange: e.value)));
    on<AnmUpdateAbhaAddress>((e, emit) => emit(state.copyWith(abhaAddress: e.value)));
    on<AnmUpdateMobileOwner>((e, emit) => emit(state.copyWith(mobileOwner: e.value)));
    on<AnmUpdateMobileNo>((e, emit) => emit(state.copyWith(mobileNo: e.value)));
    on<AnmUpdateVoterId>((e, emit) => emit(state.copyWith(voterId: e.value)));
    on<AnmUpdateRationId>((e, emit) => emit(state.copyWith(rationId: e.value)));
    on<AnmUpdatePhId>((e, emit) => emit(state.copyWith(phId: e.value)));
    on<AnmUpdateBeneficiaryType>((e, emit) => emit(state.copyWith(beneficiaryType: e.value)));
    on<AnmUpdateMaritalStatus>((e, emit) => emit(state.copyWith(maritalStatus: e.value)));
    on<AnmUpdateAgeAtMarriage>((e, emit) => emit(state.copyWith(ageAtMarriage: e.value)));
    on<AnmUpdateSpouseName>((e, emit) => emit(state.copyWith(spouseName: e.value)));
    on<AnmUpdateHasChildren>((e, emit) => emit(state.copyWith(hasChildren: e.value)));
    on<AnmUpdateIsPregnant>((e, emit) => emit(state.copyWith(isPregnant: e.value)));




    on<AnmSubmit>((event, emit) async {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.loading, clearError: true),
      );

      final errors = <String>[];
      if (state.relation == null || state.relation!.trim().isEmpty)
        errors.add('relation with family head is required');
      if (state.name == null || state.name!.trim().isEmpty)
        errors.add('Member name is required');
      if (state.mobileNo == null || state.mobileNo!.trim().length < 10)
        errors.add('Valid mobile no is required');
      if (state.useDob) {
        if (state.dob == null) errors.add('DOB required');
      } else {
        if (state.approxAge == null || state.approxAge!.trim().isEmpty)
          errors.add('Age required');
      }
      if (state.gender == null || state.gender!.isEmpty)
        errors.add('Gender required');
      if (state.maritalStatus == null || state.maritalStatus!.isEmpty) {
        errors.add('Marital status required');
      } else if (state.maritalStatus == 'Married') {
        if (state.spouseName == null || state.spouseName!.trim().isEmpty) {
          errors.add('Spouse Name is required for married status');
        }
      }

      if (errors.isNotEmpty) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: errors.join('\n'),
          ),
        );
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));
      emit(state.copyWith(postApiStatus: PostApiStatus.success));
    });

    // Separate handler for update submit
    on<AnmUpdateSubmit>((event, emit) async {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.loading, clearError: true),
      );

      final errors = <String>[];
      if (state.relation == null || state.relation!.trim().isEmpty)
        errors.add('relation with family head is required');
      if (state.name == null || state.name!.trim().isEmpty)
        errors.add('Member name is required');
      if (state.mobileNo == null || state.mobileNo!.trim().length < 10)
        errors.add('Valid mobile no is required');
      if (state.useDob) {
        if (state.dob == null) errors.add('DOB required');
      } else {
        if (state.approxAge == null || state.approxAge!.trim().isEmpty)
          errors.add('Age required');
      }
      if (state.gender == null || state.gender!.isEmpty)
        errors.add('Gender required');
      if (state.maritalStatus == null || state.maritalStatus!.isEmpty) {
        errors.add('Marital status required');
      } else if (state.maritalStatus == 'Married') {
        if (state.spouseName == null || state.spouseName!.trim().isEmpty) {
          errors.add('Spouse Name is required for married status');
        }
      }

      if (errors.isNotEmpty) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: errors.join('\n'),
          ),
        );
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));
      emit(state.copyWith(postApiStatus: PostApiStatus.success));
    });


  }
}
