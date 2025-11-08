import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/device_info_utils.dart';
import '../../../../core/utils/enums.dart' show FormStatus;
import '../../../../data/Local_Storage/User_Info.dart';
import '../../../../data/Local_Storage/tables/followup_form_data_table.dart';
import '../../../../data/SecureStorage/SecureStorage.dart';

part 'track_eligible_couple_event.dart';
part 'track_eligible_couple_state.dart';

class TrackEligibleCoupleBloc extends Bloc<TrackEligibleCoupleEvent, TrackEligibleCoupleState> {
  final String beneficiaryId;
  final bool isProtected;
  static const _secureStorage = FlutterSecureStorage();

  TrackEligibleCoupleBloc({
    required this.beneficiaryId,
    this.isProtected = false,
  }) : super(TrackEligibleCoupleState.initial(beneficiaryId: beneficiaryId, isProtected: isProtected)) {
    // Load previous form data if this is a protected beneficiary
    if (isProtected) {
      _loadPreviousFormData();
    }
    on<VisitDateChanged>((event, emit) {
      final fy = _deriveFinancialYear(event.date);
      emit(state.copyWith(visitDate: event.date, financialYear: fy, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<IsPregnantChanged>((event, emit) {
      emit(state.copyWith(
        isPregnant: event.isPregnant,
        clearPregnantFields: !event.isPregnant,
        clearNonPregnantFields: event.isPregnant,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<LmpDateChanged>((event, emit) {
      emit(state.copyWith(
        lmpDate: event.date,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<EddDateChanged>((event, emit) {
      emit(state.copyWith(
        eddDate: event.date,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });
    on<FpMethodChanged>((event, emit) {
      emit(state.copyWith(fpMethod: event.method, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });
    on<FpAntraInjectionDateChanged>((event, emit) {
      emit(state.copyWith(antraInjectionDateChanged: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<FpAdoptingChanged>((event, emit) {
      emit(state.copyWith(
        fpAdopting: event.adopting,
        fpMethod: event.adopting == true ? state.fpMethod : null,
        fpAdoptionDate: event.adopting == true ? state.fpAdoptionDate : null,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<FpAdoptionDateChanged>((event, emit) {
      emit(state.copyWith(fpAdoptionDate: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });
    on<BeneficiaryAbsentCHanged>((event, emit) {
      emit(state.copyWith(beneficiaryAbsentCHanged: event.value, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });
    on<RemovalDAteChange>((event, emit) {
      emit(state.copyWith(removalDAteChange: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });
    on<RemovalReasonChanged>((event, emit) {
      emit(state.copyWith(removalReasonChanged: event.method, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<CondomQuantity>((event, emit) {
      emit(state.copyWith(condom: event.value, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<MalaQuantity>((event, emit) {
      emit(state.copyWith(mala: event.value, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<ChayaQuantity>((event, emit) {
      emit(state.copyWith(chhaya: event.value, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<ECPQuantity>((event, emit) {
      emit(state.copyWith(ecp: event.value, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<LoadPreviousFormData>((event, emit) {
      print('Handling LoadPreviousFormData event with data: ${event.formData}');
      try {
        final formData = event.formData;
        print('Processing form data: $formData');

        DateTime? parseDate(dynamic dateValue) {
          if (dateValue == null) return null;
          if (dateValue is String) {
            try {
              return DateTime.parse(dateValue);
            } catch (e) {
              print('Error parsing date string $dateValue: $e');
              return null;
            }
          }
          if (dateValue is int) {
            return DateTime.fromMillisecondsSinceEpoch(dateValue);
          }
          return null;
        }

        final financialYear = formData['financial_year']?.toString() ?? state.financialYear;
        final isPregnant = formData['is_pregnant'] as bool?;
        final lmpDate = parseDate(formData['lmp_date']);
        final eddDate = parseDate(formData['edd_date']);
        final fpAdopting = formData['fp_adopting'] as bool? ?? state.fpAdopting;
        final fpMethod = formData['fp_method']?.toString();
        final condom = formData['condom_quantity']?.toString();
        final mala = formData['mala_quantity']?.toString();
        final chhaya = formData['chhaya_quantity']?.toString();
        final ecp = formData['ecp_quantity']?.toString();
        final removalReason = formData['removal_reason']?.toString();
        final fpAdoptionDate = parseDate(formData['fp_adoption_date']);
        final antraInjectionDate = parseDate(formData['antra_injection_date']);

        print('Updating state with form data:');
        print('- financialYear: $financialYear');
        print('- isPregnant: $isPregnant');
        print('- lmpDate: $lmpDate');
        print('- eddDate: $eddDate');
        print('- fpAdopting: $fpAdopting');
        print('- fpMethod: $fpMethod');

        emit(state.copyWith(
          financialYear: financialYear,
          isPregnant: isPregnant,
          lmpDate: lmpDate,
          eddDate: eddDate,
          fpAdopting: fpAdopting,
          fpMethod: fpMethod,
          condom: condom,
          mala: mala,
          chhaya: chhaya,
          ecp: ecp,
          removalReasonChanged: removalReason,
          fpAdoptionDate: fpAdoptionDate,
          antraInjectionDateChanged: antraInjectionDate,
        ));

        print('Successfully updated state with previous form data');
      } catch (e, stackTrace) {
        print('Error in LoadPreviousFormData handler: $e');
        print('Stack trace: $stackTrace');
      }
    });

    on<SubmitTrackForm>((event, emit) async {
      if (!state.isValid) {
        emit(state.copyWith(status: FormStatus.failure, error: 'Please complete required fields.'));
        return;
      }

      emit(state.copyWith(status: FormStatus.submitting, clearError: true));

      try {
        final db = await DatabaseProvider.instance.database;
        final now = DateTime.now().toIso8601String();

        final formType = FollowupFormDataTable.eligibleCoupleTrackingDue;
        final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'Track Eligible Couple';
        final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '';

        final formData = {
          'form_type': formType,
          'form_name': formName,
          'unique_key': formsRefKey,
          'form_data': {
            'visit_date': state.visitDate?.toIso8601String(),
            'financial_year': state.financialYear,
            'is_pregnant': state.isPregnant,
            'lmp_date': state.lmpDate?.toIso8601String(),
            'edd_date': state.eddDate?.toIso8601String(),
            'fp_adopting': state.fpAdopting,
            'fp_method': state.fpMethod,
            'fp_adoption_date': state.fpAdoptionDate?.toIso8601String(),
            'protection_status': state.fpAdopting == true ? 'Protected' : 'Unprotected',
            'condom_quantity': state.condom,
            'mala_quantity': state.mala,
            'chhaya_quantity': state.chhaya,
            'ecp_quantity': state.ecp,
            'removal_reason': state.removalReasonChanged,
            'beneficiary_absent': state.beneficiaryAbsentCHanged,
            'antra_injection_date': state.antraInjectionDateChanged?.toIso8601String(),
            'removal_date': state.removalDAteChange?.toIso8601String(),
          },
          'created_at': now,
          'updated_at': now,
        };

        List<Map<String, dynamic>> beneficiaryMaps = await db.query(
          'beneficiaries',
          where: 'unique_key LIKE ?',
          whereArgs: ['%${state.beneficiaryId}'],
        );

        if (beneficiaryMaps.isEmpty) {
          beneficiaryMaps = await db.query(
            'beneficiaries',
            where: 'id = ?',
            whereArgs: [int.tryParse(state.beneficiaryId) ?? 0],
          );
        }

        if (beneficiaryMaps.isEmpty) {
          throw Exception('Beneficiary not found');
        }

        final beneficiary = beneficiaryMaps.first;
        final householdRefKey = beneficiary['household_ref_key'] as String? ?? '';
        final motherKey = beneficiary['mother_key'] as String? ?? '';
        final fatherKey = beneficiary['father_key'] as String? ?? '';

        // final now = DateTime.now().toIso8601String();
        //
        // final formType = FollowupFormDataTable.eligibleCoupleTrackingDue;
        // final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'Track Eligible Couple';
        // final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? '';

        // final formData = {
        //   'form_type': formType,
        //   'form_name': formName,
        //   'unique_key': formsRefKey,
        //   'form_data': {
        //     'visit_date': state.visitDate?.toIso8601String(),
        //     'financial_year': state.financialYear,
        //     'is_pregnant': state.isPregnant,
        //     'lmp_date': state.lmpDate?.toIso8601String(),
        //     'edd_date': state.eddDate?.toIso8601String(),
        //     'fp_adopting': state.fpAdopting,
        //     'fp_method': state.fpMethod,
        //     'fp_adoption_date': state.fpAdoptionDate?.toIso8601String(),
        //     'protection_status': state.fpAdopting == true ? 'Protected' : 'Unprotected',
        //
        //   },
        //   'created_at': now,
        //   'updated_at': now,
        // };

        final formJson = jsonEncode(formData);



        late DeviceInfo deviceInfo;
        try {
          deviceInfo = await DeviceInfo.getDeviceInfo();
        } catch (e) {
          print('Error getting package/device info: $e');
        }

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

        final formDataForDb = {
          'server_id': '',
          'forms_ref_key': formsRefKey,
          'household_ref_key': householdRefKey,
          'beneficiary_ref_key': state.beneficiaryId,
          'mother_key': motherKey,
          'father_key': fatherKey,
          'child_care_state': '',
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
          'parent_user':  '',
          'current_user_key':  '',
          'facility_id': facilityId,
          'form_json': formJson,
          'created_date_time': now,
          'modified_date_time': now,
          'is_synced': 0,
          'is_deleted': 0,
        };

        try {
          final formId = await LocalStorageDao.instance.insertFollowupFormData(formDataForDb);

          if (formId > 0) {
            try {
              await db.update(
                'beneficiaries',
                {'is_family_planning': state.fpAdopting == true ? 1 : 0}, // 1 for true, 0 for false
                where: 'unique_key LIKE ? OR id = ?',
                whereArgs: ['%${state.beneficiaryId}', int.tryParse(state.beneficiaryId) ?? 0],
              );
              print('Updated beneficiary is_family_planning to ${state.fpAdopting == true ? 1 : 0}');
            } catch (e) {
              print('Error updating beneficiary is_family_planning: $e');
              // Don't fail the form submission if update fails
            }

            try {
              final secureStorageKey = 'ec_tracking_${state.beneficiaryId}_${DateTime.now().millisecondsSinceEpoch}';
              await _secureStorage.write(
                key: secureStorageKey,
                value: formJson,
              );
              print('Form data stored in secure storage with key: $secureStorageKey');
            } catch (e) {
              print('Error storing form data in secure storage: $e');
              // Don't fail the form submission if secure storage fails
            }

            emit(state.copyWith(status: FormStatus.success));
          } else {
            emit(state.copyWith(status: FormStatus.failure, error: 'Failed to save form data'));
          }
        } catch (e) {
          emit(state.copyWith(status: FormStatus.failure, error: 'Error saving form: $e'));
        }
      } catch (e, stackTrace) {
        print('Error saving form data: $e');
        print('Stack trace: $stackTrace');
        emit(state.copyWith(
          status: FormStatus.failure,
          error: 'Failed to save form data. Please try again.',
        )
        );
      }
    });
  }

  String _deriveFinancialYear(DateTime? date) {
    if (date == null) return '';
    return date.year.toString();
  }

  Future<void> _loadPreviousFormData() async {
    try {
      print('Loading previous form data for beneficiary: ${state.beneficiaryId}');
      // Get all keys from secure storage
      final allKeys = await _secureStorage.readAll();
      print('Found ${allKeys.length} keys in secure storage');

      if (allKeys.isEmpty) {
        print('No keys found in secure storage');
        return;
      }

      // Find all form data keys for this beneficiary
      final formDataKeys = allKeys.entries
          .where((entry) => entry.key.startsWith('ec_tracking_${state.beneficiaryId}_'))
          .toList();

      print('Found ${formDataKeys.length} form data entries for beneficiary');

      if (formDataKeys.isEmpty) {
        print('No form data found for beneficiary: ${state.beneficiaryId}');
        return;
      }

      // Sort by timestamp (newest first)
      formDataKeys.sort((a, b) {
        final aParts = a.key.split('_');
        final bParts = b.key.split('_');
        final aTime = aParts.length >= 4 ? int.tryParse(aParts[3]) ?? 0 : 0;
        final bTime = bParts.length >= 4 ? int.tryParse(bParts[3]) ?? 0 : 0;
        return bTime.compareTo(aTime); // Sort in descending order
      });

      // Get the most recent form data
      final latestKey = formDataKeys.first.key;
      print('Loading most recent form data with key: $latestKey');

      final formData = await _secureStorage.read(key: latestKey);
      if (formData != null) {
        try {
          print('Raw form data from storage: $formData');
          final jsonData = jsonDecode(formData);

          if (jsonData is! Map<String, dynamic>) {
            print('Error: Expected JSON object but got ${jsonData.runtimeType}');
            return;
          }

          print('Parsed JSON data: $jsonData');

          // Check if we have nested form_data
          Map<String, dynamic> formDataToUse = jsonData;
          if (jsonData.containsKey('form_data') && jsonData['form_data'] is Map) {
            formDataToUse = jsonData['form_data'] as Map<String, dynamic>;
            print('Using nested form_data: $formDataToUse');
          }

          // Update state with previous form data
          add(LoadPreviousFormData(formDataToUse));

        } catch (e, stackTrace) {
          print('Error parsing form data: $e');
          print('Stack trace: $stackTrace');
        }
      } else {
        print('No form data found for key: $latestKey');
      }

    } catch (e, stackTrace) {
      print('Error loading previous form data: $e');
      print('Stack trace: $stackTrace');
    }
  }
}