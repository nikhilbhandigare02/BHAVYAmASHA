
import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:medixcel_new/core/utils/device_info_utils.dart';
import 'package:medixcel_new/core/utils/geolocation_utils.dart';
import 'package:medixcel_new/core/utils/id_generator_utils.dart';
import 'package:medixcel_new/data/Database/User_Info.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../data/Database/database_provider.dart';
import '../../../../data/Database/local_storage_dao.dart';
import '../../HouseHoldDetails_Amenities/bloc/household_details_amenities_bloc.dart';

part 'registernewhousehold_event.dart';
part 'registernewhousehold_state.dart';

class RegisterNewHouseholdBloc
    extends Bloc<RegisternewhouseholdEvent, RegisterHouseholdState> {

  RegisterNewHouseholdBloc() : super(const RegisterHouseholdState()) {
    //  Add Head
    on<RegisterAddHead>((event, emit) {
      final current = state;
      final updated = List<Map<String, String>>.from(current.members);
      final data = Map<String, String>.from(event.data);
      data['#'] = '${updated.length + 1}';
      data['Relation'] = data['Relation'] ?? 'Self';
      
      // Check if this is a spouse being added (relation is 'Spouse')
      final isSpouse = data['Relation']?.toLowerCase() == 'spouse';
      final isUnmarried = data['marital_status']?.toLowerCase() == 'unmarried' ||
                         data['maritalStatus']?.toLowerCase() == 'unmarried';
      
      int newUnmarriedCount = current.unmarriedMemberCount;
      
      // Only increment unmarried count if it's a spouse and unmarried
      if (isSpouse && isUnmarried) {
        newUnmarriedCount++;
      }
      
      updated.add(data);

      // Calculate remaining children count based on head's children count
      final headChildren = int.tryParse((data['children'] ?? '0').toString()) ?? 0;
      
      emit(
        current.copyWith(
          headAdded: true,
          totalMembers: current.totalMembers + 1,
          members: updated,
          unmarriedMemberCount: newUnmarriedCount,
          remainingChildrenCount: headChildren, // Initialize with head's children count
        ),
      );
    });

    //  Add Member
    on<RegisterAddMember>((event, emit) {
      final current = state;
      final updated = List<Map<String, String>>.from(current.members);
      final data = Map<String, String>.from(event.data);
      data['#'] = '${updated.length + 1}';
      
      // Check if this is an unmarried member (not head or spouse)
      // final isUnmarried = data['marital_status']?.toLowerCase() == 'unmarried' ||
      //                    data['maritalStatus']?.toLowerCase() == 'unmarried';
      final isHeadOrSpouse = data['relation']?.toLowerCase() == 'self' || 
                            data['relation']?.toLowerCase() == 'spouse';
      
      int newUnmarriedCount = current.unmarriedMemberCount;
      int newRemainingChildrenCount = current.remainingChildrenCount;
      
      final isChild = data['Relation']?.toLowerCase() == 'son' ||
                     data['Relation']?.toLowerCase() == 'daughter' ||
                     data['Type']?.toLowerCase() == 'child';
      
      final isAdult = data['Type']?.toLowerCase() == 'adult';

      if (isChild) {
        if (newRemainingChildrenCount > 0) {
          newRemainingChildrenCount--;
        }
      } else if (isAdult  && !isHeadOrSpouse) {
        // For unmarried adults who are not head or spouse
        if (newUnmarriedCount > 0) {
          newUnmarriedCount--;
        }
      }
      
      // Decrease total members count if we have remaining children or unmarried members
      int newTotalMembers = current.totalMembers;
      if ((isChild && newRemainingChildrenCount > 0) || 
          (isAdult && newUnmarriedCount > 0)) {
        newTotalMembers--;
      }

      updated.add(data);

      emit(
        current.copyWith(
          totalMembers: newTotalMembers + 1, // Always add 1 for the new member
          members: updated,
          unmarriedMemberCount: newUnmarriedCount,
          remainingChildrenCount: newRemainingChildrenCount,
        ),
      );
    });

    //  Reset
    on<RegisterReset>((event, emit) {
      emit(const RegisterHouseholdState());
    });

    on<SaveHousehold>((event,         emit) async {
      try {
        emit(state.saving());

        final now = DateTime.now();
        final ts = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

        //  Get Location
        final geoLocation = await GeoLocation.getCurrentLocation();
        print(
          geoLocation.hasCoordinates
              ? '📍 Location obtained - Lat: ${geoLocation
              .latitude}, Long: ${geoLocation
              .longitude}, Accuracy: ${geoLocation.accuracy?.toStringAsFixed(
              2)}m'
              : '⚠️ Could not obtain location: ${geoLocation.error}',
        );

        //  Device Info
        late DeviceInfo deviceInfo;
        try {
          deviceInfo = await DeviceInfo.getDeviceInfo();
        } catch (e) {
          print('Error getting package/device info: $e');
        }

        final headForm = event.headForm ?? {};
        final String existingHeadKey = (headForm['head_unique_key'] ?? '')
            .toString();
        final String existingSpouseKey = (headForm['spouse_unique_key'] ?? '')
            .toString();
        final String existingHhKey = (headForm['hh_unique_key'] ?? '')
            .toString();
        final bool isEdit = existingHeadKey.isNotEmpty;

        String? newHouseholdKey;

        if (headForm.isNotEmpty) {
          try {
            final currentUser = await UserInfo.getCurrentUser();
            final userDetails = currentUser?['details'] is String
                ? jsonDecode(currentUser?['details'] ?? '{}')
                : currentUser?['details'] ?? {};
            final working = userDetails['working_location'] ?? {};
            final facilityId = working['asha_associated_with_facility_id'] ??
                userDetails['asha_associated_with_facility_id'] ?? 0;
            final ashaUniqueKey = userDetails['unique_key'] ?? {};

            final locationData = Map<String, String>.from(geoLocation.toJson());
            locationData['source'] = 'gps';
            if (!geoLocation.hasCoordinates) {
              locationData['status'] = 'unavailable';
              locationData['reason'] = 'Could not determine location';
            }
            final geoLocationJson = jsonEncode(locationData);

            if (!isEdit) {
              final uniqueKey = await IdGenerator.generateUniqueId(deviceInfo);

              newHouseholdKey = uniqueKey;
              final headId = await IdGenerator.generateUniqueId(deviceInfo);

              final bool hasSpouse = (headForm['maritalStatus'] == 'Married') &&
                  (headForm['spouseName'] != null &&
                      headForm['spouseName'].toString().trim().isNotEmpty);

              String? spouseKey;
              if (hasSpouse) {
                spouseKey = await IdGenerator.generateUniqueId(deviceInfo);
              }

              final headInfo = <String, dynamic>{
              'houseNo': headForm['houseNo'],
              'headName': headForm['headName'],
              'fatherName': headForm['fatherName'],
              'gender': headForm['gender'],
              'dob': headForm['dob'],
              'years': headForm['years'],
              'months': headForm['months'],
              'days': headForm['days'],
              'approxAge': headForm['approxAge'],
              'mobileNo': headForm['mobileNo'],
              'mobileOwner': headForm['mobileOwner'],
              'maritalStatus': headForm['maritalStatus'],
              'ageAtMarriage': headForm['ageAtMarriage'],
              'spouseName': headForm['spouseName'],
              'education': headForm['education'],
              'occupation': headForm['occupation'],
              'other_occupation': headForm['otherOccupation'],
              'religion': headForm['religion'],
              'other_religion': headForm['otherReligion'],
              'category': headForm['category'],
              'other_category': headForm['otherCategory'],
              'mobile_owner_relation': headForm['mobileOwnerOtherRelation'],
              'category': headForm['category'],
              'hasChildren': headForm['hasChildren'],
              'isPregnant': headForm['isPregnant'],
              'lmp': headForm['lmp'],
              'edd': headForm['edd'],
              'village': headForm['village'],
              'ward': headForm['ward'],
              'wardNo': headForm['wardNo'],
              'mohalla': headForm['mohalla'],
              'mohallaTola': headForm['mohallaTola'],
              'abhaAddress': headForm['abhaAddress'],
              'abhaNumber': headForm['abhaNumber'],
              'voterId': headForm['voterId'],
              'rationId': headForm['rationId'],
              'rationCardId': headForm['rationCardId'],
              'phId': headForm['phId'],
              'personalHealthId': headForm['personalHealthId'],
              'bankAcc': headForm['bankAcc'],
              'bankAccountNumber': headForm['bankAccountNumber'],
              'ifsc': headForm['ifsc'],
              'ifscCode': headForm['ifscCode'],
              'beneficiaryType': headForm['beneficiaryType'],
              'isMigrantWorker': headForm['isMigrantWorker'],
              'migrantState': headForm['migrantState'],
              'migrantDistrict': headForm['migrantDistrict'],
              'migrantBlock': headForm['migrantBlock'],
              'migrantPanchayat': headForm['migrantPanchayat'],
              'migrantVillage': headForm['migrantVillage'],
              'migrantContactNo': headForm['migrantContactNo'],
              'migrantDuration': headForm['migrantDuration'],
              'migrantWorkType': headForm['migrantWorkType'],
              'migrantWorkPlace': headForm['migrantWorkPlace'],
              'migrantRemarks': headForm['migrantRemarks'],
              'AfhABHAChange': headForm['AfhABHAChange'],
              'AfhRichIdChange': headForm['AfhRichIdChange'],

              'totalBorn': headForm['totalBorn'],
              'totalLive': headForm['totalLive'],
              'totalMale': headForm['totalMale'],
              'totalFemale': headForm['totalFemale'],
              'youngestAge': headForm['youngestAge'],
              'ageUnit': headForm['ageUnit'],
              'youngestGender': headForm['youngestGender'],
              'children': headForm['children'],
              'isFamilyhead': true,
              'isFamilyheadWife': false,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }
              ..removeWhere((k, v) =>
                  v == null || (v is String && v.trim().isEmpty));

              final headPayload = {
                'server_id': null,
                'household_ref_key': uniqueKey,
                'unique_key': headId,
                'beneficiary_state': 'active',
                'pregnancy_count': 0,
                'beneficiary_info': jsonEncode(headInfo),
                'geo_location': geoLocationJson,
                'spouse_key': spouseKey,
                'mother_key': null,
                'father_key': null,
                'is_family_planning': 0,
                'is_adult': 1,
                'is_guest': 0,
                'is_death': 0,
                'death_details': jsonEncode({}),
                'is_migrated': headForm['beneficiaryType'] == 'SeasonalMigrant'
                    ? 1
                    : 0,
                'is_separated':
                    headForm['maritalStatus'] == 'Separated' ||
                            headForm['maritalStatus'] == 'Divorced'
                        ? 1
                        : 0,
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
                'created_date_time': ts,
                'modified_date_time': ts,
                'is_synced': 0,
                'is_deleted': 0,
                'additional_info': jsonEncode({
                  'abha_verified': headForm['abhaVerified'],
                  'voter_id_verified': headForm['voterIdVerified'],
                  'ration_card_verified': headForm['rationCardVerified'],
                  'bank_account_verified': headForm['bankAccountVerified'],
                }),
              };

              print('📝 Inserting head beneficiary from headForm: ' +
                  jsonEncode(headPayload));
              await LocalStorageDao.instance.insertBeneficiary(headPayload);
              
              final maritalStatus = headForm['maritalStatus']?.toString();
              
              int age = 0;
              if (headForm['dob'] != null) {
                try {
                  final dob = DateTime.parse(headForm['dob']);
                  final now = DateTime.now();
                  age = now.year - dob.year;
                  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
                    age--;
                  }
                } catch (e) {
                  print('Error parsing DOB: $e');
                }
              }
              
              final isEligibleForCouple = maritalStatus == 'Married' && age >= 15 && age <= 49;
              
              if (isEligibleForCouple) {
                try {
                  final db = await DatabaseProvider.instance.database;
                  final eligibleCoupleActivityData = {
                    'server_id': '',
                    'household_ref_key': uniqueKey,
                    'beneficiary_ref_key': headId,
                    'eligible_couple_state': 'eligible_couple',
                    'device_details': jsonEncode({
                      'id': deviceInfo.deviceId,
                      'platform': deviceInfo.platform,
                      'version': deviceInfo.osVersion,
                    }),
                    'app_details': jsonEncode({
                      'app_version': deviceInfo.appVersion.split('+').first,
                      'form_data': {
                        'created_at': DateTime.now().toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                      },
                    }),
                    'parent_user': '',
                    'current_user_key': ashaUniqueKey,
                    'facility_id': facilityId,
                    'created_date_time': ts,
                    'modified_date_time': ts,
                    'is_synced': 0,
                    'is_deleted': 0,
                  };
                  
                  print('Inserting eligible couple activity for head: $headId');
                  await db.insert(
                    'eligible_couple_activities',
                    eligibleCoupleActivityData,
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                } catch (e) {
                  print('Error inserting eligible couple activity for head: $e');
                }
              }
                  
              // Check if head is female and pregnant, then insert ANC due status
              if (headForm['gender']?.toString().toLowerCase() == 'female') {
                final isPregnant = (headForm['isPregnant']?.toString().toLowerCase() == 'yes' || 
                                  headForm['isPregnant']?.toString().toLowerCase() == 'true');
                
                if (isPregnant) {
                  try {
                    final motherCareActivityData = {
                      'server_id': null,
                      'household_ref_key': uniqueKey,
                      'beneficiary_ref_key': headId,
                      'mother_care_state': 'anc_due',
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
                      'created_date_time': ts,
                      'modified_date_time': ts,
                      'is_synced': 0,
                      'is_deleted': 0,
                    };
                    
                    print('Inserting mother care activity for pregnant head: ${jsonEncode(motherCareActivityData)}');
                    await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
                  } catch (e) {
                    print('Error inserting mother care activity for head: $e');
                  }
                }
              }


              // --- INSERT SPOUSE BENEFICIARY IF MARRIED & SPOUSE NAME PRESENT ---
              if (hasSpouse && spouseKey != null) {
                try {

                  Map<String, dynamic> spDetails = {};
                  final spRaw = headForm['spousedetails'];
                  if (spRaw is Map) {
                    spDetails = Map<String, dynamic>.from(spRaw as Map);
                  } else if (spRaw is String && spRaw.isNotEmpty) {
                    try {
                      spDetails = Map<String, dynamic>.from(jsonDecode(spRaw));
                    } catch (_) {}
                  }

                  final spouseInfo = <String, dynamic>{
                    'relation': spDetails['relation'] ?? headForm['sp_relation'] ?? 'spouse',
                    'relation_to_head': 'spouse',
                    'maritalStatus': 'Married',

                    'memberName': spDetails['memberName'] ??
                        headForm['sp_memberName'] ??
                        headForm['spouseName'],

                    'ageAtMarriage': spDetails['ageAtMarriage'] ??
                        headForm['sp_ageAtMarriage'] ??
                        headForm['ageAtMarriage'],

                    'RichIDChanged': spDetails['RichIDChanged'] ?? headForm['sp_RichIDChanged'],

                    'spouseName': spDetails['spouseName'] ??
                        headForm['sp_spouseName'] ??
                        headForm['headName'],

                    'fatherName': spDetails['fatherName'] ?? headForm['sp_fatherName'],

                    'useDob': spDetails['useDob'] ?? headForm['sp_useDob'],
                    'dob': spDetails['dob'] ?? headForm['sp_dob'],
                    'edd': spDetails['edd'] ?? headForm['sp_edd'],
                    'lmp': spDetails['lmp'] ?? headForm['sp_lmp'],

                    'years': spDetails['years'] ?? headForm['sp_years'],
                    'months': spDetails['months'] ?? headForm['sp_months'],
                    'days': spDetails['days'] ?? headForm['sp_days'],

                    'approxAge': spDetails['approxAge'] ?? headForm['sp_approxAge'],

                    'gender': spDetails['gender'] ??
                        headForm['sp_gender'] ??
                        ((headForm['gender'] == 'Male')
                            ? 'Female'
                            : (headForm['gender'] == 'Female')
                            ? 'Male'
                            : null),

                    'occupation': spDetails['occupation'] ?? headForm['sp_occupation'],
                    'other_occupation':
                    spDetails['otherOccupation'] ?? headForm['sp_otherOccupation'],

                    'education': spDetails['education'] ?? headForm['sp_education'],

                    'religion': spDetails['religion'] ?? headForm['sp_religion'],
                    'other_religion':
                    spDetails['otherReligion'] ?? headForm['sp_otherReligion'],

                    'category': spDetails['category'] ?? headForm['sp_category'],
                    'other_category':
                    spDetails['otherCategory'] ?? headForm['sp_otherCategory'],

                    'abhaAddress': spDetails['abhaAddress'] ?? headForm['sp_abhaAddress'],
                    'abhaNumber': spDetails['abhaNumber'] ?? headForm['sp_abhaNumber'],

                    'mobileOwner': spDetails['mobileOwner'] ?? headForm['sp_mobileOwner'],
                    'mobileNo': spDetails['mobileNo'] ?? headForm['sp_mobileNo'],
                    'mobile_owner_relation': spDetails['mobileOwnerOtherRelation'] ??
                        headForm['sp_mobileOwnerOtherRelation'],

                    'bankAcc': spDetails['bankAcc'] ?? headForm['sp_bankAcc'],
                    'ifsc': spDetails['ifsc'] ?? headForm['sp_ifsc'],
                    'voterId': spDetails['voterId'] ?? headForm['sp_voterId'],
                    'rationId': spDetails['rationId'] ?? headForm['sp_rationId'],
                    'phId': spDetails['phId'] ?? headForm['sp_phId'],

                    'beneficiaryType':
                    spDetails['beneficiaryType'] ?? headForm['sp_beneficiaryType'],

                    'isPregnant': spDetails['isPregnant'] ?? headForm['sp_isPregnant'],

                    'familyPlanningCounseling': spDetails['familyPlanningCounseling'] ??
                        headForm['sp_familyPlanningCounseling'],

                    'is_family_planning':
                    ((spDetails['familyPlanningCounseling'] ??
                        headForm['sp_familyPlanningCounseling'])
                        ?.toString()
                        .toLowerCase() ==
                        'yes')
                        ? 1
                        : 0,

                    'fpMethod': spDetails['fpMethod'] ?? headForm['sp_fpMethod'],

                    'removalDate': spDetails['removalDate'] is DateTime
                        ? (spDetails['removalDate'] as DateTime).toIso8601String()
                        : spDetails['removalDate'] ?? headForm['sp_removalDate'],

                    'removalReason':
                    spDetails['removalReason'] ?? headForm['sp_removalReason'],

                    'condomQuantity':
                    spDetails['condomQuantity'] ?? headForm['sp_condomQuantity'],
                    'malaQuantity': spDetails['malaQuantity'] ?? headForm['sp_malaQuantity'],
                    'chhayaQuantity':
                    spDetails['chhayaQuantity'] ?? headForm['sp_chhayaQuantity'],
                    'ecpQuantity': spDetails['ecpQuantity'] ?? headForm['sp_ecpQuantity'],

                    'antraDate': spDetails['antraDate'] is DateTime
                        ? (spDetails['antraDate'] as DateTime).toIso8601String()
                        : spDetails['antraDate'] ?? headForm['sp_antraDate'],

                    // Children summary (mirrored)
                    'totalBorn': headForm['totalBorn'],
                    'totalLive': headForm['totalLive'],
                    'totalMale': headForm['totalMale'],
                    'totalFemale': headForm['totalFemale'],
                    'youngestAge': headForm['youngestAge'],
                    'ageUnit': headForm['ageUnit'],
                    'youngestGender': headForm['youngestGender'],
                    'children': headForm['children'],

                    'isFamilyhead': false,
                    'isFamilyheadWife': false,
                  }..removeWhere((k, v) =>
                      v == null || (v is String && v.trim().isEmpty));

                  final spousePayload = {
                    'server_id': null,
                    'household_ref_key': uniqueKey,
                    'unique_key': spouseKey,
                    'beneficiary_state': 'active',
                    'pregnancy_count': 0,
                    'beneficiary_info': jsonEncode(spouseInfo),
                    'geo_location': geoLocationJson,
                    'spouse_key': headId,
                    'mother_key': null,
                    'father_key': null,
                    'is_family_planning': (headForm['sp_familyPlanningCounseling']?.toString().toLowerCase() == 'yes') ? 1 : 0,
                    'is_adult': 1,
                    'is_guest': 0,
                    'is_death': 0,
                    'death_details': jsonEncode({}),
                    'is_migrated': 0,
                    'is_separated': 0,
                    'device_details': jsonEncode({
                      'id': deviceInfo.deviceId,
                      'platform': deviceInfo.platform,
                      'version': deviceInfo.osVersion,
                    }),
                    'app_details': jsonEncode({
                      'app_version':
                          deviceInfo.appVersion.split('+').first,
                      'app_name': deviceInfo.appName,
                      'build_number': deviceInfo.buildNumber,
                      'package_name': deviceInfo.packageName,
                    }),
                    'parent_user': jsonEncode({}),
                    'current_user_key': ashaUniqueKey,
                    'facility_id': facilityId,
                    'created_date_time': ts,
                    'modified_date_time': ts,
                    'is_synced': 0,
                    'is_deleted': 0,
                  };

                  print('📝 Inserting spouse beneficiary from headForm: ' +
                      jsonEncode(spousePayload));
                  await LocalStorageDao.instance
                      .insertBeneficiary(spousePayload);
                      
                  // Check if spouse is female and pregnant, then insert ANC due status
                  if (spouseInfo['gender']?.toString().toLowerCase() == 'female') {
                    final isPregnant = (spouseInfo['isPregnant']?.toString().toLowerCase() == 'yes' || 
                                      spouseInfo['isPregnant']?.toString().toLowerCase() == 'true');
                    
                    if (isPregnant) {
                      try {
                        final motherCareActivityData = {
                          'server_id': null,
                          'household_ref_key': uniqueKey,
                          'beneficiary_ref_key': spouseKey!,
                          'mother_care_state': 'anc_due',
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
                          'created_date_time': ts,
                          'modified_date_time': ts,
                          'is_synced': 0,
                          'is_deleted': 0,
                        };
                        
                        print('Inserting mother care activity for pregnant spouse: ${jsonEncode(motherCareActivityData)}');
                        await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
                      } catch (e) {
                        print('Error inserting mother care activity for spouse: $e');
                      }
                    }
                  }

                } catch (e) {
                  print(
                      'Error inserting spouse beneficiary from headForm: $e');
                }
              }
            }


            if (isEdit) {

              final existingHead =
              await LocalStorageDao.instance.getBeneficiaryByUniqueKey(
                  existingHeadKey);
              if (existingHead != null) {
                final headInfoRaw = existingHead['beneficiary_info'];
                final Map<String, dynamic> headInfo = headInfoRaw is Map
                    ? Map<String, dynamic>.from(headInfoRaw)
                    : (headInfoRaw is String && headInfoRaw.isNotEmpty)
                    ? Map<String, dynamic>.from(jsonDecode(headInfoRaw))
                    : <String, dynamic>{};

                headInfo
                  ..['houseNo'] = headForm['houseNo']
                  ..['headName'] = headForm['headName']
                  ..['fatherName'] = headForm['fatherName']
                  ..['gender'] = headForm['gender']
                  ..['dob'] = headForm['dob']
                  ..['years'] = headForm['years']
                  ..['months'] = headForm['months']
                  ..['days'] = headForm['days']
                  ..['approxAge'] = headForm['approxAge']
                  ..['mobileNo'] = headForm['mobileNo']
                  ..['mobileOwner'] = headForm['mobileOwner']
                  ..['maritalStatus'] = headForm['maritalStatus']
                  ..['ageAtMarriage'] = headForm['ageAtMarriage']
                  ..['spouseName'] = headForm['spouseName']
                  ..['education'] = headForm['education']
                  ..['occupation'] = headForm['occupation']
                  ..['religion'] = headForm['religion']
                  ..['category'] = headForm['category']
                  ..['hasChildren'] = headForm['hasChildren']
                  ..['isPregnant'] = headForm['isPregnant']
                  ..['lmp'] = headForm['lmp']
                  ..['edd'] = headForm['edd']
                  ..['village'] = headForm['village']
                  ..['ward'] = headForm['ward']
                  ..['wardNo'] = headForm['wardNo']
                  ..['mohalla'] = headForm['mohalla']
                  ..['mohallaTola'] = headForm['mohallaTola']
                  ..['abhaAddress'] = headForm['abhaAddress']
                  ..['abhaNumber'] = headForm['abhaNumber']
                  ..['voterId'] = headForm['voterId']
                  ..['rationId'] = headForm['rationId']
                  ..['rationCardId'] = headForm['rationCardId']
                  ..['phId'] = headForm['phId']
                  ..['personalHealthId'] = headForm['personalHealthId']
                  ..['bankAcc'] = headForm['bankAcc']
                  ..['bankAccountNumber'] = headForm['bankAccountNumber']
                  ..['ifsc'] = headForm['ifsc']
                  ..['ifscCode'] = headForm['ifscCode']
                  ..['beneficiaryType'] = headForm['beneficiaryType']
                  ..['isMigrantWorker'] = headForm['isMigrantWorker']
                  ..['migrantState'] = headForm['migrantState']
                  ..['migrantDistrict'] = headForm['migrantDistrict']
                  ..['migrantBlock'] = headForm['migrantBlock']
                  ..['migrantPanchayat'] = headForm['migrantPanchayat']
                  ..['migrantVillage'] = headForm['migrantVillage']
                  ..['migrantContactNo'] = headForm['migrantContactNo']
                  ..['migrantDuration'] = headForm['migrantDuration']
                  ..['migrantWorkType'] = headForm['migrantWorkType']
                  ..['migrantWorkPlace'] = headForm['migrantWorkPlace']
                  ..['migrantRemarks'] = headForm['migrantRemarks']
                  ..['AfhABHAChange'] = headForm['AfhABHAChange']
                  ..['AfhRichIdChange'] = headForm['AfhRichIdChange']
                  ..['totalBorn'] = headForm['totalBorn']
                  ..['totalLive'] = headForm['totalLive']
                  ..['totalMale'] = headForm['totalMale']
                  ..['totalFemale'] = headForm['totalFemale']
                  ..['youngestAge'] = headForm['youngestAge']
                  ..['ageUnit'] = headForm['ageUnit']
                  ..['youngestGender'] = headForm['youngestGender']
                  ..['children'] = headForm['children'];

                final updatedHead = Map<String, dynamic>.from(existingHead);
                // Store beneficiary_info consistently as JSON string, same as insert path
                updatedHead['beneficiary_info'] = jsonEncode(headInfo);
                updatedHead['geo_location'] =
                    existingHead['geo_location'] ?? geoLocationJson;

                await LocalStorageDao.instance.updateBeneficiary(updatedHead);
              }

              // ============================
              // UPDATE EXISTING SPOUSE (IF ANY)
              // ============================
              if (existingSpouseKey.isNotEmpty) {
                final existingSpouse =
                await LocalStorageDao.instance.getBeneficiaryByUniqueKey(
                    existingSpouseKey);
                if (existingSpouse != null) {
                  final spInfoRaw = existingSpouse['beneficiary_info'];
                  final Map<String, dynamic> spInfo = spInfoRaw is Map
                      ? Map<String, dynamic>.from(spInfoRaw)
                      : (spInfoRaw is String && spInfoRaw.isNotEmpty)
                      ? Map<String, dynamic>.from(jsonDecode(spInfoRaw))
                      : <String, dynamic>{};

                  // Prefer updated details from SpousBloc (spousedetails) when
                  // available in headForm, otherwise fall back to sp_* keys.
                  Map<String, dynamic> spDetails = {};
                  final spRaw = headForm['spousedetails'];
                  if (spRaw is Map) {
                    spDetails = Map<String, dynamic>.from(spRaw as Map);
                  } else if (spRaw is String && spRaw.isNotEmpty) {
                    try {
                      spDetails = Map<String, dynamic>.from(jsonDecode(spRaw));
                    } catch (_) {}
                  }

                  spInfo
                    ..['relation'] = spDetails['relation'] ?? headForm['sp_relation'] ?? 'spouse'
                    ..['memberName'] = spDetails['memberName'] ?? headForm['sp_memberName'] ??
                        headForm['spouseName']
                    ..['ageAtMarriage'] = spDetails['ageAtMarriage'] ?? headForm['sp_ageAtMarriage'] ??
                        headForm['ageAtMarriage']
                    ..['RichIDChanged'] = spDetails['RichIDChanged'] ?? headForm['sp_RichIDChanged']
                    ..['spouseName'] = spDetails['spouseName'] ?? headForm['sp_spouseName'] ??
                        headForm['headName']
                    ..['fatherName'] = spDetails['fatherName'] ?? headForm['sp_fatherName']
                    ..['useDob'] = spDetails['useDob'] ?? headForm['sp_useDob']
                    ..['dob'] = spDetails['dob'] ?? headForm['sp_dob']
                    ..['edd'] = spDetails['edd'] ?? headForm['sp_edd']
                    ..['lmp'] = spDetails['lmp'] ?? headForm['sp_lmp']
                    ..['approxAge'] = spDetails['approxAge'] ?? headForm['sp_approxAge']
                    ..['gender'] = spDetails['gender'] ?? headForm['sp_gender'] ??
                        ((headForm['gender'] == 'Male')
                            ? 'Female'
                            : (headForm['gender'] == 'Female')
                            ? 'Male'
                            : null)
                    ..['occupation'] = spDetails['occupation'] ?? headForm['sp_occupation']
                    ..['education'] = spDetails['education'] ?? headForm['sp_education']
                    ..['religion'] = spDetails['religion'] ?? headForm['sp_religion']
                    ..['category'] = spDetails['category'] ?? headForm['sp_category']
                    ..['abhaAddress'] = spDetails['abhaAddress'] ?? headForm['sp_abhaAddress']
                    ..['mobileOwner'] = spDetails['mobileOwner'] ?? headForm['sp_mobileOwner']
                    ..['mobileNo'] = spDetails['mobileNo'] ?? headForm['sp_mobileNo']
                    ..['bankAcc'] = spDetails['bankAcc'] ?? headForm['sp_bankAcc']
                    ..['ifsc'] = spDetails['ifsc'] ?? headForm['sp_ifsc']
                    ..['voterId'] = spDetails['voterId'] ?? headForm['sp_voterId']
                    ..['rationId'] = spDetails['rationId'] ?? headForm['sp_rationId']
                    ..['phId'] = spDetails['phId'] ?? headForm['sp_phId']
                    ..['beneficiaryType'] = spDetails['beneficiaryType'] ?? headForm['sp_beneficiaryType']
                    ..['isPregnant'] = spDetails['isPregnant'] ?? headForm['sp_isPregnant']
                    ..['familyPlanningCounseling'] = spDetails['familyPlanningCounseling'] ?? headForm['sp_familyPlanningCounseling']
                    ..['fpMethod'] = spDetails['fpMethod'] ?? headForm['sp_fpMethod']
                    ..['removalDate'] = spDetails['removalDate'] ?? headForm['sp_removalDate']
                    ..['removalReason'] = spDetails['removalReason'] ?? headForm['sp_removalReason']
                    ..['condomQuantity'] = spDetails['condomQuantity'] ?? headForm['sp_condomQuantity']
                    ..['malaQuantity'] = spDetails['malaQuantity'] ?? headForm['sp_malaQuantity']
                    ..['chhayaQuantity'] = spDetails['chhayaQuantity'] ?? headForm['sp_chhayaQuantity']
                    ..['ecpQuantity'] = spDetails['ecpQuantity'] ?? headForm['sp_ecpQuantity']
                    ..['maritalStatus'] = 'Married'
                    ..['relation_to_head'] = 'spouse'
                    ..['totalBorn'] = headForm['totalBorn']
                    ..['totalLive'] = headForm['totalLive']
                    ..['totalMale'] = headForm['totalMale']
                    ..['totalFemale'] = headForm['totalFemale']
                    ..['youngestAge'] = headForm['youngestAge']
                    ..['ageUnit'] = headForm['ageUnit']
                    ..['youngestGender'] = headForm['youngestGender']
                    ..['children'] = headForm['children'];

                  final updatedSpouse = Map<String, dynamic>.from(existingSpouse);
                  // Store spouse beneficiary_info as JSON string for consistency
                  updatedSpouse['beneficiary_info'] = jsonEncode(spInfo);
                  updatedSpouse['geo_location'] =
                      existingSpouse['geo_location'] ?? geoLocationJson;

                  await LocalStorageDao.instance.updateBeneficiary(
                      updatedSpouse);
                }
              }

            }
          } catch (e) {
            print('Error inserting head beneficiary from headForm: $e');
          }
        }

        //  Debug: Raw Data
        print(' Raw Form Data from Event:');
        event.amenitiesData.forEach((key, value) {
          print('- $key: $value (${value?.runtimeType})');
        });

        //  Household Info
        final householdInfo = {
          'residentialArea':
          event.amenitiesData['residentialArea']?.toString().trim() ??
              'Not Specified',
          'otherResidentialArea':
          event.amenitiesData['otherResidentialArea']?.toString().trim() ??
              '',
          'houseType': event.amenitiesData['houseType']?.toString().trim() ??
              'Not Specified',
          'otherHouseType': event.amenitiesData['otherHouseType']?.toString().trim() ??
              '',
          'ownershipType':
          event.amenitiesData['ownershipType']?.toString().trim() ??
              'Not Specified',
          'otherOwnershipType':
          event.amenitiesData['otherOwnershipType']?.toString().trim() ??
              '',
          'houseKitchen':
          event.amenitiesData['houseKitchen']?.toString().trim() ??
              'Not Specified',
          'cookingFuel':
          event.amenitiesData['cookingFuel']?.toString().trim() ??
              'Not Specified',
          'otherCookingFuel': event.amenitiesData['otherCookingFuel']?.toString().trim() ??
              '',
          'waterSource':
          event.amenitiesData['waterSource']?.toString().trim() ??
              'Not Specified',
          'otherWaterSource': event.amenitiesData['otherWaterSource']?.toString().trim() ??
              '',
          'electricity':
          event.amenitiesData['electricity']?.toString().trim() ??
              'Not Specified',
          'otherElectricity': event.amenitiesData['otherElectricity']?.toString().trim() ??
              '',
          'toilet': event.amenitiesData['toilet']?.toString().trim() ??
              'Not Specified',
          'toiletType': event.amenitiesData['toiletType']?.toString().trim() ??
              'Not Specified',
          'typeOfToilet': event.amenitiesData['typeOfToilet']?.toString().trim() ??
              '',
          'toiletPlace': event.amenitiesData['toiletPlace']
              ?.toString()
              .trim() ??
              'Not Specified',
          'lastUpdated': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'appdetails': {
            'app_version': deviceInfo.appVersion,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
          },
        };

        print(' Final Household Data to be saved:');
        householdInfo.forEach((key, value) {
          print('   - $key: $value');
        });

        final householdInfoString = Map<String, String>.fromIterable(
          householdInfo.entries,
          key: (entry) => entry.key,
          value: (entry) => entry.value?.toString() ?? 'Not Specified',
        );

        final householdInfoJson = jsonEncode(householdInfoString);
        print(' Household Info JSON: $householdInfoJson');

        final beneficiaries = await LocalStorageDao.instance
            .getAllBeneficiaries();
        if (beneficiaries.isEmpty) {
          throw Exception(
              'No existing beneficiary found to derive keys. Add a member first.');
        }
        final latestBeneficiary = beneficiaries.first;

        // Prefer the newly generated household key when creating a new record,
        // otherwise fall back to existingHhKey (edit) or the latest beneficiary's
        // stored household_ref_key.
        final String uniqueKey = isEdit && existingHhKey.isNotEmpty
            ? existingHhKey
            : (newHouseholdKey ?? (latestBeneficiary['household_ref_key'] ?? '')).toString();

        final String headId = isEdit && existingHeadKey.isNotEmpty
            ? existingHeadKey
            : (latestBeneficiary['unique_key'] ?? '').toString();


        if (event.memberForms.isNotEmpty) {
          try {
            final currentUser = await UserInfo.getCurrentUser();
            final userDetails = currentUser?['details'] is String
                ? jsonDecode(currentUser?['details'] ?? '{}')
                : currentUser?['details'] ?? {};
            final working = userDetails['working_location'] ?? {};
            final facilityId = working['asha_associated_with_facility_id'] ??
                userDetails['asha_associated_with_facility_id'] ?? 0;
            final ashaUniqueKey = userDetails['unique_key'] ?? {};

            final locationData = Map<String, String>.from(geoLocation.toJson());
            locationData['source'] = 'gps';
            if (!geoLocation.hasCoordinates) {
              locationData['status'] = 'unavailable';
              locationData['reason'] = 'Could not determine location';
            }
            final geoLocationJson = jsonEncode(locationData);

            for (final member in event.memberForms) {
              try {
                final String memberType =
                    (member['memberType'] ?? 'Adult').toString();
                final String relation =
                    (member['relation'] ?? member['Relation'] ?? '')
                        .toString();
                final String name =
                    (member['name'] ?? member['Name'] ?? '').toString();
                if (name.isEmpty) continue; // skip invalid rows

                final String memberId =
                    await IdGenerator.generateUniqueId(deviceInfo);

                final String maritalStatus =
                    (member['maritalStatus'] ?? '').toString();
                final dynamic spRaw = member['spousedetails'];
                final bool hasInlineSpouse =
                    maritalStatus == 'Married' && spRaw != null;

                String? memberSpouseKey;
                if (hasInlineSpouse) {
                  memberSpouseKey = await IdGenerator.generateUniqueId(deviceInfo);
                }

                final String beneficiaryState =
                    memberType.toLowerCase() == 'child'
                        ? 'registration_due'
                        : 'active';
                final int isAdult = memberType.toLowerCase() == 'child' ? 0 : 1;

                final String memberStatus =
                    (member['memberStatus'] ?? '').toString();
                final bool isDeathFlag =
                    memberStatus.toLowerCase() == 'death';

                final Map<String, dynamic> deathDetails = isDeathFlag
                    ? {
                        'dateOfDeath': member['dateOfDeath'],
                        'deathReason': member['deathReason'],
                        'otherDeathReason': member['otherDeathReason'],
                        'deathPlace': member['deathPlace'],
                      }
                    : <String, dynamic>{};

                final memberInfo = <String, dynamic>{
                  'memberType': memberType,
                  'relation': relation,
                  'otherRelation': member['otherRelation'],
                  'memberStatus': member['memberStatus'] ?? 'active',
                  'name': name,
                  'fatherName': member['fatherName'],
                  'motherName': member['motherName'],
                  'updateYear': member['updateYear'],
                  'updateMonth': member['updateMonth'],
                  'updateDay': member['updateDay'],
                  'useDob': member['useDob'] ?? true,
                  'dob': member['dob'],
                  'approxAge': member['approxAge'],
                  'birthOrder': member['birthOrder'],
                  'gender': member['gender'],
                  'bankAcc': member['bankAcc'],
                  'ifsc': member['ifsc'],
                  'occupation': member['occupation'],
                  'other_occupation': member['otherOccupation'],
                  'education': member['education'],
                  'religion': member['religion'],
                  'other_religion': member['otherReligion'],
                  'category': member['category'],
                  'other_category': member['otherCategory'],
                  'abhaAddress': member['abhaAddress'],
                  'mobileOwner': member['mobileOwner'],
                  'mobile_owner_relation': member['mobileOwnerRelation'],
                  'mobileNo': member['mobileNo'],
                  'voterId': member['voterId'],
                  'rationId': member['rationId'],
                  'phId': member['phId'],
                  'beneficiaryType': member['beneficiaryType'],
                  'maritalStatus': member['maritalStatus'],
                  'ageAtMarriage': member['ageAtMarriage'],
                  'spouseName': member['spouseName'],
                  'hasChildren': member['hasChildren'],
                  'isPregnant': member['isPregnant'],
                  'isFamilyPlanning': member['isFamilyPlanning'],
                  'familyPlanningMethod': member['familyPlanningMethod'],
                  'fpMethod': member['fpMethod'],
                  'antraDate': member['antraDate'],
                  'removalDate': member['removalDate'],
                  'removalReason': member['removalReason'],
                  'condomQuantity': member['condomQuantity'],
                  'malaQuantity': member['malaQuantity'],
                  'chhayaQuantity': member['chhayaQuantity'],
                  'ecpQuantity': member['ecpQuantity'],
                  'lmp': member['lmp'],
                  'edd': member['edd'],
                  'dateOfDeath': member['dateOfDeath'],
                  'deathPlace': member['deathPlace'],
                  'deathReason': member['deathReason'],
                  'otherDeathReason': member['otherDeathReason'],
                  'weight': member['weight'],
                  'birthWeight': member['birthWeight'],
                  'ChildSchool': member['ChildSchool'],
                  'birthCertificate': member['birthCertificate'],
                  'RichIDChanged': member['RichIDChanged'],
                  'children': member['children'],
                  'relation_to_head': relation,
                  'isFamilyhead': false,
                  'isFamilyheadWife': false,
                }
                  ..removeWhere((k, v) =>
                      v == null || (v is String && v.trim().isEmpty));

                final memberPayload = {
                  'server_id': null,
                  'household_ref_key': uniqueKey,
                  'unique_key': memberId,
                  'beneficiary_state': beneficiaryState,
                  'pregnancy_count': 0,
                  'beneficiary_info': jsonEncode(memberInfo),
                  'geo_location': geoLocationJson,
                  // Link to inline spouse row when available.
                  'spouse_key': memberSpouseKey,
                  'mother_key': null,
                  'father_key': null,
                  'is_family_planning': 0,
                  'is_adult': isAdult,
                  'is_guest': 0,
                  'is_death': isDeathFlag ? 1 : 0,
                  'death_details': jsonEncode(deathDetails),
                  'is_migrated': 0,
                  'is_separated': 0,
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
                  'created_date_time': ts,
                  'modified_date_time': ts,
                  'is_synced': 0,
                  'is_deleted': 0,
                };

                print('🧑‍👩‍👧 Inserting additional member from memberForms: '
                    '${jsonEncode(memberPayload)}');
                await LocalStorageDao.instance
                    .insertBeneficiary(memberPayload);
                    
                // If this is a female member who is pregnant, insert into mother_care_activities
                final isFemale = (member['gender']?.toString().toLowerCase() == 'female');
                final isPregnant = (member['isPregnant']?.toString().toLowerCase() == 'yes' || 
                                  member['isPregnant']?.toString().toLowerCase() == 'true');
                                  
                if (isFemale && isPregnant) {
                  try {
                    final motherCareActivityData = {
                      'server_id': null,
                      'household_ref_key': uniqueKey,
                      'beneficiary_ref_key': memberId,
                      'mother_care_state': 'anc_due',
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
                      'created_date_time': ts,
                      'modified_date_time': ts,
                      'is_synced': 0,
                      'is_deleted': 0,
                    };
                    
                    print('Inserting mother care activity for pregnant woman: ${jsonEncode(motherCareActivityData)}');
                    await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
                  } catch (e) {
                    print('Error inserting mother care activity: $e');
                  }
                }
                
                // If this is a female member who is pregnant, insert into mother_care_activities
                // final isFemale = (member['gender']?.toString().toLowerCase() == 'female');
                // final isPregnant = (member['isPregnant']?.toString().toLowerCase() == 'yes' ||
                //                   member['isPregnant']?.toString().toLowerCase() == 'true');
                //
                if (isFemale && isPregnant) {
                  try {
                    final motherCareActivityData = {
                      'server_id': null,
                      'household_ref_key': uniqueKey,
                      'beneficiary_ref_key': memberId,
                      'mother_care_state': 'anc_due',
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
                      'created_date_time': ts,
                      'modified_date_time': ts,
                      'is_synced': 0,
                      'is_deleted': 0,
                    };
                    
                    print('Inserting mother care activity for pregnant woman: ${jsonEncode(motherCareActivityData)}');
                    await LocalStorageDao.instance.insertMotherCareActivity(motherCareActivityData);
                  } catch (e) {
                    print('Error inserting mother care activity: $e');
                  }
                }
                
                // If this is a child with registration_due status, insert into child_care_activities
                if (memberType.toLowerCase() == 'child' && beneficiaryState == 'registration_due') {
                  try {
                    final childCareActivityData = {
                      'server_id': null,
                      'household_ref_key': uniqueKey,
                      'beneficiary_ref_key': memberId,
                      'mother_key': null, // These would need to be set if available
                      'father_key': null, // These would need to be set if available
                      'child_care_state': 'registration_due',
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
                      'created_date_time': ts,
                      'modified_date_time': ts,
                      'is_synced': 0,
                      'is_deleted': 0,
                    };
                    
                    print('Inserting child care activity: ${jsonEncode(childCareActivityData)}');
                    await LocalStorageDao.instance.insertChildCareActivity(childCareActivityData);
                  } catch (e) {
                    print('Error inserting child care activity: $e');
                  }
                }

                // ----------------------------------------
                // INSERT INLINE SPOUSE FOR THIS MEMBER
                // ----------------------------------------
                if (hasInlineSpouse && memberSpouseKey != null) {
                  try {
                    Map<String, dynamic>? spMap;
                    if (spRaw is Map) {
                      spMap = Map<String, dynamic>.from(spRaw as Map);
                    } else if (spRaw is String && spRaw.isNotEmpty) {
                      spMap = Map<String, dynamic>.from(jsonDecode(spRaw));
                    }

                    if (spMap != null) {
                      final String spouseName =
                          (spMap['memberName'] ?? spMap['spouseName'] ?? '')
                              .toString();
                      if (spouseName.isNotEmpty) {
                        final String spouseGender =
                            (spMap['gender'] ?? '').toString().isNotEmpty
                                ? spMap['gender'].toString()
                                : ((member['gender'] == 'Male')
                                    ? 'Female'
                                    : (member['gender'] == 'Female')
                                        ? 'Male'
                                        : '');

                        final spouseInfo = <String, dynamic>{
                          'relation': spMap['relation'] ?? 'spouse',
                          'memberName': spouseName,
                          'ageAtMarriage': spMap['ageAtMarriage'] ??
                              member['ageAtMarriage'],
                          'RichIDChanged': spMap['RichIDChanged'],
                          'spouseName': spMap['spouseName'] ?? name,
                          'fatherName': spMap['fatherName'],
                          'useDob': spMap['useDob'],
                          'dob': spMap['dob'],
                          'edd': spMap['edd'],
                          'lmp': spMap['lmp'],
                          'approxAge': spMap['approxAge'],
                          'gender': spouseGender,
                          'occupation': spMap['occupation'],
                          'education': spMap['education'],
                          'religion': spMap['religion'],
                          'category': spMap['category'],
                          'antraDate': spMap['antraDate'],
                          'mobile_owner_relation': spMap['mobileOwnerOtherRelation'],
                          'other_category': spMap['otherCategory'],
                          'other_religion': spMap['otherReligion'],
                          'other_occupation': spMap['otherOccupation'],
                          'abhaAddress': spMap['abhaAddress'],
                          'mobileOwner': spMap['mobileOwner'],
                          'mobileNo': spMap['mobileNo'],
                          'bankAcc': spMap['bankAcc'],
                          'ifsc': spMap['ifsc'],
                          'voterId': spMap['voterId'],
                          'rationId': spMap['rationId'],
                          'phId': spMap['phId'],
                          'beneficiaryType': spMap['beneficiaryType'],
                          'isPregnant': spMap['isPregnant'],
                          'familyPlanningCounseling':
                              spMap['familyPlanningCounseling'],
                          'is_family_planning':
                              (spMap['familyPlanningCounseling']
                                              ?.toString()
                                              .toLowerCase() ==
                                          'yes')
                                  ? 1
                                  : 0,
                          'fpMethod': spMap['fpMethod'],
                          'removalDate': spMap['removalDate'],
                          'removalReason': spMap['removalReason'],
                          'condomQuantity': spMap['condomQuantity'],
                          'malaQuantity': spMap['malaQuantity'],
                          'chhayaQuantity': spMap['chhayaQuantity'],
                          'ecpQuantity': spMap['ecpQuantity'],
                          'maritalStatus': 'Married',
                          'relation_to_head': 'spouse',
                          'isFamilyhead': false,
                          'isFamilyheadWife': false,
                        }
                          ..removeWhere((k, v) =>
                              v == null || (v is String && v.trim().isEmpty));

                        final spousePayload = {
                          'server_id': null,
                          'household_ref_key': uniqueKey,
                          'unique_key': memberSpouseKey,
                          'beneficiary_state': 'active',
                          'pregnancy_count': 0,
                          'beneficiary_info': jsonEncode(spouseInfo),
                          'geo_location': geoLocationJson,
                          'spouse_key': memberId,
                          'mother_key': null,
                          'father_key': null,
                          'is_family_planning':
                              spouseInfo['is_family_planning'] ?? 0,
                          'is_adult': 1,
                          'is_guest': 0,
                          'is_death': 0,
                          'death_details': jsonEncode({}),
                          'is_migrated': 0,
                          'is_separated': 0,
                          'device_details': jsonEncode({
                            'id': deviceInfo.deviceId,
                            'platform': deviceInfo.platform,
                            'version': deviceInfo.osVersion,
                          }),
                          'app_details': jsonEncode({
                            'app_version':
                                deviceInfo.appVersion.split('+').first,
                            'app_name': deviceInfo.appName,
                            'build_number': deviceInfo.buildNumber,
                            'package_name': deviceInfo.packageName,
                          }),
                          'parent_user': jsonEncode({}),
                          'current_user_key': ashaUniqueKey,
                          'facility_id': facilityId,
                          'created_date_time': ts,
                          'modified_date_time': ts,
                          'is_synced': 0,
                          'is_deleted': 0,
                        };

                        print(
                            '🧑‍🤝‍🧑 Inserting inline spouse beneficiary for member: '
                            '${jsonEncode(spousePayload)}');
                        await LocalStorageDao.instance
                            .insertBeneficiary(spousePayload);
                      }
                    }
                  } catch (e) {
                    print('Error inserting inline member spouse: $e');
                  }
                }

              } catch (e) {
                print('Error inserting additional member: $e');
              }
            }
          } catch (e) {
            print('Error preparing additional members: $e');
          }
        }

        String familyHeadUniqueKey = headId;
        String familyHeadName = '';
        try {
          final related = beneficiaries
              .where((b) =>
          (b['household_ref_key'] ?? '').toString() == uniqueKey)
              .toList();

          Map<String, dynamic>? picked;

          // Prefer explicit head/self markers
          for (final b in related) {
            final infoRaw = b['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                : (infoRaw as Map<String, dynamic>? ?? {});
            final rel = (info['relation'] ?? info['relation_to_head'] ??
                info['Relation'] ?? '')
                .toString()
                .toLowerCase();
            if (rel == 'self' || rel == 'head' || rel == 'family head') {
              picked = b as Map<String, dynamic>;
              break;
            }
          }

          // If no explicit head, and we have Wife/Husband, pick the opposite spouse as head
          if (picked == null) {
            final byKey = {
              for (final b in related)
                (b['unique_key'] ?? '').toString(): b,
            };

            for (final b in related) {
              final infoRaw = b['beneficiary_info'];
              final Map<String, dynamic> info = infoRaw is String
                  ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                  : (infoRaw as Map<String, dynamic>? ?? {});
              final rel = (info['relation'] ?? info['relation_to_head'] ??
                  info['Relation'] ?? '')
                  .toString()
                  .toLowerCase();

              if (rel == 'wife' || rel == 'husband') {
                final spouseKey = (b['spouse_key'] ?? '').toString();
                if (spouseKey.isNotEmpty && byKey.containsKey(spouseKey)) {
                  picked = Map<String, dynamic>.from(byKey[spouseKey] as Map);
                  break;
                }
              }
            }
          }

          if (picked == null && related.isNotEmpty) {
            picked = related.first as Map<String, dynamic>;
          }
          if (picked != null) {
            familyHeadUniqueKey =
                (picked['unique_key'] ?? familyHeadUniqueKey).toString();
            final infoRaw = picked['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                : (infoRaw as Map<String, dynamic>? ?? {});
            familyHeadName =
                (info['headName'] ?? info['name'] ?? info['memberName'] ?? '')
                    .toString();
          }
        } catch (e) {
          print('Error deriving family head from beneficiaries: $e');
        }

        final locationData = Map<String, String>.from(geoLocation.toJson());
        locationData['source'] = 'gps';
        if (!geoLocation.hasCoordinates) {
          locationData['status'] = 'unavailable';
          locationData['reason'] = 'Could not determine location';
        }
        final geoLocationJson = jsonEncode(locationData);
        print(' Final location data: $geoLocationJson');


        final currentUser = await UserInfo.getCurrentUser();
        final userDetails = currentUser?['details'] is String
            ? jsonDecode(currentUser?['details'] ?? '{}')
            : currentUser?['details'] ?? {};


        final working = userDetails['working_location'] ?? {};

        final address = {
          'state_name': working['state'] ?? userDetails['stateName'] ?? '',
          'state_id': _asInt(working['state_id']) ?? userDetails['stateId'] ??
              1,
          'state_lgd_code': userDetails['stateLgdCode'] ?? 1,
          'division_name': working['division'] ?? userDetails['division'] ??
              'Patna',
          'division_id': _asInt(working['division_id']) ??
              userDetails['divisionId'] ?? 27,
          'division_lgd_code': userDetails['divisionLgdCode'] ?? 198,
          'district_name': working['district'] ?? userDetails['districtName'],
          'district_id': _asInt(working['district_id']) ??
              userDetails['districtId'],
          'block_name': working['block'] ?? userDetails['blockName'],
          'block_id': _asInt(working['block_id']) ?? userDetails['blockId'],
          'village_name': working['village'] ?? userDetails['villageName'],
          'village_id': _asInt(working['village_id']) ??
              userDetails['villageId'],
          'hsc_id': _asInt(working['hsc_id']) ?? userDetails['facility_hsc_id'],
          'hsc_name': working['hsc_name'] ?? userDetails['facility_hsc_name'],
          'hsc_hfr_id': working['hsc_hfr_id'] ?? userDetails['facility_hfr_id'],
          'asha_id': working['asha_id'] ?? userDetails['asha_id'],
          'pincode': working['pincode'] ?? userDetails['pincode'],
          'user_identifier': working['user_identifier'] ??
              userDetails['user_identifier'],
        }
          ..removeWhere((k, v) =>
          v == null || (v is String && v
              .trim()
              .isEmpty));


        final facilityId = working['asha_associated_with_facility_id'] ??
            userDetails['asha_associated_with_facility_id'] ?? 0;


        final ashaUniqueKey = userDetails['unique_key'] ?? {};


        final householdPayload = {
          'server_id': null,
          'unique_key': uniqueKey,
          'address': jsonEncode(address),
          'geo_location': geoLocationJson,
          
          'head_id': familyHeadUniqueKey,
          'household_info': householdInfoJson,
          'device_details': jsonEncode({
            'id': deviceInfo.deviceId,
            'platform': deviceInfo.platform,
            'version': deviceInfo.osVersion,
            'model': deviceInfo.model,
          }),
          'app_details': jsonEncode({
            'app_version': deviceInfo.appVersion
                .split('+')
                .first,
            'app_name': deviceInfo.appName,
            'build_number': deviceInfo.buildNumber,
            'package_name': deviceInfo.packageName,
            "instance": "prod"
          }),
          'parent_user': jsonEncode({}),
          'current_user_key': ashaUniqueKey,
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        print('Saving household with payload: ${jsonEncode(householdPayload)}');

        final existingHousehold =
        await LocalStorageDao.instance.getHouseholdByUniqueKey(uniqueKey);
        final bool isUpdate =
            existingHousehold != null && existingHousehold.isNotEmpty;

        if (isUpdate) {
          print('Updating existing household for unique_key=$uniqueKey');
          await LocalStorageDao.instance
              .updateHouseholdByUniqueKey(householdPayload);
        } else {
          print('Inserting new household for unique_key=$uniqueKey');
          await LocalStorageDao.instance.insertHousehold(householdPayload);
        }

        Map<String, dynamic>? matchedHousehold;
        try {
          final households = await LocalStorageDao.instance.getAllHouseholds();
          for (final h in households) {
            if ((h['unique_key'] ?? '').toString() == uniqueKey) {
              matchedHousehold = Map<String, dynamic>.from(h);
              break;
            }
          }
          matchedHousehold ??= households.isNotEmpty
              ? Map<String, dynamic>.from(households.first)
              : null;
        } catch (e) {
          print('Error fetching household for API address: $e');
        }

        final apiUniqueKey = (matchedHousehold?['unique_key'] ?? uniqueKey)
            .toString();

        try {
          final related = beneficiaries
              .where((b) =>
          (b['household_ref_key'] ?? '').toString() == apiUniqueKey)
              .toList();

          Map<String, dynamic>? picked;

          // Prefer explicit head/self markers
          for (final b in related) {
            final infoRaw = b['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                : (infoRaw as Map<String, dynamic>? ?? {});
            final rel = (info['relation'] ?? info['relation_to_head'] ??
                info['Relation'] ?? '')
                .toString()
                .toLowerCase();
            if (rel == 'self' || rel == 'head' || rel == 'family head') {
              picked = b as Map<String, dynamic>;
              break;
            }
          }

          if (picked == null) {
            final byKey = {
              for (final b in related)
                (b['unique_key'] ?? '').toString(): b,
            };

            for (final b in related) {
              final infoRaw = b['beneficiary_info'];
              final Map<String, dynamic> info = infoRaw is String
                  ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                  : (infoRaw as Map<String, dynamic>? ?? {});
              final rel = (info['relation'] ?? info['relation_to_head'] ??
                  info['Relation'] ?? '')
                  .toString()
                  .toLowerCase();

              if (rel == 'wife' || rel == 'husband') {
                final spouseKey = (b['spouse_key'] ?? '').toString();
                if (spouseKey.isNotEmpty && byKey.containsKey(spouseKey)) {
                  picked = Map<String, dynamic>.from(byKey[spouseKey] as Map);
                  break;
                }
              }
            }
          }

          picked ??=
          related.isNotEmpty ? related.first as Map<String, dynamic> : null;
          if (picked != null) {
            familyHeadUniqueKey =
                (picked['unique_key'] ?? familyHeadUniqueKey).toString();
            final infoRaw = picked['beneficiary_info'];
            final Map<String, dynamic> info = infoRaw is String
                ? (jsonDecode(infoRaw) as Map<String, dynamic>)
                : (infoRaw as Map<String, dynamic>? ?? {});
            familyHeadName =
                (info['headName'] ?? info['name'] ?? info['memberName'] ?? '')
                    .toString();
          }
        } catch (e) {
          print('Error re-deriving family head with apiUniqueKey: $e');
        }

        Map<String, dynamic> apiAddress = {};
        try {
          final addrRaw = matchedHousehold?['address'];
          if (addrRaw is String) {
            apiAddress = Map<String, dynamic>.from(jsonDecode(addrRaw));
          } else if (addrRaw is Map) {
            apiAddress = Map<String, dynamic>.from(addrRaw as Map);
          } else {
            apiAddress = Map<String, dynamic>.from(address);
          }
          apiAddress.removeWhere((k, v) =>
          v == null || (v is String && v
              .trim()
              .isEmpty));
        } catch (e) {
          print('Error parsing API address from household: $e');
          apiAddress = Map<String, dynamic>.from(address);
        }

        Map<String, dynamic> apiGeo = {
          'lat': geoLocation.latitude,
          'long': geoLocation.longitude,
          'accuracy_m': geoLocation.accuracy,
          'captured_datetime': DateTime.now().toUtc().toIso8601String(),
        };
        try {
          final g = matchedHousehold?['geo_location'];
          if (g is String && g
              .trim()
              .isNotEmpty) {
            apiGeo = Map<String, dynamic>.from(jsonDecode(g));
          } else if (g is Map) {
            apiGeo = Map<String, dynamic>.from(g as Map);
          }
        } catch (e) {
          print('Error parsing geo_location from household: $e');
        }

        Map<String, dynamic> apiDevice = {
          'device_id': deviceInfo.deviceId,
          'platform': deviceInfo.platform,
          'platform_version': deviceInfo.osVersion,
        }
          ..removeWhere((k, v) =>
          v == null || (v is String && v is String && v.isEmpty));
        try {
          final d = matchedHousehold?['device_details'];
          if (d is String && d
              .trim()
              .isNotEmpty) {
            apiDevice = Map<String, dynamic>.from(jsonDecode(d));
          } else if (d is Map) {
            apiDevice = Map<String, dynamic>.from(d as Map);
          }
        } catch (e) {
          print('Error parsing device_details from household: $e');
        }

        Map<String, dynamic> storedInfo = {};
        try {
          final infoRaw = matchedHousehold?['household_info'];
          if (infoRaw is String) {
            storedInfo = Map<String, dynamic>.from(jsonDecode(infoRaw));
          } else if (infoRaw is Map) {
            storedInfo = Map<String, dynamic>.from(infoRaw as Map);
          }
        } catch (e) {
          print('Error parsing stored household_info: $e');
        }

        final apiHouseholdInfo = {
          'household_details': {
            'type_of_residential_area': storedInfo['residentialArea'] ??
                event.amenitiesData['residentialArea'],
            'type_of_house': storedInfo['houseType'] ??
                event.amenitiesData['houseType'],
            'house_ownership': storedInfo['ownershipType'] ??
                event.amenitiesData['ownershipType'],
          },
          'household_amenities': {
            'is_kitchen_outside': storedInfo['houseKitchen'] ??
                event.amenitiesData['houseKitchen'],
            'type_of_fuel_used_for_cooking': storedInfo['cookingFuel'] ??
                event.amenitiesData['cookingFuel'],
            'primary_source_of_water': storedInfo['waterSource'] ??
                event.amenitiesData['waterSource'],
            'availability_of_electricity': storedInfo['electricity'] ??
                event.amenitiesData['electricity'],
            'availability_of_toilet': storedInfo['toilet'] ??
                event.amenitiesData['toilet'],
            'type_of_toilet': storedInfo['toiletType'] ??
                event.amenitiesData['toiletType'],
            'where_do_you_go_for_toilet': storedInfo['toiletPlace'] ??
                event.amenitiesData['toiletPlace'],
          }
        };

        Map<String, dynamic> apiApp = {
          'version': deviceInfo.appVersion
              .split('+')
              .first,
          'instance': 'uat',
        };
        try {
          final a = matchedHousehold?['app_details'];
          if (a is String && a
              .trim()
              .isNotEmpty) {
            apiApp = Map<String, dynamic>.from(jsonDecode(a));
          } else if (a is Map) {
            apiApp = Map<String, dynamic>.from(a as Map);
          }
        } catch (e) {
          print('Error parsing app_details from household: $e');
        }

        final apiPayload = {
          'unique_key': apiUniqueKey,
          'address': apiAddress,
          'family_head_details': {
            'unique_key': familyHeadUniqueKey,
            'name': familyHeadName,
          },
          'household_info': apiHouseholdInfo,
          'geo_location': apiGeo,
          'device_details': apiDevice,
          'app_details': apiApp,
          'parent_user': {
            // 'user_key': userDetails['supervisor_user_key'] ?? '',
            // 'name': userDetails['supervisor_name'] ?? '',
            // 'facility_id': userDetails['supervisor_facility_id'] ?? facilityId,
          },
          'current_user_key': _asInt(matchedHousehold?['current_user_key']),
          'facility_id': _asInt(matchedHousehold?['facility_id']),
          'division_id': _asInt(apiAddress['division_id']),
          'division_name': apiAddress['division_name'],
          'district_id': _asInt(apiAddress['district_id']),
          'district_name': apiAddress['district_name'],
          'block_id': _asInt(apiAddress['block_id']),
          'block_name': apiAddress['block_name'],
          'hsc_id': _asInt(apiAddress['hsc_id']),
          'hsc_name': apiAddress['hsc_name'],
          'village_id': _asInt(apiAddress['village_id']),
          'village_name': apiAddress['village_name'],
          'facilitator_id': matchedHousehold?['facilitator_id'],
          'facilitator_name': matchedHousehold?['facilitator_name'],
          'facilitator_username': matchedHousehold?['facilitator_username'],
          'ashwin_id': matchedHousehold?['ashwin_id'] ?? apiAddress['asha_id'],
          'area_of_working': storedInfo['residentialArea'],
          'asha_mobile_no': matchedHousehold?['asha_mobile_no'],
          'asha_name': matchedHousehold?['asha_name'],
          'is_processed': 0,
          'is_data_processed': 0,
          'is_summary_processed': 0,
          'is_deleted': 0,
        };

        Map<String, dynamic> _clean(Map<String, dynamic> m) =>
            m
              ..removeWhere((k, v) =>
              v == null || (v is String && v
                  .trim()
                  .isEmpty));

        final cleanedPayload = _clean(apiPayload);


        print(
            ' Household and all members saved locally, proceeding to background sync.');
        emit(state.saved());
      } catch (e, stackTrace) {
        print('❌ Error saving household data: $e');
        print('Stack trace: $stackTrace');
        emit(
          state.saveFailed('Failed to save household data: ${e.toString()}'),
        );
      }
    });
  }

  dynamic _convertYesNoDynamic(dynamic value) {
    if (value is String) {
      if (value == 'Yes') return 1;
      if (value == 'No') return 0;
      return value;
    } else if (value is Map) {
      return _convertYesNoMap(Map<String, dynamic>.from(value as Map));
    } else if (value is List) {
      return value.map(_convertYesNoDynamic).toList();
    }
    return value;
  }

  Map<String, dynamic> _convertYesNoMap(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((k, v) {
      out[k] = _convertYesNoDynamic(v);
    });
    return out;
  }


  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> _buildBeneficiaryApiPayload(Map<String, dynamic> row,
      Map<String, dynamic> userDetails,
      Map<String, dynamic> working,
      dynamic deviceInfo,
      String ts,
      dynamic ashaUniqueKey,
      dynamic facilityId,) {
    final rawInfo = row['beneficiary_info'];
    final info = (rawInfo is Map)
        ? Map<String, dynamic>.from(rawInfo)
        : (rawInfo is String && rawInfo.isNotEmpty)
        ? Map<String, dynamic>.from(jsonDecode(rawInfo))
        : <String, dynamic>{};

    String? _genderCode(String? g) {
      if (g == null) return null;
      final s = g.toLowerCase();
      if (s.startsWith('m')) return 'M';
      if (s.startsWith('f')) return 'F';
      if (s.startsWith('o')) return 'O';
      return null;
    }

    String? _yyyyMMdd(String? iso) {
      if (iso == null || iso.isEmpty) return null;
      try {
        final d = DateTime.tryParse(iso);
        if (d == null) return null;
        return DateFormat('yyyy-MM-dd').format(d);
      } catch (_) {
        return null;
      }
    }

    Map<String, dynamic> _apiGeo(dynamic g) {
      try {
        if (g is String && g.isNotEmpty) g = jsonDecode(g);
        if (g is Map) {
          final m = Map<String, dynamic>.from(g);
          final lat = m['lat'] ?? m['latitude'] ?? m['Lat'] ?? m['Latitude'];
          final lng = m['lng'] ?? m['long'] ?? m['longitude'] ?? m['Lng'];
          final acc = m['accuracy_m'] ?? m['accuracy'] ?? m['Accuracy'];
          final tsCap = m['captured_at'] ?? m['captured_datetime'] ??
              m['timestamp'];
          return {
            'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}'),
            'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}'),
            'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}'),
            'captured_at': tsCap?.toString() ??
                DateTime.now().toUtc().toIso8601String(),
          }
            ..removeWhere((k, v) =>
            v == null || (v is String && v
                .trim()
                .isEmpty));
        }
      } catch (_) {}
      return {
        'lat': null,
        'lng': null,
        'accuracy_m': null,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      }
        ..removeWhere((k, v) =>
        v == null || (v is String && v
            .trim()
            .isEmpty));
    }

    final beneficiaryInfoApi = {
      'house_no':(info['houseNo']),
      'name': {
        'first_name': (info['headName'] ?? info['memberName'] ?? info['name'] ??
            '').toString(),
        'middle_name': '',
        'last_name': '',
      },
      'gender': _genderCode(info['gender']?.toString()),
      'dob': _yyyyMMdd(info['dob']?.toString()),
      'marital_status': (info['maritalStatus'] ?? 'married')
          .toString()
          .toLowerCase(),
      'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
      'phone': (info['mobileNo'] ?? '').toString(),
      'address': {
        'state': working['state'] ?? userDetails['stateName'],
        'district': working['district'] ?? userDetails['districtName'],
        'block': working['block'] ?? userDetails['blockName'],
        'village': info['village'] ?? working['village'] ??
            userDetails['villageName'],
        'pincode': working['pincode'] ?? userDetails['pincode'],
      }
        ..removeWhere((k, v) =>
        v == null || (v is String && v
            .trim()
            .isEmpty)),

      'is_abha_verified': info['is_abha_verified'] ?? false,
      'is_rch_id_verified': info['is_rch_id_verified'] ?? false,
      'is_fetched_from_abha': info['is_fetched_from_abha'] ?? false,
      'is_fetched_from_rch': info['is_fetched_from_rch'] ?? false,
      'ben_type': info['ben_type'] ?? (info['memberType'] ?? 'adult'),
      'mother_ben_ref_key': info['mother_ben_ref_key'] ??
          row['mother_key']?.toString() ?? '',
      'father_ben_ref_key': info['father_ben_ref_key'] ??
          row['father_key']?.toString() ?? '',
      'relaton_with_family_head':
      info['relaton_with_family_head'] ?? info['relation_to_head'] ?? 'self',
      'member_status': info['member_status'] ?? 'alive',
      'member_name': info['member_name'] ?? info['headName'] ??
          info['memberName'] ?? info['name'],
      'father_or_spouse_name':
      info['father_or_spouse_name'] ?? info['fatherName'] ??
          info['spouseName'] ?? '',
      'have_children': info['have_children'] ?? info['hasChildren'],
      'is_family_planning': info['is_family_planning'] ??
          row['is_family_planning'] ?? 0,
      'total_children': info['total_children'] ?? info['totalBorn'],
      'total_live_children': info['total_live_children'] ?? info['totalLive'],
      'total_male_children': info['total_male_children'] ?? info['totalMale'],
      'age_of_youngest_child': info['age_of_youngest_child'] ??
          info['youngestAge'],
      'gender_of_younget_child': info['gender_of_younget_child'] ??
          info['youngestGender'],
      'whose_mob_no': info['whose_mob_no'] ?? info['mobileOwner'],
      'mobile_no': info['mobile_no'] ?? info['mobileNo'],
      'dob_day': info['dob_day'],
      'dob_month': info['dob_month'],
      'dob_year': info['dob_year'],
      'age_by': info['age_by'],
      'date_of_birth': info['date_of_birth'] ?? info['dob'],
      'age': info['age'] ?? info['approxAge'],
      'village_name': info['village_name'] ?? info['village'],
      'is_new_member': info['is_new_member'] ?? true,
      'isFamilyhead': info['isFamilyhead'] ?? true,
      'isFamilyheadWife': info['isFamilyheadWife'] ?? false,
      'age_of_youngest_child_unit': info['age_of_youngest_child_unit'] ??
          info['ageUnit'],
      'type_of_beneficiary': info['type_of_beneficiary'] ??
          info['beneficiaryType'] ?? 'staying_in_house',
      'name_of_spouse': info['name_of_spouse'] ?? info['spouseName'] ?? '',
    }
      ..removeWhere((k, v) =>
      v == null || (v is String && v
          .trim()
          .isEmpty));

    return {
      'unique_key': row['unique_key'],
      'id': row['id'],
      'household_ref_key': row['household_ref_key'],
      'beneficiary_state': [
        {
          'state': 'registered',
          'at': DateTime.now().toUtc().toIso8601String(),
        },
        {
          'state': (row['beneficiary_state'] ?? 'active').toString(),
          'at': DateTime.now().toUtc().toIso8601String(),
        },
      ],
      'pregnancy_count': row['pregnancy_count'] ?? 0,
      'beneficiary_info': beneficiaryInfoApi,
      'geo_location': _apiGeo(row['geo_location']),
      'spouse_key': row['spouse_key'],
      'mother_key': row['mother_key'],
      'father_key': row['father_key'],
      'is_family_planning': row['is_family_planning'] ?? 0,
      'is_adult': row['is_adult'] ?? 1,
      'is_guest': row['is_guest'] ?? 0,
      'is_death': row['is_death'] ?? 0,
      'death_details': row['death_details'] is Map ? row['death_details'] : {},
      'is_migrated': row['is_migrated'] ?? 0,
      'is_separated': row['is_separated'] ?? 0,
      'device_details': {
        'device_id': deviceInfo.deviceId,
        'model': deviceInfo.model,
        'os': deviceInfo.platform + ' ' + (deviceInfo.osVersion ?? ''),
        'app_version': deviceInfo.appVersion
            .split('+')
            .first,
      },
      'app_details': {
        'captured_by_user': userDetails['user_identifier'] ?? '',
        'captured_role_id': userDetails['role_id'] ?? userDetails['role'] ?? 0,
        'source': 'mobile',
      },
      'parent_user': {
        'user_key': userDetails['supervisor_user_key'] ?? '',
        'name': userDetails['supervisor_name'] ?? '',
      }
        ..removeWhere((k, v) =>
        v == null || (v is String && v
            .trim()
            .isEmpty)),
      'current_user_key': row['current_user_key'] ?? ashaUniqueKey,
      'facility_id': row['facility_id'] ?? facilityId,
      'created_date_time': row['created_date_time'] ?? ts,
      'modified_date_time': row['modified_date_time'] ?? ts,
    };
  }

}
