import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../../core/utils/device_info_utils.dart';
import '../../../../../core/utils/enums.dart';
import '../../../../../data/Local_Storage/User_Info.dart';
import '../../../../../data/Local_Storage/database_provider.dart';
import '../../../../../data/Local_Storage/local_storage_dao.dart';
import '../../../../../data/Local_Storage/tables/followup_form_data_table.dart';
import '../../../../../data/SecureStorage/SecureStorage.dart';
import '../../../../../data/repositories/MotherCareRepository/MotherCareRepository.dart';

part 'anvvisitform_event.dart';
part 'anvvisitform_state.dart';

class AnvvisitformBloc extends Bloc<AnvvisitformEvent, AnvvisitformState> {
  final String beneficiaryId;
  final String householdRefKey;

  AnvvisitformBloc({
    required this.beneficiaryId,
    required this.householdRefKey,
  }) : super(const AnvvisitformInitial()) {
    on<VisitTypeChanged>((e, emit) => emit(state.copyWith(visitType: e.value)));
    on<PlaceOfAncChanged>((e, emit) => emit(state.copyWith(placeOfAnc: e.value)));
    on<DateOfInspectionChanged>((e, emit) => emit(state.copyWith(dateOfInspection: e.value)));
    on<HouseNumberChanged>((e, emit) => emit(state.copyWith(houseNumber: e.value)));
    on<WomanNameChanged>((e, emit) => emit(state.copyWith(womanName: e.value)));
    on<HusbandNameChanged>((e, emit) => emit(state.copyWith(husbandName: e.value)));
    on<RchNumberChanged>((e, emit) => emit(state.copyWith(rchNumber: e.value)));

    on<LmpDateChanged>((e, emit) {
      if (e.value == null) {
        emit(state.copyWith(lmpDate: null, eddDate: null));
        return;
      }
      // EDD = LMP + 8 months and 10 days (same as TrackEligibleCouple)
      final edd = _calculateEddFromLmp(e.value!);
      emit(state.copyWith(lmpDate: e.value, eddDate: edd));
    });
    on<EddDateChanged>((e, emit) => emit(state.copyWith(eddDate: e.value)));
    on<WeeksOfPregnancyChanged>((e, emit) => emit(state.copyWith(weeksOfPregnancy: e.value)));
    on<GravidaDecremented>((e, emit) => emit(state.copyWith(gravida: (state.gravida > 0 ? state.gravida - 1 : 0))));
    on<GravidaIncremented>((e, emit) => emit(state.copyWith(gravida: state.gravida + 1)));
    on<IsBreastFeedingChanged>((e, emit) => emit(state.copyWith(isBreastFeeding: e.value)));
    on<Td1DateChanged>((e, emit) => emit(state.copyWith(td1Date: e.value)));
    on<Td2DateChanged>((e, emit) => emit(state.copyWith(td2Date: e.value)));
    on<TdBoosterDateChanged>((e, emit) => emit(state.copyWith(tdBoosterDate: e.value)));
    on<FolicAcidTabletsChanged>((e, emit) => emit(state.copyWith(folicAcidTablets: e.value)));
    on<PreExistingDiseaseChanged>((e, emit) => emit(state.copyWith(preExistingDisease: e.value)));
    on<WeightChanged>((e, emit) => emit(state.copyWith(weight: e.value)));
    on<SystolicChanged>((e, emit) => emit(state.copyWith(systolic: e.value)));
    on<DiastolicChanged>((e, emit) => emit(state.copyWith(diastolic: e.value)));
    on<HemoglobinChanged>((e, emit) => emit(state.copyWith(hemoglobin: e.value)));
    on<HighRiskChanged>((e, emit) => emit(state.copyWith(highRisk: e.value)));
    on<SelectedRisksChanged>((e, emit) => emit(state.copyWith(selectedRisks: e.selectedRisks)));
    on<HasAbortionComplicationChanged>((e, emit) => emit(state.copyWith(hasAbortionComplication: e.value)));
    on<AbortionDateChanged>((e, emit) => emit(state.copyWith(abortionDate: e.value)));
    on<BeneficiaryAbsentChanged>((e, emit) => emit(state.copyWith(beneficiaryAbsent: e.value)));
    on<BeneficiaryIdSet>((e, emit) => emit(state.copyWith(beneficiaryId: e.beneficiaryId)));
    on<GivesBirthToBaby>((e, emit) => emit(state.copyWith(givesBirthToBaby: e.value)));
    on<VisitNumberChanged>((e, emit) {
      final visitNo = int.tryParse(e.visitNumber) ?? 1;
      emit(state.copyWith(ancVisitNo: visitNo));
    });

    on<SubmitPressed>(_onSubmit);
  }

