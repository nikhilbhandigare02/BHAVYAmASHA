import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:medixcel_new/core/utils/device_info_utils.dart';
import 'package:medixcel_new/core/utils/geolocation_utils.dart';


import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';

part 'registernewhousehold_event.dart';
part 'registernewhousehold_state.dart';

class RegisterNewHouseholdBloc extends Bloc<RegisternewhouseholdEvent, RegisterHouseholdState> {
  RegisterNewHouseholdBloc() : super(const RegisterHouseholdState()) {
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

    on<RegisterReset>((event, emit) {
      emit(const RegisterHouseholdState());
    });

    on<SaveHousehold>((event, emit) async {
      try {
        emit(state.saving());

        final now = DateTime.now();
        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
        
        // Get device location
        final geoLocation = await GeoLocation.getCurrentLocation();
        print(geoLocation.hasCoordinates 
            ? '📍 Location obtained - Lat: ${geoLocation.latitude}, Long: ${geoLocation.longitude}, Accuracy: ${geoLocation.accuracy?.toStringAsFixed(2)}m'
            : '⚠️ Could not obtain location: ${geoLocation.error}');
        
        late DeviceInfo deviceInfo;
        
        try {
          deviceInfo = await DeviceInfo.getDeviceInfo();
          
        } catch (e) {
          print('Error getting package/device info: $e');
        }

        // print('Head Details:');
        // print(const JsonEncoder.withIndent('  ').convert(event.headForm ?? {}));
        // print('Member Details:');
        // print(const JsonEncoder.withIndent('  ').convert(event.memberForms));

        print('📋 Raw Form Data from Event:');
        event.amenitiesData.forEach((key, value) {
          print('- $key: $value (${value?.runtimeType})');
        });

        final householdInfo = {
          'residentialArea': event.amenitiesData['residentialArea']?.toString().trim() ?? 'Not Specified',
          'houseType': event.amenitiesData['houseType']?.toString().trim() ?? 'Not Specified',
          'ownershipType': event.amenitiesData['ownershipType']?.toString().trim() ?? 'Not Specified',
          
          'houseKitchen': event.amenitiesData['houseKitchen']?.toString().trim() ?? 'Not Specified',
          'cookingFuel': event.amenitiesData['cookingFuel']?.toString().trim() ?? 'Not Specified',
          'waterSource': event.amenitiesData['waterSource']?.toString().trim() ?? 'Not Specified',
          'electricity': event.amenitiesData['electricity']?.toString().trim() ?? 'Not Specified',
          'toilet': event.amenitiesData['toilet']?.toString().trim() ?? 'Not Specified',
          
          'lastUpdated': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'appdetails': {
            'app_version': deviceInfo.appVersion,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
          },
        };
        
        print('💾 Final Household Data to be saved:');
        householdInfo.forEach((key, value) {
          print('   - $key: $value');
        });
        
        final householdInfoJson = jsonEncode(householdInfo);
        print('📄 Household Info JSON: $householdInfoJson');



        final householdKey = 'HH_${now.millisecondsSinceEpoch}';
        final headId = event.headForm?['unique_key'] ?? event.headForm?['id'];

        final locationData = geoLocation.toJson();
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        
        final geoLocationJson = jsonEncode(locationData);
        print('🌐 Final location data: $geoLocationJson');
        
        final householdPayload = {
          'server_id': null,
          'unique_key': householdKey,
          'address': jsonEncode({}),
          'geo_location': geoLocationJson,
          'head_id': headId,
          'household_info': householdInfoJson,
          'device_details': jsonEncode({
            'id': deviceInfo.deviceId,
            'platform': deviceInfo.platform,
            'version': deviceInfo.osVersion
          }),
          'app_details': jsonEncode({
            'app_version': deviceInfo.appVersion.split('+').first,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
          }),
          'parent_user': jsonEncode({}),
          'current_user_key': 'local_user',
          'facility_id': 283,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        print('Saving household with payload: ${jsonEncode(householdPayload)}');

        await LocalStorageDao.instance.insertHousehold(householdPayload);

        final beneficiaryInfo = jsonEncode({
          'head_details': _toJsonSafe(event.headForm) ?? {},
          'spouse_details': _toJsonSafe(event.headForm?['spousedetails']) ?? {},
          'children_details': _toJsonSafe(event.headForm?['childrendetails']) ?? {},
          'member_details': event.memberForms.map((m) => _toJsonSafe(m)).toList(),
        });
        print('Beneficiary Info JSON: $beneficiaryInfo');



        final beneficiaryPayload = {
          'server_id': null,
          'household_ref_key': householdKey,
          'unique_key': headId,
          'beneficiary_state': 'active',
          'pregnancy_count': 0,
          'beneficiary_info': beneficiaryInfo,
          'geo_location': geoLocationJson,
          'spouse_key': event.headForm?['spousedetails']?['unique_key'],
          'mother_key': null,
          'father_key': null,
          'is_family_planning': 0,
          'is_adult': 1, 
          'is_guest': 0,
          'is_death': 0,
          'death_details': {},
          'is_migrated': 0,
          'is_separated': 0,
          'device_details': {
            'id': deviceInfo.deviceId,
            'platform': deviceInfo.platform,
            'version': deviceInfo.osVersion
          },
          'app_details': jsonEncode({
            'app_version': deviceInfo.appVersion.split('+').first,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
          }),
          'parent_user': {},
          'current_user_key': 'local_user',
          'facility_id': 283,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        await LocalStorageDao.instance.insertBeneficiary(beneficiaryPayload);

        for (var member in event.memberForms) {
          final isAdult = (member['memberType']?.toString().toLowerCase() == 'adult') ? 1 : 0;
          final isDeath = (member['memberStatus']?.toString().toLowerCase() == 'death') ? 1 : 0;

          final memberPayload = {
            'server_id': null,
            'household_ref_key': householdKey,
            'unique_key': member['unique_key'] ?? 'member_${DateTime.now().millisecondsSinceEpoch}',
            'beneficiary_state': 'active',
            'pregnancy_count': 0,
            'beneficiary_info': jsonEncode(_toJsonSafe(member)),
            'geo_location': geoLocationJson,
            'spouse_key': null,
            'mother_key': member['mother_key'],
            'father_key': member['father_key'],
            'is_family_planning': 0,
            'is_adult': isAdult,
            'is_guest': 0,
            'is_death': isDeath,
            'death_details': {},
            'is_migrated': 0,
            'is_separated': 0,
            'device_details': {
              'id': deviceInfo.deviceId,
              'platform': deviceInfo.platform,
              'version': deviceInfo.osVersion
            },
            'app_details': jsonEncode({
              'app_version': deviceInfo.appVersion.split('+').first,
              'app_name': deviceInfo.appName,
              'build_number': deviceInfo.buildNumber,
              'package_name': deviceInfo.packageName,
            }),
            'parent_user': {},
            'current_user_key': 'local_user',
            'facility_id': 283,
            'created_date_time': ts,
            'modified_date_time': ts,
            'is_synced': 0,
            'is_deleted': 0,
          };

          await LocalStorageDao.instance.insertBeneficiary(memberPayload);
          print('✅ Saved family member: ${member['name']} (${isAdult == 1 ? 'Adult' : 'Child'})');
        }

        print('✅ Household and all members saved successfully!');
        emit(state.saved());
      } catch (e, stackTrace) {
        print('❌ Error saving household data: $e');
        print('Stack trace: $stackTrace');
        emit(state.saveFailed('Failed to save household data: ${e.toString()}'));
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

  // Helper method to safely convert objects to JSON-serializable format
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
