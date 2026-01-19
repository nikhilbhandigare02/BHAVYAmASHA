import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/device_info_utils.dart';
import '../../../../../core/utils/enums.dart';
import '../../../../../data/Database/User_Info.dart';
import '../../../../../data/Database/database_provider.dart';
import '../../../../../data/Database/local_storage_dao.dart';
import '../../../../../data/Database/tables/followup_form_data_table.dart';
import '../../../../../data/SecureStorage/SecureStorage.dart';
import '../../../../../data/repositories/MotherCareRepository/MotherCareRepository.dart';

part 'anvvisitform_event.dart';
part 'anvvisitform_state.dart';

class AnvvisitformBloc extends Bloc<AnvvisitformEvent, AnvvisitformState> {
  final String beneficiaryId;
  final String householdRefKey;


  final DatabaseProvider _databaseProvider = DatabaseProvider.instance;


  AnvvisitformBloc({
    required this.beneficiaryId,
    required this.householdRefKey,
  }) : super(const AnvvisitformInitial()) {
    on<VisitTypeChanged>((e, emit) => emit(state.copyWith(visitType: e.value)));
    on<PlaceOfAncChanged>((e, emit) => emit(state.copyWith(placeOfAnc: e.value)));
    on<DateOfInspectionChanged>((e, emit) {
      // Recalculate weeks of pregnancy if LMP date is available
      String weeksOfPregnancy = state.weeksOfPregnancy;
      if (state.lmpDate != null && e.value != null) {
        final difference = e.value!.difference(state.lmpDate!).inDays;
        final calculatedWeeks = (difference / 7).floor() + 1;
        weeksOfPregnancy = calculatedWeeks.toString();
      }
      emit(state.copyWith(dateOfInspection: e.value, weeksOfPregnancy: weeksOfPregnancy));
    });
    on<HouseNumberChanged>((e, emit) => emit(state.copyWith(houseNumber: e.value)));
    on<WomanNameChanged>((e, emit) => emit(state.copyWith(womanName: e.value)));
    on<HusbandNameChanged>((e, emit) => emit(state.copyWith(husbandName: e.value)));
    on<RchNumberChanged>((e, emit) => emit(state.copyWith(rchNumber: e.value)));

    on<LmpDateChanged>((e, emit) {
      if (e.value == null) {
        emit(state.copyWith(lmpDate: null, eddDate: null, weeksOfPregnancy: ''));
        return;
      }
      // EDD = LMP + 8 months and 10 days (same as TrackEligibleCouple)
      final edd = _calculateEddFromLmp(e.value!);
      
      // Calculate weeks of pregnancy
      final base = state.dateOfInspection ?? DateTime.now();
      final difference = base.difference(e.value!).inDays;
      final weeksOfPregnancy = (difference / 7).floor() + 1;
      
      emit(state.copyWith(
        lmpDate: e.value, 
        eddDate: edd, 
        weeksOfPregnancy: weeksOfPregnancy.toString()
      ));
    });
    on<EddDateChanged>((e, emit) => emit(state.copyWith(eddDate: e.value)));
    on<WeeksOfPregnancyChanged>((e, emit) => emit(state.copyWith(weeksOfPregnancy: e.value)));
    on<GravidaDecremented>((e, emit) => emit(state.copyWith(gravida: state.gravida > 1 ? state.gravida - 1 : 1)));
    on<GravidaIncremented>((e, emit) => emit(state.copyWith(gravida: state.gravida < 15 ? state.gravida + 1 : 15)));
    on<GravidaChanged>((e, emit) {
      final v = e.value;
      final clamped = v < 1 ? 1 : (v > 15 ? 15 : v);
      emit(state.copyWith(gravida: clamped));
    });
    on<IsBreastFeedingChanged>((e, emit) => emit(state.copyWith(isBreastFeeding: e.value)));
    on<Td1DateChanged>((e, emit) => emit(state.copyWith(td1Date: e.value)));
    on<Td2DateChanged>((e, emit) => emit(state.copyWith(td2Date: e.value)));
    on<TdBoosterDateChanged>((e, emit) => emit(state.copyWith(tdBoosterDate: e.value)));
    on<FolicAcidTabletsChanged>((event, emit) {
      emit(state.copyWith(folicAcidTablets: event.value));
    });

    on<IronFolicAcidTabletsChanged>((event, emit) {
      emit(state.copyWith(ironFolicAcidTablets: event.value));
    });

    on<CalciumVitaminD3TabletsChanged>((event, emit) {
      emit(state.copyWith(calciumVitaminD3Tablets: event.value));
    });

    on<PreExistingDiseasesChanged>((e, emit) => emit(state.copyWith(selectedDiseases: e.selectedDiseases)));
    on<OtherDiseaseChanged>((e, emit) => emit(state.copyWith(otherDisease: e.value)));
    on<WeightChanged>((e, emit) => emit(state.copyWith(weight: e.value)));
    on<SystolicChanged>((e, emit) => emit(state.copyWith(systolic: e.value)));
    on<DiastolicChanged>((e, emit) => emit(state.copyWith(diastolic: e.value)));
    on<HemoglobinChanged>((e, emit) => emit(state.copyWith(hemoglobin: e.value)));
    on<HighRiskChanged>((e, emit) {
      // Clear selected risks when high risk is changed to "No"
      if (e.value == 'No') {
        print('🔍 HighRiskChanged: Clearing selected risks because value is "No"');
        emit(state.copyWith(
          highRisk: e.value,
          selectedRisks: [],
        ));
      } else {
        print('🔍 HighRiskChanged: Setting high risk to "${e.value}", keeping existing risks: ${state.selectedRisks}');
        emit(state.copyWith(highRisk: e.value));
      }
    });
    on<SelectedRisksChanged>((e, emit) {
      print('🔍 SelectedRisksChanged: Updating selected risks to: ${e.selectedRisks}');
      emit(state.copyWith(selectedRisks: e.selectedRisks));
    });
    on<HasAbortionComplicationChanged>((e, emit) => emit(state.copyWith(hasAbortionComplication: e.value)));
    on<AbortionDateChanged>((e, emit) => emit(state.copyWith(abortionDate: e.value)));
    on<BeneficiaryAbsentChanged>((e, emit) => emit(state.copyWith(beneficiaryAbsent: e.value)));
    on<AbsenceReasonChanged>((e, emit) => emit(state.copyWith(absenceReason: e.value)));
    on<GivesBirthToBaby>((e, emit) => emit(state.copyWith(givesBirthToBaby: e.value)));
    on<DeliveryOutcomeChanged>((e, emit) => emit(state.copyWith(deliveryOutcome: e.value)));
    on<NumberOfChildrenChanged>((e, emit) {

      final womanName = e.womanName?.trim() ?? state.womanName.trim();

      String baby1Name = '';
      String baby2Name = '';
      String baby3Name = '';

      if (womanName.isNotEmpty) {
        switch (e.value) {
          case 'One Child':
            baby1Name = 'Baby of $womanName';
            break;
          case 'Twins':
            baby1Name = 'First baby of $womanName';
            baby2Name = 'Second baby of $womanName';
            break;
          case 'Triplets':
            baby1Name = 'First baby of $womanName';
            baby2Name = 'Second baby of $womanName';
            baby3Name = 'Third baby of $womanName';
            break;
        }
      }

      emit(state.copyWith(
        numberOfChildren: e.value,
        baby1Name: baby1Name,
        baby1Gender: '',
        baby1Weight: '',
        baby2Name: baby2Name,
        baby2Gender: '',
        baby2Weight: '',
        baby3Name: baby3Name,
        baby3Gender: '',
        baby3Weight: '',
      ));
    });

    on<Baby1NameChanged>((e, emit) => emit(state.copyWith(baby1Name: e.value)));
    on<Baby1GenderChanged>((e, emit) => emit(state.copyWith(baby1Gender: e.value)));
    on<Baby1WeightChanged>((e, emit) => emit(state.copyWith(baby1Weight: e.value)));

    on<Baby2NameChanged>((e, emit) => emit(state.copyWith(baby2Name: e.value)));
    on<Baby2GenderChanged>((e, emit) => emit(state.copyWith(baby2Gender: e.value)));
    on<Baby2WeightChanged>((e, emit) => emit(state.copyWith(baby2Weight: e.value)));

    on<Baby3NameChanged>((e, emit) => emit(state.copyWith(baby3Name: e.value)));
    on<Baby3GenderChanged>((e, emit) => emit(state.copyWith(baby3Gender: e.value)));
    on<Baby3WeightChanged>((e, emit) => emit(state.copyWith(baby3Weight: e.value)));
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

      final formType = FollowupFormDataTable.ancDueRegistration;
      final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'ANC Due Registration';
      final formsRefKey = 'bt7gs9rl1a5d26mz';


      final Map<String, dynamic> formData = {
        'anc_form': {
          'anc_visit': state.ancVisitNo,
          'visit_type': 'anc',

          'place_of_anc': state.placeOfAnc ?? '',

          'date_of_inspection': state.dateOfInspection != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(state.dateOfInspection!)
              : '',

          'house_no': state.houseNumber,
          'pw_name': state.womanName,
          'husband_name': state.husbandName,
          'rch_reg_no_of_pw': state.rchNumber ?? '',

          // IMPORTANT: server expects ISO / datetime string
          'lmp_date': state.lmpDate != null
              ? state.lmpDate!.toIso8601String()
              : '',

          'edd_date': state.eddDate != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(state.eddDate!)
              : '',

          'week_of_pregnancy': state.weeksOfPregnancy,
          'order_of_pregnancy': state.gravida,

          'is_breastfeeding': state.isBreastFeeding ?? '',

          'date_of_td1': state.td1Date != null
              ? DateFormat('yyyy-MM-dd').format(state.td1Date!)
              : '',

          'date_of_td2': state.td2Date != null
              ? DateFormat('yyyy-MM-dd').format(state.td2Date!)
              : '',

          'date_of_td_booster': state.tdBoosterDate != null
              ? DateFormat('yyyy-MM-dd').format(state.tdBoosterDate!)
              : '',

          'folic_acid_tab_quantity': state.folicAcidTablets ?? '',
          'iron_and_folic_acid_tab_quantity': state.ironFolicAcidTablets ?? '',
          'iron_folic_acid_tablets': state.ironFolicAcidTablets ?? '',
          'calcium_and_vit_d_tab_quantity': state.calciumVitaminD3Tablets ?? '',
          'has_albendazole_tab_given': '',

          'pre_exist_desease': state.selectedDiseases.isNotEmpty
              ? state.selectedDiseases.join(',')
              : '',

          'other_pre_exist_desease': state.otherDisease ?? '',

          'weight': state.weight ?? '',
          'bp_of_pw_systolic': state.systolic ?? '',
          'bp_of_pw_diastolic': state.diastolic ?? '',
          'hemoglobin': state.hemoglobin ?? '',

          'is_high_risk': state.highRisk?.toLowerCase() == 'yes' ? 'yes' : 'no',
          'high_risk_details': state.selectedRisks,

          'is_abortion': state.hasAbortionComplication ?? '',
          'date_of_abortion': state.abortionDate != null
              ? DateFormat('yyyy-MM-dd').format(state.abortionDate!)
              : '',

          'is_family_planning_counselling': '',
          'is_family_planning': '',
          'method_of_contraception': '',

          'has_pw_given_birth':
          state.givesBirthToBaby?.toLowerCase() == 'yes' ? 'yes' : 'no',

          'delivery_outcome':
          state.deliveryOutcome?.toLowerCase() == 'live birth'
              ? 'live_birth'
              : state.deliveryOutcome?.toLowerCase() == 'still birth'
              ? 'still_birth'
              : '',

          'live_birth': state.numberOfChildren == "One Child"
              ? "1"
              : state.numberOfChildren == "Twins"
              ? "2"
              : state.numberOfChildren == "Triplets"
              ? "3"
              : "",

          'children_arr': _buildChildrenArray(state),

          'ancVisitDates': _buildAncVisitDates(state),

          'prev_visit_date': '',

          'current_stage': _calculateCurrentStage(state),
          'completedVisited': state.ancVisitNo,
          'anc_visit_interval': "4",

          'next_visit_date': _calculateNextVisitDate(state),
        }
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

        if (state.givesBirthToBaby == 'Yes' || state.givesBirthToBaby == 'हाँ') {
          try {
            final deviceInfo = await DeviceInfo.getDeviceInfo();
            final ts = DateTime.now().toIso8601String();
            
            final existingActivity = await LocalStorageDao.instance.getMotherCareActivityByBeneficiary(beneficiaryId);
            
            final motherCareActivityData = {
              'mother_care_state': 'delivery_outcome',
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
              'modified_date_time': ts,
            };

            if (existingActivity != null) {
              // Update existing record
              print('Updating existing mother care activity for beneficiary: $beneficiaryId');
              await LocalStorageDao.instance.updateMotherCareActivity(beneficiaryId, motherCareActivityData);
              print('✅ Successfully updated mother care activity');
            } else {
              // Insert new record
              final newActivityData = {
                'server_id': null,
                'household_ref_key': householdRefKey,
                'beneficiary_ref_key': beneficiaryId,
                'created_date_time': ts,
                ...motherCareActivityData,
                'is_synced': 0,
                'is_deleted': 0,
              };
              print('Inserting new mother care activity for pregnant head: ${jsonEncode(newActivityData)}');
              await LocalStorageDao.instance.insertMotherCareActivity(newActivityData);
              print('✅ Successfully inserted mother care activity');
            }

            try {
              final existingEligibleActivity = await LocalStorageDao.instance.getEligibleCoupleActivityByBeneficiary(beneficiaryId);
              
              final eligibleCoupleActivityData = {
                'eligible_couple_state': 'tracking_due',
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
                'modified_date_time': ts,
              };

              if (existingEligibleActivity != null) {

                print('Updating existing eligible couple activity for beneficiary: $beneficiaryId');
                final db = await _databaseProvider.database;
                await db.update(
                  'eligible_couple_activities',
                  {
                    ...eligibleCoupleActivityData,
                    'is_synced': 0,
                  },
                  where: 'beneficiary_ref_key = ? AND is_deleted = 0',
                  whereArgs: [beneficiaryId],
                );
                print('✅ Successfully updated eligible couple activity');
              } else {
                final newEligibleActivityData = {
                  'server_id': null,
                  'household_ref_key': householdRefKey,
                  'beneficiary_ref_key': beneficiaryId,
                  'created_date_time': ts,
                  ...eligibleCoupleActivityData,
                  'is_synced': 0,
                  'is_deleted': 0,
                };
                print('Inserting tracking_due state in eligible_couple_activities table');
                await LocalStorageDao.instance.insertEligibleCoupleActivity(newEligibleActivityData);
                print('✅ Successfully inserted tracking_due state in eligible_couple_activities table');
              }
            } catch (e) {
              print('❌ Error handling eligible couple activity: $e');
            }

            final db = await _databaseProvider.database;
            final rows = await db.query(
              'beneficiaries_new',
              where: 'unique_key = ? AND is_deleted = 0',
              whereArgs: [beneficiaryId],
              limit: 1,
            );

            if (rows.isNotEmpty) {
              final row = Map<String, dynamic>.from(rows.first);
              Map<String, dynamic> info;
              try {
                info = jsonDecode(row['beneficiary_info']?.toString() ?? '{}');
              } catch (_) {
                info = {};
              }

              info['isPregnant'] = 0;

              await db.update(
                'beneficiaries_new',
                {
                  'beneficiary_info': jsonEncode(info),
                  'modified_date_time': ts,
                  'is_synced': 0,
                },
                where: 'unique_key = ?',
                whereArgs: [beneficiaryId],
              );
              print('✅ Updated isPregnant flag to 0 for beneficiary: $beneficiaryId');
            }
          } catch (e) {
            print('❌ Error inserting mother care activity or updating beneficiary: $e');
          }
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
            'week_of_pregnancy': state.weeksOfPregnancy,
            'gravida': state.gravida,
            'is_breast_feeding': state.isBreastFeeding,
            'td1_date': state.td1Date?.toIso8601String(),
            'td2_date': state.td2Date?.toIso8601String(),
            'td_booster_date': state.tdBoosterDate?.toIso8601String(),
            'folic_acid_tablets': state.folicAcidTablets,
            'iron_folic_acid_tablets': state.ironFolicAcidTablets,
            'iron_and_folic_acid_tablets': state.ironFolicAcidTablets,
            'calcium_vitamin_tablets': state.calciumVitaminD3Tablets,
            'selected_risks': state.selectedRisks,
            'has_abortion_complication': state.hasAbortionComplication,
            'abortion_date': state.abortionDate?.toIso8601String(),
            'pre_existing_diseases': state.selectedDiseases,
            'other_disease': state.otherDisease,
            'weight': state.weight,
            'systolic': state.systolic,
            'diastolic': state.diastolic,
            'hemoglobin': state.hemoglobin,
            'high_risk': state.highRisk,
            'has_pw_given_birth': state.givesBirthToBaby,
            'beneficiary_absent': state.beneficiaryAbsent,
            'anc_visit_interval':'0',
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

            Map<String, dynamic> formDataJson = {};
            Map<String, dynamic> deviceJson = {};
            Map<String, dynamic> appJson = {};
            Map<String, dynamic> formRoot = {};
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
                  formRoot = Map<String, dynamic>.from(fj);
                  if (fj['anc_form'] is Map) {
                    formDataJson = Map<String, dynamic>.from(fj['anc_form']);
                  }
                  if (fj['geolocation_details'] is Map) {
                    geoJson = Map<String, dynamic>.from(fj['geolocation_details']);
                  } else if (formDataJson['geolocation_details'] is Map) {
                    geoJson = Map<String, dynamic>.from(formDataJson['geolocation_details']);
                  }
                }
              }
            } catch (_) {}


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

