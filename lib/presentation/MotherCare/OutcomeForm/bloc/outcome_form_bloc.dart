import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../../../core/utils/device_info_utils.dart';
import '../../../../data/Local_Storage/User_Info.dart';
import '../../../../data/Local_Storage/database_provider.dart';
import '../../../../data/Local_Storage/local_storage_dao.dart';
import '../../../../data/Local_Storage/tables/followup_form_data_table.dart';
import '../../../../data/SecureStorage/SecureStorage.dart';

part 'outcome_form_event.dart';
part 'outcome_form_state.dart';

class OutcomeFormBloc extends Bloc<OutcomeFormEvent, OutcomeFormState> {
  OutcomeFormBloc() : super(OutcomeFormState.initial()) {
    on<OutcomeFormInitialized>((event, emit) {
      emit(state.copyWith(
        householdId: event.householdId,
        beneficiaryId: event.beneficiaryId,
      ));
    });
    on<DeliveryDateChanged>((event, emit) {
      emit(state.copyWith(deliveryDate: event.date, errorMessage: null));
    });
    on<GestationWeeksChanged>((event, emit) {
      emit(state.copyWith(gestationWeeks: event.weeks, errorMessage: null));
    });
    on<DeliveryTimeChanged>((event, emit) {
      emit(state.copyWith(deliveryTime: event.time, errorMessage: null));
    });
    on<PlaceOfDeliveryChanged>((event, emit) {
      emit(state.copyWith(placeOfDelivery: event.value, errorMessage: null));
    });
    on<DeliveryTypeChanged>((event, emit) {
      emit(state.copyWith(deliveryType: event.value, errorMessage: null));
    });
    on<ComplicationsChanged>((event, emit) {
      emit(state.copyWith(complications: event.value, errorMessage: null));
    });
    on<OutcomeCountChanged>((event, emit) {
      emit(state.copyWith(outcomeCount: event.value, errorMessage: null));
    });
    on<FamilyPlanningCounselingChanged>((event, emit) {
      emit(state.copyWith(familyPlanningCounseling: event.value, errorMessage: null));
    });
    on<InstitutionalPlaceTypeChanged>((event, emit) {
      emit(state.copyWith(institutionalPlaceType: event.value, errorMessage: null));
    });
    on<ConductedByChanged>((event, emit) {
      emit(state.copyWith(conductedBy: event.value, errorMessage: null));
    });
    on<TypeOfDeliveryChanged>((event, emit) {
      emit(state.copyWith(typeOfDelivery: event.value, errorMessage: null));
    });
    on<HadComplicationsChanged>((event, emit) {
      emit(state.copyWith(hadComplications: event.value, errorMessage: null));
    });
    on<FpMethodChanged>((event, emit) {
      emit(state.copyWith(fpMethod: event.value, errorMessage: null));
    });
    on<RemovalDateChanged>((event, emit) {
      emit(state.copyWith(removalDate: event.date, errorMessage: null));
    });
    on<RemovalReasonChanged>((event, emit) {
      emit(state.copyWith(removalReason: event.reason, errorMessage: null));
    });
    on<CondomQuantityChanged>((event, emit) {
      emit(state.copyWith(condomQuantity: event.quantity, errorMessage: null));
    });
    on<MalaQuantityChanged>((event, emit) {
      emit(state.copyWith(malaQuantity: event.quantity, errorMessage: null));
    });
    on<ChhayaQuantityChanged>((event, emit) {
      emit(state.copyWith(chhayaQuantity: event.quantity, errorMessage: null));
    });
    on<ECPQuantityChanged>((event, emit) {
      emit(state.copyWith(ecpQuantity: event.quantity, errorMessage: null));
    });

    on<OutcomeFormSubmitted>((event, emit) async {
      emit(state.copyWith(submitted: false, submitting: true, errorMessage: null));

      try {
        final isPlaceInvalid = state.placeOfDelivery.isEmpty || state.placeOfDelivery == 'Select';
        final isDeliveryTypeInvalid = state.deliveryType.isEmpty || state.deliveryType == 'Select';
        final isOutcomeInvalid = state.outcomeCount.isEmpty || int.tryParse(state.outcomeCount) == null;

        String? errorMessage;
        if (state.deliveryDate == null) {
          errorMessage = 'Delivery date is required';
        } else if (isPlaceInvalid) {
          errorMessage = 'Place of delivery is required';
        } else if (isDeliveryTypeInvalid) {
          errorMessage = 'Delivery type is required';
        } else if (isOutcomeInvalid) {
          errorMessage = 'Outcome count is required and must be a number';
        } else if (state.familyPlanningCounseling.isEmpty || state.familyPlanningCounseling == 'Select') {
          errorMessage = 'Family planning counseling is required';
        }

        if (errorMessage != null) {
          emit(state.copyWith(
            errorMessage: errorMessage,
            submitting: false,
            submitted: false,
          ));
          return;
        }

        emit(state.copyWith(submitting: true, errorMessage: null));

        try {
          final db = await DatabaseProvider.instance.database;
          final now = DateTime.now().toIso8601String();
          final beneficiaryId = event.beneficiaryData != null 
              ? (event.beneficiaryData!['unique_key']?.toString() ?? '')
              : '';

          final formType = FollowupFormDataTable.deliveryOutcome;
          final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'Delivery Outcome';
          final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '';

          String? beneficiaryRefKey = beneficiaryId.isNotEmpty ? beneficiaryId : null;


          String householdRefKey = event.beneficiaryData?['householdId']?.toString() ?? '';

          // In outcome_form_bloc.dart, update the formData map to include the new fields
          final formData  = {
            'form_type': formType,
            'form_name': formName,
            'unique_key': formsRefKey,
            'household_ref_key': householdRefKey,
            'form_data': {
              'beneficiaryId': beneficiaryId,
              'household_ref_key': householdRefKey,
              'delivery_date': state.deliveryDate?.toIso8601String(),
              'gestation_weeks': state.gestationWeeks,
              'delivery_time': state.deliveryTime,
              'place_of_delivery': state.placeOfDelivery,
              // Add new institutional delivery fields
              'institutional_place_type': state.institutionalPlaceType,
              'conducted_by': state.conductedBy,
              'type_of_delivery': state.typeOfDelivery,
              'had_complications': state.hadComplications,
              'delivery_type': state.deliveryType,
              'complications': state.complications,
              'outcome_count': state.outcomeCount,
              'family_planning_counseling': state.familyPlanningCounseling,
              'fp_method': state.fpMethod,
              'removal_date': state.removalDate?.toIso8601String(),
              'removal_reason': state.removalReason,
              'condom_quantity': state.condomQuantity,
              'mala_quantity': state.malaQuantity,
              'chhaya_quantity': state.chhayaQuantity,
              'ecp_quantity': state.ecpQuantity,
              'created_at': now,
              'updated_at': now,
            },
            'created_at': now,
            'updated_at': now,
          };

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
                'delivery_date': state.deliveryDate?.toIso8601String(),
                'gestation_weeks': state.gestationWeeks,
                'delivery_time': state.deliveryTime,
                'place_of_delivery': state.placeOfDelivery,
                'delivery_type': state.deliveryType,
                'complications': state.complications,
                'outcome_count': state.outcomeCount,
                'family_planning_counseling': state.familyPlanningCounseling,
                'fp_method': state.fpMethod,
                'removal_date': state.removalDate?.toIso8601String(),
                'removal_reason': state.removalReason,
                'condom_quantity': state.condomQuantity,
                'mala_quantity': state.malaQuantity,
                'chhaya_quantity': state.chhayaQuantity,
                'ecp_quantity': state.ecpQuantity,
                'created_at': now,
                'updated_at': now,
                'isSubmit': true,  // Set isSubmit to true when form is submitted
                'form_data': formDataForDb,
              };

              // Save to secure storage for offline access
              await SecureStorageService.saveDeliveryOutcome(outcomeData);
              
              // Update submission status
              emit(state.copyWith(
                submitting: false,
                submitted: true,
                errorMessage: null,
              ));

              if (beneficiaryId.isNotEmpty) {
                try {
                  final newCount = await SecureStorageService.incrementSubmissionCount(beneficiaryId);
                  print('Submission count for beneficiary $beneficiaryId: $newCount');
                } catch (e) {
                  print('Error updating submission count: $e');
                }
              }
            } catch (e) {
              print('Error saving to secure storage: $e');
              emit(state.copyWith(
                submitting: false,
                submitted: false,
                errorMessage: 'Failed to save delivery outcome to secure storage.',
              ));
            }
          } catch (e) {
            print('Error saving delivery outcome to database: $e');
            emit(state.copyWith(
              submitting: false,
              submitted: false,
              errorMessage: 'Failed to save delivery outcome to database.',
            ));
          }
        } catch (e, stackTrace) {
          print('Error in delivery outcome submission: $e');
          print('Stack trace: $stackTrace');
          emit(state.copyWith(
            submitting: false,
            submitted: false,
            errorMessage: 'An unexpected error occurred. Please try again.',
          ));
        }
      } catch (e) {
        // Handle any unexpected errors
        emit(state.copyWith(
          submitting: false,
          submitted: false,
          errorMessage: 'An unexpected error occurred. Please try again.',
        ));
      }
    });
  }
}
