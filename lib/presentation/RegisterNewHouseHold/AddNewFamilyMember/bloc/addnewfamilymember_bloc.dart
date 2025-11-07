import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import '../../../../core/utils/enums.dart';
import '../../../../data/Local_Storage/local_storage_dao.dart';

part 'addnewfamilymember_event.dart';
part 'addnewfamilymember_state.dart';

class AddnewfamilymemberBloc
    extends Bloc<AddnewfamilymemberEvent, AddnewfamilymemberState> {
  final LocalStorageDao _localStorageDao = LocalStorageDao();

  AddnewfamilymemberBloc() : super(AddnewfamilymemberState()) {
    on<AnmUpdateMemberType>(
      (e, emit) => emit(state.copyWith(memberType: e.value)),
    );
    on<AnmUpdateRelation>((e, emit) => emit(state.copyWith(relation: e.value)));
    on<AnmUpdateName>((e, emit) => emit(state.copyWith(name: e.value)));
    on<AnmUpdateFatherName>(
      (e, emit) => emit(state.copyWith(fatherName: e.value)),
    );
    on<AnmUpdateMotherName>(
      (e, emit) => emit(state.copyWith(motherName: e.value)),
    );
    on<AnmToggleUseDob>((e, emit) {
      final toggled = !(state.useDob);
      emit(state.copyWith(
        useDob: toggled,
        // Preserve the existing date when toggling
        dob: toggled ? state.dob : null,
        approxAge: toggled ? null : state.approxAge,
      ));
    });
    on<AnmUpdateDob>((e, emit) {
      emit(state.copyWith(
        dob: e.value,

        approxAge: e.value != null ? null : state.approxAge,
      ));
    });
    on<AnmUpdateApproxAge>(
      (e, emit) => emit(state.copyWith(approxAge: e.value)),
    );
    on<UpdateDayChanged>((e, emit) => emit(state.copyWith(updateDay: e.value)));
    on<UpdateMonthChanged>(
      (e, emit) => emit(state.copyWith(updateMonth: e.value)),
    );
    on<UpdateYearChanged>(
      (e, emit) => emit(state.copyWith(updateYear: e.value)),
    );
    on<ChildrenChanged>((e, emit) => emit(state.copyWith(children: e.value)));
    on<AnmUpdateBirthOrder>(
      (e, emit) => emit(state.copyWith(birthOrder: e.value)),
    );
    on<AnmUpdateGender>((e, emit) => emit(state.copyWith(gender: e.value)));
    on<AnmUpdateBankAcc>((e, emit) => emit(state.copyWith(bankAcc: e.value)));
    on<RichIDChanged>(
      (e, emit) => emit(state.copyWith(RichIDChanged: e.value)),
    );
    on<AnmUpdateIfsc>((e, emit) => emit(state.copyWith(ifsc: e.value)));
    on<AnmUpdateOccupation>(
      (e, emit) => emit(state.copyWith(occupation: e.value)),
    );
    on<AnmUpdateEducation>(
      (e, emit) => emit(state.copyWith(education: e.value)),
    );
    on<AnmUpdateReligion>((e, emit) => emit(state.copyWith(religion: e.value)));
    on<AnmUpdateCategory>((e, emit) => emit(state.copyWith(category: e.value)));
    on<WeightChange>((e, emit) => emit(state.copyWith(WeightChange: e.value)));
    on<ChildSchoolChange>(
      (e, emit) => emit(state.copyWith(ChildSchool: e.value)),
    );
    on<BirthCertificateChange>(
      (e, emit) => emit(state.copyWith(BirthCertificateChange: e.value)),
    );
    on<AnmUpdateAbhaAddress>(
      (e, emit) => emit(state.copyWith(abhaAddress: e.value)),
    );
    on<AnmUpdateMobileOwner>(
      (e, emit) => emit(state.copyWith(mobileOwner: e.value)),
    );
    on<AnmUpdateMobileNo>((e, emit) => emit(state.copyWith(mobileNo: e.value)));
    on<AnmUpdateVoterId>((e, emit) => emit(state.copyWith(voterId: e.value)));
    on<AnmUpdateRationId>((e, emit) => emit(state.copyWith(rationId: e.value)));
    on<AnmUpdatePhId>((e, emit) => emit(state.copyWith(phId: e.value)));
    on<AnmUpdateBeneficiaryType>(
      (e, emit) => emit(state.copyWith(beneficiaryType: e.value)),
    );
    on<AnmUpdateMaritalStatus>(
      (e, emit) => emit(state.copyWith(maritalStatus: e.value)),
    );
    on<AnmUpdateAgeAtMarriage>(
      (e, emit) => emit(state.copyWith(ageAtMarriage: e.value)),
    );
    on<AnmUpdateSpouseName>(

      (e, emit) => emit(state.copyWith(spouseName: e.value)),
    );
    on<AnmUpdateHasChildren>(
      (e, emit) => emit(state.copyWith(hasChildren: e.value)),
    );
    on<AnmUpdateIsPregnant>(
      (e, emit) => emit(state.copyWith(isPregnant: e.value)),
    );
    on<UpdateIsMemberStatus>(
      (e, emit) => emit(state.copyWith(memberStatus: e.value)),
    );
    on<UpdateDateOfDeath>(
      (e, emit) => emit(state.copyWith(dateOfDeath: e.value)),
    );
    on<UpdateReasonOfDeath>(
      (e, emit) => emit(state.copyWith(deathReason: e.value)),
    );
    on<UpdateOtherReasonOfDeath>(
      (e, emit) => emit(state.copyWith(otherDeathReason: e.value)),
    );
    on<UpdateDatePlace>((e, emit) {
      final newState = state.copyWith(deathPlace: e.value);
      emit(newState);
      print('Updated deathPlace: ${newState.deathPlace}');
    });


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

    on<AnmUpdateSubmit>((event, emit) async {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.loading, clearError: true),
      );

      final errors = <String>[];
      if (state.relation == null || state.relation!.trim().isEmpty)
        errors.add('Relation with family head is required');
      if (state.name == null || state.name!.trim().isEmpty)
        errors.add('Member name is required');
      if (state.gender == null || state.gender!.isEmpty)
        errors.add('Gender is required');
      if (state.useDob) {
        if (state.dob == null) errors.add('Date of birth is required');
      } else {
        if (state.approxAge == null || state.approxAge!.trim().isEmpty)
          errors.add('Approximate age is required');
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

      try {
        // Prepare member data
        final memberData = {
          'memberType': state.memberType,
          'name': state.name,
          'relation': state.relation,
          'fatherName': state.fatherName,
          'motherName': state.motherName,
          'gender': state.gender,
          'dob': state.dob?.toIso8601String(),
          'approxAge': state.approxAge,
          'birthOrder': state.birthOrder,
          'maritalStatus': state.maritalStatus,
          'ageAtMarriage': state.ageAtMarriage,
          'spouseName': state.spouseName,
          'hasChildren': state.hasChildren,
          'isPregnant': state.isPregnant,
          'mobileNo': state.mobileNo,
          'mobileOwner': state.mobileOwner,
          'education': state.education,
          'occupation': state.occupation,
          'religion': state.religion,
          'category': state.category,
          'bankAcc': state.bankAcc,
          'ifsc': state.ifsc,
          'voterId': state.voterId,
          'rationId': state.rationId,
          'phId': state.phId,
          'abhaAddress': state.abhaAddress,
          'richId': state.RichIDChanged,
          'birthCertificate': state.BirthCertificateChange,
          'weight': state.WeightChange,
          'school': state.ChildSchool,
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Get the HHID from the event
        final hhid = event.hhid;
        if (hhid.isEmpty) {
          throw Exception('Household ID is required');
        }

        // Get existing beneficiaries for this household
        final beneficiaries = await _localStorageDao.getBeneficiariesByHousehold(hhid);
        
        if (beneficiaries.isNotEmpty) {
          // Find the head of household to update member_details
          final headBeneficiary = beneficiaries.firstWhere(
            (b) => b['beneficiary_info']?['head_details'] != null,
            orElse: () => {},
          );

          if (headBeneficiary.isNotEmpty) {
            // Update existing household with new member
            final updatedBeneficiary = Map<String, dynamic>.from(headBeneficiary);
            var beneficiaryInfo = Map<String, dynamic>.from(updatedBeneficiary['beneficiary_info'] ?? {});
            
            // Initialize member_details if it doesn't exist
            if (beneficiaryInfo['member_details'] == null) {
              beneficiaryInfo['member_details'] = [];
            }
            
            // Add new member to member_details
            (beneficiaryInfo['member_details'] as List).add(memberData);
            
            // Update the beneficiary in local storage
            updatedBeneficiary['beneficiary_info'] = beneficiaryInfo;
            await _localStorageDao.updateBeneficiary(updatedBeneficiary);
          } else {
            // This should not happen as every household should have a head
            throw Exception('No head found for the household');
          }
        } else {
          // This is a new household, create a new entry with this as head
          final newBeneficiary = {
            'household_ref_key': hhid,
            'unique_key': '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().millisecond}',
            'beneficiary_state': 'active',
            'beneficiary_info': {
              'head_details': memberData,
              'member_details': [],
              'spouse_details': null,
              'children_details': null,
            },
            'is_adult': state.memberType == 'Adult' ? 1 : 0,
            'created_date_time': DateTime.now().toIso8601String(),
            'modified_date_time': DateTime.now().toIso8601String(),
            'is_synced': 0,
            'is_deleted': 0,
          };
          
          await _localStorageDao.insertBeneficiary(newBeneficiary);
        }

        emit(state.copyWith(postApiStatus: PostApiStatus.success));
      } catch (e) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: 'Failed to save member: ${e.toString()}',
          ),
        );
      }
    });
  }
}