  // Helper function to build children array from state
  List<Map<String, dynamic>> _buildChildrenArray(AnvvisitformState state) {
    final children = <Map<String, dynamic>>[];

    // Add baby 1 if data exists
    if (state.baby1Name?.isNotEmpty == true ||
        state.baby1Gender?.isNotEmpty == true ||
        state.baby1Weight?.isNotEmpty == true) {
      children.add({
        'name': state.baby1Name ?? '',
        'gender': state.baby1Gender ?? '',
        'weight_at_birth': state.baby1Weight ?? '',
      });
    }

    // Add baby 2 if data exists
    if (state.baby2Name?.isNotEmpty == true ||
        state.baby2Gender?.isNotEmpty == true ||
        state.baby2Weight?.isNotEmpty == true) {
      children.add({
        'name': state.baby2Name ?? '',
        'gender': state.baby2Gender ?? '',
        'weight_at_birth': state.baby2Weight ?? '',
      });
    }

    // Add baby 3 if data exists
    if (state.baby3Name?.isNotEmpty == true ||
        state.baby3Gender?.isNotEmpty == true ||
        state.baby3Weight?.isNotEmpty == true) {
      children.add({
        'name': state.baby3Name ?? '',
        'gender': state.baby3Gender ?? '',
        'weight_at_birth': state.baby3Weight ?? '',
      });
    }

    return children;
  }

