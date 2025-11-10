import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:medixcel_new/core/utils/app_info_utils.dart';
import 'package:medixcel_new/core/utils/device_info_utils.dart';
import 'package:medixcel_new/data/Local_Storage/User_Info.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';

part 'child_tracking_form_event.dart';
part 'child_tracking_form_state.dart';

class ChildTrackingFormBloc extends Bloc<ChildTrackingFormEvent, ChildTrackingFormState> {
  ChildTrackingFormBloc() : super(ChildTrackingFormState.initial()) {
    on<LoadFormData>(_onLoadFormData);
    on<WeightChanged>(_onWeightChanged);
    on<TabChanged>(_onTabChanged);
    on<CaseClosureToggled>(_onCaseClosureToggled);
    on<ClosureReasonChanged>(_onClosureReasonChanged);
    on<MigrationTypeChanged>(_onMigrationTypeChanged);
    on<DateOfDeathChanged>(_onDateOfDeathChanged);
    on<ProbableCauseOfDeathChanged>(_onProbableCauseOfDeathChanged);
    on<DeathPlaceChanged>(_onDeathPlaceChanged);
    on<ReasonOfDeathChanged>(_onReasonOfDeathChanged);
    on<OtherCauseChanged>(_onOtherCauseChanged);
    on<OtherReasonChanged>(_onOtherReasonChanged);
    on<SubmitForm>(_onSubmitForm);
  }

  void _onLoadFormData(LoadFormData event, Emitter<ChildTrackingFormState> emit) {
    final formData = event.formData;
    final dobStr = formData['date_of_birth']?.toString() ?? '';

    DateTime birthDate = DateTime.now();
    if (dobStr.isNotEmpty) {
      try {
        birthDate = DateTime.parse(dobStr);
      } catch (e) {
        print(' Error parsing birth date: $e');
      }
    }

    emit(state.copyWith(
      formData: formData,
      birthDate: birthDate,
      status: FormStatus.initial,
    ));
  }

  void _onWeightChanged(WeightChanged event, Emitter<ChildTrackingFormState> emit) {
    final grams = (double.tryParse(event.weightKg) ?? 0) * 1000;
    final updatedFormData = Map<String, dynamic>.from(state.formData);
    updatedFormData['weight_grams'] = grams.round();

    emit(state.copyWith(formData: updatedFormData));
  }

  void _onTabChanged(TabChanged event, Emitter<ChildTrackingFormState> emit) {
    emit(state.copyWith(currentTabIndex: event.tabIndex));
  }

