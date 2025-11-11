import 'dart:convert';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:medixcel_new/core/utils/device_info_utils.dart';
import 'package:medixcel_new/core/utils/enums.dart';
import 'package:medixcel_new/core/utils/id_generator_utils.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/data/Local_Storage/tables/beneficiaries_table.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../SpousDetails/bloc/spous_bloc.dart';

part 'add_family_head_event.dart';
part 'add_family_head_state.dart';

class AddFamilyHeadBloc extends Bloc<AddFamilyHeadEvent, AddFamilyHeadState> {
  AddFamilyHeadBloc() : super(AddFamilyHeadState(headUniqueKey: null, spouseUniqueKey: null)) {
    on<AfhHydrate>((event, emit) => emit(event.value));
    
    on<SaveHeadDetails>((event, emit) async {
      // Validate required fields
      final errors = <String>[];
      if (state.houseNo == null || state.houseNo!.trim().isEmpty) {
        errors.add('House No is required');
      }
      if (state.headName == null || state.headName!.trim().isEmpty) {
        errors.add('Head Name is required');
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
        emit(state.copyWith(postApiStatus: PostApiStatus.loading));
        
        // Get database instance from DatabaseProvider
        final database = await DatabaseProvider.instance.database;
        
        // Get device info for ID generation
        final deviceInfo = await DeviceInfo.getDeviceInfo();
        
        // Generate unique key for head if not already generated
        String headKey = state.headUniqueKey ?? await IdGenerator.generateUniqueId(deviceInfo);
        
        // Create head record
        final headRecord = {
          'household_ref_key': state.houseNo,
          'unique_key': headKey,
          'beneficiary_state': 'active',
          'is_adult': 1,
          'is_guest': 0,
          'is_death': 0,
          'is_migrated': 0,
          'is_separated': 0,
          'is_family_planning': 0,
          'beneficiary_info': jsonEncode({
            'head_details': {
              'houseNo': state.houseNo,
              'headName': state.headName,
              'fatherName': state.fatherName,
              'useDob': state.useDob,
              'dob': state.dob?.toIso8601String(),
              'gender': state.gender,
              'maritalStatus': state.maritalStatus,
              'mobileNo': state.mobileNo,
              'mobileOwner': state.mobileOwner,
              'spouseName': state.spouseName,
              'hasChildren': state.hasChildren,
              'isPregnant': state.isPregnant,
              'lmp': state.lmp?.toIso8601String(),
              'edd': state.edd?.toIso8601String(),
            },
          }),
          'created_date_time': DateTime.now().toIso8601String(),
          'modified_date_time': DateTime.now().toIso8601String(),
          'is_synced': 0,
          'is_deleted': 0,
        };
        
        // Save or update head record
        if (state.headUniqueKey == null) {
          await database.insert('beneficiaries', headRecord);
        } else {
          await database.update(
            'beneficiaries',
            headRecord,
            where: 'unique_key = ?',
            whereArgs: [headKey],
          );
        }
        
        emit(state.copyWith(
          postApiStatus: PostApiStatus.success,
          headUniqueKey: headKey,
        ));
        
      } catch (e) {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          errorMessage: 'Failed to save head details: $e',
        ));
      }
    });
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
    on<AfhRichIdChange>(
      (event, emit) => emit(state.copyWith(AfhRichIdChange: event.value)),
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

    on<LMPChange>((event, emit) {
      final lmp = event.value;
      final edd = lmp != null ? lmp.add(const Duration(days: 5)) : null;
      emit(state.copyWith(lmp: lmp, edd: edd));
    });

    on<UpdateYears>((event, emit) {
      emit(state.copyWith(years: event.value));
      // Update approxAge when any of the fields change
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
    });

    on<EDDChange>((event, emit) {
      emit(state.copyWith(edd: event.value));
    });

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
      }

      final isFemale = state.gender == 'Female';
      final isMarried = state.maritalStatus == 'Married';
      if (isFemale && isMarried) {
        if (state.isPregnant == null || state.isPregnant!.isEmpty) {
          errors.add('Is women pregnant is required');
        } else if (state.isPregnant == 'Yes') {
          if (state.lmp == null) errors.add('LMP is required');
          if (state.edd == null) errors.add('EDD is required');
        }
      }

      if (state.maritalStatus == 'Married') {
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

      try {

        final databasesPath = await getDatabasesPath();
        final path = join(databasesPath, 'medixcel.db');
        final database = await openDatabase(path);


        final deviceInfo = await DeviceInfo.getDeviceInfo();
        final idGenerator = IdGenerator();


        final headKey = await IdGenerator.generateUniqueId(deviceInfo);
        String? spouseKey;


        final headRecord = {
          'household_ref_key': state.houseNo,
          'unique_key': headKey,
          'beneficiary_state': 'active',
          'is_adult': 1,
          'is_guest': 0,
          'is_death': 0,
          'is_migrated': 0,
          'is_separated': 0,
          'is_family_planning': 0,
          'beneficiary_info': jsonEncode({
            'head_details': {
              'houseNo': state.houseNo,
              'headName': state.headName,
              'fatherName': state.fatherName,
              'useDob': state.useDob,
              'dob': state.dob?.toIso8601String(),
              'gender': state.gender,
              'maritalStatus': state.maritalStatus,
              'mobileNo': state.mobileNo,
              'mobileOwner': state.mobileOwner,
              'spouseName': state.spouseName,
              'hasChildren': state.hasChildren,
              'isPregnant': state.isPregnant,
              'lmp': state.lmp?.toIso8601String(),
              'edd': state.edd?.toIso8601String(),
            },
          }),
          'created_date_time': DateTime.now().toIso8601String(),
          'modified_date_time': DateTime.now().toIso8601String(),
          'is_synced': 0,
          'is_deleted': 0,
        };

        // Save head record
        await database.insert('beneficiaries', headRecord);

        if (isMarried && state.spouseName != null && state.spouseName!.isNotEmpty) {
          final spBloc = event.spousBloc;
          if (spBloc != null) {
            final spouseState = spBloc.state;
            spouseKey = await IdGenerator.generateUniqueId(deviceInfo);
            
            final spouseRecord = {
              'household_ref_key': state.houseNo,
              'unique_key': spouseKey,
              'beneficiary_state': 'active',
              'is_adult': 1,
              'is_guest': 0,
              'is_death': 0,
              'is_migrated': 0,
              'is_separated': 0,
              'is_family_planning': 0,
              'spouse_key': headKey,
              'beneficiary_info': jsonEncode({
                'spouse_details': {
                  'relation': 'Spouse',
                  'memberName': spouseState.memberName,
                  'spouseName': state.headName,
                  'gender': spouseState.gender,
                  'dob': spouseState.dob?.toIso8601String(),
                  'mobileNo': spouseState.mobileNo,
                  'mobileOwner': spouseState.mobileOwner,
                  'education': spouseState.education,
                  'occupation': spouseState.occupation,
                },
              }),
              'created_date_time': DateTime.now().toIso8601String(),
              'modified_date_time': DateTime.now().toIso8601String(),
              'is_synced': 0,
              'is_deleted': 0,
            };

            // Save spouse record
            await database.insert('beneficiaries', spouseRecord);

            await database.update(
              'beneficiaries',
              {'spouse_key': spouseKey},
              where: 'unique_key = ?',
              whereArgs: [headKey],
            );
          }
        }

        await database.close();

        emit(state.copyWith(
          postApiStatus: PostApiStatus.success,
          headUniqueKey: headKey,
          spouseUniqueKey: spouseKey,
        ));
      } catch (e) {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          errorMessage: 'Failed to save records: $e',
        ));
      }
    });
  }
}
