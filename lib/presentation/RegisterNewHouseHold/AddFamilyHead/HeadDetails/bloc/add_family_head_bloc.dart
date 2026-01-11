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
import '../../../../../data/Database/User_Info.dart';
import '../../../../../data/Database/local_storage_dao.dart';
import '../../../../../data/repositories/AddBeneficiary/AddBeneficiaryRepository.dart';
import '../../Children_Details/bloc/children_bloc.dart';
import '../../SpousDetails/bloc/spous_bloc.dart';

part 'add_family_head_event.dart';
part 'add_family_head_state.dart';

class AddFamilyHeadBloc extends Bloc<AddFamilyHeadEvent, AddFamilyHeadState> {
  int _daysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  Map<String, int> _agePartsFromDob(DateTime dob) {
    final today = DateTime.now();
    int years = today.year - dob.year;
    int months = today.month - dob.month;
    int days = today.day - dob.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = today.month == 1 ? 12 : today.month - 1;
      final prevYear = prevMonth == 12 ? today.year - 1 : today.year;
      days += _daysInMonth(prevYear, prevMonth);
    }

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years < 0) {
      years = 0;
      months = 0;
      days = 0;
    }

    return {
      'years': years,
      'months': months,
      'days': days,
    };
  }

  DateTime? _dobFromAgeParts(int years, int months, int days) {
    if (years < 0 || months < 0 || days < 0) return null;
    if (years == 0 && months == 0 && days == 0) return null;

    final today = DateTime.now();
    int y = today.year - years;
    int m = today.month - months;
    int d = today.day - days;

    while (d <= 0) {
      m -= 1;
      if (m <= 0) {
        m += 12;
        y -= 1;
      }
      d += _daysInMonth(y, m);
    }

    while (m <= 0) {
      m += 12;
      y -= 1;
    }

    if (y < 1900) {
      y = 1900;
    }

    return DateTime(y, m, d);
  }

  AddFamilyHeadBloc() : super(AddFamilyHeadState()) {
    // Family Planning Event Handlers
    on<HeadFamilyPlanningCounselingChanged>((event, emit) {
      emit(state.copyWith(hpfamilyPlanningCounseling: event.value));
    });

    on<hpMethodChanged>((event, emit) {
      emit(state.copyWith(hpMethod: event.value));
    });

    on<hpDateofAntraChanged>((event, emit) {
      emit(state.copyWith(hpantraDate: event.value));
    });

    on<hpRemovalDateChanged>((event, emit) {
      emit(state.copyWith(hpremovalDate: event.value));
    });

    on<hpRemovalReasonChanged>((event, emit) {
      emit(state.copyWith(hpremovalReason: event.value));
    });

    on<hpCondomQuantityChanged>((event, emit) {
      emit(state.copyWith(hpcondomQuantity: event.value));
    });

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
    on<AfhUpdateDob>((event, emit) {
      final dob = event.value;
      if (dob == null) {
        emit(state.copyWith(dob: null));
        return;
      }

      final parts = _agePartsFromDob(dob);
      final years = parts['years'] ?? 0;
      final months = parts['months'] ?? 0;
      final days = parts['days'] ?? 0;
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          dob: dob,
          years: years.toString(),
          months: months.toString(),
          days: days.toString(),
          approxAge: approx,
        ),
      );
    });
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
          (event, emit) {
        final value = event.value;
        final isButtonEnabled = value.length == 12;
        emit(state.copyWith(
          AfhRichIdChange: value,
          isRchIdButtonEnabled: isButtonEnabled,
        ));
      },
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
          (event, emit) => emit(state.copyWith(mobileOwnerOtherRelation: event.value)),
    );
    on<AfhUpdateMobileNo>(
          (event, emit) => emit(state.copyWith(mobileNo: event.value)),
    );
    on<AfhUpdateVillage>(
          (event, emit) => emit(state.copyWith(village: event.value)),
    );
    on<AfhUpdateWard>((event, emit) => emit(state.copyWith(wardNo: event.value)));
    on<AfhUpdateWardName>((event, emit) => emit(state.copyWith(ward: event.value)));
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
      final yearsStr = event.value;
      final monthsStr = state.months ?? '0';
      final daysStr = state.days ?? '0';

      final years = int.tryParse(yearsStr.isEmpty ? '0' : yearsStr) ?? 0;
      final months = int.tryParse(monthsStr.isEmpty ? '0' : monthsStr) ?? 0;
      final days = int.tryParse(daysStr.isEmpty ? '0' : daysStr) ?? 0;

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          years: yearsStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
    });

    on<UpdateMonths>((event, emit) {
      final monthsStr = event.value;
      final yearsStr = state.years ?? '0';
      final daysStr = state.days ?? '0';

      final years = int.tryParse(yearsStr.isEmpty ? '0' : yearsStr) ?? 0;
      final months = int.tryParse(monthsStr.isEmpty ? '0' : monthsStr) ?? 0;
      final days = int.tryParse(daysStr.isEmpty ? '0' : daysStr) ?? 0;

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          months: monthsStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
    });

    on<UpdateDays>((event, emit) {
      final daysStr = event.value;
      final yearsStr = state.years ?? '0';
      final monthsStr = state.months ?? '0';

      final years = int.tryParse(yearsStr.isEmpty ? '0' : yearsStr) ?? 0;
      final months = int.tryParse(monthsStr.isEmpty ? '0' : monthsStr) ?? 0;
      final days = int.tryParse(daysStr.isEmpty ? '0' : daysStr) ?? 0;

      final dob = _dobFromAgeParts(years, months, days);
      final approx = '$years years $months months $days days'.trim();

      emit(
        state.copyWith(
          days: daysStr,
          approxAge: approx,
          dob: dob ?? state.dob,
        ),
      );
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
        errors.add('Please enter house number');
      if (state.headName == null || state.headName!.trim().isEmpty)
        errors.add('Please enter name of family head');

      if (state.mobileNo == null || state.mobileNo!.trim().length < 10)
        errors.add('Please enter valid mobile number');
      // if (state.mobileOwner == null || state.mobileOwner!.trim().length < 10)
      //   errors.add('Please select whose mobile number');


      if (state.gender == null || state.gender!.isEmpty)
        errors.add('Please select gender');
      if (state.maritalStatus == null || state.maritalStatus!.isEmpty) {
        errors.add('Please select Marital status ');
      }

      // Pregnancy validations: only when Female + Married
      final isFemale = state.gender == 'Female';
      final isMarried = state.maritalStatus == 'Married';
      if (isFemale && isMarried) {
        if (state.isPregnant == null || state.isPregnant!.isEmpty) {
          errors.add('Please enter is women pregnant ');
        } else if (state.isPregnant == 'Yes') {
          if (state.lmp == null) errors.add('Please enter LMP');
          if (state.edd == null) errors.add('Please enter EDD is required');
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
            errorMessage: errors.first,
          ),
        );
        return;
      }
      // All DB insert/update + API sync is now handled in RegisterNewHouseholdBloc.SaveHousehold.
      // Here we only indicate that validation passed.
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.success,
        ),
      );
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

  Future<void> _syncBeneficiaryByUniqueKey({
    required String uniqueKey,
    required dynamic deviceInfo,
    required String ts,
  }) async {
    final saved = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(uniqueKey);
    if (saved == null) return;

    final currentUser = await UserInfo.getCurrentUser();
    final userDetails = currentUser?['details'] is String
        ? jsonDecode(currentUser?['details'] ?? '{}')
        : currentUser?['details'] ?? {};
    final working = userDetails['working_location'] ?? {};
    final facilityId = working['asha_associated_with_facility_id'] ??
        userDetails['asha_associated_with_facility_id'] ?? 0;
    final ashaUniqueKey = userDetails['unique_key'] ?? {};

    final payload = _buildBeneficiaryApiPayload(
      Map<String, dynamic>.from(saved),
      Map<String, dynamic>.from(userDetails is Map ? userDetails : {}),
      Map<String, dynamic>.from(working is Map ? working : {}),
      deviceInfo,
      ts,
      ashaUniqueKey,
      facilityId,
    );

    try {
      final repo = AddBeneficiaryRepository();
      final reqUniqueKey = (saved['unique_key'] ?? '').toString();
      final resp = await repo.addBeneficiary(payload);
      try {
        if (resp is Map && (resp['success'] == true)) {
          if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
            final first = resp['data'][0];
            if (first is Map) {
              final sid = (first['_id'] ?? first['id'] ?? '').toString();
              if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                final updated = await LocalStorageDao.instance
                    .updateBeneficiaryServerIdByUniqueKey(
                    uniqueKey: reqUniqueKey, serverId: sid);
                print('Updated beneficiary with server_id=$sid rows=$updated');
              }
            }
          } else if (resp['data'] is Map) {
            final map = Map<String, dynamic>.from(resp['data']);
            final sid = (map['_id'] ?? map['id'] ?? '').toString();
            if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
              final updated = await LocalStorageDao.instance
                  .updateBeneficiaryServerIdByUniqueKey(
                  uniqueKey: reqUniqueKey, serverId: sid);
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

  Map<String, dynamic> _buildBeneficiaryApiPayload(
      Map<String, dynamic> row,
      Map<String, dynamic> userDetails,
      Map<String, dynamic> working,
      dynamic deviceInfo,
      String ts,
      dynamic ashaUniqueKey,
      dynamic facilityId,
      ) {
    final rawInfo = row['beneficiary_info'];
    final info = (rawInfo is Map)
        ? Map<String, dynamic>.from(rawInfo)
        : (rawInfo is String && rawInfo.isNotEmpty)
        ? Map<String, dynamic>.from(jsonDecode(rawInfo))
        : <String, dynamic>{};

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
            'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}'),
            'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}'),
            'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}'),
            'captured_at': tsCap?.toString() ?? DateTime.now().toUtc().toIso8601String(),
          }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
        }
      } catch (_) {}
      return {
        'lat': null,
        'lng': null,
        'accuracy_m': null,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    }

    final beneficiaryInfoApi = {
      'name': {
        'first_name': (info['headName'] ?? info['memberName'] ?? info['name'] ?? '').toString(),
        'middle_name': '',
        'last_name': '',
      },
      'gender': _genderCode(info['gender']?.toString()),
      'dob': _yyyyMMdd(info['dob']?.toString()),
      'marital_status': (info['maritalStatus'] ?? 'married').toString().toLowerCase(),
      'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
      'phone': (info['mobileNo'] ?? '').toString(),
      'address': {
        'state': working['state'] ?? userDetails['stateName'],
        'district': working['district'] ?? userDetails['districtName'],
        'block': working['block'] ?? userDetails['blockName'],
        'village': info['village'] ?? working['village'] ?? userDetails['villageName'],
        'pincode': working['pincode'] ?? userDetails['pincode'],
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),

      'is_abha_verified': info['is_abha_verified'] ?? false,
      'is_rch_id_verified': info['is_rch_id_verified'] ?? false,
      'is_fetched_from_abha': info['is_fetched_from_abha'] ?? false,
      'is_fetched_from_rch': info['is_fetched_from_rch'] ?? false,
      'is_existing_father': info['is_existing_father'] ?? false,
      'is_existing_mother': info['is_existing_mother'] ?? false,
      'ben_type': info['ben_type'] ?? (info['memberType'] ?? 'adult'),
      'mother_ben_ref_key': info['mother_ben_ref_key'] ?? row['mother_key']?.toString() ?? '',
      'father_ben_ref_key': info['father_ben_ref_key'] ?? row['father_key']?.toString() ?? '',
      'relaton_with_family_head':
      info['relaton_with_family_head'] ?? info['relation_to_head'] ?? 'self',
      'member_status': info['member_status'] ?? 'alive',
      'member_name': info['member_name'] ?? info['headName'] ?? info['memberName'] ?? info['name'],
      'father_or_spouse_name':
      info['father_or_spouse_name'] ?? info['fatherName'] ?? info['spouseName'] ?? '',
      'have_children': info['have_children'] ?? info['hasChildren'],
      'is_family_planning': info['is_family_planning'] ?? row['is_family_planning'] ?? 0,
      'total_children': info['total_children'] ?? info['totalBorn'],
      'total_live_children': info['total_live_children'] ?? info['totalLive'],
      'total_male_children': info['total_male_children'] ?? info['totalMale'],
      'age_of_youngest_child':
      info['age_of_youngest_child'] ?? info['youngestAge'],
      'gender_of_younget_child':
      info['gender_of_younget_child'] ?? info['youngestGender'],
      'whose_mob_no': info['whose_mob_no'] ?? info['mobileOwner'],
      'mobile_no': info['mobile_no'] ?? info['mobileNo'],
      'dob_day': info['dob_day'],
      'dob_month': info['dob_month'],
      'dob_year': info['dob_year'],
      'age_by': info['age_by'],
      'date_of_birth': info['date_of_birth'] ?? info['dob'],
      'age': info['age'] ?? info['approxAge'],
      'village_name': info['village_name'] ?? info['village'],
      'is_new_member': info['is_new_member'] ?? true,
      'isFamilyhead': info['isFamilyhead'] ?? true,
      'isFamilyheadWife': info['isFamilyheadWife'] ?? false,
      'age_of_youngest_child_unit':
      info['age_of_youngest_child_unit'] ?? info['ageUnit'],
      'type_of_beneficiary':
      info['type_of_beneficiary'] ?? info['beneficiaryType'] ?? 'staying_in_house',
      'name_of_spouse': info['name_of_spouse'] ?? info['spouseName'] ?? '',
    }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

    return {
      'unique_key': row['unique_key'],
      'id': row['id'],
      'household_ref_key': row['household_ref_key'],
      'beneficiary_state': [
        {
          'state': 'registered',
          'at': DateTime.now().toUtc().toIso8601String(),
        },
        {
          'state': (row['beneficiary_state'] ?? 'active').toString(),
          'at': DateTime.now().toUtc().toIso8601String(),
        },
      ],
      'pregnancy_count': row['pregnancy_count'] ?? 0,
      'beneficiary_info': beneficiaryInfoApi,
      'geo_location': _apiGeo(row['geo_location']),
      'spouse_key': row['spouse_key'],
      'mother_key': row['mother_key'],
      'father_key': row['father_key'],
      'is_family_planning': row['is_family_planning'] ?? 0,
      'is_adult': row['is_adult'] ?? 1,
      'is_guest': row['is_guest'] ?? 0,
      'is_death': row['is_death'] ?? 0,
      'death_details': row['death_details'] is Map ? row['death_details'] : {},
      'is_migrated': row['is_migrated'] ?? 0,
      'is_separated': row['is_separated'] ?? 0,
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
      'current_user_key': row['current_user_key'] ?? ashaUniqueKey,
      'facility_id': row['facility_id'] ?? facilityId,
      'created_date_time': row['created_date_time'] ?? ts,
      'modified_date_time': row['modified_date_time'] ?? ts,
    };
  }
}
