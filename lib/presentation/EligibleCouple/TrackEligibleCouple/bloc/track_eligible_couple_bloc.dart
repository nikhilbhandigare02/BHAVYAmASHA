import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import 'package:medixcel_new/data/Local_Storage/tables/followup_form_data_table.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/device_info_utils.dart';
import '../../../../core/utils/enums.dart' show FormStatus;
import '../../../../data/Local_Storage/User_Info.dart';
import '../../../../data/repositories/EligibleCoupleRepository.dart';

part 'track_eligible_couple_event.dart';
part 'track_eligible_couple_state.dart';

class TrackEligibleCoupleBloc extends Bloc<TrackEligibleCoupleEvent, TrackEligibleCoupleState> {
  final String beneficiaryId;
  final String? beneficiaryRefKey;
  final bool isProtected;
  static const _secureStorage = FlutterSecureStorage();

  TrackEligibleCoupleBloc({
    required this.beneficiaryId,
    this.beneficiaryRefKey,
    this.isProtected = false,
  }) : super(TrackEligibleCoupleState.initial(
          beneficiaryId: beneficiaryId,
          beneficiaryRefKey: beneficiaryRefKey,
          isProtected: isProtected,
        )) {
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
      try {
        final formData = event.formData;
        DateTime? parseDate(dynamic dateValue) {
          if (dateValue == null) return null;
          if (dateValue is String) {
            return DateTime.parse(dateValue);
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
        final nowIso = DateTime.now().toIso8601String();
        final nowTs = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

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
          'created_at': nowIso,
          'updated_at': nowIso,
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

        final formJson = jsonEncode(formData);

        late DeviceInfo deviceInfo;
        try {
          deviceInfo = await DeviceInfo.getDeviceInfo();
        } catch (e) {
          print('Error getting package/device info: $e');
        }

        final currentUser = await UserInfo.getCurrentUser();

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
        }

        final facilityId = userDetails['asha_associated_with_facility_id'] ??
            userDetails['facility_id'] ??
            userDetails['facilityId'] ??
            userDetails['facility'] ??
            0;

        final formDataForDb = {
          'server_id': '',
          'forms_ref_key': formsRefKey,
          'household_ref_key': householdRefKey,
          'beneficiary_ref_key': state.beneficiaryRefKey ?? state.beneficiaryId,
          'mother_key': motherKey,
          'father_key': fatherKey,
          'child_care_state': 'tracking_due',
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
          'created_date_time': nowIso,
          'modified_date_time': nowIso,
          'is_synced': 0,
          'is_deleted': 0,
        };

        try {
          final formId = await LocalStorageDao.instance.insertFollowupFormData(formDataForDb);

          if (formId > 0) {
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
                String _uniq(String suffix) => '${deviceInfo.deviceId}_${suffix}${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
                final householdRefKey = beneficiary['household_ref_key'] as String? ?? '';
                final motherKey = beneficiary['mother_key'] as String? ?? '';
                final fatherKey = beneficiary['father_key'] as String? ?? '';
                final ecPayloadList = [
                  {
                    'unique_key': householdRefKey,
                    'beneficiaries_registration_ref_key': state.beneficiaryRefKey ?? state.beneficiaryId,
                    'eligible_couple_type': 'tracking_due',
                    'user_id': userId,
                    'facility_id': facility,
                    'is_deleted': 0,
                    'created_by': userId,
                    'created_date_time': nowTs,
                    'modified_by': userId,
                    'modified_date_time': nowTs,
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

                try {
                  final repo = EligibleCoupleRepository();
                  final apiResp = await repo.trackEligibleCouple(ecPayloadList);
                  try {
                    if (apiResp is Map && apiResp['success'] == true && apiResp['data'] is List) {
                      final List data = apiResp['data'];
                      Map? tracking = data.cast<Map>().firstWhere(
                        (e) => (e['eligible_couple_type']?.toString() ?? '') == 'tracking_due',
                        orElse: () => {},
                      );
                      final serverId = (tracking?['_id'] ?? '').toString();
                      if (serverId.isNotEmpty) {
                        final reqUniqueKey = beneficiaryRefKey;
                        final updated = await db.update(
                          FollowupFormDataTable.table,
                          {
                            'server_id': serverId,
                            'modified_date_time': nowIso,
                          },
                          where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
                          whereArgs: [reqUniqueKey, formsRefKey],
                        );
                        print('Updated followup_form_data (by req unique_key) server_id=$serverId rows=$updated');
                      }
                    }
                  } catch (e) {
                    print('Error updating followup_form_data with EC server_id: $e');
                  }
                } catch (e) {
                  print('EC API call failed: $e');
                }
              }
            } catch (e) {
              print('Error reading saved followup_form_data to build EC payload: $e');
            }
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
        ));
      }
    });
  }

  String _deriveFinancialYear(DateTime? date) {
    if (date == null) return '';
    return date.year.toString();
  }

  Future<void> _loadPreviousFormData() async {
    try {
      final allKeys = await _secureStorage.readAll();

      if (allKeys.isEmpty) {
        return;
      }

      final formDataKeys = allKeys.entries
          .where((entry) => entry.key.startsWith('ec_tracking_${state.beneficiaryId}_'))
          .toList();

      if (formDataKeys.isEmpty) {
        return;
      }

      formDataKeys.sort((a, b) {
        final aParts = a.key.split('_');
        final bParts = b.key.split('_');
        final aTime = aParts.length >= 4 ? int.tryParse(aParts[3]) ?? 0 : 0;
        final bTime = bParts.length >= 4 ? int.tryParse(bParts[3]) ?? 0 : 0;
        return bTime.compareTo(aTime); // Sort in descending order
      });

      final latestKey = formDataKeys.first.key;

      final formData = await _secureStorage.read(key: latestKey);
      if (formData != null) {
        try {
          final jsonData = jsonDecode(formData);

          if (jsonData is! Map<String, dynamic>) {
            return;
          }

          Map<String, dynamic> formDataToUse = jsonData;
          if (jsonData.containsKey('form_data') && jsonData['form_data'] is Map) {
            formDataToUse = jsonData['form_data'] as Map<String, dynamic>;
          }

          add(LoadPreviousFormData(formDataToUse));
        } catch (e, stackTrace) {
          print('Error parsing form data: $e');
          print('Stack trace: $stackTrace');
        }
      }
    } catch (e, stackTrace) {
      print('Error loading previous form data: $e');
      print('Stack trace: $stackTrace');
    }
  }
}