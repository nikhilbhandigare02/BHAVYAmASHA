import 'dart:convert';

import 'package:medixcel_new/data/Database/database_provider.dart';
import 'package:medixcel_new/data/Database/tables/followup_form_data_table.dart';
import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/Endpoints.dart';
import 'package:medixcel_new/data/NetworkAPIServices/api_services/network_services_API.dart';
import 'package:medixcel_new/data/SecureStorage/SecureStorage.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/utils/device_info_utils.dart';
import '../../../core/utils/id_generator_utils.dart';
import '../../Database/User_Info.dart';
import '../../Database/local_storage_dao.dart';


class FollowupFormsRepository {
  final NetworkServiceApi _api = NetworkServiceApi();

  Future<dynamic> addFollowupFormsFromDb(int formId) async {
    final db = await DatabaseProvider.instance.database;
    final rows = await db.query(
      FollowupFormDataTable.table,
      where: 'id = ?',
      whereArgs: [formId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('No followup_form_data row found for id=$formId');
    }

    final saved = Map<String, dynamic>.from(rows.first);
    final List<Map<String, Object?>> countResult = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM ${FollowupFormDataTable.table} WHERE is_synced = 0'
    );

    final int remainingToSync =
        Sqflite.firstIntValue(countResult) ?? 0;

    print('📌 Remaining followup forms to sync: $remainingToSync');

    final int isSynced = (saved['is_synced'] is int) ? saved['is_synced'] as int : 0;
    if (isSynced == 1) {
      return {'skipped': true, 'reason': 'already_synced'};
    }


    Map<String, dynamic> deviceJson = {};
    Map<String, dynamic> appJson = {};
    Map<String, dynamic> geoJson = {};
    dynamic formJsonValue;
    Map<String, dynamic> formRoot = {};

    try {
      final devStr = saved['device_details']?.toString();
      if (devStr != null && devStr.isNotEmpty) {
        final dj = jsonDecode(devStr);
        if (dj is Map) deviceJson = Map<String, dynamic>.from(dj);
      }
    } catch (_) {}


    try {
      final appStr = saved['app_details']?.toString();
      if (appStr != null && appStr.isNotEmpty) {
        final aj = jsonDecode(appStr);
        if (aj is Map) appJson = Map<String, dynamic>.from(aj);
      }
    } catch (_) {}

    // Parse form_json
    try {
      final formStr = saved['form_json']?.toString();
      if (formStr != null && formStr.isNotEmpty) {
        final fj = jsonDecode(formStr);
        formJsonValue = fj;
        if (fj is Map) {
          formRoot = Map<String, dynamic>.from(fj);
          if (fj['geolocation_details'] is Map) {
            geoJson = Map<String, dynamic>.from(fj['geolocation_details']);
          } else if (fj['form_data'] is Map && (fj['form_data']['geolocation_details'] is Map)) {
            geoJson = Map<String, dynamic>.from(fj['form_data']['geolocation_details']);
          }
        }
      }
    } catch (_) {}

    // All meta values should come from DB row + stored form_json + user details (same pattern as EC tracking)
    final String dbUserId = (saved['current_user_key'] ?? formRoot['user_id'] ?? '').toString();
    final String dbFacility = (saved['facility_id']?.toString() ?? formRoot['facility_id']?.toString() ?? '').toString();

    final String createdAt = (saved['created_date_time'] ?? formRoot['created_date_time'] ?? '').toString();
    final String modifiedAt = (saved['modified_date_time'] ?? formRoot['modified_date_time'] ?? '').toString();

    final String householdRefKey = (saved['household_ref_key'] ?? '').toString();
    final String beneficiaryRefKey = (saved['beneficiary_ref_key'] ?? '').toString();
    final String formsRefKey = (saved['forms_ref_key'] ?? '').toString();
    late DeviceInfo deviceInfo;
    try {
      deviceInfo = await DeviceInfo.getDeviceInfo();
    } catch (e) {
      print('Error getting package/device info: $e');
    }
    final String uniqueKeyFromForm =
    await IdGenerator.generateUniqueId(deviceInfo);

    if (householdRefKey.isEmpty || beneficiaryRefKey.isEmpty) {
      throw Exception('Missing household_ref_key or beneficiary_ref_key for followup_form_data id=$formId');
    }

    final currentUser = await UserInfo.getCurrentUser();
    final userDetails = currentUser?['details'] is String
        ? jsonDecode(currentUser?['details'] ?? '{}')
        : currentUser?['details'] ?? {};

    final working = userDetails['working_location'] ?? {};
    final facilityId = working['asha_associated_with_facility_id'] ??
        userDetails['asha_associated_with_facility_id'] ?? 0;
    final ashaUniqueKey = userDetails['unique_key'] ?? dbUserId;
    final String appRoleId = (userDetails['app_role_id'] ?? formRoot['app_role_id'] ?? '').toString();

    final String userId = ashaUniqueKey.toString();
    final String facility = facilityId.toString();
final formType = formJsonValue['form_type'];
    final Map<String, dynamic> payloadItem = {
      "unique_key": uniqueKeyFromForm,
      "household_registration_ref_key": householdRefKey,
      "beneficiaries_registration_ref_key": beneficiaryRefKey,
      "forms_ref_key": formsRefKey,
      "form_type": formType,

      "form_json": formJsonValue,

      "user_id": userId,
      "facility_id": facilityId.toString(),
      "is_guest": "0",

      "created_by": userId,
      "created_date_time": createdAt,
      "modified_by": userId,
      "modified_date_time": modifiedAt,

      "is_deleted": 0,

      "parent_added_by": userId,
      "parent_facility_id": int.parse(facilityId.toString()),

      "app_role_id": appRoleId,
      "is_hsc_updated": "0",
      "pregnancy_count": 0,

      "device_details": {
        "device_id": deviceJson["id"] ?? deviceJson["device_id"],
        "device_plateform": deviceJson["platform"] ?? deviceJson["device_plateform"],
        "device_plateform_version":
        deviceJson["version"] ?? deviceJson["device_plateform_version"],
      },

      "app_details": {
        "app_version": appJson["app_version"],
        "app_name": appJson["app_name"],
      },

      "geolocation_details": {
        "latitude": geoJson["lat"],
        "longitude": geoJson["long"],
      },

      "added_date_time": DateTime.now().toUtc().toIso8601String(),
      "modified_date_time_added_on_server":
      DateTime.now().toUtc().toIso8601String(),

      "added_by": userId,
      "modified_by_added_on_server": userId,
    };

    // AFTER payloadItem is created
    final String payloadJson = const JsonEncoder.withIndent('  ')
        .convert(payloadItem);

    print('📦 Followup Payload JSON:\n$payloadJson');

    String? token = await SecureStorageService.getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final response = await _api.postApi(
      Endpoints.addFollowupForms1,
      [payloadItem],
      headers: headers,
    );

    final respJson = response is String ? jsonDecode(response) : response;

    try {
      if (respJson is Map && respJson['data'] is List) {
        final List dataList = respJson['data'] as List;

        Map<String, dynamic>? itemForThisForm;
        for (final it in dataList) {
          if (it is Map) {
            final uk = it['unique_key']?.toString();
            if (uk == uniqueKeyFromForm) {
              itemForThisForm = Map<String, dynamic>.from(it);
              break;
            }
          }
        }

        if (itemForThisForm != null) {
          final bool itemSuccess = itemForThisForm['success'] == true;
          final dynamic sidRaw = itemForThisForm['_id'] ?? itemForThisForm['server_id'];
          final String serverId = sidRaw?.toString() ?? '';

          if (itemSuccess) {
            final updateValues = <String, Object?>{
              'is_synced': 1,
              'modified_date_time': DateTime.now().toIso8601String(),
            };
            if (serverId.isNotEmpty) {
              updateValues['server_id'] = serverId;
            }

            await db.update(
              FollowupFormDataTable.table,
              updateValues,
              where: 'beneficiary_ref_key = ? AND forms_ref_key = ?',
              whereArgs: [beneficiaryRefKey, formsRefKey],
            );
          }
        }
      }
    } catch (e) {
      // Best-effort update; log and continue
      print('Error updating followup_form_data after add_followup_forms1: $e');
    }

    return respJson;
  }

