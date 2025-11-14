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
import '../../../../../data/repositories/AddBeneficiaryRepository.dart';
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

      // Pregnancy validations: only when Female + Married
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

        final deviceInfo = await DeviceInfo.getDeviceInfo();
        final now = DateTime.now();
        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

        final uniqueKey = await IdGenerator.generateUniqueId(deviceInfo);
        final headId = await IdGenerator.generateUniqueId(deviceInfo);
        final spouseKey = await IdGenerator.generateUniqueId(deviceInfo);

        final currentUser = await UserInfo.getCurrentUser();
        final userDetails = currentUser?['details'] is String
            ? jsonDecode(currentUser?['details'] ?? '{}')
            : currentUser?['details'] ?? {};

        final working = userDetails['working_location'] ?? {};
        final facilityId = working['asha_associated_with_facility_id'] ??
            userDetails['asha_associated_with_facility_id'] ?? 0;
        final ashaUniqueKey = userDetails['unique_key'] ?? {};



        final geoLocation = await GeoLocation.getCurrentLocation();
        final geoLocationJson = _geoLocationJson(geoLocation);

        final childrenData = _childrenData(event.context);

        final headPayload = {
          'server_id': null,
          'household_ref_key': uniqueKey,
          'unique_key': headId,
          'beneficiary_state': 'active',
          'pregnancy_count': 0,
          'beneficiary_info': jsonEncode({
            'houseNo': state.houseNo,
            'headName': state.headName,
            'fatherName': state.fatherName,
            'gender': state.gender,
            'dob': state.dob?.toIso8601String(),
            'years': state.years,
            'months': state.months,
            'days': state.days,
            'approxAge': state.approxAge,
            'mobileNo': state.mobileNo,
            'mobileOwner': state.mobileOwner,
            'maritalStatus': state.maritalStatus,
            'ageAtMarriage': state.ageAtMarriage,
            'spouseName': state.spouseName,
            'education': state.education,
            'occupation': state.occupation,
            'religion': state.religion,
            'category': state.category,
            'hasChildren': state.hasChildren,
            'isPregnant': state.isPregnant,
            'lmp': state.lmp?.toIso8601String(),
            'edd': state.edd?.toIso8601String(),

            'village': state.village,
            'ward': state.ward,
            'wardNo': state.wardNo,
            'mohalla': state.mohalla,
            'mohallaTola': state.mohallaTola,

            'abhaAddress': state.abhaAddress,
            'abhaNumber': state.abhaNumber,
            'voterId': state.voterId,
            'rationId': state.rationId,
            'rationCardId': state.rationCardId,
            'phId': state.phId,
            'personalHealthId': state.personalHealthId,
            'bankAcc': state.bankAcc,
            'bankAccountNumber': state.bankAccountNumber,
            'ifsc': state.ifsc,
            'ifscCode': state.ifscCode,

            'beneficiaryType': state.beneficiaryType,
            'isMigrantWorker': state.isMigrantWorker,

            'migrantState': state.migrantState,
            'migrantDistrict': state.migrantDistrict,
            'migrantBlock': state.migrantBlock,
            'migrantPanchayat': state.migrantPanchayat,
            'migrantVillage': state.migrantVillage,
            'migrantContactNo': state.migrantContactNo,
            'migrantDuration': state.migrantDuration,
            'migrantWorkType': state.migrantWorkType,
            'migrantWorkPlace': state.migrantWorkPlace,
            'migrantRemarks': state.migrantRemarks,
            'AfhABHAChange': state.AfhABHAChange,
            'AfhRichIdChange': state.AfhRichIdChange,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),

            ...childrenData,
          }),
          'geo_location': geoLocationJson,
          'spouse_key': state.maritalStatus == 'Married' ? spouseKey : null,
          'mother_key': null,
          'father_key': null,
          'is_family_planning': 0,
          'is_adult': 1,
          'is_guest': 0,
          'is_death': 0,
          'death_details': jsonEncode({}),
          'is_migrated': state.beneficiaryType == 'SeasonalMigrant' ? 1 : 0,
          'is_separated': state.maritalStatus == 'Separated' || state.maritalStatus == 'Divorced' ? 1 : 0,
          'device_details': jsonEncode(_deviceDetails(deviceInfo)),
          'app_details': jsonEncode(_appDetails(deviceInfo)),
          'parent_user': jsonEncode({}),
          'current_user_key': ashaUniqueKey,
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
          'additional_info': jsonEncode({
            'abha_verified': state.abhaVerified,
            'voter_id_verified': state.voterIdVerified,
            'ration_card_verified': state.rationCardVerified,
            'bank_account_verified': state.bankAccountVerified,
          }),
        };

        await LocalStorageDao.instance.insertBeneficiary(headPayload);

        if (state.maritalStatus == 'Married' && state.spouseName != null) {
          try {
            final spousBloc = BlocProvider.of<SpousBloc>(event.context);
            final spousState = spousBloc.state;

            final spousePayload = {
              'server_id': null,
              'household_ref_key': uniqueKey,
              'unique_key': spouseKey,
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
                'maritalStatus': 'Married',
                'relation_to_head': 'spouse',
                ...childrenData,
              }),
              'geo_location': geoLocationJson,
              'spouse_key': headId,
              'mother_key': null,
              'father_key': null,
              'is_family_planning': 0,
              'is_adult': 1,
              'is_guest': 0,
              'is_death': 0,
              'death_details': jsonEncode({}),
              'is_migrated': 0,
              'is_separated': 0,
              'device_details': jsonEncode(_deviceDetails(deviceInfo)),
              'app_details': jsonEncode(_appDetails(deviceInfo)),
              'parent_user': jsonEncode({}),
              'current_user_key': ashaUniqueKey,
              'facility_id': facilityId,
              'created_date_time': ts,
              'modified_date_time': ts,
            };

            await LocalStorageDao.instance.insertBeneficiary(spousePayload);
          } catch (e) {
            print('Error saving spouse: $e');
            // Continue even if spouse save fails
          }
        }

        try {
          final savedHead = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(headId);
          if (savedHead != null) {
            final info = (savedHead['beneficiary_info'] is Map)
                ? Map<String, dynamic>.from(savedHead['beneficiary_info'])
                : (savedHead['beneficiary_info'] is String && (savedHead['beneficiary_info'] as String).isNotEmpty)
                    ? Map<String, dynamic>.from(jsonDecode(savedHead['beneficiary_info']))
                    : <String, dynamic>{};

            final currentUser2 = await UserInfo.getCurrentUser();
            final userDetails = currentUser2?['details'] is String
                ? jsonDecode(currentUser2?['details'] ?? '{}')
                : currentUser2?['details'] ?? {};
            final working = userDetails['working_location'] ?? {};

            String? _genderCode(String? g) {
              if (g == null) return null;
              final s = g.toLowerCase();
              if (s.startsWith('m')) return 'M';
              if (s.startsWith('f')) return 'F';
              if (s.startsWith('o')) return 'O';
              return null;
            }

            String? _yyyyMMdd(String? iso) {
              if (iso == null || iso.isEmpty) return null;
              try {
                final d = DateTime.tryParse(iso);
                if (d == null) return null;
                return DateFormat('yyyy-MM-dd').format(d);
              } catch (_) {
                return null;
              }
            }

            Map<String, dynamic> _apiGeo(dynamic g) {
              try {
                if (g is String && g.isNotEmpty) g = jsonDecode(g);
                if (g is Map) {
                  final m = Map<String, dynamic>.from(g);
                  final lat = m['lat'] ?? m['latitude'] ?? m['Lat'] ?? m['Latitude'];
                  final lng = m['lng'] ?? m['long'] ?? m['longitude'] ?? m['Lng'];
                  final acc = m['accuracy_m'] ?? m['accuracy'] ?? m['Accuracy'];
                  final tsCap = m['captured_at'] ?? m['captured_datetime'] ?? m['timestamp'];
                  return {
                    'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}') ,
                    'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}') ,
                    'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}') ,
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

            final beneficiaryInfoApi = {
              'name': {
                'first_name': (info['headName'] ?? info['memberName'] ?? '').toString(),
                'middle_name': '',
                'last_name': '',
              },
              'gender': _genderCode(info['gender']?.toString() ?? state.gender),
              'dob': _yyyyMMdd(info['dob']?.toString()),
              'marital_status': (info['maritalStatus'] ?? state.maritalStatus)?.toString().toLowerCase(),
              'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
              'phone': (info['mobileNo'] ?? state.mobileNo)?.toString(),
              'address': {
                'state': working['state'] ?? userDetails['stateName'],
                'district': working['district'] ?? userDetails['districtName'],
                'block': working['block'] ?? userDetails['blockName'],
                'village': info['village'] ?? working['village'] ?? userDetails['villageName'],
                'pincode': working['pincode'] ?? userDetails['pincode'],
              }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
            }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

            final apiPayload = {
              'unique_key': savedHead['unique_key'],
              'id': savedHead['id'],
              'household_ref_key': savedHead['household_ref_key'],
              'beneficiary_state': [
                {
                  'state': 'registered',
                  'at': DateTime.now().toUtc().toIso8601String(),
                },
                {
                  'state': (savedHead['beneficiary_state'] ?? 'active').toString(),
                  'at': DateTime.now().toUtc().toIso8601String(),
                },
              ],
              'pregnancy_count': savedHead['pregnancy_count'] ?? 0,
              'beneficiary_info': beneficiaryInfoApi,
              'geo_location': _apiGeo(savedHead['geo_location']),
              'spouse_key': savedHead['spouse_key'],
              'mother_key': savedHead['mother_key'],
              'father_key': savedHead['father_key'],
              'is_family_planning': savedHead['is_family_planning'] ?? 0,
              'is_adult': savedHead['is_adult'] ?? 1,
              'is_guest': savedHead['is_guest'] ?? 0,
              'is_death': savedHead['is_death'] ?? 0,
              'death_details': savedHead['death_details'] is Map
                  ? savedHead['death_details']
                  : {},
              'is_migrated': savedHead['is_migrated'] ?? 0,
              'is_separated': savedHead['is_separated'] ?? 0,
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
              'current_user_key': savedHead['current_user_key'] ?? ashaUniqueKey,
              'facility_id': savedHead['facility_id'] ?? facilityId,
              'created_date_time': savedHead['created_date_time'] ?? ts,
              'modified_date_time': savedHead['modified_date_time'] ?? ts,
            };

            try {
              final repo = AddBeneficiaryRepository();
              final reqUniqueKey = (savedHead['unique_key'] ?? '').toString();
              final resp = await repo.addBeneficiary(apiPayload);
              try {
                if (resp is Map && (resp['success'] == true)) {
                  if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
                    final first = resp['data'][0];
                    if (first is Map) {
                      final sid = (first['_id'] ?? first['id'] ?? '').toString();
                      if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                        final updated = await LocalStorageDao.instance.updateBeneficiaryServerIdByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                        print('Updated beneficiary with server_id=$sid rows=$updated');
                      }
                    }
                  } else if (resp['data'] is Map) {
                    final map = Map<String, dynamic>.from(resp['data']);
                    final sid = (map['_id'] ?? map['id'] ?? '').toString();
                    if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                      final updated = await LocalStorageDao.instance.updateBeneficiaryServerIdByUniqueKey(uniqueKey: reqUniqueKey, serverId: sid);
                      print('Updated beneficiary with server_id=$sid rows=$updated');
                    }
                  }
                }
              } catch (e) {
                print('Error updating local beneficiary after API: $e');
              }
            } catch (apiErr) {
              print('add_beneficiary API failed, will sync later: $apiErr');
            }
          }
        } catch (e) {
          print('Error preparing or posting add_beneficiary: $e');
        }

        emit(state.copyWith(postApiStatus: PostApiStatus.success));
      } catch (e) {
        print('Error saving family head: $e');
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: 'Failed to save family data: ${e.toString()}',
          ),
        );
      }
    });
  }
}

