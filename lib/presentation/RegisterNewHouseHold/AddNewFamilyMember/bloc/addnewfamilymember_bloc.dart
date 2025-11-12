import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import '../../../../core/utils/device_info_utils.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/geolocation_utils.dart';
import '../../../../core/utils/id_generator_utils.dart';
import '../../../../data/Local_Storage/User_Info.dart';
import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../AddFamilyHead/Children_Details/bloc/children_bloc.dart' show ChildrenBloc;
import '../../AddFamilyHead/SpousDetails/bloc/spous_bloc.dart';

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
      emit(
        state.copyWith(
          useDob: toggled,
          // Preserve the existing date when toggling
          dob: toggled ? state.dob : null,
          approxAge: toggled ? null : state.approxAge,
        ),
      );
    });
    on<AnmUpdateDob>((e, emit) {
      emit(
        state.copyWith(
          dob: e.value,

          approxAge: e.value != null ? null : state.approxAge,
        ),
      );
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
        errors.add('Relation with family head is required');
      if (state.name == null || state.name!.trim().isEmpty)
        errors.add('Member name is required');
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

      try {
        final now = DateTime.now();
        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        final deviceInfo = await DeviceInfo.getDeviceInfo();

        // Fetch the latest household from database
        final households = await LocalStorageDao.instance.getAllHouseholds();
        if (households.isEmpty) {
          emit(
            state.copyWith(
              postApiStatus: PostApiStatus.error,
              errorMessage: 'No household found. Please create a household first.',
            ),
          );
          return;
        }

        final beneficiaries = await LocalStorageDao.instance.getAllBeneficiaries();
        if (beneficiaries.isEmpty) {
          throw Exception('No existing beneficiary found to derive keys. Add a member first.');
        }
        final latestBeneficiary = beneficiaries.first;
        final uniqueKey = (latestBeneficiary['household_ref_key'] ?? '').toString();
        final memberId = await IdGenerator.generateUniqueId(deviceInfo);
        final spousKey = await IdGenerator.generateUniqueId(deviceInfo);
        // Get current user info
        final currentUser = await UserInfo.getCurrentUser();
        final facilityId = currentUser?['asha_associated_with_facility_id'] ?? 0;

        final geoLocation = await GeoLocation.getCurrentLocation();
        final locationData = Map<String, String>.from(geoLocation.toJson());
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        final geoLocationJson = jsonEncode(locationData);



        int isAdult = 0;
        if (state.memberType == 'Adult') {
          isAdult = 1;
        } else if (state.useDob && state.dob != null) {
          final age = DateTime.now().difference(state.dob!).inDays ~/ 365;
          isAdult = age >= 18 ? 1 : 0;
        }

        final isDeath = (state.memberStatus?.toLowerCase() == 'death') ? 1 : 0;

        final deathDetails = isDeath == 1
            ? {
                'dateOfDeath': state.dateOfDeath?.toIso8601String(),
                'deathReason': state.deathReason,
                'otherDeathReason': state.otherDeathReason,
                'deathPlace': state.deathPlace,
              }
            : {};

        Map<String, dynamic> childrenData = {};
        try {
          final childrenBloc = BlocProvider.of<ChildrenBloc>(event.context);
          final childrenState = childrenBloc.state;

          childrenData = {
            'totalBorn': childrenState.totalBorn,
            'totalLive': childrenState.totalLive,
            'totalMale': childrenState.totalMale,
            'totalFemale': childrenState.totalFemale,
            'youngestAge': childrenState.youngestAge,
            'ageUnit': childrenState.ageUnit,
            'youngestGender': childrenState.youngestGender,
            'children': childrenState.children,
          };
        } catch (e) {
          print('Error getting children data: $e');
        }

        // Resolve parent keys when relation is 'Mother' or 'Father'
        String? resolvedMotherKey;
        String? resolvedFatherKey;
        try {
          if (state.relation == 'Mother' || state.relation == 'Father') {
            // Prefer filtered DAO call to avoid type mismatches and get pre-decoded JSON
            final hhBeneficiaries = await LocalStorageDao.instance
                .getBeneficiariesByHousehold(uniqueKey.toString());

            Map<String, dynamic>? headRecord;
            for (final b in hhBeneficiaries) {
              try {
                final info = b['beneficiary_info'] is Map
                    ? Map<String, dynamic>.from(b['beneficiary_info'])
                    : <String, dynamic>{};
                final relToHead = (info['relation_to_head'] ?? '').toString().toLowerCase();
                final rel = (info['relation'] ?? '').toString().toLowerCase();
                if (relToHead == 'self' || rel == 'head') {
                  headRecord = b as Map<String, dynamic>;
                  break;
                }
              } catch (_) {}
            }
            if (headRecord != null) {
              final headUnique = (headRecord['unique_key'] ?? '').toString();
              String? spouseKeyLocal = headRecord['spouse_key']?.toString();
              if (spouseKeyLocal == null || spouseKeyLocal.isEmpty) {
                // Fallback: find spouse where spouse_key matches head unique_key
                try {
                  for (final b in hhBeneficiaries) {
                    if ((b['spouse_key'] ?? '').toString() == headUnique) {
                      spouseKeyLocal = (b['unique_key'] ?? '').toString();
                      break;
                    }
                  }
                } catch (_) {}
              }

              if (state.relation == 'Mother') {
                resolvedMotherKey = headUnique;
                resolvedFatherKey = spouseKeyLocal;
              } else if (state.relation == 'Father') {
                resolvedFatherKey = headUnique;
                resolvedMotherKey = spouseKeyLocal;
              }
            }
          }
        } catch (_) {}

        final memberPayload = {
          'server_id': null,
          'household_ref_key': uniqueKey,
          'unique_key': memberId,
          'beneficiary_state': 'active',
          'pregnancy_count': 0,
          'beneficiary_info': jsonEncode({
            'memberType': state.memberType,
            'relation': state.relation,
            'name': state.name,
            'fatherName': state.fatherName,
            'motherName': state.motherName,
            'useDob': state.useDob,
            'dob': state.dob?.toIso8601String(),
            'approxAge': state.approxAge,
            'updateDay': state.updateDay,
            'updateMonth': state.updateMonth,
            'updateYear': state.updateYear,
            'children': state.children,
            'birthOrder': state.birthOrder,
            'gender': state.gender,
            'bankAcc': state.bankAcc,
            'ifsc': state.ifsc,
            'occupation': state.occupation,
            'education': state.education,
            'religion': state.religion,
            'category': state.category,
            'weight': state.WeightChange,
            'childSchool': state.ChildSchool,
            'birthCertificate': state.BirthCertificateChange,
            'abhaAddress': state.abhaAddress,
            'mobileOwner': state.mobileOwner,
            'mobileNo': state.mobileNo,
            'voterId': state.voterId,
            'rationId': state.rationId,
            'phId': state.phId,
            'beneficiaryType': state.beneficiaryType,
            'maritalStatus': state.maritalStatus,
            'ageAtMarriage': state.ageAtMarriage,
            'spouseName': state.spouseName,
            'hasChildren': state.hasChildren,
            'isPregnant': state.isPregnant,
            'memberStatus': state.memberStatus,
            'relation_to_head': state.relation,
            ...childrenData,
          }),
          'geo_location': geoLocationJson,
          'spouse_key': null,
          'mother_key': resolvedMotherKey,
          'father_key': resolvedFatherKey,
          'is_family_planning': 0,
          'is_adult': isAdult,
          'is_guest': 0,
          'is_death': isDeath,
          'death_details': jsonEncode(deathDetails),
          'is_migrated': 0,
          'is_separated': 0,
          'device_details': jsonEncode({
            'id': deviceInfo.deviceId,
            'platform': deviceInfo.platform,
            'version': deviceInfo.osVersion,
          }),
          'app_details': jsonEncode({
            'app_version': deviceInfo.appVersion.split('+').first,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
          }),
          'parent_user': jsonEncode({}),
          'current_user_key': 'local_user',
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        print('Saving new family member with payload: ${jsonEncode(memberPayload)}');
        await LocalStorageDao.instance.insertBeneficiary(memberPayload);



        if (state.maritalStatus == 'Married' && state.spouseName != null) {
          try {
            final spousBloc = BlocProvider.of<SpousBloc>(event.context);
            final spousState = spousBloc.state;


            final spousePayload = {
              'server_id': null,
              'household_ref_key': uniqueKey,
              'unique_key': spousKey,
              'beneficiary_state': 'active',
              'pregnancy_count': 0,
              'beneficiary_info': jsonEncode({
                'relation': spousState.relation ?? 'spouse',
                'memberName': spousState.memberName ?? state.spouseName,
                'ageAtMarriage': spousState.ageAtMarriage,
                'RichIDChanged': spousState.RichIDChanged,
                'spouseName': spousState.spouseName,
                'fatherName': spousState.fatherName,
                'useDob': spousState.useDob,
                'dob': spousState.dob?.toIso8601String(),
                'edd': spousState.edd?.toIso8601String(),
                'lmp': spousState.lmp?.toIso8601String(),
                'approxAge': spousState.approxAge,
                'gender': spousState.gender ?? (state.gender == 'Male' ? 'Female' : 'Male'),
                'occupation': spousState.occupation,
                'education': spousState.education,
                'religion': spousState.religion,
                'category': spousState.category,
                'abhaAddress': spousState.abhaAddress,
                'mobileOwner': spousState.mobileOwner,
                'mobileNo': spousState.mobileNo,
                'bankAcc': spousState.bankAcc,
                'ifsc': spousState.ifsc,
                'voterId': spousState.voterId,
                'rationId': spousState.rationId,
                'phId': spousState.phId,
                'beneficiaryType': spousState.beneficiaryType,
                'isPregnant': spousState.isPregnant,
                'relation_to_head': 'spouse',
                ...childrenData,
              }),
              'geo_location': geoLocationJson,
              'spouse_key': memberId,
              'mother_key': null,
              'father_key': null,
              'is_family_planning': 0,
              'is_adult': 1,
              'is_guest': 0,
              'is_death': 0,
              'death_details': jsonEncode({}),
              'is_migrated': 0,
              'is_separated': 0,
              'device_details': jsonEncode({
                'id': deviceInfo.deviceId,
                'platform': deviceInfo.platform,
                'version': deviceInfo.osVersion,
              }),
              'app_details': jsonEncode({
                'app_version': deviceInfo.appVersion.split('+').first,
                'app_name': deviceInfo.appName,
                'build_number': deviceInfo.buildNumber,
                'package_name': deviceInfo.packageName,
              }),
              'parent_user': jsonEncode({}),
              'current_user_key': 'local_user',
              'facility_id': facilityId,
              'created_date_time': ts,
              'modified_date_time': ts,
              'is_synced': 0,
              'is_deleted': 0,
            };

            await LocalStorageDao.instance.insertBeneficiary(spousePayload);
          } catch (e) {
            print('Error saving spouse: $e');
          }
        }
        emit(state.copyWith(postApiStatus: PostApiStatus.success));
      } catch (e) {
        print('Error saving family member: $e');
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: 'Failed to save family member: ${e.toString()}',
          ),
        );
      }
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
        final now = DateTime.now();
        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        final deviceInfo = await DeviceInfo.getDeviceInfo();

        final householdRefKey = event.hhid.toString();
        String? headId;

        final currentUser = await UserInfo.getCurrentUser();
        final facilityId = currentUser?['asha_associated_with_facility_id'] ?? 0;

        final geoLocation = await GeoLocation.getCurrentLocation();
        final locationData = Map<String, String>.from(geoLocation.toJson());
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        final geoLocationJson = jsonEncode(locationData);

        int isAdult = 0;
        if (state.memberType == 'Adult') {
          isAdult = 1;
        } else if (state.useDob && state.dob != null) {
          final age = DateTime.now().difference(state.dob!).inDays ~/ 365;
          isAdult = age >= 18 ? 1 : 0;
        }

        final isDeath = (state.memberStatus?.toLowerCase() == 'death') ? 1 : 0;

        final deathDetails = isDeath == 1
            ? {
                'dateOfDeath': state.dateOfDeath?.toIso8601String(),
                'deathReason': state.deathReason,
                'otherDeathReason': state.otherDeathReason,
                'deathPlace': state.deathPlace,
              }
            : {};

        String? resolvedMotherKey2;
        String? resolvedFatherKey2;
        try {
          if (state.relation == 'Mother' || state.relation == 'Father') {
            final hhBeneficiaries2 = await LocalStorageDao.instance
                .getBeneficiariesByHousehold(householdRefKey.toString());
            if (headId == null || headId.isEmpty) {
              for (final b in hhBeneficiaries2) {
                try {
                  final info = b['beneficiary_info'] is Map
                      ? Map<String, dynamic>.from(b['beneficiary_info'])
                      : <String, dynamic>{};
                  final relToHead = (info['relation_to_head'] ?? '').toString().toLowerCase();
                  final rel = (info['relation'] ?? '').toString().toLowerCase();
                  if (relToHead == 'self' || rel == 'head') {
                    headId = (b['unique_key'] ?? '').toString();
                    break;
                  }
                } catch (_) {}
              }
            }

            String? spouseKeyLocal;
            for (final b in hhBeneficiaries2) {
              if ((b['unique_key'] ?? '') == headId) {
                final headSpouseKey = b['spouse_key'];
                if (headSpouseKey != null && headSpouseKey.toString().isNotEmpty) {
                  spouseKeyLocal = headSpouseKey.toString();
                }
                break;
              }
            }

            if ((spouseKeyLocal == null || spouseKeyLocal.isEmpty) && headId != null && headId.isNotEmpty) {
              for (final b in hhBeneficiaries2) {
                if ((b['spouse_key'] ?? '').toString() == headId) {
                  spouseKeyLocal = (b['unique_key'] ?? '').toString();
                  break;
                }
              }
            }

            if (state.relation == 'Mother') {
              resolvedMotherKey2 = headId;
              resolvedFatherKey2 = spouseKeyLocal;
            } else if (state.relation == 'Father') {
              resolvedFatherKey2 = headId;
              resolvedMotherKey2 = spouseKeyLocal;
            }
            // Sanitize empty strings to null
            if (resolvedMotherKey2 != null && resolvedMotherKey2.trim().isEmpty) {
              resolvedMotherKey2 = null;
            }
            if (resolvedFatherKey2 != null && resolvedFatherKey2.trim().isEmpty) {
              resolvedFatherKey2 = null;
            }
            print('Resolved parent keys (UpdateSubmit): headId=$headId spouse=$spouseKeyLocal -> mother_key=$resolvedMotherKey2 father_key=$resolvedFatherKey2');
          }
        } catch (_) {}

        final memberPayload = {
          'server_id': null,
          'household_ref_key': householdRefKey,
          'unique_key': null,
          'beneficiary_state': 'active',
          'pregnancy_count': 0,
          'beneficiary_info': jsonEncode({
            'memberType': state.memberType,
            'relation': state.relation,
            'name': state.name,
            'fatherName': state.fatherName,
            'motherName': state.motherName,
            'useDob': state.useDob,
            'dob': state.dob?.toIso8601String(),
            'approxAge': state.approxAge,
            'updateDay': state.updateDay,
            'updateMonth': state.updateMonth,
            'updateYear': state.updateYear,
            'children': state.children,
            'birthOrder': state.birthOrder,
            'gender': state.gender,
            'bankAcc': state.bankAcc,
            'ifsc': state.ifsc,
            'occupation': state.occupation,
            'education': state.education,
            'religion': state.religion,
            'category': state.category,
            'weight': state.WeightChange,
            'childSchool': state.ChildSchool,
            'birthCertificate': state.BirthCertificateChange,
            'abhaAddress': state.abhaAddress,
            'mobileOwner': state.mobileOwner,
            'mobileNo': state.mobileNo,
            'voterId': state.voterId,
            'rationId': state.rationId,
            'phId': state.phId,
            'beneficiaryType': state.beneficiaryType,
            'maritalStatus': state.maritalStatus,
            'ageAtMarriage': state.ageAtMarriage,
            'spouseName': state.spouseName,
            'hasChildren': state.hasChildren,
            'isPregnant': state.isPregnant,
            'memberStatus': state.memberStatus,
            'relation_to_head': state.relation,
          }),
          'geo_location': geoLocationJson,
          'spouse_key': null,
          'mother_key': resolvedMotherKey2,
          'father_key': resolvedFatherKey2,
          'is_family_planning': 0,
          'is_adult': isAdult,
          'is_guest': 0,
          'is_death': isDeath,
          'death_details': jsonEncode(deathDetails),
          'is_migrated': 0,
          'is_separated': 0,
          'device_details': jsonEncode({
            'id': deviceInfo.deviceId,
            'platform': deviceInfo.platform,
            'version': deviceInfo.osVersion,
          }),
          'app_details': jsonEncode({
            'app_version': deviceInfo.appVersion.split('+').first,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
          }),
          'parent_user': jsonEncode({}),
          'current_user_key': 'local_user',
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        final memberId2 = await IdGenerator.generateUniqueId(deviceInfo);
        memberPayload['unique_key'] = memberId2;
        print('Saving new family member (update submit) with payload: ${jsonEncode(memberPayload)}');
        await LocalStorageDao.instance.insertBeneficiary(memberPayload);

        emit(state.copyWith(postApiStatus: PostApiStatus.success));
      } catch (e) {
        print('Error saving family member (update submit): $e');
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: 'Failed to save family member: ${e.toString()}',
          ),
        );
      }
    });
  }
}
