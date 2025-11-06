import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:medixcel_new/data/Local_Storage/local_storage_dao.dart';
import 'package:medixcel_new/data/Local_Storage/database_provider.dart';
import '../../../../core/utils/device_info_utils.dart';
import '../../../../core/utils/enums.dart' show FormStatus;
import '../../../../data/Local_Storage/User_Info.dart';
import '../../../../data/Local_Storage/tables/followup_form_data_table.dart';

part 'track_eligible_couple_event.dart';
part 'track_eligible_couple_state.dart';

class TrackEligibleCoupleBloc extends Bloc<TrackEligibleCoupleEvent, TrackEligibleCoupleState> {
  final String beneficiaryId;
  
  TrackEligibleCoupleBloc({required this.beneficiaryId}) : super(TrackEligibleCoupleState.initial(beneficiaryId: beneficiaryId)) {
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
      emit(state.copyWith(lmpDate: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<EddDateChanged>((event, emit) {
      emit(state.copyWith(eddDate: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<FpMethodChanged>((event, emit) {
      emit(state.copyWith(fpMethod: event.method, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<FpAdoptingChanged>((event, emit) {
      emit(state.copyWith(
        fpAdopting: event.adopting,
        // If not adopting, clear method/adoption date
        fpMethod: event.adopting == true ? state.fpMethod : null,
        fpAdoptionDate: event.adopting == true ? state.fpAdoptionDate : null,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<FpAdoptionDateChanged>((event, emit) {
      emit(state.copyWith(fpAdoptionDate: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<SubmitTrackForm>((event, emit) async {
      if (!state.isValid) {
        emit(state.copyWith(status: FormStatus.failure, error: 'Please complete required fields.'));
        return;
      }
      
      emit(state.copyWith(status: FormStatus.submitting, clearError: true));
      
      try {
        final db = await DatabaseProvider.instance.database;
        
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

          },
          'created_at': now,
          'updated_at': now,
        };
        
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
            // Update the is_family_planning flag based on fpAdopting value
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
}