  // Helper function to build ANC visit dates array
  List<Map<String, dynamic>> _buildAncVisitDates(AnvvisitformState state) {
    final visitDates = <Map<String, dynamic>>[];
    final lmpDate = state.lmpDate;
    final eddDate = state.eddDate;
    
    if (lmpDate != null && eddDate != null) {
      // ANC Visit 1: Up to 12 weeks
      visitDates.add({
        'from': DateFormat('yyyy-MM-dd HH:mm:ss').format(lmpDate),
        'to': DateFormat('yyyy-MM-dd HH:mm:ss').format(lmpDate.add(Duration(days: 84))), // 12 weeks
      });
      
      // ANC Visit 2: 13-20 weeks
      final visit2From = lmpDate.add(Duration(days: 85));
      visitDates.add({
        'from': DateFormat('yyyy-MM-dd HH:mm:ss').format(visit2From),
        'to': DateFormat('yyyy-MM-dd HH:mm:ss').format(lmpDate.add(Duration(days: 140))), // 20 weeks
      });
      
      // ANC Visit 3: 21-28 weeks
      final visit3From = lmpDate.add(Duration(days: 141));
      visitDates.add({
        'from': DateFormat('yyyy-MM-dd HH:mm:ss').format(visit3From),
        'to': DateFormat('yyyy-MM-dd HH:mm:ss').format(lmpDate.add(Duration(days: 196))), // 28 weeks
      });
      
      // ANC Visit 4: 29-32 weeks
      final visit4From = lmpDate.add(Duration(days: 197));
      visitDates.add({
        'from': DateFormat('yyyy-MM-dd HH:mm:ss').format(visit4From),
        'to': DateFormat('yyyy-MM-dd HH:mm:ss').format(lmpDate.add(Duration(days: 224))), // 32 weeks
      });
      
      // ANC Visit 5: 33-36 weeks
      final visit5From = lmpDate.add(Duration(days: 225));
      visitDates.add({
        'from': DateFormat('yyyy-MM-dd HH:mm:ss').format(visit5From),
        'to': DateFormat('yyyy-MM-dd HH:mm:ss').format(lmpDate.add(Duration(days: 252))), // 36 weeks
      });
      
      // ANC Visit 6: 37-40 weeks
      final visit6From = lmpDate.add(Duration(days: 253));
      final visit6To = eddDate.isBefore(lmpDate.add(Duration(days: 280))) ? eddDate : lmpDate.add(Duration(days: 280));
      visitDates.add({
        'from': DateFormat('yyyy-MM-dd HH:mm:ss').format(visit6From),
        'to': DateFormat('yyyy-MM-dd HH:mm:ss').format(visit6To),
      });
    }
    
    return visitDates;
  }

  // Helper function to calculate current stage based on weeks of pregnancy
  int _calculateCurrentStage(AnvvisitformState state) {
    final weeks = int.tryParse(state.weeksOfPregnancy ?? '0') ?? 0;
    if (weeks <= 12) return 1;
    if (weeks <= 20) return 2;
    if (weeks <= 28) return 3;
    if (weeks <= 32) return 4;
    if (weeks <= 36) return 5;
    return 6;
  }

  String _calculateNextVisitDate(AnvvisitformState state) {
    final currentDate = state.dateOfInspection ?? DateTime.now();
    final nextVisitDate = currentDate.add(Duration(days: 28)); // 4 weeks interval
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(nextVisitDate);
  }
}
