import 'dart:convert';
 import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medixcel_new/core/utils/app_info_utils.dart';
import 'package:medixcel_new/core/utils/device_info_utils.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

part 'cbac_form_event.dart';
part 'cbac_form_state.dart';

class BeneficiaryInfo {
  final String? name;
  final String? gender;
  final String? dob;
  final String? mobile;
  final String? address;
  final String? fatherName;
  final String? spouseName;
  final String? relationToHead;
  final String? uniqueKey;
  final String? householdRefKey;

  BeneficiaryInfo({
    this.name,
    this.gender,
    this.dob,
    this.mobile,
    this.address,
    this.fatherName,
    this.spouseName,
    this.relationToHead,
    this.uniqueKey,
    this.householdRefKey,
  });

  factory BeneficiaryInfo.fromMap(Map<String, dynamic> data) {
    // Parse beneficiary_info JSON if it's a string
    dynamic info = data['beneficiary_info'];
    if (info is String) {
      try {
        info = jsonDecode(info);
      } catch (e) {
        info = {};
      }
    }
    
    return BeneficiaryInfo(
      name: info?['name'] ?? info?['memberName'] ?? info?['headName'],
      gender: info?['gender']?.toString().toLowerCase(),
      dob: info?['dob'],
      mobile: info?['mobileNo'],
      address: info?['address'] ?? info?['village'],
      fatherName: info?['fatherName'],
      spouseName: info?['spouseName'],
      relationToHead: info?['relation_to_head'],
      uniqueKey: data['unique_key']?.toString(),
      householdRefKey: data['household_ref_key']?.toString(),
    );
  }

  int? get age {
    if (dob == null) return null;
    try {
      final birthDate = DateTime.parse(dob!);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }
}

class CbacFormBloc extends Bloc<CBACFormEvent, CbacFormState> {
  static const int totalTabs = 6;
  static const _secureStorage = FlutterSecureStorage();
  
  String? beneficiaryId;
  String? householdId;
  