  DateTime _calculateEddFromLmp(DateTime lmp) {
    int year = lmp.year;
    int month = lmp.month + 8;
    if (month > 12) {
      year += (month - 1) ~/ 12;
      month = ((month - 1) % 12) + 1;
    }
    final base = DateTime(year, month, lmp.day);
    return base.add(const Duration(days: 10));
  }

  Future<void> _onSubmit(SubmitPressed e, Emitter<AnvvisitformState> emit) async {
    emit(state.copyWith(isSubmitting: true, isSuccess: false, error: null, clearError: true));
    try {
      final db = await DatabaseProvider.instance.database;
      final now = DateTime.now().toIso8601String();

      // Form type and keys
      final formType = FollowupFormDataTable.ancDueRegistration;
      final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'ANC Due Registration';
      final formsRefKey = 'bt7gs9rl1a5d26mz';

      
      final formData = {
        'form_type': formType,
        'form_name': formName,
        'unique_key': formsRefKey,
        'form_data': {
          'anc_visit_no': state.ancVisitNo,
          'visit_type': state.visitType,
          'beneficiaryId': beneficiaryId,
          'beneficiary_ref_key': beneficiaryId,
          'household_ref_key': householdRefKey,
          'place_of_anc': state.placeOfAnc,
          'date_of_inspection': state.dateOfInspection?.toIso8601String(),
          'house_number': state.houseNumber,
          'woman_name': state.womanName,
          'husband_name': state.husbandName,
          'rch_number': state.rchNumber,
          'lmp_date': state.lmpDate?.toIso8601String(),
          'edd_date': state.eddDate?.toIso8601String(),
          'weeks_of_pregnancy': state.weeksOfPregnancy,
          'gravida': state.gravida,
          'selected_risks': state.selectedRisks,
          'has_abortion_complication': state.hasAbortionComplication,
          'abortion_date': state.abortionDate?.toIso8601String(),
          'is_breast_feeding': state.isBreastFeeding,
          'td1_date': state.td1Date?.toIso8601String(),
          'td2_date': state.td2Date?.toIso8601String(),
          'td_booster_date': state.tdBoosterDate?.toIso8601String(),
          'folic_acid_tablets': state.folicAcidTablets,
          'pre_existing_disease': state.preExistingDisease,
          'weight': state.weight,
          'systolic': state.systolic,
          'diastolic': state.diastolic,
          'hemoglobin': state.hemoglobin,
          'pregnantWoman': state.givesBirthToBaby,
          'high_risk': state.highRisk,
          'gives_birth_to_baby': state.givesBirthToBaby,
          'beneficiary_absent': state.beneficiaryAbsent,
          'created_at': now,
          'updated_at': now,
        },
        'created_at': now,
        'updated_at': now,
      };

      final currentUser = await UserInfo.getCurrentUser();
      final userDetails = currentUser?['details'] is String
          ? jsonDecode(currentUser?['details'] ?? '{}')
          : currentUser?['details'] ?? {};

      final working = userDetails['working_location'] ?? {};
      final facilityId = working['asha_associated_with_facility_id'] ??
          userDetails['asha_associated_with_facility_id'] ?? 0;
      final ashaUniqueKey = userDetails['unique_key'] ?? {};


      final formDataForDb  = {
        'server_id': '',
        'forms_ref_key': formsRefKey,
        'household_ref_key': householdRefKey,
        'beneficiary_ref_key': beneficiaryId,
        'mother_key': '',
        'father_key': '',
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
        'current_user_key': ashaUniqueKey,
        'facility_id': facilityId,
        'form_json': jsonEncode(formData),
        'created_date_time': now,
        'modified_date_time': now,
        'is_synced': 0,
        'is_deleted': 0,
      };

      try {
        final formId = await LocalStorageDao.instance.insertFollowupFormData(formDataForDb);
        print('✅ ANC visit form saved successfully with ID: $formId');

        try {
          // After a successful ANC submission, mark this beneficiary as
          // logically deleted for local lists and flag it as unsynced so
          // that the updated state is sent to the API.
          await LocalStorageDao.instance
              .updateBeneficiaryDeleteAndSyncFlagByUniqueKey(
            uniqueKey: beneficiaryId,
            isDeleted: 1,
          );
          print('✅ Beneficiary $beneficiaryId marked is_deleted=1 and is_synced=0');
        } catch (e) {
          print('❌ Error updating beneficiary delete/sync flags: $e');
        }

        try {
          final visitData = {
            'id': formId,
            'beneficiaryId': beneficiaryId,
            'house_number': state.houseNumber,
            'woman_name': state.womanName,
            'husband_name': state.husbandName,
            'rch_number': state.rchNumber,
            'visit_type': state.visitType,
            'place_of_anc': state.placeOfAnc,
            'date_of_inspection': state.dateOfInspection?.toIso8601String(),
            'lmp_date': state.lmpDate?.toIso8601String(),
            'edd_date': state.eddDate?.toIso8601String(),
            'weeks_of_pregnancy': state.weeksOfPregnancy,
            'gravida': state.gravida,
            'is_breast_feeding': state.isBreastFeeding,
            'td1_date': state.td1Date?.toIso8601String(),
            'td2_date': state.td2Date?.toIso8601String(),
            'td_booster_date': state.tdBoosterDate?.toIso8601String(),
            'folic_acid_tablets': state.folicAcidTablets,
             'selected_risks': state.selectedRisks,
             'has_abortion_complication': state.hasAbortionComplication,
            'abortion_date': state.abortionDate?.toIso8601String(),
            'pre_existing_disease': state.preExistingDisease,
            'weight': state.weight,
            'systolic': state.systolic,
            'diastolic': state.diastolic,
            'hemoglobin': state.hemoglobin,
            'high_risk': state.highRisk,
            'gives_birth_to_baby': state.givesBirthToBaby,
            'beneficiary_absent': state.beneficiaryAbsent,
            'form_data': formDataForDb,
          };

          await SecureStorageService.saveAncVisit(visitData);
          print('ANC visit data saved to secure storage');
        } catch (e) {
          print('Error saving to secure storage: $e');
        }


        try {
          final dbRows = await db.query(
            FollowupFormDataTable.table,
            where: 'id = ?',
            whereArgs: [formId],
            limit: 1,
          );

          if (dbRows.isNotEmpty) {
            final saved = Map<String, dynamic>.from(dbRows.first);

            Map<String, dynamic> deviceJson = {};
            Map<String, dynamic> appJson = {};
            Map<String, dynamic> geoJson = {};
            Map<String, dynamic> formRoot = {};
            Map<String, dynamic> formDataJson = {};

            try {
              if (saved['device_details'] is String && (saved['device_details'] as String).isNotEmpty) {
                deviceJson = Map<String, dynamic>.from(jsonDecode(saved['device_details']));
              }
            } catch (_) {}

            try {
              if (saved['app_details'] is String && (saved['app_details'] as String).isNotEmpty) {
                appJson = Map<String, dynamic>.from(jsonDecode(saved['app_details']));
              }
            } catch (_) {}

            try {
              if (saved['form_json'] is String && (saved['form_json'] as String).isNotEmpty) {
                final fj = jsonDecode(saved['form_json']);
                if (fj is Map) {
                  formRoot = Map<String, dynamic>.from(fj);
                  if (fj['form_data'] is Map) {
                    formDataJson = Map<String, dynamic>.from(fj['form_data']);
                  }
                  if (fj['geolocation_details'] is Map) {
                    geoJson = Map<String, dynamic>.from(fj['geolocation_details']);
                  } else if (formDataJson['geolocation_details'] is Map) {
                    geoJson = Map<String, dynamic>.from(formDataJson['geolocation_details']);
                  }
                }
              }
            } catch (_) {}

            // All meta values should come from DB / form_json
            final String userId = (saved['current_user_key'] ?? formRoot['user_id'] ?? formDataJson['user_id'] ?? '').toString();
            final String facility = (saved['facility_id']?.toString() ?? formRoot['facility_id']?.toString() ?? formDataJson['facility_id']?.toString() ?? '');
            final String appRoleId = (formRoot['app_role_id'] ?? formDataJson['app_role_id'] ?? '').toString();
            final String createdAt = (saved['created_date_time'] ?? formRoot['created_date_time'] ?? formDataJson['created_date_time'] ?? '').toString();
            final String modifiedAt = (saved['modified_date_time'] ?? formRoot['modified_date_time'] ?? formDataJson['modified_date_time'] ?? '').toString();

            final dbHouseholdRefKey = (saved['household_ref_key'] ?? householdRefKey).toString();
            final dbBeneficiaryRefKey = (saved['beneficiary_ref_key'] ?? beneficiaryId).toString();

            final motherCarePayload = [
              {
                'unique_key': dbHouseholdRefKey,
                'beneficiaries_registration_ref_key': dbBeneficiaryRefKey,
                'mother_care_type': 'anc_due',
                'user_id': userId,
                'facility_id': facility,
                'is_deleted': 0,
                'created_by': userId,
                'created_date_time': createdAt,
                'modified_by': userId,
                'modified_date_time': modifiedAt,
                'parent_added_by': userId,
                'parent_facility_id': int.tryParse(facility) ?? facility,
                'app_role_id': appRoleId,
                'is_guest': 0,
                'pregnancy_count': 1,
                'device_details': {
                  'device_id': deviceJson['id'] ?? deviceJson['device_id'],
                  'device_plateform': deviceJson['platform'] ?? deviceJson['device_plateform'],
                  'device_plateform_version': deviceJson['version'] ?? deviceJson['device_plateform_version'],
                },
                'app_details': {
                  'app_version': appJson['app_version'],
                  'app_name': appJson['app_name'],
                },
                'geolocation_details': {
                  'latitude': geoJson['lat']?.toString() ?? '',
                  'longitude': geoJson['long']?.toString() ?? '',
                },
              },
            ];

            try {
              final repo = MotherCareRepository();
              final apiResp = await repo.addMotherCareActivity(motherCarePayload);

              try {
                if (apiResp is Map && apiResp['success'] == true && apiResp['data'] is List) {
                  final List data = apiResp['data'];
                  Map? rec = data.cast<Map>().firstWhere(
                    (e) => (e['mother_care_type']?.toString() ?? '') == 'anc_due',
                    orElse: () => {},
                  );
                  final serverId = (rec?['_id'] ?? '').toString();
                  if (serverId.isNotEmpty) {
                    final updated = await db.update(
                      FollowupFormDataTable.table,
                      {
                        'server_id': serverId,
                        // keep modified_date_time as stored in DB, no new timestamp
                      },
                      where: 'id = ?',
                      whereArgs: [formId],
                    );
                    print('Updated followup_form_data with mother care server_id=$serverId rows=$updated');
                  }
                }
              } catch (e) {
                print('Error updating followup_form_data with mother care server_id: $e');
              }
            } catch (e) {
              print('Mother care API call failed: $e');
            }
          }
        } catch (e) {
          print('Error reading saved followup_form_data to build mother care payload: $e');
        }

        // Update submission count
        try {
          print('🔢 Incrementing count for beneficiary: $beneficiaryId');
          final newCount = await SecureStorageService.incrementSubmissionCount(beneficiaryId);
          print('✅ New submission count: $newCount');
        } catch (e) {
          print('❌ Error updating submission count: $e');
        }

        emit(state.copyWith(isSubmitting: false, isSuccess: true, error: null));
      } catch (e) {
        emit(state.copyWith(isSubmitting: false, error: 'Error saving form: $e'));
      }
    } catch (e, stackTrace) {
      print('Error saving form data: $e');
      print('Stack trace: $stackTrace');
      emit(state.copyWith(
        isSubmitting: false,
        error: 'Failed to save form data. Please try again.',
      ));
    }
  }
}
