import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medixcel_new/core/utils/app_info_utils.dart';
import 'package:medixcel_new/core/utils/device_info_utils.dart';
import 'package:medixcel_new/core/utils/enums.dart' show FormStatus;
import 'package:medixcel_new/data/Local_Storage/User_Info.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';
import 'package:meta/meta.dart';

import '../../../../data/repositories/ChildCareRepository/ChildCareRepository.dart';

part 'register_child_form_event.dart';
part 'register_child_form_state.dart';

class RegisterChildFormBloc extends Bloc<RegisterChildFormEvent, RegisterChildFormState> {
  static const _secureStorage = FlutterSecureStorage();
  final String? beneficiaryId;
  final String? householdId;

  RegisterChildFormBloc({
    this.beneficiaryId,
    this.householdId,
  }) : super(RegisterChildFormState.initial()) {
    on<RchIdChildChanged>((e, emit) => emit(state.copyWith(rchIdChild: e.value, clearError: true)));
    on<SerialNumberChanged>((e, emit) => emit(state.copyWith(serialNumber: e.value, clearError: true)));
    on<DateOfBirthChanged>((e, emit) => emit(state.copyWith(dateOfBirth: e.value, clearError: true)));
    on<DateOfRegistrationChanged>((e, emit) => emit(state.copyWith(dateOfRegistration: e.value, clearError: true)));
    on<ChildNameChanged>((e, emit) => emit(state.copyWith(childName: e.value, clearError: true)));
    on<GenderChanged>((e, emit) => emit(state.copyWith(gender: e.value, clearError: true)));
    on<MotherNameChanged>((e, emit) => emit(state.copyWith(motherName: e.value, clearError: true)));
    on<FatherNameChanged>((e, emit) => emit(state.copyWith(fatherName: e.value, clearError: true)));
    on<AddressChanged>((e, emit) => emit(state.copyWith(address: e.value, clearError: true)));
    on<WhoseMobileNumberChanged>((e, emit) => emit(state.copyWith(whoseMobileNumber: e.value, clearError: true)));
    on<MobileNumberChanged>((e, emit) => emit(state.copyWith(mobileNumber: e.value, clearError: true)));
    on<MothersRchIdNumberChanged>((e, emit) => emit(state.copyWith(mothersRchIdNumber: e.value, clearError: true)));
    on<BirthCertificateIssuedChanged>((e, emit) => emit(state.copyWith(birthCertificateIssued: e.value, clearError: true)));
    on<BirthCertificateNumberChanged>((e, emit) => emit(state.copyWith(birthCertificateNumber: e.value, clearError: true)));
    on<WeightGramsChanged>((e, emit) => emit(state.copyWith(weightGrams: e.value, clearError: true)));
    on<BirthWeightGramsChanged>((e, emit) => emit(state.copyWith(birthWeightGrams: e.value, clearError: true)));
    on<ReligionChanged>((e, emit) => emit(state.copyWith(religion: e.value, clearError: true)));
    on<CasteChanged>((e, emit) => emit(state.copyWith(caste: e.value, clearError: true)));
    on<SerialNumberOFRegister>((e, emit) => emit(state.copyWith(registerSerialNumber: e.value, clearError: true)));

    on<SubmitPressed>(_onSubmit);
  }

  void _onSubmit(SubmitPressed event, Emitter<RegisterChildFormState> emit) async {
    // Minimal validation based on screenshots
    final missing = <String>[];
    if (state.dateOfBirth == null) missing.add('Date of Birth');
    if (state.dateOfRegistration == null) missing.add('Date of Registration');
    if (state.childName.isEmpty) missing.add("Child's name");
    if (state.motherName.isEmpty) missing.add("Mother's name");
    if (state.mobileNumber.isEmpty) missing.add('Mobile number');

    if (missing.isNotEmpty) {
      emit(state.copyWith(error: 'Please fill: ' + missing.join(', ')));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true, isSuccess: false));