  Future<Map<String, dynamic>> fetchAndStoreFollowupForms({
    required String facilityId,
    required String ashaId,
    String? lastId,
    int limit = 20,
  }) async {
    final currentUser = await UserInfo.getCurrentUser();
    final userDetails = currentUser?['details'] is String
        ? jsonDecode(currentUser?['details'] ?? '{}')
        : currentUser?['details'] ?? {};

    String? token = await SecureStorageService.getToken();
    if ((token == null || token.isEmpty) && userDetails is Map) {
      try {
        token = userDetails['token']?.toString();
      } catch (_) {}
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    String effectiveLastId = (lastId ?? '').toString();
    if (effectiveLastId.isEmpty) {
      effectiveLastId = await LocalStorageDao.instance.getLatestFollowupFormServerId();
    }

    final body = <String, dynamic>{
      'facility_id': facilityId,
      'asha_id': ashaId,
      '_id': effectiveLastId,
      'limit': limit,
    };

    final response = await _api.postApi(
      Endpoints.getFollowupFormsDataByFal3,
      body,
      headers: headers,
    );

    final dataList = (response is Map && response['data'] is List)
        ? List<Map<String, dynamic>>.from(response['data'] as List)
        : <Map<String, dynamic>>[];

    final db = await DatabaseProvider.instance.database;

    int inserted = 0;
    int updated = 0;

    for (final rec in dataList) {
      final serverId = rec['_id']?.toString();
      if (serverId == null || serverId.isEmpty) continue;

      final existing = await db.query(
        FollowupFormDataTable.table,
        where: 'server_id = ?',
        whereArgs: [serverId],
      );

      final formsRefKey = rec['forms_ref_key']?.toString() ?? '';
      final householdRefKey = rec['household_registration_ref_key']?.toString();
      final beneficiaryRefKey = rec['beneficiaries_registration_ref_key']?.toString();

      // ---- Normalize form_json into the same wrapper used by local BLoCs ----
      Map<String, dynamic> formRoot = {};
      Map<String, dynamic> formDataMap = {};

      final rawFormJson = rec['form_json'];
      if (rawFormJson is Map) {
        formRoot = Map<String, dynamic>.from(rawFormJson);
      }

      try {
        final ecKeyDebug = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue];
        if (formsRefKey == ecKeyDebug) {
          print('FollowupForms Pull DEBUG EC: raw form_json for server_id=$serverId -> $rawFormJson');
        }
      } catch (_) {}

      if (formRoot['form_data'] is Map) {
        formDataMap = Map<String, dynamic>.from(formRoot['form_data'] as Map);
      } else {
        final ecKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.eligibleCoupleTrackingDue];
        final ancKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.ancDueRegistration];
        final hbycKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.hbycForm];
        final cbacKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.cbac];
        final childRegKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.childRegistrationDue];
        final childTrackKey = FollowupFormDataTable.formUniqueKeys[FollowupFormDataTable.childTrackingDue];

        if (formsRefKey == ecKey && formRoot['eligible_couple_tracking_due_from'] is Map) {
          final src = Map<String, dynamic>.from(
            formRoot['eligible_couple_tracking_due_from'] as Map,
          );
          formDataMap = {
            'visit_date': src['visit_date'],
            'financial_year': src['financial_year'],
            'is_pregnant': src['is_pregnant'],
            'lmp_date': src['lmp_date'],
            'edd_date': src['edd_date'],
            'fp_adopting': src['fp_adopting'],
            'fp_method': src['fp_method'],
            'fp_adoption_date': src['fp_adoption_date'],
            'protection_status': src['protection_status'],
            'condom_quantity': src['condom_quantity'],
            'mala_quantity': src['mala_quantity'],
            'chhaya_quantity': src['chhaya_quantity'],
            'ecp_quantity': src['ecp_quantity'],
            'removal_reason': src['removal_reason'],
            'beneficiary_absent': src['beneficiary_absent'],
            'antra_injection_date': src['antra_injection_date'],
            'removal_date': src['removal_date'],
          };
        } else if (formsRefKey == ancKey) {
          final Map<String, dynamic> src =
          formRoot['form_type'] == 'mother_care'
              ? Map<String, dynamic>.from(formRoot['anc_form'] ?? {})
              : Map<String, dynamic>.from(formRoot['anc_form'] ?? {});

          String _normalizeYesNo(dynamic value) {
            if (value == null) return '';

            if (value is bool) {
              return value ? 'yes' : 'no';
            }

            if (value is String) {
              final v = value.toLowerCase().trim();
              if (v == 'true' || v == 'yes') return 'yes';
              if (v == 'false' || v == 'no') return 'no';
              return v; // keep existing like 'unknown'
            }

            return '';
          }
          dynamic _pick(Map<String, dynamic> src, String k1, [String? k2]) {
            if (src[k1] != null && src[k1].toString().isNotEmpty) return src[k1];
            if (k2 != null && src[k2] != null && src[k2].toString().isNotEmpty) {
              return src[k2];
            }
            return null;
          }

          formDataMap = {
            'anc_visit_no': _pick(src, 'anc_visit_no', 'anc_visit'),
            'visit_type': src['visit_type'],
            'place_of_anc': src['place_of_anc'],
            'date_of_inspection': src['date_of_inspection'],
            'house_number': _pick(src, 'house_number', 'house_no'),


            'woman_name': _pick(src, 'woman_name', 'pw_name'),
            'husband_name': src['husband_name'],
            'rch_number': _pick(src, 'rch_number', 'rch_reg_no_of_pw'),


            'lmp_date': _pick(src,'lmp_date', 'lmp') ,
            'edd_date': _pick(src, 'edd_date' 'edd'),
            'weeks_of_pregnancy':
            _pick(src, 'weeks_of_pregnancy', 'week_of_pregnancy'),
            'gravida': _pick(src, 'gravida', 'order_of_pregnancy'),


            'selected_risks':
            _pick(src, 'selected_risks', 'high_risk_details') ?? [],
            'high_risk': _pick(src, 'high_risk', 'is_high_risk'),
            'has_abortion_complication':
            _pick(src, 'has_abortion_complication', 'is_abortion'),
            'abortion_date': _pick(src, 'abortion_date', 'date_of_abortion'),

            'is_breast_feeding':
            _pick(src, 'is_breast_feeding', 'is_breastfeeding'),
            'weight': src['weight'],
            'systolic': _pick(src, 'systolic', 'bp_of_pw_systolic'),
            'diastolic': _pick(src, 'diastolic', 'bp_of_pw_diastolic'),
            'hemoglobin': src['hemoglobin'],

            'td1_date': _pick(src, 'td1_date', 'date_of_td1'),
            'td2_date': _pick(src, 'td2_date', 'date_of_td2'),
            'td_booster_date': _pick(src, 'td_booster_date', 'date_of_td_booster'),

            'folic_acid_tablets':
            _pick(src, 'folic_acid_tablets', 'folic_acid_tab_quantity'),
            'pre_existing_disease':
            _pick(src, 'pre_existing_disease', 'pre_exist_desease'),

            'gives_birth_to_baby': _normalizeYesNo(
              _pick(src, 'gives_birth_to_baby', 'has_pw_given_birth'),
            ),
            'delivery_outcome': src['delivery_outcome'],
            'delivery_outcome': src['delivery_outcome'],
            'delivery_outcome': src['delivery_outcome'],
            'delivery_outcome': src['delivery_outcome'],

            'beneficiary_absent':
            _pick(src, 'beneficiary_absent', 'is_beneficiary_absent'),
            'anc_visit_interval':
            _pick(src, 'anc_visit_interval', 'is_anc_visit_interval'),
          };
        }
        else if (formsRefKey == hbycKey && formRoot['hbyc_form'] is Map) {
          final src = Map<String, dynamic>.from(formRoot['hbyc_form'] as Map);
          formDataMap = {
            'beneficiary_absent': src['beneficiary_absent'],
            'hbyc_bhraman': src['hbyc_bhraman'],
            'is_child_sick': src['is_child_sick'],
            'sickness_details': src['sickness_details'],
            'breastfeeding_continuing': src['breastfeeding_continuing'],
            'complete_diet_provided': src['complete_diet_provided'],
            'weighed_by_aww': src['weighed_by_aww'],
            'length_height_recorded': src['length_height_recorded'],
            'weight_less_than_3sd_referred': src['weight_less_than_3sd_referred'],
            'referral_details': src['referral_details'],
            'development_delays_observed': src['development_delays_observed'],
            'development_delays_details': src['development_delays_details'],
            'fully_vaccinated_as_per_mcp': src['fully_vaccinated_as_per_mcp'],
            'measles_vaccine_given': src['measles_vaccine_given'],
            'vitamin_a_dosage_given': src['vitamin_a_dosage_given'],
            'ors_packet_available': src['ors_packet_available'],
            'iron_folic_syrup_available': src['iron_folic_syrup_available'],
            'counseling_exclusive_bf_6m': src['counseling_exclusive_bf_6m'],
            'advice_complementary_foods': src['advice_complementary_foods'],
            'advice_hand_washing_hygiene': src['advice_hand_washing_hygiene'],
            'advice_parenting_support': src['advice_parenting_support'],
            'counseling_family_planning': src['counseling_family_planning'],
            'advice_preparing_administering_ors': src['advice_preparing_administering_ors'],
            'advice_administering_ifa_syrup': src['advice_administering_ifa_syrup'],
            'completion_date': src['completion_date'],
          };
        } else if (formsRefKey == cbacKey && formRoot['cbac_form'] is Map) {
          final src = Map<String, dynamic>.from(formRoot['cbac_form'] as Map);
          formDataMap = {
            'beneficiary_id': src['beneficiary_id'],
            'household_ref_key': src['household_ref_key'],
            'asha_name': src['asha_name'],
            'anm_name': src['anm_name'],
            'phc': src['phc'],
            'village': src['village'],
            'hsc': src['hsc'],
            'name': src['name'],
            'father': src['father'],
            'age': src['age'],
            'gender': src['gender'],
            'address': src['address'],
            'id_type': src['id_type'],
            'has_conditions': src['has_conditions'],
            'mobile': src['mobile'],
            'disability': src['disability'],
            'partA_age': src['partA_age'],
            'partA_tobacco': src['partA_tobacco'],
            'partA_alcohol': src['partA_alcohol'],
            'partA_activity': src['partA_activity'],
            'partA_waist': src['partA_waist'],
            'partA_family_history': src['partA_family_history'],
            'partB_b1_breath': src['partB_b1_breath'],
            'partB_b1_cough2w': src['partB_b1_cough2w'],
            'partB_b1_blood_mucus': src['partB_b1_blood_mucus'],
            'partB_b1_fever2w': src['partB_b1_fever2w'],
            'partB_b1_weight_loss': src['partB_b1_weight_loss'],
            'partB_b1_night_sweat': src['partB_b1_night_sweat'],
            'partB_b1_seizures': src['partB_b1_seizures'],
            'partB_b1_open_mouth': src['partB_b1_open_mouth'],
            'partB_b1_ulcers': src['partB_b1_ulcers'],
            'partB_b1_swelling_mouth': src['partB_b1_swelling_mouth'],
            'partB_b1_rash_mouth': src['partB_b1_rash_mouth'],
            'partB_b1_chew_pain': src['partB_b1_chew_pain'],
            'partB_b1_druggs': src['partB_b1_druggs'],
            'partB_b1_tuberculosis': src['partB_b1_tuberculosis'],
            'partB_b1_history': src['partB_b1_history'],
            'partB_b1_palms': src['partB_b1_palms'],
            'partB_b1_tingling': src['partB_b1_tingling'],
            'partB_b1_vision_blurred': src['partB_b1_vision_blurred'],
            'partB_b1_reading_difficulty': src['partB_b1_reading_difficulty'],
            'partB_b1_eye_pain': src['partB_b1_eye_pain'],
            'partB_b1_eye_redness': src['partB_b1_eye_redness'],
            'partB_b1_hearing_difficulty': src['partB_b1_hearing_difficulty'],
            'partB_b1_change_voice': src['partB_b1_change_voice'],
            'partB_b1_skin_rash_discolor': src['partB_b1_skin_rash_discolor'],
            'partB_b1_skin_thick': src['partB_b1_skin_thick'],
            'partB_b1_skin_lump': src['partB_b1_skin_lump'],
            'partB_b1_numbness_hot_cold': src['partB_b1_numbness_hot_cold'],
            'partB_b1_scratches_cracks': src['partB_b1_scratches_cracks'],
            'partB_b1_tingling_numbness': src['partB_b1_tingling_numbness'],
            'partB_b1_close_eyelids_difficulty': src['partB_b1_close_eyelids_difficulty'],
            'partB_b1_holding_difficulty': src['partB_b1_holding_difficulty'],
            'partB_b1_leg_weakness_walk': src['partB_b1_leg_weakness_walk'],
            'partB_b2_breast_lump': src['partB_b2_breast_lump'],
            'partB_b2_nipple_bleed': src['partB_b2_nipple_bleed'],
            'partB_b2_breast_shape_diff': src['partB_b2_breast_shape_diff'],
            'partB_b2_excess_bleeding': src['partB_b2_excess_bleeding'],
            'partB_b2_depression': src['partB_b2_depression'],
            'partB_b2_uterus_prolapse': src['partB_b2_uterus_prolapse'],
            'partB_b2_post_menopause_bleed': src['partB_b2_post_menopause_bleed'],
            'partB_b2_post_intercourse_bleed': src['partB_b2_post_intercourse_bleed'],
            'partB_b2_smelly_discharge': src['partB_b2_smelly_discharge'],
            'partB_b2_irregular_periods': src['partB_b2_irregular_periods'],
            'partB_b2_joint_pain': src['partB_b2_joint_pain'],
            'partC_cooking_fuel': src['partC_cooking_fuel'],
            'partC_business_risk': src['partC_business_risk'],
            'partD_q1': src['partD_q1'],
            'partD_q2': src['partD_q2'],
            'score_partA': src['score_partA'],
            'score_partD': src['score_partD'],
            'score_total': src['score_total'],
          };
        } else if (formsRefKey == childRegKey) {

          Map<String, dynamic> src;
          final mapEntries = formRoot.entries
              .where((e) => e.value is Map<String, dynamic>)
              .toList();
          if (formRoot['form_data'] is Map) {
            src = Map<String, dynamic>.from(formRoot['form_data'] as Map);
          } else if (mapEntries.length == 1) {
            src = Map<String, dynamic>.from(mapEntries.first.value as Map);
          } else {
            src = Map<String, dynamic>.from(formRoot);
          }

          formDataMap = {
            'rch_id_child': src['rch_id_child'],
            'register_serial_number': src['register_serial_number'],
            'date_of_birth': src['date_of_birth'],
            'date_of_registration': src['date_of_registration'],
            'child_name': src['child_name'],
            'gender': src['gender'],
            'mother_name': src['mother_name'],
            'father_name': src['father_name'],
            'address': src['address'],
            'whose_mobile_number': src['whose_mobile_number'],
            'mobile_number': src['mobile_number'],
            'mothers_rch_id_number': src['mothers_rch_id_number'],
            'birth_certificate_issued': src['birth_certificate_issued'],
            'birth_certificate_number': src['birth_certificate_number'],
            'weight_grams': src['weight_grams'],
            'religion': src['religion'],
            'caste': src['caste'],
          };
        } else if (formsRefKey == childTrackKey) {
          // Child Tracking Due (ChildTrackingFormBloc) mapping
          // Determine source map similar to child registration
          Map<String, dynamic> src;
          final mapEntries = formRoot.entries
              .where((e) => e.value is Map<String, dynamic>)
              .toList();
          if (formRoot['form_data'] is Map) {
            src = Map<String, dynamic>.from(formRoot['form_data'] as Map);
          } else if (mapEntries.length == 1) {
            src = Map<String, dynamic>.from(mapEntries.first.value as Map);
          } else {
            src = Map<String, dynamic>.from(formRoot);
          }

          formDataMap = {
            ...src,
            'current_tab': src['current_tab'],
            'current_tab_index': src['current_tab_index'],
            'weight_grams': src['weight_grams'],
            'case_closure': src['case_closure'],
            'visit_date': src['visit_date'],
          };
        } else {
          // Fallback: if there is exactly one nested Map, treat it as form_data
          final mapEntries = formRoot.entries
              .where((e) => e.value is Map<String, dynamic>)
              .toList();
          if (mapEntries.length == 1) {
            formDataMap = Map<String, dynamic>.from(
              mapEntries.first.value as Map,
            );
          } else {
            // Last resort: keep entire root as form_data
            formDataMap = Map<String, dynamic>.from(formRoot);
          }
        }
      }

      // Derive form_type & form_name from forms_ref_key using FollowupFormDataTable
      String? formTypeKey;
      String formName = '';
      FollowupFormDataTable.formUniqueKeys.forEach((k, v) {
        if (v == formsRefKey) {
          formTypeKey = k;
        }
      });
      if (formTypeKey != null) {
        formName = FollowupFormDataTable.formDisplayNames[formTypeKey!] ?? '';
      }

      final normalizedFormJson = <String, dynamic>{
        if (formTypeKey != null) 'form_type': formTypeKey,
        if (formName.isNotEmpty) 'form_name': formName,
        'unique_key': formsRefKey,
        'form_data': formDataMap,
        'created_at': rec['created_date_time'],
        'updated_at': rec['modified_date_time'],
      };

      final formJsonString = jsonEncode(normalizedFormJson);

      final deviceDetails = jsonEncode(rec['device_details'] ?? {});
      final appDetails = jsonEncode(rec['app_details'] ?? {});

      final parentUser = <String, dynamic>{
        'app_role_id': rec['app_role_id'],
        'is_guest': rec['is_guest'],
        'pregnancy_count': rec['pregnancy_count'],
        'created_by': rec['created_by'],
        'created_date_time': rec['created_date_time'],
        'modified_by': rec['modified_by'],
        'modified_date_time': rec['modified_date_time'],
        'added_by': rec['added_by'],
        'added_date_time': rec['added_date_time'],
        'modified_by_added_on_server': rec['modified_by_added_on_server'],
        'modified_date_time_added_on_server': rec['modified_date_time_added_on_server'],
        'is_member_details_processed': rec['is_member_details_processed'],
        'is_death': rec['is_death'],
        'is_hsc_updated': rec['is_hsc_updated'],
        'is_deleted': rec['is_deleted'],
        'is_processed': rec['is_processed'],
        'is_summary_processed': rec['is_summary_processed'],
        'is_data_processed': rec['is_data_processed'],
        '__v': rec['__v'],
        'member_name': rec['member_name'],
      };

      final row = <String, dynamic>{
        'server_id': serverId,
        'forms_ref_key': formsRefKey,
        'household_ref_key': householdRefKey,
        'beneficiary_ref_key': beneficiaryRefKey,
        'mother_key': rec['mother_key']?.toString(),
        'father_key': rec['father_key']?.toString(),
        'child_care_state': rec['child_care_state']?.toString() ?? '',
        'device_details': deviceDetails,
        'app_details': appDetails,
        'parent_user': jsonEncode(parentUser),
        'current_user_key': rec['created_by']?.toString() ?? ashaId,
        'facility_id': int.tryParse(rec['facility_id']?.toString() ?? facilityId) ?? 0,
        'form_json': formJsonString,
        'created_date_time': rec['created_date_time']?.toString(),
        'modified_date_time': rec['modified_date_time']?.toString(),
        'is_synced': 1,
        'is_deleted': rec['is_deleted'] is num ? rec['is_deleted'] : 0,
      };

      if (existing.isEmpty) {
        await db.insert(FollowupFormDataTable.table, row);
        print('FollowupForms Pull: INSERT form_type=${formTypeKey ?? ''} form_name=$formName forms_ref_key=$formsRefKey household=$householdRefKey beneficiary=$beneficiaryRefKey server_id=$serverId');
        inserted++;
      } else {
        await db.update(
          FollowupFormDataTable.table,
          row,
          where: 'server_id = ?',
          whereArgs: [serverId],
        );
        print('FollowupForms Pull: UPDATE form_type=${formTypeKey ?? ''} form_name=$formName forms_ref_key=$formsRefKey household=$householdRefKey beneficiary=$beneficiaryRefKey server_id=$serverId');
        updated++;
      }

      // Debug: print only the stored form_json from DB for this server_id
      try {
        final stored = await db.query(
          FollowupFormDataTable.table,
          where: 'server_id = ?',
          whereArgs: [serverId],
          limit: 1,
        );
        if (stored.isNotEmpty) {
          final rawFormJson = stored.first['form_json']?.toString();
          if (rawFormJson != null && rawFormJson.isNotEmpty) {
            try {
              final decoded = jsonDecode(rawFormJson);
              print('FollowupForms Pull: STORED form_json for server_id=$serverId -> $decoded');
            } catch (_) {
              print('FollowupForms Pull: STORED form_json (raw) for server_id=$serverId -> $rawFormJson');
            }
          } else {
            print('FollowupForms Pull: STORED form_json for server_id=$serverId is EMPTY or NULL');
          }
        } else {
          print('FollowupForms Pull: STORED form_json for server_id=$serverId -> ROW NOT FOUND');
        }
      } catch (e) {
        print('FollowupForms Pull: error reading back stored form_json for server_id=$serverId -> $e');
      }
    }

    return {
      'inserted': inserted,
      'updated': updated,
      'fetched': dataList.length,
    };
  }
}
