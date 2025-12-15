import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';

import '../../../../data/Database/User_Info.dart';

part 'hbyc_child_care_event.dart';
part 'hbyc_child_care_state.dart';

class HbycChildCareBloc extends Bloc<HbycChildCareEvent, HbycChildCareState> {
  HbycChildCareBloc() : super(const HbycChildCareInitial()) {
    on<BeneficiaryAbsentChanged>((event, emit) => emit(state.copyWith(beneficiaryAbsent: event.value, beneficiaryAbsentReason: event.value == 'Yes' ? state.beneficiaryAbsentReason : '')));
    on<BeneficiaryAbsentReasonChanged>((event, emit) => emit(state.copyWith(beneficiaryAbsentReason: event.value)));
    on<HbycBhramanChanged>((event, emit) => emit(state.copyWith(hbycBhraman: event.value)));
    on<IsChildSickChanged>((event, emit) => emit(state.copyWith(isChildSick: event.value)));
    on<BreastfeedingContinuingChanged>((event, emit) => emit(state.copyWith(breastfeedingContinuing: event.value)));
    on<CompleteDietProvidedChanged>((event, emit) => emit(state.copyWith(completeDietProvided: event.value)));
    on<WeighedByAwwChanged>((event, emit) => emit(state.copyWith(weighedByAww: event.value)));
    on<LengthHeightRecordedChanged>((event, emit) => emit(state.copyWith(lengthHeightRecorded: event.value)));
    on<WeightLessThan3sdReferredChanged>((event, emit) => emit(state.copyWith(weightLessThan3sdReferred: event.value)));
    on<DevelopmentDelaysObservedChanged>((event, emit) {
      emit(
        state.copyWith(
          developmentDelaysObserved: event.value,
          childReferred: '',
          referralDetails: '',
        ),
      );
    });
    on<ChildReferredChanged>((event, emit) {
      emit(
        state.copyWith(
          childReferred: event.value,

          // Reset referral place if No
          referralDetails: event.value == 'Yes' ? state.referralDetails : '',
        ),
      );
    });

    on<ReferralDetailsChanged>((event, emit) {
      emit(state.copyWith(referralDetails: event.value));
    });
    on<ReferralDetailsChildChanged>(
          (event, emit) =>
          emit(state.copyWith(referralDetailsChild: event.value)),
    );
    on<ChildReferredToHealthFacilityChanged>((event, emit) {
      emit(state.copyWith(childReferredToHealthFacility: event.value));
    });

    on<FullyVaccinatedAsPerMcpChanged>((event, emit) => emit(state.copyWith(fullyVaccinatedAsPerMcp: event.value)));
    on<MeaslesVaccineGivenChanged>((event, emit) => emit(state.copyWith(measlesVaccineGiven: event.value)));
    on<VitaminADosageGivenChanged>((event, emit) => emit(state.copyWith(vitaminADosageGiven: event.value)));
    on<OrsPacketAvailableChanged>((event, emit) => emit(state.copyWith(orsPacketAvailable: event.value)));
    on<IronFolicSyrupAvailableChanged>((event, emit) => emit(state.copyWith(ironFolicSyrupAvailable: event.value)));
    on<CounselingExclusiveBf6mChanged>((event, emit) => emit(state.copyWith(counselingExclusiveBf6m: event.value)));
    on<AdviceComplementaryFoodsChanged>((event, emit) => emit(state.copyWith(adviceComplementaryFoods: event.value)));
    on<AdviceHandWashingHygieneChanged>((event, emit) => emit(state.copyWith(adviceHandWashingHygiene: event.value)));
    on<AdviceParentingSupportChanged>((event, emit) => emit(state.copyWith(adviceParentingSupport: event.value)));
    on<CounselingFamilyPlanningChanged>((event, emit) => emit(state.copyWith(counselingFamilyPlanning: event.value)));
    on<AdvicePreparingAdministeringOrsChanged>((event, emit) => emit(state.copyWith(advicePreparingAdministeringOrs: event.value)));
    on<AdviceAdministeringIfaSyrupChanged>((event, emit) => emit(state.copyWith(adviceAdministeringIfaSyrup: event.value)));
    on<CompletionDateChanged>((event, emit) => emit(state.copyWith(completionDate: event.value)));
     on<FoodFrequency1Changed>((event, emit) => emit(state.copyWith(foodFrequency1: event.value)));
    on<FoodFrequency2Changed>((event, emit) => emit(state.copyWith(foodFrequency2: event.value)));
    on<FoodFrequency3Changed>((event, emit) => emit(state.copyWith(foodFrequency3: event.value)));
    on<FoodFrequency4Changed>((event, emit) => emit(state.copyWith(foodFrequency4: event.value)));
    // In hbyc_child_care_bloc.dart
    on<WeightForAgeChanged>((event, emit) => emit(state.copyWith(weightForAge: event.value)));
    on<WeightForLengthChanged>((event, emit) => emit(state.copyWith(weightForLength: event.value)));
    on<OrsGivenChanged>((event, emit) => emit(state.copyWith(orsGiven: event.value, orsCount: event.value == 'Yes' ? state.orsCount : '')));
    on<OrsCountChanged>((event, emit) => emit(state.copyWith(orsCount: event.value)));
    on<IfaSyrupGivenChanged>((event, emit) => emit(state.copyWith(ifaSyrupGiven: event.value, ifaSyrupCount: event.value == 'Yes' ? state.ifaSyrupCount : '')));
    on<IfaSyrupCountChanged>((event, emit) => emit(state.copyWith(ifaSyrupCount: event.value)));

    on<SubmitForm>((event, emit) async {


      emit(state.copyWith(status: HbycFormStatus.submitting, error: null));
      final errors = <String>[];
      if (state.hbycBhraman.trim().isEmpty) {
        errors.add('hbycBhramanRequired');
      }
      if (errors.isNotEmpty) {
        emit(state.copyWith(status: HbycFormStatus.failure, error: errors.join('\n')));
        return;
      }


      try {
        final db = await DatabaseProvider.instance.database;
        final now = DateTime.now().toIso8601String();
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
        final ashaUniqueKey = userDetails['unique_key'] ?? {};
        
        final formData = {
          'form_name': 'Home Based Young Child',
          'unique_key': '999',
          'form_data': {
            'beneficiary_absent': state.beneficiaryAbsent,
            'hbyc_bhraman': state.hbycBhraman,
            if (state.beneficiaryAbsent == 'Yes')
              'beneficiary_absent_reason': state.beneficiaryAbsentReason,
            'is_child_sick': state.isChildSick,
            if (state.isChildSick == 'Yes' && event.sicknessDetails != null) 'sickness_details': event.sicknessDetails,
            if (state.weighedByAww == 'Yes') 'weight_for_age': state.weightForAge,
            if (state.lengthHeightRecorded == 'Yes') 'weight_for_length': state.weightForLength,
            if (state.orsPacketAvailable == 'No') 'ors_given': state.orsGiven,
            if (state.orsPacketAvailable == 'No' && state.orsGiven == 'Yes') 'ors_count': state.orsCount,
            if (state.ironFolicSyrupAvailable == 'No') 'ifa_syrup_given': state.ifaSyrupGiven,
            if (state.ironFolicSyrupAvailable == 'No' && state.ifaSyrupGiven == 'Yes') 'ifa_syrup_count': state.ifaSyrupCount,
            'breastfeeding_continuing': state.breastfeedingContinuing,
            'is_referred_to_health_facility':state.childReferredToHealthFacility,
            'referred_place':state.referralDetails,
            'is_Child_Referred':state.childReferred,
            'referred_place_child':state.referralDetailsChild,
            'complete_diet_provided': state.completeDietProvided,
            'food_frequency_1': state.foodFrequency1,
            'food_frequency_2': state.foodFrequency2,
            'food_frequency_3': state.foodFrequency3,
            'food_frequency_4': state.foodFrequency4,
            'weighed_by_aww': state.weighedByAww,
            'length_height_recorded': state.lengthHeightRecorded,
            'weight_less_than_3sd_referred': state.weightLessThan3sdReferred,
            if (state.weightLessThan3sdReferred == 'Yes' && event.referralDetails != null) 'referral_details': event.referralDetails,
            'development_delays_observed': state.developmentDelaysObserved,
            if (state.developmentDelaysObserved == 'Yes' && event.developmentDelaysDetails != null) 'development_delays_details': event.developmentDelaysDetails,
            'fully_vaccinated_as_per_mcp': state.fullyVaccinatedAsPerMcp,
            'measles_vaccine_given': state.measlesVaccineGiven,
            'vitamin_a_dosage_given': state.vitaminADosageGiven,
            'ors_packet_available': state.orsPacketAvailable,
            'iron_folic_syrup_available': state.ironFolicSyrupAvailable,
            'counseling_exclusive_bf_6m': state.counselingExclusiveBf6m,
            'advice_complementary_foods': state.adviceComplementaryFoods,
            'advice_hand_washing_hygiene': state.adviceHandWashingHygiene,
            'advice_parenting_support': state.adviceParentingSupport,
            'counseling_family_planning': state.counselingFamilyPlanning,
            'advice_preparing_administering_ors': state.advicePreparingAdministeringOrs,
            'advice_administering_ifa_syrup': state.adviceAdministeringIfaSyrup,
            'completion_date': state.completionDate,

          },
          'created_at': now,
          'updated_at': now,
        };

        final beneficiaryRefKey = event.beneficiaryRefKey;
        final householdRefKey = event.householdRefKey;

        await db.insert(
          FollowupFormDataTable.table,
          {
            'forms_ref_key': '999',
            'household_ref_key': householdRefKey,
            'beneficiary_ref_key': beneficiaryRefKey,
            'form_json': jsonEncode(formData),
            'current_user_key': ashaUniqueKey,
            'created_date_time': now,
            'modified_date_time': now,
            'is_synced': 0,
            'is_deleted': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
 
        print('✅ HBYC Form Submitted Successfully');
        print('📋 Form Data:');
        print('   - Household ID: $householdRefKey');
        print('   - Beneficiary ID: $beneficiaryRefKey');
        print('   - Form Data: ${jsonEncode(formData, toEncodable: (item) => item.toString())}');
        print('   - Submitted at: $now');

        emit(state.copyWith(status: HbycFormStatus.success));
      } catch (e) {
        print('❌ Error saving HBYC form: $e');
        emit(state.copyWith(
          status: HbycFormStatus.failure, 
          error: 'Failed to save form data: $e',
        ));
      }
    });
  }
}
