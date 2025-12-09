import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:medixcel_new/core/extensions/string_extensions.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';

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

      final beneficiaryId = (data['unique_key'] ?? data['fullBeneficiaryId'] ?? data['BeneficiaryID'])?.toString() ?? '';

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

      // Initialize children data variables
      String totalBorn = '0';
      String totalLive = '0';
      String totalMale = '0';
      String totalFemale = '0';
      String youngestAge = '0';
      String youngestAgeUnit = 'Years';
      String youngestGender = '';

      // Try to extract children data from the initial data
      try {
        if (data['totalBorn'] != null) totalBorn = data['totalBorn'].toString();
        if (data['totalLive'] != null) totalLive = data['totalLive'].toString();
        if (data['totalMale'] != null) totalMale = data['totalMale'].toString();
        if (data['totalFemale'] != null) totalFemale = data['totalFemale'].toString();
        if (data['youngestAge'] != null) youngestAge = data['youngestAge'].toString();
        if (data['youngestAgeUnit'] != null) youngestAgeUnit = data['youngestAgeUnit'].toString();
        if (data['youngestGender'] != null) youngestGender = data['youngestGender'].toString();
      } catch (e) {
        print('⚠️ Error extracting children data: $e');
      }

      print('✅ Parsed values:');
      print('   👤 Name: $name');
      print('   🆔 RCH ID: $rchId');
      print('   📅 Age: $currentAge (from: $ageGender)');
      print('   📱 Mobile: $mobile');
      print('   🏠 HH ID: $hhId');

      // Now query the database to get full beneficiary details
      final db = await DatabaseProvider.instance.database;

      List<Map<String, dynamic>> rows = [];

      if (beneficiaryId.isNotEmpty) {
        // Look up by unique_key when we have the exact beneficiary ID
        rows = await db.query(
          'beneficiaries_new',
          where: 'unique_key = ?',
          whereArgs: [beneficiaryId],
          limit: 1,
        );
      } else if (hhId.isNotEmpty) {
        // Fallback: look up by household_ref_key if beneficiaryId is not available
        rows = await db.query(
          'beneficiaries_new',
          where: 'household_ref_key = ?',
          whereArgs: [hhId],
        );
      }

      if (rows.isEmpty) {
        print('⚠️ No beneficiary found in database, using only passed data');
        // Use only the data passed from previous screen
        emit(state.copyWith(
          rchId: rchId,
          womanName: name,
          currentAge: currentAge,
          mobileNo: mobile,
          otherReligion: data['otherReligion']?.toString() ?? data['other_religion']?.toString() ?? '',
          otherCategory: data['otherCategory']?.toString() ?? data['other_category']?.toString() ?? '',
          totalChildrenBorn: totalBorn,
          totalLiveChildren: totalLive,
          totalMaleChildren: totalMale,
          totalFemaleChildren: totalFemale,
          youngestChildAge: youngestAge,
          youngestChildAgeUnit: youngestAgeUnit,
          youngestChildGender: youngestGender,
          beneficiaryName: name,
          clearError: true,
        ));
        return;
      }

      print('✅ Found ${rows.length} potential record(s)');

      // When we query by unique_key or exact household_ref_key, the first row is the match
      final row = rows.first;
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

      // Try to extract children data from beneficiary info
      if (beneficiaryInfoJson.isNotEmpty) {
        try {
          final info = jsonDecode(beneficiaryInfoJson);

          // Try to extract children data from beneficiary info
          if (info['totalBorn'] != null) totalBorn = info['totalBorn'].toString();
          if (info['totalLive'] != null) totalLive = info['totalLive'].toString();
          if (info['totalMale'] != null) totalMale = info['totalMale'].toString();
          if (info['totalFemale'] != null) totalFemale = info['totalFemale'].toString();
          if (info['youngestAge'] != null) youngestAge = info['youngestAge'].toString();
          if (info['youngestAgeUnit'] != null) youngestAgeUnit = info['youngestAgeUnit'].toString();
          if (info['youngestGender'] != null) youngestGender = info['youngestGender'].toString();

          // Update state with the matched beneficiary info
          emit(state.copyWith(
            rchId: info['RichID']?.toString() ?? rchId,
            womanName: info['memberName']?.toString() ?? name,
            currentAge: info['age']?.toString() ?? currentAge,
            mobileNo: info['mobileNo']?.toString() ?? mobile,
            address: info['address']?.toString() ?? '',
            religion: info['religion']?.toString() ?? state.religion,
            category: info['category']?.toString() ?? state.category,
            otherReligion: (info['otherReligion']?.toString() ?? info['other_religion']?.toString() ?? state.otherReligion),
            otherCategory: (info['otherCategory']?.toString() ?? info['other_category']?.toString() ?? state.otherCategory),
            ageAtMarriage: info['ageAtMarriage']?.toString() ?? state.ageAtMarriage,
            whoseMobile: info['mobileOwner']?.toString() ?? state.whoseMobile,
            totalChildrenBorn: info['totalBorn']?.toString() ?? totalBorn,
            totalLiveChildren: info['totalLive']?.toString() ?? totalLive,
            totalMaleChildren: info['totalMale']?.toString() ?? totalMale,
            totalFemaleChildren: info['totalFemale']?.toString() ?? totalFemale,
            youngestChildAge: info['youngestAge']?.toString() ?? youngestAge,
            youngestChildAgeUnit: info['youngestAgeUnit']?.toString() ?? youngestAgeUnit,
            youngestChildGender: info['youngestGender']?.toString() ?? youngestGender,
            clearError: true,
          ));
        } catch (e) {
          print('⚠️ Error parsing beneficiary info: $e');
        }
      }

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
        ageAtMarriage: womanDetails['ageAtMarriage']?.toString() ?? state.ageAtMarriage,
        address: address,
        whoseMobile: womanDetails['mobileOwner']?.toString() ?? state.whoseMobile,
        religion: womanDetails['religion']?.toString() ??
            headDetails['religion']?.toString() ?? state.religion,
        category: womanDetails['category']?.toString() ??
            headDetails['category']?.toString() ??
            womanDetails['caste']?.toString() ??
            headDetails['caste']?.toString() ?? state.category,
        otherReligion: (womanDetails['otherReligion']?.toString() ?? womanDetails['other_religion']?.toString() ?? headDetails['otherReligion']?.toString() ?? headDetails['other_religion']?.toString() ?? state.otherReligion),
        otherCategory: (womanDetails['otherCategory']?.toString() ?? womanDetails['other_category']?.toString() ?? headDetails['otherCategory']?.toString() ?? headDetails['other_category']?.toString() ?? state.otherCategory),

        // Children details from database
        totalChildrenBorn: childrenDetails['totalBorn']?.toString() ?? totalBorn,
        totalLiveChildren: childrenDetails['totalLive']?.toString() ?? totalLive,
        totalMaleChildren: childrenDetails['totalMale']?.toString() ?? totalMale,
        totalFemaleChildren: childrenDetails['totalFemale']?.toString() ?? totalFemale,
        youngestChildAge: childrenDetails['youngestAge']?.toString() ?? youngestAge,
        youngestChildAgeUnit: _capitalizeFirst(childrenDetails['ageUnit']?.toString() ?? youngestAgeUnit),
        youngestChildGender: _capitalizeFirst(childrenDetails['youngestGender']?.toString() ?? youngestGender),

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

      final rows = await db.query(
        'beneficiaries_new',
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

      // Update the database
      final updateCount = await db.update(
        'beneficiaries_new',
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
      print('  ERROR updating beneficiary: $e');
      print('Stack trace: $stackTrace');
      emit(state.copyWith(
        error: 'Failed to update: ${e.toString()}',
        isSubmitting: false,
      ));
    }
  }
}
