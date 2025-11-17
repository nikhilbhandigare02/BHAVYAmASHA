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
import '../../../../data/repositories/AddBeneficiary/AddBeneficiaryRepository.dart';
import '../../AddFamilyHead/Children_Details/bloc/children_bloc.dart' show ChildrenBloc;
import '../../AddFamilyHead/SpousDetails/bloc/spous_bloc.dart';

part 'addnewfamilymember_event.dart';
part 'addnewfamilymember_state.dart';

class AddnewfamilymemberBloc
    extends Bloc<AddnewfamilymemberEvent, AddnewfamilymemberState> {
  final LocalStorageDao _localStorageDao = LocalStorageDao();

  // Helper method to determine if a member is an adult based on memberType and DOB
  int _getIsAdultValue(String? memberType, bool useDob, DateTime? dob) {
    // If member type is explicitly 'child', return 0
    if (memberType == 'child') {
      return 0;
    }

    // If member type is explicitly 'Adult', return 1
    if (memberType == 'Adult') {
      return 1;
    }

    // If DOB is available, calculate age
    if (useDob && dob != null) {
      final age = DateTime.now().difference(dob).inDays ~/ 365;
      return age > 18 ? 1 : 0;
    }

    return 1;
  }

  String _getBeneficiaryState(String? memberType) {
    if (memberType?.toLowerCase() == 'child') {
      return 'registration_due';
    } else {
      return 'active';
    }
  }

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

    on<AnmSubmit>((event,      emit) async {
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
      
      // Marital status is only required for Adults, not for Children
      if (state.memberType != 'Child') {
        if (state.maritalStatus == null || state.maritalStatus!.isEmpty) {
          errors.add('Marital status required');
        } else if (state.maritalStatus == 'Married') {
          if (state.spouseName == null || state.spouseName!.trim().isEmpty) {
            errors.add('Spouse Name is required for married status');
          }
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

        String householdRefKey;
        if (event.hhid != null && event.hhid!.isNotEmpty) {
          householdRefKey = event.hhid!.toString();
        } else {
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
          householdRefKey = (latestBeneficiary['household_ref_key'] ?? '').toString();
        }

        final beneficiaries = await LocalStorageDao.instance.getAllBeneficiaries();
        final latestBeneficiary = beneficiaries.isNotEmpty ? beneficiaries.first : null;
        final uniqueKeyForSpouseFallback = (latestBeneficiary?['household_ref_key'] ?? householdRefKey).toString();

        final memberId = await IdGenerator.generateUniqueId(deviceInfo);
        final spousKey = await IdGenerator.generateUniqueId(deviceInfo);

        // Get current user info
        final currentUser = await UserInfo.getCurrentUser();
        final userDetails = currentUser?['details'] is String
            ? jsonDecode(currentUser?['details'] ?? '{}')
            : currentUser?['details'] ?? {};

        final working = userDetails['working_location'] ?? {};
        final facilityId = working['asha_associated_with_facility_id'] ??
            userDetails['asha_associated_with_facility_id'] ?? 0;
        final ashaUniqueKey = userDetails['unique_key'] ?? {};


        final geoLocation = await GeoLocation.getCurrentLocation();
        final locationData = Map<String, String>.from(geoLocation.toJson());
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        final geoLocationJson = jsonEncode(locationData);

        // Use helper method to determine beneficiary_state and isAdult
        final beneficiaryState = _getBeneficiaryState(state.memberType);
        final isAdult = _getIsAdultValue(state.memberType, state.useDob, state.dob);

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

        String? resolvedMotherKey;
        String? resolvedFatherKey;
        try {
          if (state.relation == 'Mother' || state.relation == 'Father' || state.relation == 'Child') {
            final hhBeneficiaries = await LocalStorageDao.instance
                .getBeneficiariesByHousehold(householdRefKey.toString());

            Map<String, dynamic>? headRecord;
            Map<String, dynamic>? spouseRecord;
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
                try {
                  for (final b in hhBeneficiaries) {
                    if ((b['spouse_key'] ?? '').toString() == headUnique) {
                      spouseKeyLocal = (b['unique_key'] ?? '').toString();
                      spouseRecord = b as Map<String, dynamic>;
                      break;
                    }
                  }
                } catch (_) {}
              } else {
                try {
                  for (final b in hhBeneficiaries) {
                    if ((b['unique_key'] ?? '').toString() == spouseKeyLocal) {
                      spouseRecord = b as Map<String, dynamic>;
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
              } else if (state.relation == 'Child') {
                // Infer parent keys based on genders of head and spouse
                final headInfo = headRecord['beneficiary_info'] is Map
                    ? Map<String, dynamic>.from(headRecord['beneficiary_info'])
                    : <String, dynamic>{};
                final spouseInfo = spouseRecord != null && spouseRecord['beneficiary_info'] is Map
                    ? Map<String, dynamic>.from(spouseRecord['beneficiary_info'])
                    : <String, dynamic>{};
                final headGender = (headInfo['gender'] ?? '').toString().toLowerCase();
                final spouseGender = (spouseInfo['gender'] ?? '').toString().toLowerCase();
                // Assign based on gender where possible
                if (headGender == 'female') {
                  resolvedMotherKey = headUnique;
                  resolvedFatherKey = spouseKeyLocal;
                } else if (headGender == 'male') {
                  resolvedFatherKey = headUnique;
                  resolvedMotherKey = spouseKeyLocal;
                } else if (spouseGender.isNotEmpty) {
                  if (spouseGender == 'female') {
                    resolvedMotherKey = spouseKeyLocal;
                    resolvedFatherKey = headUnique;
                  } else if (spouseGender == 'male') {
                    resolvedFatherKey = spouseKeyLocal;
                    resolvedMotherKey = headUnique;
                  }
                } else {
                  resolvedMotherKey = headUnique;
                  resolvedFatherKey = spouseKeyLocal;
                }
              }
            }
          }
        } catch (_) {}

        final memberPayload = {
          'server_id': null,
          'household_ref_key': householdRefKey,
          'unique_key': memberId,
          'beneficiary_state': beneficiaryState,
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
          'spouse_key': state.maritalStatus == 'Married' ? spousKey : null,
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
          'current_user_key': ashaUniqueKey,
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
              'household_ref_key': householdRefKey,
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
              'current_user_key': ashaUniqueKey,
              'facility_id': facilityId,
              'created_date_time': ts,
              'modified_date_time': ts,
              'is_synced': 0,
              'is_deleted': 0,
            };

            await LocalStorageDao.instance.insertBeneficiary(spousePayload);
          } catch (e) {
            print('Error saving spouse: $e');
            // Continue even if spouse save fails
          }
        }
        try {
          final savedMember = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(memberId);
          if (savedMember != null) {
            final info = (savedMember['beneficiary_info'] is Map)
                ? Map<String, dynamic>.from(savedMember['beneficiary_info'])
                : (savedMember['beneficiary_info'] is String && (savedMember['beneficiary_info'] as String).isNotEmpty)
                    ? Map<String, dynamic>.from(jsonDecode(savedMember['beneficiary_info']))
                    : <String, dynamic>{};

            final currentUser2 = await UserInfo.getCurrentUser();
            final userDetails = currentUser2?['details'] is String
                ? jsonDecode(currentUser2?['details'] ?? '{}')
                : currentUser2?['details'] ?? {};
            final working = userDetails['working_location'] ?? {};

            String? genderCode(String? g) {
              if (g == null) return null;
              final s = g.toLowerCase();
              if (s.startsWith('m')) return 'M';
              if (s.startsWith('f')) return 'F';
              if (s.startsWith('o')) return 'O';
              return null;
            }

            String? yyyyMMdd(String? iso) {
              if (iso == null || iso.isEmpty) return null;
              try {
                final d = DateTime.tryParse(iso);
                if (d == null) return null;
                return DateFormat('yyyy-MM-dd').format(d);
              } catch (_) {
                return null;
              }
            }

            Map<String, dynamic> apiGeo(dynamic g) {
              try {
                if (g is String && g.isNotEmpty) g = jsonDecode(g);
                if (g is Map) {
                  final m = Map<String, dynamic>.from(g);
                  final lat = m['lat'] ?? m['latitude'] ?? m['Lat'] ?? m['Latitude'];
                  final lng = m['lng'] ?? m['long'] ?? m['longitude'] ?? m['Lng'];
                  final acc = m['accuracy_m'] ?? m['accuracy'] ?? m['Accuracy'];
                  final tsCap = m['captured_at'] ?? m['captured_datetime'] ?? m['timestamp'];
                  return {
                    'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}'),
                    'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}'),
                    'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}'),
                    'captured_at': tsCap?.toString() ?? DateTime.now().toUtc().toIso8601String(),
                  }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
                }
              } catch (_) {}
              return {
                'lat': null,
                'lng': null,
                'accuracy_m': null,
                'captured_at': DateTime.now().toUtc().toIso8601String(),
              }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
            }

            final nameStr = (info['name'] ?? '').toString();
            final beneficiaryInfoApi = {
              'name': {
                'first_name': nameStr,
                'middle_name': '',
                'last_name': '',
              },
              'gender': genderCode((info['gender'] ?? state.gender)?.toString()),
              'dob': yyyyMMdd(info['dob']?.toString()),
              'marital_status': (info['maritalStatus'] ?? state.maritalStatus)?.toString().toLowerCase(),
              'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
              'phone': (info['mobileNo'] ?? state.mobileNo)?.toString(),
              'address': {
                'state': working['state'] ?? userDetails['stateName'],
                'district': working['district'] ?? userDetails['districtName'],
                'block': working['block'] ?? userDetails['blockName'],
                'village': working['village'] ?? userDetails['villageName'],
                'pincode': working['pincode'] ?? userDetails['pincode'],
              }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
            }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

            final apiPayload = {
              'unique_key': savedMember['unique_key'],
              'id': null,
              'household_ref_key': savedMember['household_ref_key'],
              'beneficiary_state': [
                {
                  'state': 'registered',
                  'at': DateTime.now().toUtc().toIso8601String(),
                },
                {
                  'state': (savedMember['beneficiary_state'] ?? 'active').toString(),
                  'at': DateTime.now().toUtc().toIso8601String(),
                },
              ],
              'pregnancy_count': savedMember['pregnancy_count'] ?? 0,
              'beneficiary_info': beneficiaryInfoApi,
              'geo_location': apiGeo(savedMember['geo_location']),
              'spouse_key': savedMember['spouse_key'],
              'mother_key': savedMember['mother_key'],
              'father_key': savedMember['father_key'],
              'is_family_planning': savedMember['is_family_planning'] ?? 0,
              'is_adult': savedMember['is_adult'] ?? 0,
              'is_guest': savedMember['is_guest'] ?? 0,
              'is_death': savedMember['is_death'] ?? 0,
              'death_details': savedMember['death_details'] is Map ? savedMember['death_details'] : {},
              'is_migrated': savedMember['is_migrated'] ?? 0,
              'is_separated': savedMember['is_separated'] ?? 0,
              'device_details': {
                'device_id': deviceInfo.deviceId,
                'model': deviceInfo.model,
                'os': deviceInfo.platform + ' ' + (deviceInfo.osVersion ?? ''),
                'app_version': deviceInfo.appVersion.split('+').first,
              },
              'app_details': {
                'captured_by_user': userDetails['user_identifier'] ?? '',
                'captured_role_id': userDetails['role_id'] ?? userDetails['role'] ?? 0,
                'source': 'mobile',
              },
              'parent_user': {
                'user_key': userDetails['supervisor_user_key'] ?? '',
                'name': userDetails['supervisor_name'] ?? '',
              }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
              'current_user_key': savedMember['current_user_key'] ?? facilityId,
              'facility_id': savedMember['facility_id'] ?? facilityId,
              'created_date_time': savedMember['created_date_time'] ?? ts,
              'modified_date_time': savedMember['modified_date_time'] ?? ts,
            };

            try {
              final repo = AddBeneficiaryRepository();
              final reqUniqueKey = (savedMember['unique_key'] ?? '').toString();
              final resp = await repo.addBeneficiary(apiPayload);
              try {
                if (resp is Map && (resp['success'] == true)) {
                  if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
                    final first = resp['data'][0];
                    if (first is Map) {
                      final sid = (first['_id'] ?? first['id'] ?? '').toString();
                      if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                        final updated = await LocalStorageDao.instance.updateBeneficiaryServerIdByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                        print('Updated member with server_id='+sid+' rows='+updated.toString());
                      }
                    }
                  } else if (resp['data'] is Map) {
                    final map = Map<String, dynamic>.from(resp['data']);
                    final sid = (map['_id'] ?? map['id'] ?? '').toString();
                    if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                      final updated = await LocalStorageDao.instance.updateBeneficiaryServerIdByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                      print('Updated member with server_id='+sid+' rows='+updated.toString());
                    }
                  }
                }
              } catch (e) {
                print('Error updating local member after API: $e');
              }
            } catch (apiErr) {
              print('add_beneficiary API failed for member, will sync later: $apiErr');
            }
          }
        } catch (e) {
          print('Error preparing or posting add_beneficiary for member: $e');
        }

        try {
          final unsynced = await LocalStorageDao.instance.getUnsyncedBeneficiaries();
          for (final savedMember in unsynced) {
            try {
              if ((savedMember['is_synced'] == 1) || (savedMember['is_synced']?.toString() == '1')) {
                continue;
              }

              final info = (savedMember['beneficiary_info'] is Map)
                  ? Map<String, dynamic>.from(savedMember['beneficiary_info'])
                  : (savedMember['beneficiary_info'] is String && (savedMember['beneficiary_info'] as String).isNotEmpty)
                      ? Map<String, dynamic>.from(jsonDecode(savedMember['beneficiary_info']))
                      : <String, dynamic>{};

              final currentUser2 = await UserInfo.getCurrentUser();
              final userDetails = currentUser2?['details'] is String
                  ? jsonDecode(currentUser2?['details'] ?? '{}')
                  : currentUser2?['details'] ?? {};
              final working = userDetails['working_location'] ?? {};

              String? genderCode(String? g) {
                if (g == null) return null;
                final s = g.toLowerCase();
                if (s.startsWith('m')) return 'M';
                if (s.startsWith('f')) return 'F';
                if (s.startsWith('o')) return 'O';
                return null;
              }

              String? yyyyMMdd(String? iso) {
                if (iso == null || iso.isEmpty) return null;
                try {
                  final d = DateTime.tryParse(iso);
                  if (d == null) return null;
                  return DateFormat('yyyy-MM-dd').format(d);
                } catch (_) {
                  return null;
                }
              }

              Map<String, dynamic> apiGeo(dynamic g) {
                try {
                  if (g is String && g.isNotEmpty) g = jsonDecode(g);
                  if (g is Map) {
                    final m = Map<String, dynamic>.from(g);
                    final lat = m['lat'] ?? m['latitude'] ?? m['Lat'] ?? m['Latitude'];
                    final lng = m['lng'] ?? m['long'] ?? m['longitude'] ?? m['Lng'];
                    final acc = m['accuracy_m'] ?? m['accuracy'] ?? m['Accuracy'];
                    final tsCap = m['captured_at'] ?? m['captured_datetime'] ?? m['timestamp'];
                    return {
                      'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}'),
                      'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}'),
                      'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}'),
                      'captured_at': tsCap?.toString() ?? DateTime.now().toUtc().toIso8601String(),
                    }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
                  }
                } catch (_) {}
                return {
                  'lat': null,
                  'lng': null,
                  'accuracy_m': null,
                  'captured_at': DateTime.now().toUtc().toIso8601String(),
                }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
              }

              final nameStr = (info['name'] ?? '').toString();
              final beneficiaryInfoApi = {
                'name': {
                  'first_name': nameStr,
                  'middle_name': '',
                  'last_name': '',
                },
                'gender': genderCode((info['gender'] ?? state.gender)?.toString()),
                'dob': yyyyMMdd(info['dob']?.toString()),
                'marital_status': (info['maritalStatus'] ?? state.maritalStatus)?.toString().toLowerCase(),
                'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
                'phone': (info['mobileNo'] ?? state.mobileNo)?.toString(),
                'address': {
                  'state': working['state'] ?? userDetails['stateName'],
                  'district': working['district'] ?? userDetails['districtName'],
                  'block': working['block'] ?? userDetails['blockName'],
                  'village': working['village'] ?? userDetails['villageName'],
                  'pincode': working['pincode'] ?? userDetails['pincode'],
                }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
              }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

              final apiPayload = {
                'unique_key': savedMember['unique_key'],
                'id': null,
                'household_ref_key': savedMember['household_ref_key'],
                'beneficiary_state': [
                  {
                    'state': 'registered',
                    'at': DateTime.now().toUtc().toIso8601String(),
                  },
                  {
                    'state': (savedMember['beneficiary_state'] ?? 'active').toString(),
                    'at': DateTime.now().toUtc().toIso8601String(),
                  },
                ],
                'pregnancy_count': savedMember['pregnancy_count'] ?? 0,
                'beneficiary_info': beneficiaryInfoApi,
                'geo_location': apiGeo(savedMember['geo_location']),
                'spouse_key': savedMember['spouse_key'],
                'mother_key': savedMember['mother_key'],
                'father_key': savedMember['father_key'],
                'is_family_planning': savedMember['is_family_planning'] ?? 0,
                'is_adult': savedMember['is_adult'] ?? 0,
                'is_guest': savedMember['is_guest'] ?? 0,
                'is_death': savedMember['is_death'] ?? 0,
                'death_details': savedMember['death_details'] is Map ? savedMember['death_details'] : {},
                'is_migrated': savedMember['is_migrated'] ?? 0,
                'is_separated': savedMember['is_separated'] ?? 0,
                'device_details': {
                  'device_id': deviceInfo.deviceId,
                  'model': deviceInfo.model,
                  'os': deviceInfo.platform + ' ' + (deviceInfo.osVersion ?? ''),
                  'app_version': deviceInfo.appVersion.split('+').first,
                },
                'app_details': {
                  'captured_by_user': userDetails['user_identifier'] ?? '',
                  'captured_role_id': userDetails['role_id'] ?? userDetails['role'] ?? 0,
                  'source': 'mobile',
                },
                'parent_user': {
                  'user_key': userDetails['supervisor_user_key'] ?? '',
                  'name': userDetails['supervisor_name'] ?? '',
                }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
                'current_user_key': savedMember['current_user_key'] ?? savedMember['facility_id'],
                'facility_id': savedMember['facility_id'] ?? savedMember['facility_id'],
                'created_date_time': savedMember['created_date_time'] ?? DateTime.now().toIso8601String(),
                'modified_date_time': savedMember['modified_date_time'] ?? DateTime.now().toIso8601String(),
              };

              try {
                final repo = AddBeneficiaryRepository();
                final reqUniqueKey = (savedMember['unique_key'] ?? '').toString();
                final resp = await repo.addBeneficiary(apiPayload);
                try {
                  if (resp is Map && (resp['success'] == true)) {
                    if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
                      final first = resp['data'][0];
                      if (first is Map) {
                        final sid = (first['_id'] ?? first['id'] ?? '').toString();
                        if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                          await LocalStorageDao.instance.markBeneficiarySyncedByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                        }
                      }
                    } else if (resp['data'] is Map) {
                      final map = Map<String, dynamic>.from(resp['data']);
                      final sid = (map['_id'] ?? map['id'] ?? '').toString();
                      if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                        await LocalStorageDao.instance.markBeneficiarySyncedByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                      }
                    }
                  }
                } catch (e) {
                  print('Error marking local member synced after API: $e');
                }
              } catch (apiErr) {
                print('add_beneficiary API failed for unsynced member, will retry later: $apiErr');
              }
            } catch (e) {
              print('Error preparing payload for unsynced member: $e');
            }
          }
        } catch (e) {
          print('Error syncing unsynced beneficiaries: $e');
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

        // Resolve household by the passed HHID
        final households = await LocalStorageDao.instance.getAllHouseholds();
        Map<String, dynamic>? matchedHousehold;
        for (final h in households) {
          if (h['unique_key'] == event.hhid) {
            matchedHousehold = h;
            break;
          }
        }
        matchedHousehold ??= households.isNotEmpty ? households.first : null;
        if (matchedHousehold == null) {
          emit(
            state.copyWith(
              postApiStatus: PostApiStatus.error,
              errorMessage: 'No household found. Please create a household first.',
            ),
          );
          return;
        }

        final householdRefKey = event.hhid;
        String? headId = matchedHousehold['head_id'] as String?;

        final currentUser = await UserInfo.getCurrentUser();
        final userDetails = currentUser?['details'] is String
            ? jsonDecode(currentUser?['details'] ?? '{}')
            : currentUser?['details'] ?? {};

        final working = userDetails['working_location'] ?? {};
        final facilityId = working['asha_associated_with_facility_id'] ??
            userDetails['asha_associated_with_facility_id'] ?? 0;
        final ashaUniqueKey = userDetails['unique_key'] ?? {};



        final geoLocation = await GeoLocation.getCurrentLocation();
        final locationData = Map<String, String>.from(geoLocation.toJson());
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        final geoLocationJson = jsonEncode(locationData);

        final beneficiaryState = _getBeneficiaryState(state.memberType);
        final isAdult = _getIsAdultValue(state.memberType, state.useDob, state.dob);

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
          if (state.relation == 'Mother' || state.relation == 'Father' || state.relation == 'Child') {
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

            // Try to get spouse from head row first
            String? spouseKeyLocal;
            Map<String, dynamic>? spouseRecord;
            for (final b in hhBeneficiaries2) {
              if ((b['unique_key'] ?? '') == headId) {
                final headSpouseKey = b['spouse_key'];
                if (headSpouseKey != null && headSpouseKey.toString().isNotEmpty) {
                  spouseKeyLocal = headSpouseKey.toString();
                }
                break;
              }
            }

            // Fallback: find any beneficiary whose spouse_key equals headId
            if ((spouseKeyLocal == null || spouseKeyLocal.isEmpty) && headId != null && headId.isNotEmpty) {
              for (final b in hhBeneficiaries2) {
                if ((b['spouse_key'] ?? '').toString() == headId) {
                  spouseKeyLocal = (b['unique_key'] ?? '').toString();
                  spouseRecord = b as Map<String, dynamic>;
                  break;
                }
              }
            } else if (spouseKeyLocal != null && spouseKeyLocal.isNotEmpty) {
              // Find spouse record by unique key
              try {
                for (final b in hhBeneficiaries2) {
                  if ((b['unique_key'] ?? '').toString() == spouseKeyLocal) {
                    spouseRecord = b as Map<String, dynamic>;
                    break;
                  }
                }
              } catch (_) {}
            }

            if (state.relation == 'Mother') {
              resolvedMotherKey2 = headId;
              resolvedFatherKey2 = spouseKeyLocal;
            } else if (state.relation == 'Father') {
              resolvedFatherKey2 = headId;
              resolvedMotherKey2 = spouseKeyLocal;
            } else if (state.relation == 'Child') {
              // Infer parent keys based on genders of head and spouse
              Map<String, dynamic>? headRecord;
              for (final b in hhBeneficiaries2) {
                if ((b['unique_key'] ?? '') == headId) {
                  headRecord = b as Map<String, dynamic>;
                  break;
                }
              }

              final headInfo = headRecord != null && headRecord['beneficiary_info'] is Map
                  ? Map<String, dynamic>.from(headRecord['beneficiary_info'])
                  : <String, dynamic>{};
              final spouseInfo = spouseRecord != null && spouseRecord['beneficiary_info'] is Map
                  ? Map<String, dynamic>.from(spouseRecord['beneficiary_info'])
                  : <String, dynamic>{};
              final headGender = (headInfo['gender'] ?? '').toString().toLowerCase();
              final spouseGender = (spouseInfo['gender'] ?? '').toString().toLowerCase();

              // Assign based on gender where possible
              if (headGender == 'female') {
                resolvedMotherKey2 = headId;
                resolvedFatherKey2 = spouseKeyLocal;
              } else if (headGender == 'male') {
                resolvedFatherKey2 = headId;
                resolvedMotherKey2 = spouseKeyLocal;
              } else if (spouseGender.isNotEmpty) {
                if (spouseGender == 'female') {
                  resolvedMotherKey2 = spouseKeyLocal;
                  resolvedFatherKey2 = headId;
                } else if (spouseGender == 'male') {
                  resolvedFatherKey2 = spouseKeyLocal;
                  resolvedMotherKey2 = headId;
                }
              } else {
                resolvedMotherKey2 = headId;
                resolvedFatherKey2 = spouseKeyLocal;
              }
            }
 
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
          'unique_key': headId,
          'beneficiary_state': beneficiaryState,
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
          'current_user_key': ashaUniqueKey,
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

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