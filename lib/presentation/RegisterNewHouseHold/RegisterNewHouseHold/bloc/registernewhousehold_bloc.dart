import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:medixcel_new/core/utils/device_info_utils.dart';
import 'package:medixcel_new/core/utils/geolocation_utils.dart';
import 'package:medixcel_new/core/utils/id_generator_utils.dart';
import 'package:medixcel_new/data/Local_Storage/User_Info.dart';
import 'package:medixcel_new/data/repositories/HousholdRepository/household_repository.dart';

import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';

part 'registernewhousehold_event.dart';
part 'registernewhousehold_state.dart';

class RegisterNewHouseholdBloc
    extends Bloc<RegisternewhouseholdEvent, RegisterHouseholdState> {
  final HouseholdRepository _householdRepository = HouseholdRepository();
  RegisterNewHouseholdBloc() : super(const RegisterHouseholdState()) {
    //  Add Head
    on<RegisterAddHead>((event, emit) {
      final current = state;

      final updated = List<Map<String, String>>.from(current.members);
      final data = Map<String, String>.from(event.data);
      data['#'] = '${updated.length + 1}';
      data['Relation'] = data['Relation'] ?? 'Self';
      updated.add(data);

      emit(
        current.copyWith(
          headAdded: true,
          totalMembers: current.totalMembers + 1,
          members: updated,
        ),
      );
    });

    //  Add Member
    on<RegisterAddMember>((event, emit) {
      final current = state;

      final updated = List<Map<String, String>>.from(current.members);
      final data = Map<String, String>.from(event.data);
      data['#'] = '${updated.length + 1}';
      updated.add(data);

      emit(
        current.copyWith(
          totalMembers: current.totalMembers + 1,
          members: updated,
        ),
      );
    });

    //  Reset
    on<RegisterReset>((event, emit) {
      emit(const RegisterHouseholdState());
    });

     on<SaveHousehold>((event, emit) async {
      try {
        emit(state.saving());

        final now = DateTime.now();
        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

        //  Get Location
        final geoLocation = await GeoLocation.getCurrentLocation();
        print(
          geoLocation.hasCoordinates
              ? '📍 Location obtained - Lat: ${geoLocation.latitude}, Long: ${geoLocation.longitude}, Accuracy: ${geoLocation.accuracy?.toStringAsFixed(2)}m'
              : '⚠️ Could not obtain location: ${geoLocation.error}',
        );

        //  Device Info
        late DeviceInfo deviceInfo;
        try {
          deviceInfo = await DeviceInfo.getDeviceInfo();
        } catch (e) {
          print('Error getting package/device info: $e');
        }

        //  Debug: Raw Data
        print(' Raw Form Data from Event:');
        event.amenitiesData.forEach((key, value) {
          print('- $key: $value (${value?.runtimeType})');
        });

        //  Household Info
        final householdInfo = {
          'residentialArea':
          event.amenitiesData['residentialArea']?.toString().trim() ??
              'Not Specified',
          'houseType': event.amenitiesData['houseType']?.toString().trim() ??
              'Not Specified',
          'ownershipType':
          event.amenitiesData['ownershipType']?.toString().trim() ??
              'Not Specified',
          'houseKitchen':
          event.amenitiesData['houseKitchen']?.toString().trim() ??
              'Not Specified',
          'cookingFuel':
          event.amenitiesData['cookingFuel']?.toString().trim() ??
              'Not Specified',
          'waterSource':
          event.amenitiesData['waterSource']?.toString().trim() ??
              'Not Specified',
          'electricity':
          event.amenitiesData['electricity']?.toString().trim() ??
              'Not Specified',
          'toilet': event.amenitiesData['toilet']?.toString().trim() ??
              'Not Specified',
          'toiletType': event.amenitiesData['toiletType']?.toString().trim() ??
              'Not Specified',
          'toiletPlace': event.amenitiesData['toiletPlace']?.toString().trim() ??
              'Not Specified',
          'lastUpdated': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'appdetails': {
            'app_version': deviceInfo.appVersion,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
          },
        };

        print(' Final Household Data to be saved:');
        householdInfo.forEach((key, value) {
          print('   - $key: $value');
        });

        final householdInfoString = Map<String, String>.fromIterable(
          householdInfo.entries,
          key: (entry) => entry.key,
          value: (entry) => entry.value?.toString() ?? 'Not Specified',
        );

        final householdInfoJson = jsonEncode(householdInfoString);
        print(' Household Info JSON: $householdInfoJson');

        final beneficiaries = await LocalStorageDao.instance.getAllBeneficiaries();
        if (beneficiaries.isEmpty) {
          throw Exception('No existing beneficiary found to derive keys. Add a member first.');
        }
        final latestBeneficiary = beneficiaries.first;
        final uniqueKey = (latestBeneficiary['household_ref_key'] ?? '').toString();
        final headId = (latestBeneficiary['unique_key'] ?? '').toString();

        String familyHeadUniqueKey = headId;
        String familyHeadName = '';
        try {
          final related = beneficiaries
              .where((b) => (b['household_ref_key'] ?? '').toString() == uniqueKey)
              .toList();

          Map<String, dynamic>? picked;

          // Prefer explicit head/self markers
          for (final b in related) {
            final infoRaw = b['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                : (infoRaw as Map<String, dynamic>? ?? {});
            final rel = (info['relation'] ?? info['relation_to_head'] ?? info['Relation'] ?? '')
                .toString()
                .toLowerCase();
            if (rel == 'self' || rel == 'head' || rel == 'family head') {
              picked = b as Map<String, dynamic>;
              break;
            }
          }

          // If no explicit head, and we have Wife/Husband, pick the opposite spouse as head
          if (picked == null) {
            final byKey = {
              for (final b in related)
                (b['unique_key'] ?? '').toString(): b,
            };

            for (final b in related) {
              final infoRaw = b['beneficiary_info'];
              final Map<String, dynamic> info = infoRaw is String
                  ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                  : (infoRaw as Map<String, dynamic>? ?? {});
              final rel = (info['relation'] ?? info['relation_to_head'] ?? info['Relation'] ?? '')
                  .toString()
                  .toLowerCase();

              if (rel == 'wife' || rel == 'husband') {
                final spouseKey = (b['spouse_key'] ?? '').toString();
                if (spouseKey.isNotEmpty && byKey.containsKey(spouseKey)) {
                  picked = Map<String, dynamic>.from(byKey[spouseKey] as Map);
                  break;
                }
              }
            }
          }

          if (picked == null && related.isNotEmpty) {
            picked = related.first as Map<String, dynamic>;
          }
          if (picked != null) {
            familyHeadUniqueKey = (picked['unique_key'] ?? familyHeadUniqueKey).toString();
            final infoRaw = picked['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                : (infoRaw as Map<String, dynamic>? ?? {});
            familyHeadName = (info['headName'] ?? info['name'] ?? info['memberName'] ?? '').toString();
          }
        } catch (e) {
          print('Error deriving family head from beneficiaries: $e');
        }

        final locationData = Map<String, String>.from(geoLocation.toJson());
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        final geoLocationJson = jsonEncode(locationData);
        print(' Final location data: $geoLocationJson');


        final currentUser = await UserInfo.getCurrentUser();
        final userDetails = currentUser?['details'] is String
            ? jsonDecode(currentUser?['details'] ?? '{}')
            : currentUser?['details'] ?? {};


        final working = userDetails['working_location'] ?? {};

        final address = {
          'state_name': working['state'] ?? userDetails['stateName'] ?? '',
          'state_id': _asInt(working['state_id']) ?? userDetails['stateId'] ?? 1,
          'state_lgd_code': userDetails['stateLgdCode'] ?? 1,
          'division_name': working['division'] ?? userDetails['division'] ?? 'Patna',
          'division_id': _asInt(working['division_id']) ?? userDetails['divisionId'] ?? 27,
          'division_lgd_code': userDetails['divisionLgdCode'] ?? 198,
          'district_name': working['district'] ?? userDetails['districtName'],
          'district_id': _asInt(working['district_id']) ?? userDetails['districtId'],
          'block_name': working['block'] ?? userDetails['blockName'],
          'block_id': _asInt(working['block_id']) ?? userDetails['blockId'],
          'village_name': working['village'] ?? userDetails['villageName'],
          'village_id': _asInt(working['village_id']) ?? userDetails['villageId'],
          'hsc_id': _asInt(working['hsc_id']) ?? userDetails['facility_hsc_id'],
          'hsc_name': working['hsc_name'] ?? userDetails['facility_hsc_name'],
          'hsc_hfr_id': working['hsc_hfr_id'] ?? userDetails['facility_hfr_id'],
          'asha_id': working['asha_id'] ?? userDetails['asha_id'],
          'pincode': working['pincode'] ?? userDetails['pincode'],
          'user_identifier': working['user_identifier'] ?? userDetails['user_identifier'],
        }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));


        final facilityId = working['asha_associated_with_facility_id'] ??
            userDetails['asha_associated_with_facility_id'] ?? 0;


        final ashaUniqueKey = userDetails['unique_key'] ?? {};


        final householdPayload = {
          'server_id': null,
          'unique_key': uniqueKey,
          'address': jsonEncode(address),
          'geo_location': geoLocationJson,
          // Store the true family head beneficiary unique_key in head_id
          'head_id': familyHeadUniqueKey,
          'household_info': householdInfoJson,
          'device_details': jsonEncode({
            'id': deviceInfo.deviceId,
            'platform': deviceInfo.platform,
            'version': deviceInfo.osVersion,
            'model': deviceInfo.model,
          }),
          'app_details': jsonEncode({
            'app_version': deviceInfo.appVersion.split('+').first,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
            "instance": "prod"
          }),
          'parent_user': jsonEncode({}),
          'current_user_key': ashaUniqueKey,
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        print('Saving household with payload: ${jsonEncode(householdPayload)}');
        await LocalStorageDao.instance.insertHousehold(householdPayload);

        Map<String, dynamic>? matchedHousehold;
        try {
          final households = await LocalStorageDao.instance.getAllHouseholds();
          for (final h in households) {
            if ((h['unique_key'] ?? '').toString() == uniqueKey) {
              matchedHousehold = Map<String, dynamic>.from(h);
              break;
            }
          }
          matchedHousehold ??= households.isNotEmpty
              ? Map<String, dynamic>.from(households.first)
              : null;
        } catch (e) {
          print('Error fetching household for API address: $e');
        }

        final apiUniqueKey = (matchedHousehold?['unique_key'] ?? uniqueKey).toString();

        try {
          final related = beneficiaries
              .where((b) => (b['household_ref_key'] ?? '').toString() == apiUniqueKey)
              .toList();

          Map<String, dynamic>? picked;

          // Prefer explicit head/self markers
          for (final b in related) {
            final infoRaw = b['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                : (infoRaw as Map<String, dynamic>? ?? {});
            final rel = (info['relation'] ?? info['relation_to_head'] ?? info['Relation'] ?? '')
                .toString()
                .toLowerCase();
            if (rel == 'self' || rel == 'head' || rel == 'family head') {
              picked = b as Map<String, dynamic>;
              break;
            }
          }

          // If no explicit head, and we have Wife/Husband, pick the opposite spouse as head
          if (picked == null) {
            final byKey = {
              for (final b in related)
                (b['unique_key'] ?? '').toString(): b,
            };

            for (final b in related) {
              final infoRaw = b['beneficiary_info'];
              final Map<String, dynamic> info = infoRaw is String
                  ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                  : (infoRaw as Map<String, dynamic>? ?? {});
              final rel = (info['relation'] ?? info['relation_to_head'] ?? info['Relation'] ?? '')
                  .toString()
                  .toLowerCase();

              if (rel == 'wife' || rel == 'husband') {
                final spouseKey = (b['spouse_key'] ?? '').toString();
                if (spouseKey.isNotEmpty && byKey.containsKey(spouseKey)) {
                  picked = Map<String, dynamic>.from(byKey[spouseKey] as Map);
                  break;
                }
              }
            }
          }

          picked ??= related.isNotEmpty ? related.first as Map<String, dynamic> : null;
          if (picked != null) {
            familyHeadUniqueKey = (picked['unique_key'] ?? familyHeadUniqueKey).toString();
            final infoRaw = picked['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                : (infoRaw as Map<String, dynamic>? ?? {});
            familyHeadName = (info['headName'] ?? info['name'] ?? info['memberName'] ?? '').toString();
          }
        } catch (e) {
          print('Error re-deriving family head with apiUniqueKey: $e');
        }

        Map<String, dynamic> apiAddress = {};
        try {
          final addrRaw = matchedHousehold?['address'];
          if (addrRaw is String) {
            apiAddress = Map<String, dynamic>.from(jsonDecode(addrRaw));
          } else if (addrRaw is Map) {
            apiAddress = Map<String, dynamic>.from(addrRaw as Map);
          } else {
            apiAddress = Map<String, dynamic>.from(address);
          }
          apiAddress.removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
        } catch (e) {
          print('Error parsing API address from household: $e');
          apiAddress = Map<String, dynamic>.from(address);
        }

        Map<String, dynamic> apiGeo = {
          'lat': geoLocation.latitude,
          'long': geoLocation.longitude,
          'accuracy_m': geoLocation.accuracy,
          'captured_datetime': DateTime.now().toUtc().toIso8601String(),
        };
        try {
          final g = matchedHousehold?['geo_location'];
          if (g is String && g.trim().isNotEmpty) {
            apiGeo = Map<String, dynamic>.from(jsonDecode(g));
          } else if (g is Map) {
            apiGeo = Map<String, dynamic>.from(g as Map);
          }
        } catch (e) {
          print('Error parsing geo_location from household: $e');
        }

        Map<String, dynamic> apiDevice = {
          'device_id': deviceInfo.deviceId,
          'platform': deviceInfo.platform,
          'platform_version': deviceInfo.osVersion,
        }..removeWhere((k, v) => v == null || (v is String && v is String && v.isEmpty));
        try {
          final d = matchedHousehold?['device_details'];
          if (d is String && d.trim().isNotEmpty) {
            apiDevice = Map<String, dynamic>.from(jsonDecode(d));
          } else if (d is Map) {
            apiDevice = Map<String, dynamic>.from(d as Map);
          }
        } catch (e) {
          print('Error parsing device_details from household: $e');
        }

        Map<String, dynamic> storedInfo = {};
        try {
          final infoRaw = matchedHousehold?['household_info'];
          if (infoRaw is String) {
            storedInfo = Map<String, dynamic>.from(jsonDecode(infoRaw));
          } else if (infoRaw is Map) {
            storedInfo = Map<String, dynamic>.from(infoRaw as Map);
          }
        } catch (e) {
          print('Error parsing stored household_info: $e');
        }

        final apiHouseholdInfo = {
          'household_details': {
            'type_of_residential_area': storedInfo['residentialArea'] ?? event.amenitiesData['residentialArea'],
            'type_of_house': storedInfo['houseType'] ?? event.amenitiesData['houseType'],
            'house_ownership': storedInfo['ownershipType'] ?? event.amenitiesData['ownershipType'],
          },
          'household_amenities': {
            'is_kitchen_outside': storedInfo['houseKitchen'] ?? event.amenitiesData['houseKitchen'],
            'type_of_fuel_used_for_cooking': storedInfo['cookingFuel'] ?? event.amenitiesData['cookingFuel'],
            'primary_source_of_water': storedInfo['waterSource'] ?? event.amenitiesData['waterSource'],
            'availability_of_electricity': storedInfo['electricity'] ?? event.amenitiesData['electricity'],
            'availability_of_toilet': storedInfo['toilet'] ?? event.amenitiesData['toilet'],
            'type_of_toilet': storedInfo['toiletType'] ?? event.amenitiesData['toiletType'],
            'where_do_you_go_for_toilet': storedInfo['toiletPlace'] ?? event.amenitiesData['toiletPlace'],
          }
        };

        Map<String, dynamic> apiApp = {
          'version': deviceInfo.appVersion.split('+').first,
          'instance': 'uat',
        };
        try {
          final a = matchedHousehold?['app_details'];
          if (a is String && a.trim().isNotEmpty) {
            apiApp = Map<String, dynamic>.from(jsonDecode(a));
          } else if (a is Map) {
            apiApp = Map<String, dynamic>.from(a as Map);
          }
        } catch (e) {
          print('Error parsing app_details from household: $e');
        }

        final apiPayload = {
          'unique_key': apiUniqueKey,
          'address': apiAddress,
          'family_head_details': {
            'unique_key': familyHeadUniqueKey,
            'name': familyHeadName,
          },
          'household_info': apiHouseholdInfo,
          'geo_location': apiGeo,
          'device_details': apiDevice,
          'app_details': apiApp,
          'parent_user': {
            // 'user_key': userDetails['supervisor_user_key'] ?? '',
            // 'name': userDetails['supervisor_name'] ?? '',
            // 'facility_id': userDetails['supervisor_facility_id'] ?? facilityId,
          },
          'current_user_key':  _asInt(matchedHousehold?['current_user_key']),
          'facility_id': _asInt(matchedHousehold?['facility_id']),
          'division_id': _asInt(apiAddress['division_id']),
          'division_name': apiAddress['division_name'],
          'district_id': _asInt(apiAddress['district_id']),
          'district_name': apiAddress['district_name'],
          'block_id': _asInt(apiAddress['block_id']),
          'block_name': apiAddress['block_name'],
          'hsc_id': _asInt(apiAddress['hsc_id']),
          'hsc_name': apiAddress['hsc_name'],
          'village_id': _asInt(apiAddress['village_id']),
          'village_name': apiAddress['village_name'],
          'facilitator_id': matchedHousehold?['facilitator_id'],
          'facilitator_name': matchedHousehold?['facilitator_name'],
          'facilitator_username': matchedHousehold?['facilitator_username'],
          'ashwin_id': matchedHousehold?['ashwin_id'] ?? apiAddress['asha_id'],
          'area_of_working': storedInfo['residentialArea'],
          'asha_mobile_no': matchedHousehold?['asha_mobile_no'],
          'asha_name': matchedHousehold?['asha_name'],
          'is_processed': 0,
          'is_data_processed': 0,
          'is_summary_processed': 0,
          'is_deleted': 0,
        };

        Map<String, dynamic> _clean(Map<String, dynamic> m) => m
          ..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

        final cleanedPayload = _clean(apiPayload);


        print(' Household and all members saved locally, proceeding to background sync.');
        emit(state.saved());

        () async {
          print('📡 Posting add_household: ' + jsonEncode(cleanedPayload));
          try {
            final apiResp = await _householdRepository.addHousehold(cleanedPayload);
            print('✅ add_household response: $apiResp');
            try {
              if (apiResp is Map && (apiResp['success'] == true) && apiResp['data'] is List) {
                final List dataList = apiResp['data'] as List;
                for (final item in dataList) {
                  if (item is Map) {
                    final serverId = (item['_id'] ?? item['id'] ?? '').toString();
                    final respUniqueKey = (item['unique_key'] ?? apiUniqueKey).toString();
                    if (serverId.isNotEmpty && respUniqueKey.isNotEmpty) {
                      final updated = await LocalStorageDao.instance.updateHouseholdServerIdByUniqueKey(
                        uniqueKey: respUniqueKey,
                        serverId: serverId,
                      );
                      print('🗄️ Updated $updated row(s) with server_id=$serverId for unique_key=$respUniqueKey');
                    }
                  }
                }
              }
            } catch (e) {
              print('Error updating local household with server id: $e');
            }
          } catch (apiError) {
            print('⚠️ add_household API failed, continuing with local save: $apiError');
          }
        }();
      } catch (e, stackTrace) {
        print('❌ Error saving household data: $e');
        print('Stack trace: $stackTrace');
        emit(
          state.saveFailed('Failed to save household data: ${e.toString()}'),
        );
      }
    });
  }

  dynamic _convertYesNoDynamic(dynamic value) {
    if (value is String) {
      if (value == 'Yes') return 1;
      if (value == 'No') return 0;
      return value;
    } else if (value is Map) {
      return _convertYesNoMap(Map<String, dynamic>.from(value as Map));
    } else if (value is List) {
      return value.map(_convertYesNoDynamic).toList();
    }
    return value;
  }

  Map<String, dynamic> _convertYesNoMap(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((k, v) {
      out[k] = _convertYesNoDynamic(v);
    });
    return out;
  }


  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }
    return int.tryParse(v.toString());
  }
}
