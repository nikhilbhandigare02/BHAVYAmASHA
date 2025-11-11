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

import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';

part 'registernewhousehold_event.dart';
part 'registernewhousehold_state.dart';

class RegisterNewHouseholdBloc
    extends Bloc<RegisternewhouseholdEvent, RegisterHouseholdState> {
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

        // Convert all values to string before encoding to JSON
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


        final address = {
          'state_name': userDetails['stateName'] ?? 'Bihar',
          'state_id': userDetails['stateId'] ?? 1,
          'state_lgd_code': userDetails['stateLgdCode'] ?? 1,
          'division_name': userDetails['division'] ?? 'Patna',
          'division_id': userDetails['divisionId'] ?? 27,
          'division_lgd_code': userDetails['divisionLgdCode'] ?? 198,
        };


        final facilityId = userDetails['asha_associated_with_facility_id'] ?? 0;
        
        print('📝 Using address from user profile: $address');
        print('🏥 Using facility ID from user profile: $facilityId');

        final householdPayload = {
          'server_id': null,
          'unique_key': uniqueKey,
          'address': jsonEncode(address),
          'geo_location': geoLocationJson,
          'head_id': headId,
          'household_info': householdInfoJson,
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

        print('Saving household with payload: ${jsonEncode(householdPayload)}');
        await LocalStorageDao.instance.insertHousehold(householdPayload);

        print(' Household and all members saved successfully!');
        emit(state.saved());
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

  //  JSON Safe Conversion
  dynamic _toJsonSafe(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return Map.fromEntries(
        value.entries.map((e) => MapEntry(e.key, _toJsonSafe(e.value))),
      );
    }
    if (value is Iterable) return value.map(_toJsonSafe).toList();
    return value.toString();
  }
}
