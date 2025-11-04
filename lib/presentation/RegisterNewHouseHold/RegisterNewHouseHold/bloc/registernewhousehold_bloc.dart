import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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

        // Debug prints for head and member details
        print('Head Details:');
        print(const JsonEncoder.withIndent('  ').convert(event.headForm ?? {}));
        print('Member Details:');
        print(const JsonEncoder.withIndent('  ').convert(event.memberForms));

        // Get the current state from amenities bloc
        final hhState = event.hhBloc.state;

        // Create household info with all amenities data
        final householdInfo = <String, dynamic>{
          'residentialArea': hhState.residentialArea,
          'ownershipType': hhState.ownershipType,
          'houseType': hhState.houseType,
          'houseKitchen': hhState.houseKitchen,
          'cookingFuel': hhState.cookingFuel,
          'waterSource': hhState.waterSource,
          'electricity': hhState.electricity,
          'toilet': hhState.toilet,
        };

        // Encode the household info to JSON string
        final householdInfoJson = jsonEncode(householdInfo);
        print('Household Amenities JSON: $householdInfoJson');

        // Prepare beneficiary info
        final beneficiaryInfo = {
          'head_details': event.headForm ?? {},
          'spouse_details': event.headForm?['spousedetails'] ?? {},
          'children_details': event.headForm?['childrendetails'] ?? {},
          'member_details': event.memberForms,
        };

        // Generate unique keys
        final householdKey = 'HH_${now.millisecondsSinceEpoch}';
        final headId = event.headForm?['unique_key'] ?? event.headForm?['id'];

        // Prepare household payload for database
        final householdPayload = {
          'server_id': null,
          'unique_key': householdKey,
          'address': jsonEncode({}),
          'geo_location': jsonEncode({}),
          'head_id': headId,
          'household_info': householdInfoJson, // Use the pre-encoded JSON string
          'device_details': jsonEncode({'platform': Platform.operatingSystem}),
          'app_details': jsonEncode({'app_name': 'BHAVYA mASHA UAT'}),
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

        final beneficiaryPayload = {
          'server_id': null,
          'household_ref_key': householdKey,
          'unique_key': headId,
          'beneficiary_state': 'active',
          'pregnancy_count': 0,
          'beneficiary_info': beneficiaryInfo,
          'geo_location': {},
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
          'device_details': {'platform': Platform.operatingSystem},
          'app_details': {'app_name': 'BHAVYA mASHA UAT'},
          'parent_user': {},
          'current_user_key': 'local_user',
          'facility_id': 283,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        await LocalStorageDao.instance.insertBeneficiary(beneficiaryPayload);

        print('✅ Household saved successfully!');
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
}