  void _onCaseClosureToggled(CaseClosureToggled event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(
      isCaseClosureChecked: event.isChecked,
    );

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  void _onClosureReasonChanged(ClosureReasonChanged event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(
      selectedClosureReason: event.reason,
      showOtherCauseField: event.reason == 'Any other (specify)',
    );

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  void _onMigrationTypeChanged(MigrationTypeChanged event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(migrationType: event.migrationType);

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  void _onDateOfDeathChanged(DateOfDeathChanged event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(dateOfDeath: event.date);

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  void _onProbableCauseOfDeathChanged(ProbableCauseOfDeathChanged event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(
      probableCauseOfDeath: event.cause,
      showOtherCauseField: event.cause == 'Any other (specify)',
    );

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  void _onDeathPlaceChanged(DeathPlaceChanged event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(deathPlace: event.place);

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  void _onReasonOfDeathChanged(ReasonOfDeathChanged event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(reasonOfDeath: event.reason);

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  void _onOtherCauseChanged(OtherCauseChanged event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(otherCause: event.otherCause);

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  void _onOtherReasonChanged(OtherReasonChanged event, Emitter<ChildTrackingFormState> emit) {
    final updatedData = Map<int, CaseClosureData>.from(state.tabCaseClosureData);
    final currentData = updatedData[event.tabIndex] ?? const CaseClosureData();

    updatedData[event.tabIndex] = currentData.copyWith(otherReason: event.otherReason);

    emit(state.copyWith(tabCaseClosureData: updatedData));
  }

  Future<void> _onSubmitForm(SubmitForm event, Emitter<ChildTrackingFormState> emit) async {
    emit(state.copyWith(status: FormStatus.loading, clearError: true));

    try {
      final db = await DatabaseProvider.instance.database;
      final now = DateTime.now().toIso8601String();
      final currentTabIndex = event.currentTabIndex;

      // Tab names mapping
      const tabs = [
        'BIRTH DOSE',
        '6 WEEK',
        '10 WEEK',
        '14 WEEK',
        '9 MONTH',
        '16-24 MONTHS',
        '5-6 YEAR',
        '10 YEAR',
        '16 YEAR',
      ];

      final currentTabName = tabs[currentTabIndex];

      final formType = FollowupFormDataTable.childTrackingDue;
      final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'Child Tracking Due';
      final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '30bycxe4gv7fqnt6';


      final caseClosureData = state.tabCaseClosureData[currentTabIndex] ?? const CaseClosureData();

      final formData = {
        'form_type': formType,
        'form_name': formName,
        'unique_key': formsRefKey,
        'form_data': {
          ...state.formData,
          'current_tab': currentTabName,
          'current_tab_index': currentTabIndex,
          'weight_grams': state.formData['weight_grams'],
          'case_closure': caseClosureData.toJson(),
          'visit_date': now,
        },
        'created_at': now,
        'updated_at': now,
      };


      String householdRefKey = state.formData['household_ref_key']?.toString() ?? '';
      String motherKey = state.formData['mother_key']?.toString() ?? '';
      String fatherKey = state.formData['father_key']?.toString() ?? '';
      String beneficiaryRefKey = state.formData['beneficiary_ref_key']?.toString() ?? '';


      if (beneficiaryRefKey.isEmpty && state.formData['beneficiary_id'] != null) {
        beneficiaryRefKey = state.formData['beneficiary_id'].toString();
      }

      if (householdRefKey.isEmpty && state.formData['household_id'] != null) {
        final householdId = state.formData['household_id'].toString();
        List<Map<String, dynamic>> beneficiaryMaps = await db.query(
          'beneficiaries',
          where: 'household_ref_key = ?',
          whereArgs: [householdId],
        );

        if (beneficiaryMaps.isEmpty) {
          beneficiaryMaps = await db.query(
            'beneficiaries',
            where: 'id = ?',
            whereArgs: [int.tryParse(householdId) ?? 0],
          );
        }

        if (beneficiaryMaps.isNotEmpty) {
          final beneficiary = beneficiaryMaps.first;
          householdRefKey = beneficiary['household_ref_key'] as String? ?? '';
          motherKey = beneficiary['mother_key'] as String? ?? '';
          fatherKey = beneficiary['father_key'] as String? ?? '';
          if (beneficiaryRefKey.isEmpty) {
            beneficiaryRefKey = beneficiary['beneficiary_ref_key'] as String? ?? '';
          }
        }
      }

      final formJson = jsonEncode(formData);
      print('💾 Child Tracking Form JSON to be saved: $formJson');

      late DeviceInfo deviceInfo;
      try {
        deviceInfo = await DeviceInfo.getDeviceInfo();
      } catch (e) {
        print('Error getting device info: $e');
        deviceInfo = DeviceInfo(
          deviceId: 'unknown',
          platform: 'unknown',
          osVersion: 'unknown',
          appInfo: AppInfo(
            appVersion: '1.0.0',
            appName: 'BHAVYA mASHA',
            buildNumber: '1',
            packageName: 'com.medixcel.bhavyamasha',
          ),
        );
      }

      // Get current user
      final currentUser = await UserInfo.getCurrentUser();
      Map<String, dynamic> userDetails = {};
      if (currentUser != null) {
        if (currentUser['details'] is String) {
          try {
            userDetails = jsonDecode(currentUser['details'] ?? '{}');
          } catch (e) {
            print('Error parsing user details: $e');
          }
        } else if (currentUser['details'] is Map) {
          userDetails = Map<String, dynamic>.from(currentUser['details']);
        }
      }

      final facilityId = userDetails['asha_associated_with_facility_id'] ??
          userDetails['facility_id'] ??
          userDetails['facilityId'] ??
          0;

      final formDataForDb = {
        'server_id': '',
        'forms_ref_key': formsRefKey,
        'household_ref_key': householdRefKey,
        'beneficiary_ref_key': beneficiaryRefKey,
        'mother_key': motherKey,
        'father_key': fatherKey,
        'child_care_state': currentTabName,
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
        'parent_user': '',
        'current_user_key': '',
        'facility_id': facilityId,
        'form_json': formJson,
        'created_date_time': now,
        'modified_date_time': now,
        'is_synced': 0,
        'is_deleted': 0,
      };

      final formId = await LocalStorageDao.instance.insertFollowupFormData(formDataForDb);

      if (formId > 0) {
        print('✅ Child Tracking Form saved successfully with ID: $formId');
        print('📋 Tab: $currentTabName (Index: $currentTabIndex)');
        print('🏠 Household Ref Key: $householdRefKey');
        print('👤 Beneficiary Ref Key: $beneficiaryRefKey');
        print('📱 Form Type: $formType');

        emit(state.copyWith(
          status: FormStatus.success,
          savedFormId: formId,
        ));
      } else {
        throw Exception('Failed to save form data');
      }
    } catch (e) {
      print(' Error saving child tracking form: $e');
      emit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: 'Error saving form: $e',
      ));
    }
  }
}
