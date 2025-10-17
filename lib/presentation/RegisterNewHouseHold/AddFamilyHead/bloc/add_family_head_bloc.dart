import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../../../../core/utils/enums.dart';

part 'add_family_head_event.dart';
part 'add_family_head_state.dart';

class AddFamilyHeadBloc extends Bloc<AddFamilyHeadEvent, AddFamilyHeadState> {
  AddFamilyHeadBloc() : super(const AddFamilyHeadState()) {
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
    on<AfhUpdateOccupation>(
      (event, emit) => emit(state.copyWith(occupation: event.value)),
    );
    on<AfhUpdateEducation>(
      (event, emit) => emit(state.copyWith(education: event.value)),
    );
    on<AfhUpdateReligion>(
      (event, emit) => emit(state.copyWith(religion: event.value)),
    );
    on<AfhUpdateCategory>(
      (event, emit) => emit(state.copyWith(category: event.value)),
    );
    on<AfhUpdateMobileOwner>(
      (event, emit) => emit(state.copyWith(mobileOwner: event.value)),
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

    on<AfhSubmit>((event, emit) async {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.loading, clearError: true),
      );

      final errors = <String>[];
      if (state.houseNo == null || state.houseNo!.trim().isEmpty)
        errors.add('House no is required');
      if (state.headName == null || state.headName!.trim().isEmpty)
        errors.add('Head name is required');
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
