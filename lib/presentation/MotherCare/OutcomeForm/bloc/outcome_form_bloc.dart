import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../../../core/utils/device_info_utils.dart';
import '../../../../core/utils/id_generator_utils.dart';
import '../../../../core/utils/geolocation_utils.dart';
import '../../../../data/Database/User_Info.dart';
import '../../../../data/Database/database_provider.dart';
import '../../../../data/Database/local_storage_dao.dart';
import '../../../../data/Database/tables/followup_form_data_table.dart';
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
    on<DischargeDateChanged>((event, emit) {
      emit(state.copyWith(dischargeDate: event.date, errorMessage: null));
    });
    on<DischargeTimeChanged>((event, emit) {
      emit(state.copyWith(dischargeTime: event.time, errorMessage: null));
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
    on<ComplicationTypeChanged>((event, emit) {
      emit(state.copyWith(complicationType: event.value, errorMessage: null));
    });
    on<OutcomeCountChanged>((event, emit) {
      emit(state.copyWith(outcomeCount: event.value, errorMessage: null));
    });
    on<FamilyPlanningCounselingChanged>((event, emit) {
      emit(state.copyWith(familyPlanningCounseling: event.value, errorMessage: null));
    });
    on<AdaptFpMethodChanged>((event, emit) {
      emit(state.copyWith(adaptFpMethod: event.value, errorMessage: null));
    });
    on<InstitutionalPlaceTypeChanged>((event, emit) {
      emit(state.copyWith(institutionalPlaceType: event.value, errorMessage: null));
    });
    on<InstitutionalPlaceOfDeliveryChanged>((event, emit) {
      emit(state.copyWith(institutionalPlaceOfDelivery: event.value, errorMessage: null));
    });
    on<ConductedByChanged>((event, emit) {
      emit(state.copyWith(conductedBy: event.value, errorMessage: null));
    });
    on<OtherConductedByNameChanged>((event, emit) {
      emit(state.copyWith(otherConductedByName: event.value, errorMessage: null));
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
    on<AntraDateChanged>((event, emit) {
      emit(state.copyWith(antraDate: event.date, errorMessage: null));
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
    on<NonInstitutionalPlaceTypeChanged>((event, emit) {
      emit(state.copyWith(nonInstitutionalPlaceType: event.value, errorMessage: null));
    });
    on<TransitPlaceChanged>((event, emit) {
      emit(state.copyWith(transitPlace: event.value, errorMessage: null));
    });
    on<OtherNonInstitutionalPlaceNameChanged>((event, emit) {
      emit(state.copyWith(otherNonInstitutionalPlaceName: event.value, errorMessage: null));
    });
    on<OtherPlaceOfDeliveryNameChanged>((event, emit) {
      emit(state.copyWith(otherPlaceOfDeliveryName: event.value, errorMessage: null));
    });
    on<OtherTransitPlaceNameChanged>((event, emit) {
      emit(state.copyWith(otherTransitPlaceName: event.value, errorMessage: null));
    });
    on<OtherComplicationNameChanged>((event, emit) {
      emit(state.copyWith(otherComplicationName: event.value, errorMessage: null));
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
              'discharge_date': state.dischargeDate?.toIso8601String(),
              'discharge_time': state.dischargeTime,
              'place_of_delivery': state.placeOfDelivery,
              'other_place_of_delivery_name': state.otherPlaceOfDeliveryName,
              // Add new institutional delivery fields
              'institutional_place_type': state.institutionalPlaceType,
              'institutional_place_of_delivery': state.institutionalPlaceOfDelivery,
              'conducted_by': state.conductedBy,
              'other_conducted_by_name': state.otherConductedByName,
              'type_of_delivery': state.typeOfDelivery,
              'had_complications': state.hadComplications,
              'non_institutional_place_type': state.nonInstitutionalPlaceType,
              'other_non_institutional_place_name': state.otherNonInstitutionalPlaceName,
              'transit_place': state.transitPlace,
              'other_transit_place_name': state.otherTransitPlaceName,
              'delivery_type': state.deliveryType,
              'complications': state.complications,
              'complication_type': state.complicationType,
              'other_complication_name': state.otherComplicationName,
              'outcome_count': state.outcomeCount,
              'family_planning_counseling': state.familyPlanningCounseling,
              'adapt_fp_method': state.adaptFpMethod,
              'fp_method': state.fpMethod,
              'antra_date': state.antraDate?.toIso8601String(),
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
              'beneficiaries_new',
              where: 'unique_key = ?',
              whereArgs: [beneficiaryId],
            );

            if (beneficiaryMaps.isEmpty) {
              beneficiaryMaps = await db.query(
                'beneficiaries_new',
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
          final currentUser = await UserInfo.getCurrentUser();
          final userDetails = currentUser?['details'] is String
              ? jsonDecode(currentUser?['details'] ?? '{}')
              : currentUser?['details'] ?? {};

          final working = userDetails['working_location'] ?? {};
          final facilityId = working['asha_associated_with_facility_id'] ??
              userDetails['asha_associated_with_facility_id'] ?? 0;
          final ashaUniqueKey = userDetails['unique_key'] ?? '';

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
            'current_user_key':ashaUniqueKey,
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
                'other_place_of_delivery_name': state.otherPlaceOfDeliveryName,
                'institutional_place_type': state.institutionalPlaceType,
                'institutional_place_of_delivery': state.institutionalPlaceOfDelivery,
                'non_institutional_place_type': state.nonInstitutionalPlaceType,
                'other_non_institutional_place_name': state.otherNonInstitutionalPlaceName,
                'transit_place': state.transitPlace,
                'other_transit_place_name': state.otherTransitPlaceName,
                'delivery_type': state.deliveryType,
                'complications': state.complications,
                'complication_type': state.complicationType,
                'other_complication_name': state.otherComplicationName,
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


              await SecureStorageService.saveDeliveryOutcome(outcomeData);

              try {
                final fpVal = state.fpMethod?.toString() ?? '';
                final low = fpVal.toLowerCase().trim();
                if (low == 'male sterilization' || low == 'female sterilization') {
                  final bKey = beneficiaryId.length >= 11
                      ? beneficiaryId.substring(beneficiaryId.length - 11)
                      : beneficiaryId;
                  if (bKey.isNotEmpty) {
                    final beneficiary = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(bKey);
                    if (beneficiary != null) {
                      final info = Map<String, dynamic>.from(
                          (beneficiary['beneficiary_info'] is Map)
                              ? beneficiary['beneficiary_info'] as Map
                              : <String, dynamic>{});
                      info['fpMethod'] = fpVal;
                      await LocalStorageDao.instance.updateBeneficiary({
                        'id': beneficiary['id'],
                        'beneficiary_info': info,
                      });
                    }
                  }
                }
              } catch (e) {
                print('Error updating fpMethod in beneficiary_info: $e');
              }

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

                  try {
                    final deviceInfo = await DeviceInfo.getDeviceInfo();
                    final ts = DateTime.now().toIso8601String();



                    final motherCareActivityData = {
                      'server_id': null,
                      'household_ref_key': householdRefKey,
                      'beneficiary_ref_key': beneficiaryId,
                      'mother_care_state': 'hbnc_visit',
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
                      'current_user_key': ashaUniqueKey,
                      'facility_id': facilityId,
                      'created_date_time': ts,
                      'modified_date_time': ts,
                      'is_synced': 0,
                      'is_deleted': 0,
                    };

                    print('Inserting mother care activity for delivery outcome: ${jsonEncode(motherCareActivityData)}');
                    await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
                    print('✅ Successfully inserted mother care activity for delivery outcome');

                    try {
                      final count = int.tryParse(state.outcomeCount) ?? 0;
                      if (count > 0) {
                        final ancForms = await LocalStorageDao.instance.getFollowupFormsByHouseholdAndBeneficiary(
                          formType: FollowupFormDataTable.ancDueRegistration,
                          householdId: householdRefKey,
                          beneficiaryId: beneficiaryId,
                        );

                        Map<String, dynamic> formSource = {};
                        if (ancForms.isNotEmpty) {
                          final latest = Map<String, dynamic>.from(ancForms.first);
                          final raw = latest['form_json']?.toString() ?? '';
                          try {
                            final parsed = jsonDecode(raw);
                            if (parsed is Map) {
                              final root = Map<String, dynamic>.from(parsed);
                              if (root['form_data'] is Map) {
                                formSource = Map<String, dynamic>.from(root['form_data']);
                              } else {
                                formSource = root;
                              }
                            }
                          } catch (_) {}
                        }

                        final deviceInfo = await DeviceInfo.getDeviceInfo();
                        final geoLocation = await GeoLocation.getCurrentLocation();
                        final locationData = Map<String, String>.from(geoLocation.toJson());
                        locationData['source'] = 'gps';
                        if (!geoLocation.hasCoordinates) {
                          locationData['status'] = 'unavailable';
                          locationData['reason'] = 'Could not determine location';
                        }
                        final geoLocationJson = jsonEncode(locationData);

                        for (int i = 1; i <= count; i++) {
                          final childName = (formSource['baby${i}_name'] ?? '').toString();
                          final childGender = (formSource['baby${i}_gender'] ?? '').toString();
                          final childWeight = formSource['baby${i}_weight'];
                          final fatherName = (formSource['husband_name'] ?? '').toString();
                          final motherName = (formSource['woman_name'] ?? '').toString();

                          final memberId = await IdGenerator.generateUniqueId(deviceInfo);
                          final tsChild = DateTime.now().toIso8601String();

                          final memberPayload = {
                            'server_id': null,
                            'household_ref_key': householdRefKey,
                            'unique_key': memberId,
                            'beneficiary_state': 'active',
                            'pregnancy_count': 0,
                            'beneficiary_info': jsonEncode({
                              'memberType': 'Child',
                              'relation': 'Child',
                              'otherRelation': '',
                              'name': childName.isNotEmpty ? childName : 'Child $i',
                              'fatherName': fatherName,
                              'motherName': motherName,
                              'useDob': true,
                              'dob': state.deliveryDate?.toIso8601String(),
                              'approxAge': null,
                              'updateDay': null,
                              'updateMonth': null,
                              'updateYear': null,
                              'children': null,
                              'birthOrder': i,
                              'gender': childGender,
                              'bankAcc': null,
                              'ifsc': null,
                              'occupation': null,
                              'education': null,
                              'religion': null,
                              'category': null,
                              'weight': null,
                              'childSchool': null,
                              'birthCertificate': null,
                              'birthWeight': childWeight,
                              'abhaAddress': null,
                              'abhaNumber': null,
                              'mobileOwner': null,
                              'mobileOwnerRelation': null,
                              'mobileNo': null,
                              'voterId': null,
                              'rationId': null,
                              'phId': null,
                              'beneficiaryType': 'Child',
                              'maritalStatus': null,
                              'ageAtMarriage': null,
                              'spouseName': null,
                              'hasChildren': null,
                              'isPregnant': null,
                              'lmp': null,
                              'isFamilyPlanning': null,
                              'familyPlanningMethod': null,
                              'other_occupation': null,
                              'other_religion': null,
                              'other_category': null,
                              'mobile_owner_relation': null,
                              'years': null,
                              'months': null,
                              'days': null,
                              'fpMethod': null,
                              'removalDate': null,
                              'removalReason': null,
                              'condomQuantity': null,
                              'malaQuantity': null,
                              'chhayaQuantity': null,
                              'ecpQuantity': null,
                              'antraDate': null,
                              'memberStatus': 'active',
                              'relation_to_head': 'Child',
                              'isFamilyhead': false,
                              'isFamilyheadWife': false,
                            }),
                            'geo_location': geoLocationJson,
                            'spouse_key': null,
                            'mother_key': motherKey.isNotEmpty ? motherKey : null,
                            'father_key': fatherKey.isNotEmpty ? fatherKey : null,
                            'is_family_planning': 0,
                            'is_adult': 0,
                            'is_guest': 0,
                            'is_death': 0,
                            'death_details': jsonEncode({}),
                            'is_migrated': 0,
                            'is_separated': 0,
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
                            'current_user_key': ashaUniqueKey,
                            'facility_id': facilityId,
                            'created_date_time': tsChild,
                            'modified_date_time': tsChild,
                            'is_synced': 0,
                            'is_deleted': 0,
                          };

                          print('Saving child beneficiary from delivery outcome: ${jsonEncode(memberPayload)}');
                          await LocalStorageDao.instance.insertBeneficiary(memberPayload);
                          try {
                            final childCareActivityData = {
                              'server_id': null,
                              'household_ref_key': householdRefKey,
                              'beneficiary_ref_key': memberId,
                              'mother_key': motherKey.isNotEmpty ? motherKey : null,
                              'father_key': fatherKey.isNotEmpty ? fatherKey : null,
                              'child_care_state': 'registration_due',
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
                              'current_user_key': ashaUniqueKey,
                              'facility_id': facilityId,
                              'created_date_time': tsChild,
                              'modified_date_time': tsChild,
                              'is_synced': 0,
                              'is_deleted': 0,
                            };
                            print('Inserting child care activity for delivery outcome: ${jsonEncode(childCareActivityData)}');
                            await LocalStorageDao.instance.insertChildCareActivity(childCareActivityData);
                            print('✅ Successfully inserted child care activity for delivery outcome');
                          } catch (e) {
                            print('❌ Error inserting child care activity for delivery outcome: $e');
                          }
                        }
                      }
                    } catch (e) {
                      print('❌ Error auto-creating child beneficiaries: $e');
                    }
                  } catch (e) {
                    print('❌ Error inserting mother care activity: $e');
                  }
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