    try {
      final db = await DatabaseProvider.instance.database;
      final now = DateTime.now().toIso8601String();

      final formType = FollowupFormDataTable.childRegistrationDue;
      final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'Child Registration Due';
      final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '2ol35gbp7rczyvn6';

      final formData = {
        'form_type': formType,
        'form_name': formName,
        'unique_key': formsRefKey,
        'form_data': {
          'rch_id_child': state.rchIdChild,
          'register_serial_number': state.registerSerialNumber,
          'date_of_birth': state.dateOfBirth?.toIso8601String(),
          'date_of_registration': state.dateOfRegistration?.toIso8601String(),
          'child_name': state.childName,
          'gender': state.gender,
          'mother_name': state.motherName,
          'father_name': state.fatherName,
          'address': state.address,
          'whose_mobile_number': state.whoseMobileNumber,
          'mobile_number': state.mobileNumber,
          'mothers_rch_id_number': state.mothersRchIdNumber,
          'birth_certificate_issued': state.birthCertificateIssued,
          'birth_certificate_number': state.birthCertificateNumber,
          'weight_grams': state.weightGrams,
          'birth_weight_grams': state.birthWeightGrams,
          'religion': state.religion,
          'caste': state.caste,
        },
        'created_at': now,
        'updated_at': now,
      };

      // Get beneficiary details
      String householdRefKey = '';
      String motherKey = '';
      String fatherKey = '';
      String beneficiaryRefKey = beneficiaryId ?? '';

      if (householdId != null && householdId!.isNotEmpty) {
        List<Map<String, dynamic>> beneficiaryMaps = await db.query(
          'beneficiaries',
          where: 'household_ref_key = ?',
          whereArgs: [householdId],
        );

        if (beneficiaryMaps.isEmpty) {
          beneficiaryMaps = await db.query(
            'beneficiaries',
            where: 'id = ?',
            whereArgs: [int.tryParse(householdId!) ?? 0],
          );
        }

        if (beneficiaryMaps.isNotEmpty) {
          final beneficiary = beneficiaryMaps.first;
          householdRefKey = beneficiary['household_ref_key'] as String? ?? '';
          motherKey = beneficiary['mother_key'] as String? ?? '';
          fatherKey = beneficiary['father_key'] as String? ?? '';
        }
      }

      final formJson = jsonEncode(formData);
      print('💾 Form JSON to be saved: $formJson');
      print('💾 Form JSON length: ${formJson.length}');

      late DeviceInfo deviceInfo;
      try {
        deviceInfo = await DeviceInfo.getDeviceInfo();
      } catch (e) {
        print('Error getting package/device info: $e');

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
      print('Current User: $currentUser');

      Map<String, dynamic> userDetails = {};
      if (currentUser != null) {
        if (currentUser['details'] is String) {
          try {
            userDetails = jsonDecode(currentUser['details'] ?? '{}');
          } catch (e) {
            print('Error parsing user details: $e');
            userDetails = {};
          }
        } else if (currentUser['details'] is Map) {
          userDetails = Map<String, dynamic>.from(currentUser['details']);
        }
        print('User Details: $userDetails');
      }

      // Try different possible keys for facility ID
      final facilityId = userDetails['asha_associated_with_facility_id'] ??
          userDetails['facility_id'] ??
          userDetails['facilityId'] ??
          userDetails['facility'] ??
          0;

      print('Using Facility ID: $facilityId');

      final formDataForDb     = {
        'server_id': '',
        'forms_ref_key': formsRefKey,
        'household_ref_key': householdRefKey,
        'beneficiary_ref_key': beneficiaryRefKey,
        'mother_key': motherKey,
        'father_key': fatherKey,
        'child_care_state': '',
        'device_details': jsonEncode({
          'id': deviceInfo. deviceId,
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

      try {
        print('\n📝 Data being inserted to DB:');
        print('form_json field: ${formDataForDb['form_json']}');
        print('form_json is null: ${formDataForDb['form_json'] == null}');
        print('form_json length: ${(formDataForDb['form_json'] as String?)?.length}');
        
        final formId = await LocalStorageDao.instance.insertFollowupFormData(formDataForDb);

        if (formId > 0) {
          print('✅ Form saved successfully with ID: $formId');
          print('📋 Form Data: $formJson');
          print('🏠 Household Ref Key: $householdRefKey');
          print('👤 Beneficiary Ref Key: $beneficiaryRefKey');
          print('📱 Form Type: $formType');
          print('📝 Form Name: $formName');
          print('🔑 Forms Ref Key: $formsRefKey');

          // Store in secure storage
          try {
            final secureStorageKey = 'child_registration_${beneficiaryRefKey}_${DateTime.now().millisecondsSinceEpoch}';
            await _secureStorage.write(
              key: secureStorageKey,
              value: formJson,
            );
            print('🔒 Form data stored in secure storage with key: $secureStorageKey');
          } catch (e) {
            print('⚠️ Error storing form data in secure storage: $e');
          }

          try {
            final savedData = await db.query(
              'followup_form_data',
              where: 'id = ?',
              whereArgs: [formId],
            );
            if (savedData.isNotEmpty) {
              print('\n📊 Saved Data from Database:');
              print(savedData.first);
            }
          } catch (e) {
            print('⚠️ Error reading saved data: $e');
          }

          // Build Child Care API payload (mirror EligibleCouple payload build)
          try {
            final rows = await db.query(
              FollowupFormDataTable.table,
              where: 'id = ?',
              whereArgs: [formId],
              limit: 1,
            );
            if (rows.isNotEmpty) {
              final saved = Map<String, dynamic>.from(rows.first);
              Map<String, dynamic> deviceJson = {};
              Map<String, dynamic> appJson = {};
              Map<String, dynamic> geoJson = {};
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
                    if (fj['geolocation_details'] is Map) {
                      geoJson = Map<String, dynamic>.from(fj['geolocation_details']);
                    } else if (fj['form_data'] is Map && (fj['form_data']['geolocation_details'] is Map)) {
                      geoJson = Map<String, dynamic>.from(fj['form_data']['geolocation_details']);
                    }
                  }
                }
              } catch (_) {}

              final working = userDetails['working_location'] ?? {};
              final userId = (working['asha_id'] ?? userDetails['unique_key'] ?? '').toString();
              final facility = (working['asha_associated_with_facility_id'] ?? working['hsc_id'] ?? userDetails['facility_id'] ?? userDetails['hsc_id'] ?? '').toString();
              final appRoleId = (userDetails['app_role_id'] ?? '').toString();

              final nowTs = DateTime.now();
              String fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

              final payload = [
                {
                  'unique_key': householdRefKey,
                  'beneficiaries_registration_ref_key': beneficiaryRefKey,
                  'child_care_type': 'registration_due',
                  'user_id': userId,
                  'facility_id': facility,
                  'is_deleted': 0,
                  'created_by': userId,
                  'created_date_time': fmt(nowTs),
                  'modified_by': userId,
                  'modified_date_time': fmt(nowTs),
                  'parent_added_by': userId,
                  'parent_facility_id': int.tryParse(facility) ?? facility,
                  'app_role_id': appRoleId,
                  'is_guest': 0,
                  'device_details': {
                    'device_id': deviceJson['id'] ?? deviceJson['device_id'] ?? deviceInfo.deviceId,
                    'device_plateform': deviceJson['platform'] ?? deviceJson['device_plateform'] ?? deviceInfo.platform,
                    'device_plateform_version': deviceJson['version'] ?? deviceJson['device_plateform_version'] ?? deviceInfo.osVersion,
                  },
                  'app_details': {
                    'app_version': appJson['app_version'] ?? deviceInfo.appVersion.split('+').first,
                    'app_name': appJson['app_name'] ?? deviceInfo.appName,
                  },
                  'geolocation_details': {
                    'latitude': geoJson['lat']?.toString() ?? '',
                    'longitude': geoJson['long']?.toString() ?? '',
                  },
                },
              ];

              print('Child Care API payload: '+jsonEncode(payload));
              try {
                final repo = ChildCareRepository();
                final apiResp = await repo.submitChildCareActivities(payload);
                print('Child Care API response: '+apiResp.toString());

                try {
                  if (apiResp is Map && apiResp['success'] == true && apiResp['data'] is List) {
                    final List data = apiResp['data'];
                    Map? item = data.cast<Map>().firstWhere(
                      (e) => (e['child_care_type']?.toString() ?? '') == 'registration_due',
                      orElse: () => {},
                    );
                    final serverId = (item?['_id'] ?? '').toString();
                    if (serverId.isNotEmpty) {
                      int updated = await db.update(
                        FollowupFormDataTable.table,
                        {
                          'server_id': serverId,
                          'modified_date_time': now,
                        },
                        where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
                        whereArgs: [beneficiaryRefKey, formsRefKey],
                      );
                      if (updated == 0) {
                        updated = await db.update(
                          FollowupFormDataTable.table,
                          {
                            'server_id': serverId,
                            'modified_date_time': now,
                          },
                          where: 'household_ref_key = ? AND forms_ref_key = ?',
                          whereArgs: [householdRefKey, formsRefKey],
                        );
                      }
                      print('Updated followup_form_data server_id=$serverId rows=$updated');
                    }
                  }
                } catch (e) {
                  print('Error updating followup_form_data with Child Care server_id: $e');
                }
              } catch (e) {
                print('Child Care API call failed: $e');
              }
            }
          } catch (e) {
            print('Error building Child Care API payload: $e');
          }

          emit(state.copyWith(isSubmitting: false, isSuccess: true));
        } else {
          throw Exception('Failed to save form data');
        }
      } catch (e) {
        print('❌ Error saving form data: $e');
        emit(state.copyWith(
          isSubmitting: false,
          error: 'Failed to save form: $e',
        ));
      }
    } catch (e) {
      print('❌ Error in form submission: $e');
      emit(state.copyWith(
        isSubmitting: false,
        error: 'Error: $e',
      ));
    }
  }
}
