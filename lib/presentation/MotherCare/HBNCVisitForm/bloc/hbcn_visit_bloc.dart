import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/device_info_utils.dart';
import '../../../../data/Local_Storage/User_Info.dart';
import '../../../../data/Local_Storage/database_provider.dart';
import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../../../data/Local_Storage/tables/followup_form_data_table.dart';
import '../../../../data/SecureStorage/SecureStorage.dart';
import 'hbcn_visit_event.dart';
import 'hbcn_visit_state.dart';

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
    emit(state.copyWith(isSaving: true, saveSuccess: false, errorMessage: null));

    try {
      // Validate required fields before saving
      final validationErrors = <String>[];
      final visitDetails = state.visitDetails;
      
      if (visitDetails['visitDate'] == null) {
        validationErrors.add('Visit date is required');
      }
      if (visitDetails['visitNumber']?.toString().isEmpty ?? true) {
        validationErrors.add('Visit number is required');
      }
      
      if (validationErrors.isNotEmpty) {
        emit(state.copyWith(
          isSaving: false,
          errorMessage: validationErrors.join('\n'),
          validationErrors: validationErrors,
        ));
        return;
      }

      // Prepare data for saving
      emit(state.copyWith(isSubmitting: true, errorMessage: null));

      try {
        final db = await DatabaseProvider.instance.database;
        final now = DateTime.now().toIso8601String();
        final beneficiaryId = event.beneficiaryData != null
            ? (event.beneficiaryData!['unique_key']?.toString() ?? '')
            : '';

        final formType = FollowupFormDataTable.hbycForm;
        final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'Delivery Outcome';
        final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '';

        String? beneficiaryRefKey = beneficiaryId.isNotEmpty ? beneficiaryId : null;

        // Helper function to convert DateTime objects to ISO strings
        Map<String, dynamic> _convertDatesToStrings(Map<String, dynamic> data) {
          return data.map((key, value) {
            if (value is DateTime) {
              return MapEntry(key, value.toIso8601String());
            } else if (value is Map<String, dynamic>) {
              return MapEntry(key, _convertDatesToStrings(value));
            } else if (value is Map) {
              return MapEntry(key, _convertDatesToStrings(Map<String, dynamic>.from(value)));
            }
            return MapEntry(key, value);
          });
        }

        final processedMotherDetails = _convertDatesToStrings(Map<String, dynamic>.from(state.motherDetails));
        final processedNewbornDetails = _convertDatesToStrings(Map<String, dynamic>.from(state.newbornDetails));
        final processedVisitDetails = _convertDatesToStrings(Map<String, dynamic>.from(state.visitDetails));

        final formData = {
          'form_type': formType,
          'form_name': formName,
          'unique_key': formsRefKey,
          'form_data': {
            'beneficiaryId': beneficiaryId.length >= 11
                ? beneficiaryId.substring(beneficiaryId.length - 11)
                : beneficiaryId,
            'motherDetails': processedMotherDetails,
            'newbornDetails': processedNewbornDetails,
            'visitDetails': processedVisitDetails,
          },
          'created_at': now,
          'updated_at': now,
        };

        String householdRefKey = '';
        String motherKey = '';
        String fatherKey = '';

        if (beneficiaryId.isNotEmpty) {
          List<Map<String, dynamic>> beneficiaryMaps = await db.query(
            'beneficiaries',
            where: 'unique_key = ?',
            whereArgs: [beneficiaryId],
          );

          if (beneficiaryMaps.isEmpty) {
            beneficiaryMaps = await db.query(
              'beneficiaries',
              where: 'id = ?',
              whereArgs: [int.tryParse(beneficiaryId) ?? 0],
            );
          }

          if (beneficiaryMaps.isNotEmpty) {
            final beneficiary = beneficiaryMaps.first;
            householdRefKey = beneficiary['household_ref_key'] as String? ?? '';
            motherKey = beneficiary['mother_key'] as String? ?? '';
            fatherKey = beneficiary['father_key'] as String? ?? '';
          }
        }

        final formDataForDb = {
          'server_id': '',
          'forms_ref_key': formsRefKey,
          'household_ref_key': householdRefKey,
          'beneficiary_ref_key': beneficiaryId,
          'mother_key': motherKey,
          'father_key': fatherKey,
          'child_care_state': '',
          'device_details': jsonEncode({
            'id': await DeviceInfo.getDeviceInfo().then((value) => value.deviceId),
            'platform': await DeviceInfo.getDeviceInfo().then((value) => value.platform),
            'version': await DeviceInfo.getDeviceInfo().then((value) => value.osVersion),
          }),
          'app_details': jsonEncode({
            'app_version': await DeviceInfo.getDeviceInfo().then((value) => value.appVersion.split('+').first),
            'app_name': await DeviceInfo.getDeviceInfo().then((value) => value.appName),
            'build_number': await DeviceInfo.getDeviceInfo().then((value) => value.buildNumber),
            'package_name': await DeviceInfo.getDeviceInfo().then((value) => value.packageName),
          }),
          'parent_user': '',
          'current_user_key': '',
          'facility_id': await UserInfo.getCurrentUser().then((value) {
            if (value != null) {
              if (value['details'] is String) {
                try {
                  final userDetails = jsonDecode(value['details'] ?? '{}');
                  return userDetails['asha_associated_with_facility_id'] ??
                      userDetails['facility_id'] ??
                      userDetails['facilityId'] ??
                      userDetails['facility'] ??
                      0;
                } catch (e) {
                  return 0;
                }
              } else if (value['details'] is Map) {
                final userDetails = Map<String, dynamic>.from(value['details']);
                return userDetails['asha_associated_with_facility_id'] ??
                    userDetails['facility_id'] ??
                    userDetails['facilityId'] ??
                    userDetails['facility'] ??
                    0;
              }
            }
            return 0;
          }),
          'form_json': jsonEncode(formData),
          'created_date_time': now,
          'modified_date_time': now,
          'is_synced': 0,
          'is_deleted': 0,
        };

        try {
          final formId = await LocalStorageDao.instance.insertFollowupFormData(formDataForDb);

          try {
            final outcomeData = {
              'id': formId,
              'beneficiaryId': beneficiaryId.length >= 11
                  ? beneficiaryId.substring(beneficiaryId.length - 11)
                  : beneficiaryId,
              'motherDetails': processedMotherDetails,
              'newbornDetails': processedNewbornDetails,
              'visitDetails': processedVisitDetails,
              'isSubmit': true,
              'form_data': formDataForDb,
            };

            // Save to secure storage for offline access
            await SecureStorageService.saveDeliveryOutcome(outcomeData);

            // Update submission status and reset loading states
            emit(state.copyWith(
              isSubmitting: false,
              isSaving: false,
              saveSuccess: true,
              errorMessage: null,
            ));

            if (beneficiaryId.isNotEmpty) {
              try {
                final newCount = await SecureStorageService.incrementVisitCount(beneficiaryId);
                print('Submission count for beneficiary $beneficiaryId: $newCount');
              } catch (e) {
                print('Error updating submission count: $e');
              }
            }
          } catch (e) {
            print('Error saving to secure storage: $e');
            emit(state.copyWith(
              isSubmitting: false,
              isSaving: false,
              saveSuccess: true,
              errorMessage: 'Failed to save delivery outcome to secure storage.',
            ));
          }
        } catch (e) {
          print('Error saving delivery outcome to database: $e');
          emit(state.copyWith(
            isSubmitting: false,
            isSaving: false,
            saveSuccess: true,
            errorMessage: 'Failed to save delivery outcome to database.',
          ));
        }
      } catch (e, stackTrace) {
        print('Error in delivery outcome submission: $e');
        print('Stack trace: $stackTrace');
        emit(state.copyWith(
          isSubmitting: false,
          isSaving: false,
          saveSuccess: true,
          errorMessage: 'An unexpected error occurred. Please try again.',
        ));
      }
    } catch (e) {
      print('Error saving HBNC visit: $e');
      emit(state.copyWith(
        isSaving: false,
        saveSuccess: true,
        errorMessage: 'Failed to save HBNC visit: ${e.toString()}',
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
    final updatedDetails = Map<String, dynamic>.from(state.newbornDetails);
    updatedDetails[event.field] = event.value;
    emit(state.copyWith(newbornDetails: updatedDetails));
  }

  void _onVisitDetailsChanged(
      VisitDetailsChanged event, Emitter<HbncVisitState> emit) {
    final updatedDetails = Map<String, dynamic>.from(state.visitDetails);
    updatedDetails[event.field] = event.value;
    emit(state.copyWith(visitDetails: updatedDetails));
  }

  Future<void> _onSubmitHbncVisit(
      SubmitHbncVisit event, Emitter<HbncVisitState> emit) async {
    emit(state.copyWith(isSubmitting: true));

    try {
      print('Mother Details: ' + jsonEncode(state.motherDetails));
      print('Visit Details: ' + jsonEncode(state.visitDetails));
      print('Newborn Details: ' + jsonEncode(state.newbornDetails));
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
      req('motherStatus', 'err_mother_status_required');
      req('mcpCardAvailable', 'err_mcp_mother_required');
      req('postDeliveryProblems', 'err_post_delivery_problems_required');
      req('breastfeedingProblems', 'err_breastfeeding_problems_required');
      req('padsPerDay', 'err_pads_per_day_required');
      req('temperature', 'err_mothers_temperature_required');
      req('foulDischargeHighFever', 'err_foul_discharge_high_fever_required');
      req('abnormalSpeechOrSeizure', 'err_abnormal_speech_or_seizure_required');
      // Newly added starred fields
      req('counselingAdvice', 'err_counseling_advice_required');
      req('milkNotProducingOrLess', 'err_milk_not_producing_or_less_required');
      req('nippleCracksPainOrEngorged', 'err_nipple_cracks_pain_or_engorged_required');
    } else if (idx == 2) {
      final c = state.newbornDetails;
      void req(String key, String code) {
        final val = c[key];
        if (val == null || (val is String && val.trim().isEmpty)) {
          errors.add(code);
        }
      }
      req('babyCondition', 'err_baby_condition_required');
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
      // Newly added breastfeeding section
      req('exclusiveBreastfeedingStarted', 'err_exclusive_breastfeeding_started_required');
      req('firstBreastfeedTiming', 'err_first_breastfeed_timing_required');
      req('howWasBreastfed', 'err_how_was_breastfed_required');
      req('firstFeedGivenAfterBirth', 'err_first_feed_given_after_birth_required');
      req('adequatelyFedSevenToEightTimes', 'err_adequately_fed_seven_eight_required');
      req('babyDrinkingLessMilk', 'err_baby_drinking_less_milk_required');
      req('breastfeedingStopped', 'err_breastfeeding_stopped_required');
      req('bloatedStomachOrFrequentVomiting', 'err_bloated_or_frequent_vomit_required');
    }

    emit(state.copyWith(
      lastValidatedIndex: idx,
      lastValidationWasSave: event.isSave,
      validationErrors: errors,
      validationTick: state.validationTick + 1,
    ));
  }
}
