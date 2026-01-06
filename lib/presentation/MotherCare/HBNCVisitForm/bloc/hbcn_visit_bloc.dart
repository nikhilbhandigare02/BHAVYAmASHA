import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/utils/device_info_utils.dart';
import '../../../../data/Database/User_Info.dart';
import '../../../../data/Database/database_provider.dart';

import '../../../../data/Database/local_storage_dao.dart';
import '../../../../data/Database/tables/followup_form_data_table.dart';
import '../../../../data/Database/tables/mother_care_activities_table.dart';
import '../../../../data/SecureStorage/SecureStorage.dart';

import 'hbcn_visit_event.dart';
import 'hbcn_visit_state.dart';


Map<String, dynamic> _convertDatesToStrings(Map<String, dynamic> data) {
  final result = <String, dynamic>{};
  data.forEach((key, value) {
    if (value is DateTime) {
      result[key] = value.toIso8601String();
    } else if (value is Map<String, dynamic>) {
      result[key] = _convertDatesToStrings(value);
    } else if (value is List) {
      result[key] = value.map((item) {
        if (item is Map<String, dynamic>) {
          return _convertDatesToStrings(item);
        } else if (item is DateTime) {
          return item.toIso8601String();
        }
        return item;
      }).toList();
    } else {
      result[key] = value;
    }
  });
  return result;
}

class HbncVisitBloc extends Bloc<HbncVisitEvent, HbncVisitState> {
  HbncVisitBloc() : super(const HbncVisitState()) {
    on<TabChanged>(_onTabChanged);
    on<MotherDetailsChanged>(_onMotherDetailsChanged);
    on<NewbornDetailsChanged>(_onNewbornDetailsChanged);
    on<VisitDetailsChanged>(_onVisitDetailsChanged);
    on<SubmitHbncVisit>(_onSubmitHbncVisit);
    on<SaveHbncVisit>(_onSaveHbncVisit);
    on<ResetHbncVisitForm>(_onResetHbncVisitForm);
    on<ValidateSection>(_onValidateSection);
  }