extension _AddFamilyHeadBlocHelpers on AddFamilyHeadBloc {
  Map<String, dynamic> _childrenData(BuildContext context) {
    try {
      final childrenBloc = BlocProvider.of<ChildrenBloc>(context);
      final s = childrenBloc.state;
      return {
        'totalBorn': s.totalBorn,
        'totalLive': s.totalLive,
        'totalMale': s.totalMale,
        'totalFemale': s.totalFemale,
        'youngestAge': s.youngestAge,
        'ageUnit': s.ageUnit,
        'youngestGender': s.youngestGender,
        'children': s.children,
      };
    } catch (e) {
      print('Error getting children data: $e');
      return {};
    }
  }

  String _geoLocationJson(dynamic geoLocation) {
    final locationData = Map<String, String>.from(geoLocation.toJson());
    locationData['source'] = 'gps';
    if (!geoLocation.hasCoordinates) {
      locationData['status'] = 'unavailable';
      locationData['reason'] = 'Could not determine location';
    }
    return jsonEncode(locationData);
  }

  Map<String, dynamic> _deviceDetails(dynamic deviceInfo) => {
        'id': deviceInfo.deviceId,
        'platform': deviceInfo.platform,
        'version': deviceInfo.osVersion,
      };

  Map<String, dynamic> _appDetails(dynamic deviceInfo) => {
        'app_version': deviceInfo.appVersion.split('+').first,
        'app_name': deviceInfo.appName,
        'build_number': deviceInfo.buildNumber,
        'package_name': deviceInfo.packageName,
      };
}
