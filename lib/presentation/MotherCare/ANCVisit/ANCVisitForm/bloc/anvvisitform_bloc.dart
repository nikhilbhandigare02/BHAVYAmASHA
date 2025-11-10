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

part 'anvvisitform_event.dart';
part 'anvvisitform_state.dart';

class AnvvisitformBloc extends Bloc<AnvvisitformEvent, AnvvisitformState> {
  AnvvisitformBloc() : super(const AnvvisitformInitial()) {
    on<VisitTypeChanged>((e, emit) => emit(state.copyWith(visitType: e.value)));
    on<PlaceOfAncChanged>((e, emit) => emit(state.copyWith(placeOfAnc: e.value)));
    on<DateOfInspectionChanged>((e, emit) => emit(state.copyWith(dateOfInspection: e.value)));
    on<HouseNumberChanged>((e, emit) => emit(state.copyWith(houseNumber: e.value)));
    on<WomanNameChanged>((e, emit) => emit(state.copyWith(womanName: e.value)));
    on<HusbandNameChanged>((e, emit) => emit(state.copyWith(husbandName: e.value)));
    on<RchNumberChanged>((e, emit) => emit(state.copyWith(rchNumber: e.value)));

    on<LmpDateChanged>((e, emit) {
      // EDD = LMP + 280 days (when LMP provided)
      final edd = (e.value == null) ? null : e.value!.add(const Duration(days: 280));
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
    on<BeneficiaryAbsentChanged>((e, emit) => emit(state.copyWith(beneficiaryAbsent: e.value)));
    on<BeneficiaryIdSet>((e, emit) => emit(state.copyWith(beneficiaryId: e.beneficiaryId)));
    on<GivesBirthToBaby>((e, emit) => emit(state.copyWith(givesBirthToBaby: e.value)));

    on<SubmitPressed>(_onSubmit);
  }

  Future<void> _onSubmit(SubmitPressed e, Emitter<AnvvisitformState> emit) async {
    emit(state.copyWith(isSubmitting: true, isSuccess: false, error: null, clearError: true));
    try {
      final db = await DatabaseProvider.instance.database;
      final now = DateTime.now().toIso8601String();

      final formType = FollowupFormDataTable.ancDueRegistration;
      final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'anc Due Registration';
      final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '';

      String? beneficiaryRefKey;
      if (state.beneficiaryId != null && state.beneficiaryId!.contains('_')) {
        beneficiaryRefKey = state.beneficiaryId;
      }

      final formData  = {
        'form_type': formType,
        'form_name': formName,
        'unique_key': formsRefKey,
        'form_data': {
          'anc_visit_no': state.ancVisitNo,
          'visit_type': state.visitType,
          'beneficiaryId': state.beneficiaryId,
          'beneficiary_ref_key': beneficiaryRefKey,
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
        },
        'created_at': now,
        'updated_at': now,
      };

      String householdRefKey = '';
      String motherKey = '';
      String fatherKey = '';

      if (state.beneficiaryId != null && state.beneficiaryId!.isNotEmpty) {
        List<Map<String, dynamic>> beneficiaryMaps = await db.query(
          'beneficiaries',
          where: 'unique_key = ?',
          whereArgs: [state.beneficiaryId],
        );

        if (beneficiaryMaps.isEmpty) {
          beneficiaryMaps = await db.query(
            'beneficiaries',
            where: 'id = ?',
            whereArgs: [int.tryParse(state.beneficiaryId) ?? 0],
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
        'beneficiary_ref_key': state.beneficiaryId,
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
          final visitData = {
            'id': formId,
            'beneficiaryId': state.beneficiaryId.length >= 11
                ? state.beneficiaryId.substring(state.beneficiaryId.length - 11)
                : state.beneficiaryId,
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
        
        if (state.beneficiaryId != null && state.beneficiaryId!.isNotEmpty) {
          try {
            // Use the full unique key for the count
            final uniqueKey = state.beneficiaryId!;
            print('🔢 Incrementing count for full unique key: $uniqueKey');
            final newCount = await SecureStorageService.incrementSubmissionCount(uniqueKey);
            print('✅ New submission count for $uniqueKey: $newCount');
          } catch (e) {
            print('❌ Error updating submission count: $e');
            // Don't fail the submission if counter update fails
          }
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