  Future<Database> get _database async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'm_aasha.db');
    return openDatabase(path);
  }
  
  CbacFormBloc({String? beneficiaryId, String? householdId}) : super(const CbacFormInitial()) {
    this.beneficiaryId = beneficiaryId;
    this.householdId = householdId;
    
    on<CbacOpened>((event, emit) async {
      // Update beneficiary and household IDs from event
      if (event.beneficiaryId != null && event.beneficiaryId!.isNotEmpty) {
        this.beneficiaryId = event.beneficiaryId;
      }
      if (event.hhid != null && event.hhid!.isNotEmpty) {
        this.householdId = event.hhid;
      }
      
      print('🔄 CbacOpened - beneficiaryId: ${this.beneficiaryId}, householdId: ${this.householdId}');
      
      // Show consent dialog if not shown before
      if (!state.consentDialogShown) {
        emit(state.copyWith(consentDialogShown: true));
      }
      
      // Update state with the provided IDs
      emit(state.copyWith(
        data: {
          ...state.data,
          'beneficiary_id': this.beneficiaryId,
          'household_ref_key': this.householdId,
        },
      ));
      
      // Load beneficiary data if ID is provided
      if (this.beneficiaryId?.isNotEmpty == true) {
        try {
          final db = await _database;
          print('🔍 Querying beneficiary with key: ${this.beneficiaryId}');
          final List<Map<String, dynamic>> results = await db.query(
            'beneficiaries',
            where: 'unique_key = ?',
            whereArgs: [this.beneficiaryId],
          );
          print('🔍 Found ${results.length} matching beneficiaries');
          
          if (results.isNotEmpty) {
            final beneficiary = BeneficiaryInfo.fromMap(results.first);
            add(CbacBeneficiaryLoaded({
              'name': beneficiary.name,
              'gender': beneficiary.gender,
              'age': beneficiary.age,
              'mobile': beneficiary.mobile,
              'address': beneficiary.address,
              'fatherName': beneficiary.fatherName,
              'spouseName': beneficiary.spouseName,
              'relationToHead': beneficiary.relationToHead,
              'uniqueKey': beneficiary.uniqueKey,
              'householdRefKey': beneficiary.householdRefKey,
            }));
          } else {
            print('⚠️ No beneficiary found with ID: ${this.beneficiaryId}');
            // Even if beneficiary not found, we can still proceed with the form
            // The user can manually enter the required information
          }
        } catch (e) {
          debugPrint('Error loading beneficiary data: $e');
          // Even if there's an error, we can still proceed with the form
          // The user can manually enter the required information
        }
      }
    });
    
    on<CbacBeneficiaryLoaded>((event, emit) {
      final data = Map<String, dynamic>.from(state.data);
      final beneficiary = event.beneficiaryData;
      
      // Map beneficiary data to form fields
      data['personal.name'] = beneficiary['name'];
      data['personal.gender'] = beneficiary['gender'] == 'male' 
          ? 'Male' 
          : beneficiary['gender'] == 'female' 
              ? 'Female' 
              : 'Other';
      data['personal.age'] = beneficiary['age']?.toString();
      data['personal.mobile'] = beneficiary['mobile'];
      data['personal.address'] = beneficiary['address'];
      
      // Set father/husband name based on gender and relation
      if (beneficiary['gender'] == 'female' && beneficiary['spouseName'] != null) {
        data['personal.father'] = beneficiary['spouseName'];
      } else if (beneficiary['fatherName'] != null) {
        data['personal.father'] = beneficiary['fatherName'];
      }
      
      emit(state.copyWith(data: data));
    });

    on<CbacConsentDialogShown>((event, emit) => emit(state.copyWith(consentDialogShown: true)));
    
    on<CbacConsentAgreed>((event, emit) => emit(state.copyWith(
      consentAgreed: true,
      // Reset error message when consent is given
      errorMessage: null,
      missingKeys: const [],
    )));
    
    on<CbacConsentDisagreed>((event, emit) => emit(state.copyWith(consentAgreed: false)));

    on<CbacNextTab>((event, emit) {
      if (!state.consentAgreed) return;  
      bool has(String key) {
        final v = state.data[key];
        if (v == null) return false;
        if (v is String) return v.trim().isNotEmpty;
        return true;
      }

      List<String> missing = [];
      // Tabs: 0=General, 1=Personal, 2=Part A, 3=Part B, 4=Part C, 5=Part D
      switch (state.activeTab) {
        case 2: // Part A
          {
            final req = [
              'partA.age',
              'partA.tobacco',
              'partA.alcohol',
              'partA.activity',
              'partA.waist',
              'partA.familyHistory',
            ];
            for (final k in req) {
              if (!has(k)) missing.add(k);
            }
          }
          break;
        case 3:
          {
            final req = [
              'partB.b1.cough2w',
              'partB.b1.bloodMucus',
              'partB.b1.fever2w',
              'partB.b1.weightLoss',
              'partB.b1.nightSweat',
              'partB.b2.excessBleeding',
              'partB.b2.depression',
              'partB.b2.uterusProlapse',
            ];
            for (final k in req) {
              if (!has(k)) missing.add(k);
            }
          }
          break;
        default:
          break;
      }

      if (missing.isNotEmpty) {

        final token = DateTime.now().microsecondsSinceEpoch.toString();
        emit(state.copyWith(missingKeys: missing, errorMessage: token, clearError: false));
        return;
      }

      final next = (state.activeTab + 1).clamp(0, totalTabs - 1);
      emit(state.copyWith(activeTab: next));
    });

    on<CbacPrevTab>((event, emit) {
      final prev = (state.activeTab - 1).clamp(0, totalTabs - 1);
      emit(state.copyWith(activeTab: prev));
    });

    on<CbacFieldChanged>((event, emit) {
      final newData = Map<String, dynamic>.from(state.data);
      newData[event.keyPath] = event.value;
      emit(state.copyWith(data: newData, clearError: true));
    });

    on<CbacSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(CbacSubmitted event, Emitter<CbacFormState> emit) async {
    emit(state.copyWith(submitting: true, clearError: true, isSuccess: false));

    try {
      // Get database instance
      final db = await DatabaseProvider.instance.database;

      print('� _onSubmit - Initial values - beneficiaryId: $beneficiaryId, householdId: $householdId');

      // Initialize reference keys
      String householdRefKey = householdId ?? '';
      String beneficiaryRefKey = beneficiaryId ?? '';

      print('🔍 Initial reference keys - beneficiaryRefKey: $beneficiaryRefKey, householdRefKey: $householdRefKey');

      // If we have a household ID but no beneficiary ID, try to get the first beneficiary in the household
      if (householdRefKey.isNotEmpty && beneficiaryRefKey.isEmpty) {
        print('🔍 Looking up beneficiary for household: $householdRefKey');
        List<Map<String, dynamic>> beneficiaryMaps = await db.query(
          'beneficiaries',
          where: 'household_ref_key = ?',
          whereArgs: [householdRefKey],
          limit: 1,
        );
        
        print('🔍 Found ${beneficiaryMaps.length} beneficiaries for household');
        
        if (beneficiaryMaps.isNotEmpty) {
          final beneficiary = beneficiaryMaps.first;
          print('🔍 Found beneficiary data: ${beneficiary.toString()}');
          beneficiaryRefKey = beneficiary['unique_key']?.toString() ?? '';
          print('✅ Updated beneficiaryRefKey to: $beneficiaryRefKey');
        } else {
          print('⚠️ No beneficiaries found for household: $householdRefKey');
        }
      } else {
        print('ℹ️ Skipping beneficiary lookup - householdRefKey: $householdRefKey, beneficiaryRefKey: $beneficiaryRefKey');
      }
      
      print('💾 Final reference keys - beneficiaryRefKey: $beneficiaryRefKey, householdRefKey: $householdRefKey');

      final now = DateTime.now().toIso8601String();
      final formType = FollowupFormDataTable.cbac;
      final formName = FollowupFormDataTable.formDisplayNames[formType] ?? 'Community Based Assessment Checklist';
      final formsRefKey = FollowupFormDataTable.formUniqueKeys[formType] ?? 'vl7o6r9b6v3fbesk';

      // Calculate scores
      final partAScore = _calculatePartAScore(state);
      final partDScore = _calculatePartDScore(state);
      final totalScore = partAScore + partDScore;

      print('💾 Saving form with - beneficiaryRefKey: $beneficiaryRefKey, householdRefKey: $householdRefKey');

      final formData = {
        'form_type': formType,
        'form_name': formName,
        'unique_key': formsRefKey,
        'beneficiary_id': beneficiaryRefKey,
        'household_ref_key': householdRefKey,
        'form_data': {
          'beneficiary_id': beneficiaryRefKey,
          'household_ref_key': householdRefKey,
          'asha_name': state.data['general.ashaName'],
          'anm_name': state.data['general.anmName'],
          'phc': state.data['general.phc'],
          'village': state.data['general.village'],
          'hsc': state.data['general.hsc'],
          // Personal Information
          'name': state.data['personal.name'],
          'father': state.data['personal.father'],
          'age': state.data['personal.age'],
          'gender': state.data['personal.gender'],
          'address': state.data['personal.address'],
          'id_type': state.data['personal.idType'],
          'has_conditions': state.data['personal.hasConditions'],
          'mobile': state.data['personal.mobile'],
          'disability': state.data['personal.disability'],
          // Part A
          'partA_age': state.data['partA.age'],
          'partA_tobacco': state.data['partA.tobacco'],
          'partA_alcohol': state.data['partA.alcohol'],
          'partA_activity': state.data['partA.activity'],
          'partA_waist': state.data['partA.waist'],
          'partA_family_history': state.data['partA.familyHistory'],

          'partB_b1_breath': state.data['partB.b1.breath'],
          'partB_b1_cough2w': state.data['partB.b1.cough2w'],
          'partB_b1_blood_mucus': state.data['partB.b1.bloodMucus'],
          'partB_b1_fever2w': state.data['partB.b1.fever2w'],
          'partB_b1_weight_loss': state.data['partB.b1.weightLoss'],
          'partB_b1_night_sweat': state.data['partB.b1.nightSweat'],
          'partB_b1_seizures': state.data['partB.b1.seizures'],
          'partB_b1_open_mouth': state.data['partB.b1.openMouth'],
          'partB_b1_ulcers': state.data['partB.b1.ulcers'],
          'partB_b1_swelling_mouth': state.data['partB.b1.swellingMouth'],
          'partB_b1_rash_mouth': state.data['partB.b1.rashMouth'],
          'partB_b1_chew_pain': state.data['partB.b1.chewPain'],
          'partB_b1_druggs': state.data['partB.b1.druggs'],
          'partB_b1_tuberculosis': state.data['partB.b1.Tuberculosis'],
          'partB_b1_history': state.data['partB.b1.history'],
          'partB_b1_palms': state.data['partB.b1.palms'],
          'partB_b1_tingling': state.data['partB.b1.tingling'],
          'partB_b1_vision_blurred': state.data['partB.b1.visionBlurred'],
          'partB_b1_reading_difficulty': state.data['partB.b1.readingDifficulty'],
          'partB_b1_eye_pain': state.data['partB.b1.eyePain'],
          'partB_b1_eye_redness': state.data['partB.b1.eyeRedness'],
          'partB_b1_hearing_difficulty': state.data['partB.b1.hearingDifficulty'],
          'partB_b1_change_voice': state.data['partB.b1.changeVoice'],
          'partB_b1_skin_rash_discolor': state.data['partB.b1.skinRashDiscolor'],
          'partB_b1_skin_thick': state.data['partB.b1.skinThick'],
          'partB_b1_skin_lump': state.data['partB.b1.skinLump'],
          'partB_b1_numbness_hot_cold': state.data['partB.b1.numbnessHotCold'],
          'partB_b1_scratches_cracks': state.data['partB.b1.scratchesCracks'],
          'partB_b1_tingling_numbness': state.data['partB.b1.tinglingNumbness'],
          'partB_b1_close_eyelids_difficulty': state.data['partB.b1.closeEyelidsDifficulty'],
          'partB_b1_holding_difficulty': state.data['partB.b1.holdingDifficulty'],
          'partB_b1_leg_weakness_walk': state.data['partB.b1.legWeaknessWalk'],
          // Part B - B2
          'partB_b2_breast_lump': state.data['partB.b2.breastLump'],
          'partB_b2_nipple_bleed': state.data['partB.b2.nippleBleed'],
          'partB_b2_breast_shape_diff': state.data['partB.b2.breastShapeDiff'],
          'partB_b2_excess_bleeding': state.data['partB.b2.excessBleeding'],
          'partB_b2_depression': state.data['partB.b2.depression'],
          'partB_b2_uterus_prolapse': state.data['partB.b2.uterusProlapse'],
          'partB_b2_post_menopause_bleed': state.data['partB.b2.postMenopauseBleed'],
          'partB_b2_post_intercourse_bleed': state.data['partB.b2.postIntercourseBleed'],
          'partB_b2_smelly_discharge': state.data['partB.b2.smellyDischarge'],
          'partB_b2_irregular_periods': state.data['partB.b2.irregularPeriods'],
          'partB_b2_joint_pain': state.data['partB.b2.jointPain'],
          // Part C
          'partC_cooking_fuel': state.data['partC.cookingFuel'],
          'partC_business_risk': state.data['partC.businessRisk'],
          // Part D
          'partD_q1': state.data['partD.q1'],
          'partD_q2': state.data['partD.q2'],
          // Scores
          'score_partA': partAScore,
          'score_partD': partDScore,
          'score_total': totalScore,
        },
        'created_at': now,
        'updated_at': now,
      };


      final formJson = jsonEncode(formData);
      print('💾 CBAC Form JSON to be saved: $formJson');
      print('💾 CBAC Form JSON length: ${formJson.length}');

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

      final formDataForDb = {
        'server_id': '',
        'forms_ref_key': formsRefKey,
        'household_ref_key': householdRefKey,
        'beneficiary_ref_key': beneficiaryRefKey,
        'mother_key': '',
        'father_key': '',
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
        print('\n📝 CBAC Data being inserted to DB:');
        print('form_json field: ${formDataForDb['form_json']}');
        print('form_json is null: ${formDataForDb['form_json'] == null}');
        print('form_json length: ${(formDataForDb['form_json'] as String?)?.length}');
        
        final formId = await LocalStorageDao.instance.insertFollowupFormData(formDataForDb);

        if (formId > 0) {
          print('✅ CBAC Form saved successfully with ID: $formId');
          print('📋 Form Data: $formJson');
          print('🏠 Household Ref Key: $householdRefKey');
          print('👤 Beneficiary Ref Key: $beneficiaryRefKey');
          print('📱 Form Type: $formType');
          print('📝 Form Name: $formName');
          print('🔑 Forms Ref Key: $formsRefKey');

          // Store in secure storage
          try {
            final secureStorageKey = 'cbac_${beneficiaryRefKey}_${DateTime.now().millisecondsSinceEpoch}';
            await _secureStorage.write(
              key: secureStorageKey,
              value: formJson,
            );
            print(' CBAC Form data stored in secure storage with key: $secureStorageKey');
          } catch (e) {
            print(' Error storing CBAC form data in secure storage: $e');
          }

          // Print the saved data from database
          try {
            final savedData = await db.query(
              'followup_form_data',
              where: 'id = ?',
              whereArgs: [formId],
            );
            if (savedData.isNotEmpty) {
              print('\n📊 Saved CBAC Data from Database:');
              print(savedData.first);
            }
          } catch (e) {
            print('⚠️ Error reading saved CBAC data: $e');
          }

          emit(state.copyWith(submitting: false, isSuccess: true));
        } else {
          throw Exception('Failed to save CBAC form data');
        }
      } catch (e) {
        print('❌ Error saving CBAC form data: $e');
        emit(state.copyWith(
          submitting: false,
          errorMessage: 'Failed to save form: $e',
        ));
      }
    } catch (e) {
      print(' Error in CBAC form submission: $e');
      emit(state.copyWith(
        submitting: false,
        errorMessage: 'An error occurred: $e',
      ));
    }
  }

  int _calculatePartAScore(CbacFormState state) {
    final itemsAge = [
      'Less than 30 years',
      '30-39 years',
      '40-49 years',
      '50-69 years',
    ];
    
    final itemsTobacco = [
      'Never consumed',
      'Sometimes',
      'Daily',
    ];
    
    final itemsActivity = [
      'Less than 150 minutes per week',
      '150 minutes or more per week',
    ];
    
    final itemsWaist = [
      '≤ 80 cm',
      '81-90 cm',
      '> 90 cm',
    ];

    // Calculate Part A scores
    final age = state.data['partA.age'] as String?;
    final tobacco = state.data['partA.tobacco'] as String?;
    final alcohol = state.data['partA.alcohol'] as String?;
    final activity = state.data['partA.activity'] as String?;
    final waist = state.data['partA.waist'] as String?;
    final familyHx = state.data['partA.familyHistory'] as String?;

    final idxAge = age == null ? -1 : itemsAge.indexOf(age);
    final scoreAge = switch (idxAge) { 1 => 1, 2 => 2, 3 => 3, _ => 0 };
    
    final idxTob = tobacco == null ? -1 : itemsTobacco.indexOf(tobacco);
    final scoreTobacco = idxTob <= 0 ? 0 : 1;
    
    final idxAlcohol = alcohol == null ? -1 : (alcohol.toLowerCase() == 'yes' ? 0 : 1);
    final scoreAlcohol = idxAlcohol == 0 ? 1 : 0;
    
    final idxActivity = activity == null ? -1 : itemsActivity.indexOf(activity);
    final scoreActivity = idxActivity == 0 ? 1 : 0;
    
    final idxWaist = waist == null ? -1 : itemsWaist.indexOf(waist);
    final scoreWaist = switch (idxWaist) { 1 => 1, 2 => 2, _ => 0 };
    
    final idxFamily = familyHx == null ? -1 : (familyHx.toLowerCase() == 'yes' ? 0 : 1);
    final scoreFamily = idxFamily == 0 ? 2 : 0;

    return scoreAge + scoreTobacco + scoreAlcohol + scoreActivity + scoreWaist + scoreFamily;
  }

  int _calculatePartDScore(CbacFormState state) {
    final q1 = state.data['partD.q1'] as String?;
    final q2 = state.data['partD.q2'] as String?;
    
    final options = [
      'Not at all',
      'Several days',
      'More than half the days',
      'Nearly every day',
    ];

    int scoreFromValue(String? v) {
      if (v == null) return 0;
      final idx = options.indexOf(v);
      return idx < 0 ? 0 : idx;
    }

    return scoreFromValue(q1) + scoreFromValue(q2);
  }
}