  Future<void> _onSaveHbncVisit(
      SaveHbncVisit event, Emitter<HbncVisitState> emit) async {
    print('🚀 _onSaveHbncVisit started');
    emit(state.copyWith(isSaving: true, saveSuccess: false, errorMessage: null));

    try {
      print('🔍 Validating form data...');
      final validationErrors = <String>[];
      final visitDetails = state.visitDetails;

      print('📋 Visit details: $visitDetails');
      print('👤 Beneficiary data: ${event.beneficiaryData}');

      if (visitDetails['visitDate'] == null) {
        validationErrors.add('Visit date is required');
      }
      if (visitDetails['visitNumber']?.toString().isEmpty ?? true) {
        validationErrors.add('Visit number is required');
      }

      if (validationErrors.isNotEmpty) {
        final errorMessage = validationErrors.join('\n');
        print('❌ Validation errors: $errorMessage');
        emit(state.copyWith(
          isSaving: false,
          errorMessage: errorMessage,
          validationErrors: validationErrors,
        ));
        return;
      }

      print('✅ Form validation passed');
      emit(state.copyWith(isSubmitting: true, errorMessage: null));

      final db = await DatabaseProvider.instance.database;
      print('🔌 Database connection established');

      final now = DateTime.now().toIso8601String();
      print('⏰ Current time: $now' );

      final beneficiaryId = event.beneficiaryData != null
          ? (event.beneficiaryData!['unique_key']?.toString() ?? '')
          : '';

      print('👤 Beneficiary ID: $beneficiaryId');

      // Get household reference key from beneficiary data
      String? householdRefKey;
      String? motherKey;
      String? fatherKey;

      if (event.beneficiaryData != null) {
        householdRefKey = event.beneficiaryData!['household_ref_key']?.toString();
        motherKey = event.beneficiaryData!['mother_key']?.toString();
        fatherKey = event.beneficiaryData!['father_key']?.toString();
        print('🏠 Household Ref Key: $householdRefKey');
        print('👩 Mother Key: $motherKey');
        print('👨 Father Key: $fatherKey');
      }

      final formType = FollowupFormDataTable.pncMother;
      final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'PNC Mother';
      final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '';

      print('📝 Form Details:');
      print('  - Type: $formType');
      print('  - Name: $formName');
      print('  - Ref Key: $formsRefKey');

      final userInfo = await UserInfo.getCurrentUser();
      final facilityId = userInfo?['facility_id']?.toString() ?? '0';
      final currentUserKey = userInfo?['user_key']?.toString() ?? '';

      print('👤 Current User:');
      print('  - User Key: $currentUserKey');
      print('  - Facility ID: $facilityId');

      // Update the device info section
      final deviceInfo = await DeviceInfo.getDeviceInfo();
      final appInfo = {
        'app_version': deviceInfo.appVersion.split('+').first,
        'build_number': deviceInfo.buildNumber,
        'platform': deviceInfo.platform,
        'os_version': deviceInfo.osVersion,
        'device_id': deviceInfo.deviceId,
      };

      final formData = _convertDatesToStrings({
        'form_type': formType,
        'form_name': formName,
        'unique_key': formsRefKey,
        'hbyc_form': {
          'motherDetails': state.motherDetails,
          'newbornDetailsList': state.newbornDetailsList,
          'visitDetails': state.visitDetails,
        },
        'created_at': now,
        'updated_at': now,
      });

      final followupData = {
        'server_id': '',
        'forms_ref_key': formsRefKey,
        'household_ref_key': householdRefKey,
        'beneficiary_ref_key': beneficiaryId.isNotEmpty ? beneficiaryId : null,
        'mother_key': motherKey,
        'father_key': fatherKey,
        'child_care_state': '',
        'device_details': jsonEncode({
          'id': deviceInfo.deviceId,
          'platform': deviceInfo.platform,
          'version': deviceInfo.osVersion,

        }),
        'app_details': jsonEncode(appInfo),
        'parent_user': '',
        'current_user_key': currentUserKey,
        'facility_id': int.tryParse(facilityId) ?? 0,
        'form_json': jsonEncode(formData),
        'created_date_time': now,
        'modified_date_time': now,
        'is_synced': 0,
        'is_deleted': 0,
      };
      print('💾 Attempting to save followup data:');
      print('  - Table: ${FollowupFormDataTable.table}');
      print('  - Forms Ref Key: $formsRefKey');
      print('  - Beneficiary Ref Key: $beneficiaryId');
      print('  - Form Data: ${jsonEncode(formData)}');

      try {
        final id = await db.insert(
          FollowupFormDataTable.table,
          followupData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('✅ Record inserted with ID: $id');

        // Verify the data was saved
        final savedData = await db.query(
          FollowupFormDataTable.table,
          where: 'id = ?',
          whereArgs: [id],
        );

        print('🔍 Saved data verification:');
        print('  - ID: ${savedData.first['id']}');
        print('  - Forms Ref Key: ${savedData.first['forms_ref_key']}');
        print('  - Beneficiary Ref Key: ${savedData.first['beneficiary_ref_key']}');
        print('  - Created: ${savedData.first['created_date_time']}');

        final visitNumber = state.visitDetails['visitNumber'] as int?;

        // Also close the mother care activity if both mother and baby are recorded as death
        final motherStatus = state.motherDetails['motherStatus']?.toString();
        String? babyCondition;
        if (state.newbornDetailsList.isNotEmpty) {
          final firstBaby = state.newbornDetailsList.first;
          babyCondition = firstBaby['babyCondition']?.toString();
        }

        final shouldCompleteMotherCare =
            ((visitNumber ?? 0) == 42) ||
            (motherStatus == 'death' && babyCondition == 'death');

        if (beneficiaryId.isNotEmpty && shouldCompleteMotherCare) {
          try {
            final updated = await db.update(
              MotherCareActivitiesTable.table,
              {
                'is_synced': 1,
                'is_deleted': 1,
                'modified_date_time': now,
              },
              where: 'beneficiary_ref_key = ?',
              whereArgs: [beneficiaryId],
            );
            print('🔄 Updated mother_care_activities flags for beneficiary $beneficiaryId. Rows: $updated');
          } catch (e) {
            print('❌ Error updating mother_care_activities flags: $e');
          }
        }

        // if (beneficiaryId.isNotEmpty) {
        //   try {
        //     final visitCount = await SecureStorageService.getVisitCount(beneficiaryId) ?? 0;
        //     final deviceInfo = await DeviceInfo.getDeviceInfo();
        //     final ts = DateTime.now().toIso8601String();
        //
        //     final motherCareActivityData = {
        //       'server_id': null,
        //       'household_ref_key': householdRefKey,
        //       'beneficiary_ref_key': beneficiaryId,
        //       'mother_care_state': 'hbnc_visit_$visitCount',
        //       'device_details': jsonEncode({
        //         'id': deviceInfo.deviceId,
        //         'platform': deviceInfo.platform,
        //         'version': deviceInfo.osVersion,
        //       }),
        //       'app_details': jsonEncode({
        //         'app_version': deviceInfo.appVersion.split('+').first,
        //         'app_name': deviceInfo.appName,
        //         'build_number': deviceInfo.buildNumber,
        //         'package_name': deviceInfo.packageName,
        //       }),
        //       'parent_user': jsonEncode({}),
        //       'current_user_key': currentUserKey,
        //       'facility_id': int.tryParse(facilityId) ?? 0,
        //       'created_date_time': ts,
        //       'modified_date_time': ts,
        //       'is_synced': 0,
        //       'is_deleted': 0,
        //     };
        //
        //     print('Inserting mother care activity for HBNC visit: ${jsonEncode(motherCareActivityData)}');
        //     await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
        //     print('✅ Successfully inserted mother care activity for HBNC visit $visitCount');
        //   } catch (e) {
        //     print('❌ Error inserting mother care activity: $e');
        //   }
        // }



        emit(state.copyWith(
          isSaving: false,
          isSubmitting: false,
          saveSuccess: true,
          errorMessage: null,
        ));
      } catch (e) {
        print('❌ Error inserting record: $e');
        print('Data being inserted: ${jsonEncode(followupData)}');
        rethrow;
      }
    } catch (e, stackTrace) {
      print(' Error in _onSaveHbncVisit: $e');
      print('Stack trace: $stackTrace');
      emit(state.copyWith(
        isSaving: false,
        isSubmitting: false,
        saveSuccess: false,
        errorMessage: 'Unexpected error: $e',
      ));
    }
  }

  void _onTabChanged(TabChanged event, Emitter<HbncVisitState> emit) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  void _onMotherDetailsChanged(
      MotherDetailsChanged event, Emitter<HbncVisitState> emit) {
    final updatedDetails = Map<String, dynamic>.from(state.motherDetails);
    updatedDetails[event.field] = event.value;
    emit(state.copyWith(motherDetails: updatedDetails));
  }

  void _onNewbornDetailsChanged(
      NewbornDetailsChanged event, Emitter<HbncVisitState> emit) {
    final idx = (event.childIndex <= 0) ? 0 : event.childIndex - 1;
    final list = List<Map<String, dynamic>>.from(state.newbornDetailsList);
    while (list.length <= idx) {
      list.add({
        'babyCondition': null,
        'babyName': '',
        'gender': null,
        'weightAtBirth': '',
        'temperature': '',
        'tempUnit': null,
        'weightColorMatch': null,
        'weighingScaleColor': null,
        'motherReportsTempOrChestIndrawing': null,
        'bleedingUmbilicalCord': null,
        'pusInNavel': null,
        'routineCareDone': null,
        'wipedWithCleanCloth': null,
        'keptWarm': null,
        'givenBath': null,
        'wrappedAndPlacedNearMother': null,
        'breathingRapid': null,
        'congenitalAbnormalities': null,
        'eyesNormal': null,
        'eyesSwollenOrPus': null,
        'skinFoldRedness': null,
        'jaundice': null,
        'pusBumpsOrBoil': null,
        'seizures': null,
        'cryingConstantlyOrLessUrine': null,
        'cryingSoftly': null,
        'stoppedCrying': null,
        'referredByASHA': null,
        'birthRegistered': null,
        'birthCertificateIssued': null,
        'birthDoseVaccination': null,
        'mcpCardAvailable': null,
        'referredByASHAFacility': null,
        'referToHospitalFacility': null,
        'navelTiedByAshaAnm': null,
        'weightRecordedInMcpCard': null,
        'referToHospital': null,
        'exclusiveBreastfeedingStarted': null,
        'firstBreastfeedTiming': null,
        'howWasBreastfed': null,
        'firstFeedGivenAfterBirth': null,
        'firstFeedOther': '',
        'adequatelyFedSevenToEightTimes': null,
        'adequatelyFedCounseling': null,
        'babyDrinkingLessMilk': null,
        'breastfeedingStopped': null,
        'bloatedStomachOrFrequentVomiting': null,
        'eyesProblemType': null,
        'cryingCounseling': null,
      });
    }
    final updated = Map<String, dynamic>.from(list[idx]);
    updated[event.field] = event.value;
    list[idx] = updated;
    emit(state.copyWith(newbornDetailsList: list));
  }

  void _onVisitDetailsChanged(
      VisitDetailsChanged event,
      Emitter<HbncVisitState> emit,
      ) {
    final value = event.field == 'visitDate' && event.value is String
        ? DateTime.tryParse(event.value as String) ?? event.value
        : event.value;

    final updatedVisitDetails = Map<String, dynamic>.from(state.visitDetails)
      ..[event.field] = value;

    // Auto-calculate next visit date when visit number changes
    if (event.field == 'visitNumber' && event.value != null) {
      final visitNumber = int.tryParse(event.value.toString()) ?? 0;
      final nextVisitDate = _calculateNextHbncVisitDate(visitNumber);
      
      if (nextVisitDate != null) {
        updatedVisitDetails['nextVisitDate'] = nextVisitDate;
        print('🗓️ Auto-calculated next visit date for visit $visitNumber: $nextVisitDate');
      }
    }

    emit(state.copyWith(visitDetails: updatedVisitDetails));
  }

  /// Calculate next HBNC visit date based on visit number (weeks after delivery)
  String? _calculateNextHbncVisitDate(int visitNumber) {
    try {
      final now = DateTime.now();
      final schedule = <int>[1, 3, 7, 14, 21, 28, 42]; // weeks after delivery
      
      // For initial visit (no previous visits), next visit is 1 week after
      if (visitNumber <= 0) {
        final nextVisitDate = now.add(Duration(days: 7)); // 1 week
        return '${nextVisitDate.year.toString().padLeft(4, '0')}-${nextVisitDate.month.toString().padLeft(2, '0')}-${nextVisitDate.day.toString().padLeft(2, '0')}';
      }
      
      // Find the next visit number in the schedule
      int? nextVisitWeeks;
      for (int i = 0; i < schedule.length; i++) {
        if (schedule[i] == visitNumber && i < schedule.length - 1) {
          nextVisitWeeks = schedule[i + 1];
          break;
        }
      }

      if (nextVisitWeeks == null) {
        // Either visitNumber is 42 (last visit) or not in schedule
        return null;
      }

      // Calculate next visit date as current date + weeks until next visit
      final weeksToAdd = nextVisitWeeks - visitNumber;
      final nextVisitDate = now.add(Duration(days: weeksToAdd * 7));
      
      return '${nextVisitDate.year.toString().padLeft(4, '0')}-${nextVisitDate.month.toString().padLeft(2, '0')}-${nextVisitDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('❌ Error calculating next HBNC visit date: $e');
      return null;
    }
  }

  Future<void> _onSubmitHbncVisit(
      SubmitHbncVisit event, Emitter<HbncVisitState> emit) async {
    emit(state.copyWith(isSubmitting: true));

    try {
      print('Mother Details: ${jsonEncode(state.motherDetails)}');
      print('Visit Details: ${jsonEncode(state.visitDetails)}');
      print('Newborn Details: ${jsonEncode(state.newbornDetailsList)}');
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      emit(state.copyWith(
        isSubmitting: false,
        isSaving: false,
        saveSuccess: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit HBNC visit: $e',
      ));
    }
  }

  void _onResetHbncVisitForm(
      ResetHbncVisitForm event, Emitter<HbncVisitState> emit) {
    emit(const HbncVisitState());
  }

  void _onValidateSection(
      ValidateSection event, Emitter<HbncVisitState> emit) {
    final List<String> errors = [];
    final idx = event.index;

    if (idx == 0) {
      final v = state.visitDetails;
      if (v['visitNumber'] == null || (v['visitNumber'].toString()).isEmpty) {
        errors.add('err_visit_day_required');
      }
      if (v['visitDate'] == null) {
        errors.add('err_visit_date_required');
      }
    } else if (idx == 1) {
      final m = state.motherDetails;
      void req(String key, String code) {
        final val = m[key];
        if (val == null || (val is String && val.trim().isEmpty)) {
          errors.add(code);
        }
      }

      void reqIf(bool condition, String key, String code) {
        if (!condition) return;
        final val = m[key];
        if (val == null || (val is String && val.trim().isEmpty)) {
          errors.add(code);
        }
      }
      req('motherStatus', 'err_mother_status_required');
      req('mcpCardAvailable', 'err_mcp_mother_required');
      reqIf(m['mcpCardAvailable'] == 'Yes', 'mcpCardFilled', 'err_mcp_mother_filled_required');
      req('postDeliveryProblems', 'err_post_delivery_problems_required');
      final hasPostDeliveryProblem =
          m['postDeliveryProblems'] != null && m['postDeliveryProblems'] != 'None';
      reqIf(hasPostDeliveryProblem, 'excessiveBleeding', 'err_excessive_bleeding_required');
      reqIf(hasPostDeliveryProblem, 'unconsciousFits', 'err_unconscious_fits_required');
      req('breastfeedingProblems', 'err_breastfeeding_problems_required');
      reqIf(m['breastfeedingProblems'] == 'Yes', 'breastfeedingProblemDescription', 'err_breastfeeding_problem_description_required');
      reqIf(m['breastfeedingProblems'] == 'Yes', 'breastfeedingHelpGiven', 'err_breastfeeding_help_required');
      req('padsPerDay', 'err_pads_per_day_required');
      req('mealsPerDay', 'err_meals_per_day_required');
      req('temperature', 'err_mothers_temperature_required');
      final _tempStr = (m['temperature'] ?? '').toString();
      final _isUpto102 = _tempStr == 'Temperature upto 102 degree F(38.9 degree C)';
      reqIf(_isUpto102, 'paracetamolGiven', 'err_paracetamol_given_required');
      req('foulDischargeHighFever', 'err_foul_discharge_high_fever_required');
      req('abnormalSpeechOrSeizure', 'err_abnormal_speech_or_seizure_required');
      // Newly added starred fields
      req('counselingAdvice', 'err_counseling_advice_required');
      req('milkNotProducingOrLess', 'err_milk_not_producing_or_less_required');
      reqIf(m['milkNotProducingOrLess'] == 'Yes', 'milkCounselingAdvice', 'err_milk_counseling_advice_required');
      req('nippleCracksPainOrEngorged', 'err_nipple_cracks_pain_or_engorged_required');
      req('referHospital', 'err_refer_hospital_required');
      reqIf(m['referHospital'] == 'Yes', 'referTo', 'err_refer_to_required');
      if (m['motherStatus'] == 'death') {
        errors.clear();
        void reqDeath(String key, String code) {
          final val = m[key];
          if (val == null || (val is String && val.trim().isEmpty)) {
            errors.add(code);
          }
        }
        reqDeath('dateOfDeath', 'err_date_of_death_required');
        reqDeath('deathPlace', 'err_death_place_required');
        reqDeath('reasonOfDeath', 'err_reason_of_death_required');
        if (m['reasonOfDeath'] == 'Other (Specify)') {
          reqDeath('reasonOfDeathOther', 'err_other_reason_of_death_required');
        }
      }
    } else if (idx >= 2) {
      final ci = idx - 2;
      final c = ci < state.newbornDetailsList.length ? state.newbornDetailsList[ci] : <String, dynamic>{};
      void req(String key, String code) {
        final val = c[key];
        if (val == null || (val is String && val.trim().isEmpty)) {
          errors.add(code);
        }
      }
      req('babyCondition', 'err_baby_condition_required');
      final isAlive = c['babyCondition'] == 'alive';
      if (isAlive) {
        req('babyName', 'err_baby_name_required');
        req('gender', 'err_baby_gender_required');
        req('weightAtBirth', 'err_baby_weight_required');
        req('temperature', 'err_newborn_temperature_required');
        req('tempUnit', 'err_infant_temp_unit_required');
        req('weightColorMatch', 'err_weight_color_match_required');
        req('weighingScaleColor', 'err_weighing_scale_color_required');
        req('motherReportsTempOrChestIndrawing', 'err_mother_reports_temp_or_chest_indrawing_required');
        req('bleedingUmbilicalCord', 'err_bleeding_umbilical_cord_required');
        req('pusInNavel', 'err_pus_in_navel_required');
        req('routineCareDone', 'err_routine_care_done_required');
        req('breathingRapid', 'err_breathing_rapid_required');
        req('congenitalAbnormalities', 'err_congenital_abnormalities_required');
        req('eyesNormal', 'err_eyes_normal_required');
        req('eyesSwollenOrPus', 'err_eyes_swollen_or_pus_required');
        req('skinFoldRedness', 'err_skin_fold_redness_required');
        req('jaundice', 'err_newborn_jaundice_required');
        req('pusBumpsOrBoil', 'err_pus_bumps_or_boil_required');
        req('seizures', 'err_newborn_seizures_required');
        req('cryingConstantlyOrLessUrine', 'err_crying_constant_or_less_urine_required');
        req('cryingSoftly', 'err_crying_softly_required');
        req('stoppedCrying', 'err_stopped_crying_required');
        req('referredByASHA', 'err_referred_by_asha_required');
        req('birthRegistered', 'err_birth_registered_required');
        req('birthCertificateIssued', 'err_birth_certificate_issued_required');
        req('birthDoseVaccination', 'err_birth_dose_vaccination_required');
        req('mcpCardAvailable', 'err_mcp_child_required');
        req('exclusiveBreastfeedingStarted', 'err_exclusive_breastfeeding_started_required');
        req('firstBreastfeedTiming', 'err_first_breastfeed_timing_required');
        req('howWasBreastfed', 'err_how_was_breastfed_required');
        req('firstFeedGivenAfterBirth', 'err_first_feed_given_after_birth_required');
        req('adequatelyFedSevenToEightTimes', 'err_adequately_fed_seven_eight_required');
        req('babyDrinkingLessMilk', 'err_baby_drinking_less_milk_required');
        req('breastfeedingStopped', 'err_breastfeeding_stopped_required');
        req('bloatedStomachOrFrequentVomiting', 'err_bloated_or_frequent_vomit_required');
      }
    }

    emit(state.copyWith(
      lastValidatedIndex: idx,
      lastValidationWasSave: event.isSave,
      validationErrors: errors,
      validationTick: state.validationTick + 1,
    ));
  }
}
