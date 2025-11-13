import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:medixcel_new/core/extensions/string_extensions.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';

part 'eligible_coule_update_event.dart';
part 'eligible_coule_update_state.dart';

class EligibleCouleUpdateBloc
    extends Bloc<EligibleCouleUpdateEvent, EligibleCouleUpdateState> {
  EligibleCouleUpdateBloc() : super(EligibleCouleUpdateState.initial()) {
    on<InitializeForm>(_onInitializeForm);
    on<RegistrationDateChanged>((e, emit) =>
        emit(state.copyWith(registrationDate: e.date, clearError: true)));
    on<RchIdChanged>((e, emit) => emit(state.copyWith(rchId: e.rchId, clearError: true)));
    on<WomanNameChanged>((e, emit) => emit(state.copyWith(womanName: e.name, clearError: true)));
    on<CurrentAgeChanged>((e, emit) => emit(state.copyWith(currentAge: e.age, clearError: true)));
    on<AgeAtMarriageChanged>((e, emit) => emit(state.copyWith(ageAtMarriage: e.age, clearError: true)));
    on<AddressChanged>((e, emit) => emit(state.copyWith(address: e.address, clearError: true)));
    on<WhoseMobileChanged>((e, emit) => emit(state.copyWith(whoseMobile: e.whose, clearError: true)));
    on<MobileNoChanged>((e, emit) => emit(state.copyWith(mobileNo: e.mobile, clearError: true)));
    on<ReligionChanged>((e, emit) => emit(state.copyWith(religion: e.religion, clearError: true)));
    on<CategoryChanged>((e, emit) => emit(state.copyWith(category: e.category, clearError: true)));
    on<TotalChildrenBornChanged>((e, emit) => emit(state.copyWith(totalChildrenBorn: e.value, clearError: true)));
    on<TotalLiveChildrenChanged>((e, emit) => emit(state.copyWith(totalLiveChildren: e.value, clearError: true)));
    on<TotalMaleChildrenChanged>((e, emit) => emit(state.copyWith(totalMaleChildren: e.value, clearError: true)));
    on<TotalFemaleChildrenChanged>((e, emit) => emit(state.copyWith(totalFemaleChildren: e.value, clearError: true)));
    on<YoungestChildAgeChanged>((e, emit) => emit(state.copyWith(youngestChildAge: e.value, clearError: true)));
    on<YoungestChildAgeUnitChanged>((e, emit) =>
        emit(state.copyWith(youngestChildAgeUnit: e.unit, clearError: true)));
    on<YoungestChildGenderChanged>((e, emit) =>
        emit(state.copyWith(youngestChildGender: e.gender, clearError: true)));
    on<SubmitPressed>(_onSubmit);
  }

  Future<void> _onInitializeForm(InitializeForm event, Emitter<EligibleCouleUpdateState> emit) async {
    final data = event.initialData;
    print('\n🚀 ====== INITIALIZING FORM ======');
    print('📋 Received data: $data');

    try {
      // Extract data directly from the passed arguments
      final name = data['name']?.toString() ?? '';
      final mobile = data['mobile']?.toString() ?? data['mobileno']?.toString() ?? '';
      final rchId = data['RichID']?.toString() ?? '';
      final ageGender = data['ageGender']?.toString() ?? '';
      final hhId = data['hhId']?.toString() ?? '';
      final beneficiaryId = data['BeneficiaryID']?.toString() ?? '';

      // Parse age from ageGender (format: "31 Y / Other")
      String currentAge = '';
      if (ageGender.isNotEmpty) {
        final parts = ageGender.split('/');
        if (parts.isNotEmpty) {
          final agePart = parts[0].trim(); // "31 Y"
          final ageMatch = RegExp(r'(\d+)').firstMatch(agePart);
          if (ageMatch != null) {
            currentAge = ageMatch.group(1) ?? '';
          }
        }
      }

      print('✅ Parsed values:');
      print('   👤 Name: $name');
      print('   🆔 RCH ID: $rchId');
      print('   📅 Age: $currentAge (from: $ageGender)');
      print('   📱 Mobile: $mobile');
      print('   🏠 HH ID: $hhId');

      // Now query the database to get full beneficiary details
      final db = await DatabaseProvider.instance.database;
      final rows = await db.query(
        'beneficiaries',
        where: 'household_ref_key LIKE ?',
        whereArgs: ['%$hhId'],
      );

      if (rows.isEmpty) {
        print('⚠️ No beneficiary found in database, using only passed data');
        // Use only the data passed from previous screen
        emit(state.copyWith(
          rchId: rchId,
          womanName: name,
          currentAge: currentAge,
          mobileNo: mobile,
          beneficiaryName: name,
          clearError: true,
        ));
        return;
      }

      print('✅ Found ${rows.length} potential household(s)');

      // Find the matching row by name
      Map<String, dynamic>? matchedRow;
      for (final row in rows) {
        try {
          final beneficiaryInfoJson = row['beneficiary_info'] as String? ?? '{}';
          final beneficiaryInfo = jsonDecode(beneficiaryInfoJson) as Map<String, dynamic>;
          final headDetails = Map<String, dynamic>.from(beneficiaryInfo['head_details'] as Map? ?? {});
          final spouseDetails = Map<String, dynamic>.from(beneficiaryInfo['spouse_details'] as Map? ??
              headDetails['spousedetails'] as Map? ?? {});

          final headName = headDetails['headName']?.toString() ?? headDetails['memberName']?.toString() ?? '';
          final spouseName = spouseDetails['memberName']?.toString() ?? spouseDetails['spouseName']?.toString() ?? '';

          // Check if name matches head or spouse
          if (name.toLowerCase() == headName.toLowerCase() || name.toLowerCase() == spouseName.toLowerCase()) {
            matchedRow = row;
            print('✅ Found matching record for name: $name');
            break;
          }
        } catch (e) {
          print('⚠️ Error parsing row: $e');
          continue;
        }
      }

      if (matchedRow == null) {
        print('⚠️ No matching beneficiary found in database, using only passed data');
        // Use only the data passed from previous screen
        emit(state.copyWith(
          rchId: rchId,
          womanName: name,
          currentAge: currentAge,
          mobileNo: mobile,
          beneficiaryName: name,
          clearError: true,
        ));
        return;
      }

      final row = matchedRow;
      print('✅ Found beneficiary record in database');

      // Store the database row ID and household_ref_key for later update
      final dbRowId = row['id'] as int?;
      final householdRefKey = row['household_ref_key'] as String?;

      final beneficiaryInfoJson = row['beneficiary_info'] as String? ?? '{}';
      final beneficiaryInfo = jsonDecode(beneficiaryInfoJson) as Map<String, dynamic>;

      print('📦 Beneficiary info keys: ${beneficiaryInfo.keys.join(', ')}');

      // Extract nested data
      final headDetails = Map<String, dynamic>.from(beneficiaryInfo['head_details'] as Map? ?? {});
      final spouseDetails = Map<String, dynamic>.from(beneficiaryInfo['spouse_details'] as Map? ??
          headDetails['spousedetails'] as Map? ?? {});
      final childrenDetails = Map<String, dynamic>.from(beneficiaryInfo['children_details'] as Map? ??
          headDetails['childrendetails'] as Map? ?? {});

      print('👤 Head details keys: ${headDetails.keys.join(', ')}');
      print('👥 Spouse details keys: ${spouseDetails.keys.join(', ')}');
      print('👶 Children details keys: ${childrenDetails.keys.join(', ')}');

      // Determine if we're dealing with head or spouse based on the name
      final headName = headDetails['headName']?.toString() ?? headDetails['memberName']?.toString() ?? '';
      final spouseName = spouseDetails['memberName']?.toString() ?? spouseDetails['spouseName']?.toString() ?? '';

      final isHead = name.toLowerCase() == headName.toLowerCase();
      print('🎯 Is Head: $isHead (name: $name, headName: $headName, spouseName: $spouseName)');

      // Extract woman's details (the eligible couple member)
      final womanDetails = isHead ? headDetails : spouseDetails;

      // Get address components
      final village = headDetails['village']?.toString() ?? '';
      final mohalla = headDetails['mohalla']?.toString() ?? headDetails['tola']?.toString() ?? '';
      final ward = headDetails['ward']?.toString() ?? '';
      final address = [village, mohalla, ward].where((e) => e.isNotEmpty).join(', ');

      // Prepare the state update with database values, but prioritize passed values for basic fields
      final newState = state.copyWith(
        // Use passed data for basic fields (this is what user expects to see)
        rchId: rchId.isNotEmpty ? rchId : (womanDetails['RichIDChanged']?.toString() ??
            womanDetails['richIdChanged']?.toString() ??
            womanDetails['RichID']?.toString() ?? ''),
        womanName: name, // Always use the passed name
        currentAge: currentAge, // Always use the parsed age
        mobileNo: mobile, // Always use the passed mobile

        // Use database values for other fields
        ageAtMarriage: womanDetails['ageAtMarriage']?.toString() ?? '',
        address: address,
        whoseMobile: womanDetails['mobileOwner']?.toString() ?? 'Self',
        religion: womanDetails['religion']?.toString() ??
            headDetails['religion']?.toString() ?? '',
        category: womanDetails['category']?.toString() ??
            headDetails['category']?.toString() ??
            womanDetails['caste']?.toString() ??
            headDetails['caste']?.toString() ?? '',

        // Children details from database
        totalChildrenBorn: childrenDetails['totalBorn']?.toString() ?? '0',
        totalLiveChildren: childrenDetails['totalLive']?.toString() ?? '0',
        totalMaleChildren: childrenDetails['totalMale']?.toString() ?? '0',
        totalFemaleChildren: childrenDetails['totalFemale']?.toString() ?? '0',
        youngestChildAge: childrenDetails['youngestAge']?.toString() ?? '0',
        youngestChildAgeUnit: _capitalizeFirst(childrenDetails['ageUnit']?.toString() ?? 'Years'),
        youngestChildGender: _capitalizeFirst(childrenDetails['youngestGender']?.toString() ?? ''),

        // Set registration date and database tracking fields
        registrationDate: DateTime.tryParse(row['created_date_time']?.toString() ?? '') ?? DateTime.now(),
        dbRowId: dbRowId,
        householdRefKey: householdRefKey,
        beneficiaryName: name,
        clearError: true,
      );

      print('✅ Form initialized successfully');
      print('   👤 Woman Name: ${newState.womanName}');
      print('   🆔 RCH ID: ${newState.rchId}');
      print('   📅 Age: ${newState.currentAge}');
      print('   📱 Mobile: ${newState.mobileNo}');
      print('   🏠 Address: ${newState.address}');

      emit(newState);

    } catch (e, stackTrace) {
      print('❌ ERROR initializing form: $e');
      print('Stack trace: $stackTrace');

      // Even if there's an error, try to use the basic data passed from previous screen
      try {
        final name = data['name']?.toString() ?? '';
        final mobile = data['mobile']?.toString() ?? data['mobileno']?.toString() ?? '';
        final rchId = data['RichID']?.toString() ?? '';
        final ageGender = data['ageGender']?.toString() ?? '';

        String currentAge = '';
        if (ageGender.isNotEmpty) {
          final parts = ageGender.split('/');
          if (parts.isNotEmpty) {
            final agePart = parts[0].trim();
            final ageMatch = RegExp(r'(\d+)').firstMatch(agePart);
            if (ageMatch != null) {
              currentAge = ageMatch.group(1) ?? '';
            }
          }
        }

        emit(state.copyWith(
          rchId: rchId,
          womanName: name,
          currentAge: currentAge,
          mobileNo: mobile,
          beneficiaryName: name,
          error: 'Using basic data only. Full details unavailable.',
        ));
      } catch (fallbackError) {
        emit(state.copyWith(
          error: 'Failed to load beneficiary data: ${e.toString()}',
        ));
      }
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  Future<void> _onSubmit(
      SubmitPressed event,
      Emitter<EligibleCouleUpdateState> emit,
      ) async {
    if (!state.isValid) {
      emit(state.copyWith(error: 'Please fill required fields', isSubmitting: false));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      print('\n🚀 ====== UPDATING BENEFICIARY ======');
      print('📋 DB Row ID: ${state.dbRowId}');
      print('📋 Household Ref Key: ${state.householdRefKey}');
      print('📋 Beneficiary Name: ${state.beneficiaryName}');

      if (state.dbRowId == null || state.householdRefKey == null) {
        emit(state.copyWith(
          error: 'Missing database reference. Cannot update.',
          isSubmitting: false,
        ));
        return;
      }

      // Get the database
      final db = await DatabaseProvider.instance.database;

      // Fetch the current beneficiary record
      final rows = await db.query(
        'beneficiaries',
        where: 'id = ?',
        whereArgs: [state.dbRowId],
        limit: 1,
      );

      if (rows.isEmpty) {
        emit(state.copyWith(
          error: 'Beneficiary record not found',
          isSubmitting: false,
        ));
        return;
      }

      final currentRow = rows.first;
      final beneficiaryInfoJson = currentRow['beneficiary_info'] as String? ?? '{}';
      final beneficiaryInfo = jsonDecode(beneficiaryInfoJson) as Map<String, dynamic>;

      print('📦 Current beneficiary info: ${beneficiaryInfo.keys.join(', ')}');

      final updatedChildrenDetails = {
        'totalBorn': state.totalChildrenBorn,
        'totalLive': state.totalLiveChildren,
        'totalMale': state.totalMaleChildren,
        'totalFemale': state.totalFemaleChildren,
        'youngestAge': state.youngestChildAge,
        'ageUnit': state.youngestChildAgeUnit.toLowerCase(),
        'youngestGender': state.youngestChildGender.toLowerCase(),
      };

      beneficiaryInfo['children_details'] = updatedChildrenDetails;

      if (beneficiaryInfo.containsKey('head_details')) {
        final headDetails = Map<String, dynamic>.from(beneficiaryInfo['head_details'] as Map? ?? {});
        if (headDetails.containsKey('childrendetails')) {
          headDetails['childrendetails'] = updatedChildrenDetails;
          beneficiaryInfo['head_details'] = headDetails;
        }
      }

      print('✅ Updated children details: $updatedChildrenDetails');

      final updatedBeneficiaryInfoJson = jsonEncode(beneficiaryInfo);

      final updateCount = await db.update(
        'beneficiaries',
        {
          'beneficiary_info': updatedBeneficiaryInfoJson,
          'modified_date_time': DateTime.now().toIso8601String(),
          'is_synced': 0, // Mark as not synced since we updated locally
        },
        where: 'id = ?',
        whereArgs: [state.dbRowId],
      );

      print('✅ Updated $updateCount row(s) in database');

      if (updateCount > 0) {
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      } else {
        emit(state.copyWith(
          error: 'Failed to update database',
          isSubmitting: false,
        ));
      }

    } catch (e, stackTrace) {
      print('❌ ERROR updating beneficiary: $e');
      print('Stack trace: $stackTrace');
      emit(state.copyWith(
        error: 'Failed to update: ${e.toString()}',
        isSubmitting: false,
      ));
    }
  }
}