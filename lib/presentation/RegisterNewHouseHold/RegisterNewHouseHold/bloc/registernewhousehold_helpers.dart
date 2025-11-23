part of 'registernewhousehold_bloc.dart';

class _HeadSpouseKeys {
  final String householdRefKey;
  final String headId;
  final String? spouseKey;

  _HeadSpouseKeys({
    required this.householdRefKey,
    required this.headId,
    this.spouseKey,
  });
}

extension _RegisterNewHouseholdHelpers on RegisterNewHouseholdBloc {
  String _geoLocationJson(dynamic geoLocation) {
    final locationData = Map<String, String>.from(geoLocation.toJson());
    locationData['source'] = 'gps';
    if (!geoLocation.hasCoordinates) {
      locationData['status'] = 'unavailable';
      locationData['reason'] = 'Could not determine location';
    }
    return jsonEncode(locationData);
  }

  Map<String, dynamic> _deviceDetails(dynamic deviceInfo) => {
        'id': deviceInfo.deviceId,
        'platform': deviceInfo.platform,
        'version': deviceInfo.osVersion,
      };

  Map<String, dynamic> _appDetails(dynamic deviceInfo) => {
        'app_version': deviceInfo.appVersion.split('+').first,
        'app_name': deviceInfo.appName,
        'build_number': deviceInfo.buildNumber,
        'package_name': deviceInfo.packageName,
      };

  Future<_HeadSpouseKeys> _upsertHeadAndSpouseFromHeadForm({
    required Map<String, dynamic> headForm,
    required bool isEdit,
    required String? existingHeadUniqueKey,
    required String? existingSpouseUniqueKey,
    required dynamic deviceInfo,
    required String ts,
    required dynamic ashaUniqueKey,
    required dynamic facilityId,
    required String geoLocationJson,
  }) async {
    final childrenData = <String, dynamic>{
      'totalBorn': headForm['totalBorn'],
      'totalLive': headForm['totalLive'],
      'totalMale': headForm['totalMale'],
      'totalFemale': headForm['totalFemale'],
      'youngestAge': headForm['youngestAge'],
      'ageUnit': headForm['ageUnit'],
      'youngestGender': headForm['youngestGender'],
      'children': headForm['children'],
    }..removeWhere((k, v) => v == null);

    if (isEdit && existingHeadUniqueKey != null && existingHeadUniqueKey.isNotEmpty) {
      final existingHead = await LocalStorageDao.instance
          .getBeneficiaryByUniqueKey(existingHeadUniqueKey);
      if (existingHead == null) {
        return _upsertHeadAndSpouseFromHeadForm(
          headForm: headForm,
          isEdit: false,
          existingHeadUniqueKey: null,
          existingSpouseUniqueKey: null,
          deviceInfo: deviceInfo,
          ts: ts,
          ashaUniqueKey: ashaUniqueKey,
          facilityId: facilityId,
          geoLocationJson: geoLocationJson,
        );
      }

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
        ..addAll(childrenData);

      final updatedHead = Map<String, dynamic>.from(existingHead);
      updatedHead['beneficiary_info'] = headInfo;
      updatedHead['geo_location'] =
          existingHead['geo_location'] ?? geoLocationJson;

      await LocalStorageDao.instance.updateBeneficiary(updatedHead);

      String? spouseKey = existingSpouseUniqueKey;
      if (spouseKey != null && spouseKey.isNotEmpty) {
        try {
          final existingSpouse = await LocalStorageDao.instance
              .getBeneficiaryByUniqueKey(spouseKey);
          if (existingSpouse != null) {
            final spInfoRaw = existingSpouse['beneficiary_info'];
            final Map<String, dynamic> spInfo = spInfoRaw is Map
                ? Map<String, dynamic>.from(spInfoRaw)
                : (spInfoRaw is String && spInfoRaw.isNotEmpty)
                    ? Map<String, dynamic>.from(jsonDecode(spInfoRaw))
                    : <String, dynamic>{};

            spInfo
              ..['relation'] = headForm['sp_relation'] ?? 'spouse'
              ..['memberName'] = headForm['sp_memberName'] ?? headForm['spouseName']
              ..['ageAtMarriage'] = headForm['sp_ageAtMarriage']
              ..['RichIDChanged'] = headForm['sp_RichIDChanged']
              ..['spouseName'] = headForm['sp_spouseName']
              ..['fatherName'] = headForm['sp_fatherName']
              ..['useDob'] = headForm['sp_useDob']
              ..['dob'] = headForm['sp_dob']
              ..['edd'] = headForm['sp_edd']
              ..['lmp'] = headForm['sp_lmp']
              ..['approxAge'] = headForm['sp_approxAge']
              ..['gender'] = headForm['sp_gender'] ??
                  ((headForm['gender'] == 'Male') ? 'Female' : 'Male')
              ..['occupation'] = headForm['sp_occupation']
              ..['education'] = headForm['sp_education']
              ..['religion'] = headForm['sp_religion']
              ..['category'] = headForm['sp_category']
              ..['abhaAddress'] = headForm['sp_abhaAddress']
              ..['mobileOwner'] = headForm['sp_mobileOwner']
              ..['mobileNo'] = headForm['sp_mobileNo']
              ..['bankAcc'] = headForm['sp_bankAcc']
              ..['ifsc'] = headForm['sp_ifsc']
              ..['voterId'] = headForm['sp_voterId']
              ..['rationId'] = headForm['sp_rationId']
              ..['phId'] = headForm['sp_phId']
              ..['beneficiaryType'] = headForm['sp_beneficiaryType']
              ..['isPregnant'] = headForm['sp_isPregnant']
              ..['familyPlanningCounseling'] =
                  headForm['sp_familyPlanningCounseling']
              ..['fpMethod'] = headForm['sp_fpMethod']
              ..['removalDate'] = headForm['sp_removalDate']
              ..['removalReason'] = headForm['sp_removalReason']
              ..['condomQuantity'] = headForm['sp_condomQuantity']
              ..['malaQuantity'] = headForm['sp_malaQuantity']
              ..['chhayaQuantity'] = headForm['sp_chhayaQuantity']
              ..['ecpQuantity'] = headForm['sp_ecpQuantity']
              ..['maritalStatus'] = 'Married'
              ..['relation_to_head'] = 'spouse'
              ..addAll(childrenData);

            final updatedSpouse = Map<String, dynamic>.from(existingSpouse);
            updatedSpouse['beneficiary_info'] = spInfo;
            updatedSpouse['geo_location'] =
                existingSpouse['geo_location'] ?? geoLocationJson;

            await LocalStorageDao.instance.updateBeneficiary(updatedSpouse);
          }
        } catch (e) {
          print('Error updating spouse: $e');
        }
      }

      return _HeadSpouseKeys(
        householdRefKey:
            (existingHead['household_ref_key'] ?? '').toString(),
        headId: (existingHead['unique_key'] ?? '').toString(),
        spouseKey: spouseKey,
      );
    }

    final uniqueKey = await IdGenerator.generateUniqueId(deviceInfo);
    final headId = await IdGenerator.generateUniqueId(deviceInfo);
    String? spouseKey;

    final headInfo = {
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
      'religion': headForm['religion'],
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
      'isFamilyhead': false,
      'isFamilyheadWife': false,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      ...childrenData,
    };

    final headPayload = {
      'server_id': null,
      'household_ref_key': uniqueKey,
      'unique_key': headId,
      'beneficiary_state': 'active',
      'pregnancy_count': 0,
      'beneficiary_info': jsonEncode(headInfo),
      'geo_location': geoLocationJson,
      'spouse_key': (headForm['maritalStatus'] == 'Married')
          ? (spouseKey = await IdGenerator.generateUniqueId(deviceInfo))
          : null,
      'mother_key': null,
      'father_key': null,
      'is_family_planning': 0,
      'is_adult': 1,
      'is_guest': 0,
      'is_death': 0,
      'death_details': jsonEncode({}),
      'is_migrated':
          headForm['beneficiaryType'] == 'SeasonalMigrant' ? 1 : 0,
      'is_separated': (headForm['maritalStatus'] == 'Separated' ||
              headForm['maritalStatus'] == 'Divorced')
          ? 1
          : 0,
      'device_details': jsonEncode(_deviceDetails(deviceInfo)),
      'app_details': jsonEncode(_appDetails(deviceInfo)),
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

    await LocalStorageDao.instance.insertBeneficiary(headPayload);

    if (headForm['maritalStatus'] == 'Married' &&
        (headForm['spouseName'] ?? '').toString().isNotEmpty &&
        spouseKey != null) {
      try {
        final spouseInfo = {
          'relation': headForm['sp_relation'] ?? 'spouse',
          'memberName': headForm['sp_memberName'] ?? headForm['spouseName'],
          'ageAtMarriage': headForm['sp_ageAtMarriage'],
          'RichIDChanged': headForm['sp_RichIDChanged'],
          'spouseName': headForm['sp_spouseName'],
          'fatherName': headForm['sp_fatherName'],
          'useDob': headForm['sp_useDob'],
          'dob': headForm['sp_dob'],
          'edd': headForm['sp_edd'],
          'lmp': headForm['sp_lmp'],
          'approxAge': headForm['sp_approxAge'],
          'gender': headForm['sp_gender'] ??
              ((headForm['gender'] == 'Male') ? 'Female' : 'Male'),
          'occupation': headForm['sp_occupation'],
          'education': headForm['sp_education'],
          'religion': headForm['sp_religion'],
          'category': headForm['sp_category'],
          'abhaAddress': headForm['sp_abhaAddress'],
          'mobileOwner': headForm['sp_mobileOwner'],
          'mobileNo': headForm['sp_mobileNo'],
          'bankAcc': headForm['sp_bankAcc'],
          'ifsc': headForm['sp_ifsc'],
          'voterId': headForm['sp_voterId'],
          'rationId': headForm['sp_rationId'],
          'phId': headForm['sp_phId'],
          'beneficiaryType': headForm['sp_beneficiaryType'],
          'isPregnant': headForm['sp_isPregnant'],
          'familyPlanningCounseling':
              headForm['sp_familyPlanningCounseling'],
          'fpMethod': headForm['sp_fpMethod'],
          'removalDate': headForm['sp_removalDate'],
          'removalReason': headForm['sp_removalReason'],
          'condomQuantity': headForm['sp_condomQuantity'],
          'malaQuantity': headForm['sp_malaQuantity'],
          'chhayaQuantity': headForm['sp_chhayaQuantity'],
          'ecpQuantity': headForm['sp_ecpQuantity'],
          'maritalStatus': 'Married',
          'relation_to_head': 'spouse',
          'isFamilyhead': false,
          'isFamilyheadWife': false,
          ...childrenData,
        };

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
          'is_family_planning': 0,
          'is_adult': 1,
          'is_guest': 0,
          'is_death': 0,
          'death_details': jsonEncode({}),
          'is_migrated': 0,
          'is_separated': 0,
          'device_details': jsonEncode(_deviceDetails(deviceInfo)),
          'app_details': jsonEncode(_appDetails(deviceInfo)),
          'parent_user': jsonEncode({}),
          'current_user_key': ashaUniqueKey,
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
        };

        await LocalStorageDao.instance.insertBeneficiary(spousePayload);
      } catch (e) {
        print('Error saving spouse: $e');
      }
    }

    return _HeadSpouseKeys(
      householdRefKey: uniqueKey,
      headId: headId,
      spouseKey: spouseKey,
    );
  }

  Future<void> _insertMemberFromForm({
    required Map<String, dynamic> memberForm,
    required String householdRefKey,
    required dynamic deviceInfo,
    required String ts,
    required dynamic ashaUniqueKey,
    required dynamic facilityId,
    required String geoLocationJson,
    required String headId,
    required String? headSpouseKey,
  }) async {
    // Basic validation: must have name and relation
    final name = (memberForm['name'] ?? '').toString().trim();
    final relation = (memberForm['relation'] ?? '').toString().trim();
    if (name.isEmpty || relation.isEmpty) {
      print('Skipping member insert due to missing name or relation');
      return;
    }

    final memberType = (memberForm['memberType'] ?? 'Adult').toString();
    final memberGender = (memberForm['gender'] ?? '').toString();
    final maritalStatus = (memberForm['maritalStatus'] ?? '').toString();
    final hasChildren = memberForm['hasChildren'];

    // Determine isAdult similar to AddnewfamilymemberBloc
    int isAdult;
    if (memberType.toLowerCase() == 'child') {
      isAdult = 0;
    } else {
      isAdult = 1;
    }

    String _beneficiaryState(String? mt) {
      if (mt != null && mt.toLowerCase() == 'child') return 'registration_due';
      return 'active';
    }

    final beneficiaryState = _beneficiaryState(memberType);

    // Derive mother_key / father_key when relation is Father/Mother/Child
    String? resolvedMotherKey;
    String? resolvedFatherKey;
    try {
      if (relation == 'Mother' || relation == 'Father' || relation == 'Child') {
        final hhBeneficiaries =
            await LocalStorageDao.instance.getBeneficiariesByHousehold(householdRefKey);

        Map<String, dynamic>? headRecord;
        Map<String, dynamic>? spouseRecord;
        for (final b in hhBeneficiaries) {
          try {
            final info = b['beneficiary_info'] is Map
                ? Map<String, dynamic>.from(b['beneficiary_info'])
                : <String, dynamic>{};
            final relToHead =
                (info['relation_to_head'] ?? '').toString().toLowerCase();
            final rel = (info['relation'] ?? '').toString().toLowerCase();
            if (relToHead == 'self' || rel == 'head') {
              headRecord = b as Map<String, dynamic>;
              break;
            }
          } catch (_) {}
        }
        if (headRecord != null) {
          final headUnique = (headRecord['unique_key'] ?? '').toString();
          String? spouseKeyLocal = headRecord['spouse_key']?.toString();
          if (spouseKeyLocal == null || spouseKeyLocal.isEmpty) {
            try {
              for (final b in hhBeneficiaries) {
                if ((b['spouse_key'] ?? '').toString() == headUnique) {
                  spouseKeyLocal = (b['unique_key'] ?? '').toString();
                  spouseRecord = b as Map<String, dynamic>;
                  break;
                }
              }
            } catch (_) {}
          } else {
            try {
              for (final b in hhBeneficiaries) {
                if ((b['unique_key'] ?? '').toString() == spouseKeyLocal) {
                  spouseRecord = b as Map<String, dynamic>;
                  break;
                }
              }
            } catch (_) {}
          }

          if (relation == 'Mother') {
            resolvedMotherKey = headUnique;
            resolvedFatherKey = spouseKeyLocal;
          } else if (relation == 'Father') {
            resolvedFatherKey = headUnique;
            resolvedMotherKey = spouseKeyLocal;
          } else if (relation == 'Child') {
            final headInfo = headRecord['beneficiary_info'] is Map
                ? Map<String, dynamic>.from(headRecord['beneficiary_info'])
                : <String, dynamic>{};
            final spouseInfo = spouseRecord != null &&
                    spouseRecord!['beneficiary_info'] is Map
                ? Map<String, dynamic>.from(spouseRecord!['beneficiary_info'])
                : <String, dynamic>{};
            final headGender =
                (headInfo['gender'] ?? '').toString().toLowerCase();
            final spouseGender =
                (spouseInfo['gender'] ?? '').toString().toLowerCase();
            if (headGender == 'female') {
              resolvedMotherKey = headUnique;
              resolvedFatherKey = spouseKeyLocal;
            } else if (headGender == 'male') {
              resolvedFatherKey = headUnique;
              resolvedMotherKey = spouseKeyLocal;
            } else if (spouseGender.isNotEmpty) {
              if (spouseGender == 'female') {
                resolvedMotherKey = spouseKeyLocal;
                resolvedFatherKey = headUnique;
              } else if (spouseGender == 'male') {
                resolvedFatherKey = spouseKeyLocal;
                resolvedMotherKey = headUnique;
              }
            } else {
              resolvedMotherKey = headUnique;
              resolvedFatherKey = spouseKeyLocal;
            }
          }
        }
      }
    } catch (_) {}

    final memberId = await IdGenerator.generateUniqueId(deviceInfo);
    final String? spouseKeyForMember =
        maritalStatus == 'Married' && (memberForm['spouseName'] ?? '') != ''
            ? await IdGenerator.generateUniqueId(deviceInfo)
            : null;

    final memberInfo = {
      'memberType': memberForm['memberType'],
      'relation': memberForm['relation'],
      'otherRelation': memberForm['otherRelation'],
      'name': name,
      'fatherName': memberForm['fatherName'],
      'motherName': memberForm['motherName'],
      'useDob': memberForm['useDob'],
      'dob': memberForm['dob'],
      'approxAge': memberForm['approxAge'],
      'children': memberForm['children'],
      'birthOrder': memberForm['birthOrder'],
      'gender': memberGender,
      'bankAcc': memberForm['bankAcc'],
      'ifsc': memberForm['ifsc'],
      'occupation': memberForm['occupation'],
      'education': memberForm['education'],
      'religion': memberForm['religion'],
      'category': memberForm['category'],
      'weight': memberForm['weight'],
      'childSchool': memberForm['school'],
      'birthCertificate': memberForm['birthCertificate'],
      'birthWeight': memberForm['birthWeight'],
      'abhaAddress': memberForm['abhaAddress'],
      'mobileOwner': memberForm['mobileOwner'],
      'mobileOwnerRelation': memberForm['mobileOwnerRelation'],
      'mobileNo': memberForm['mobileNo'],
      'voterId': memberForm['voterId'],
      'rationId': memberForm['rationId'],
      'phId': memberForm['phId'],
      'beneficiaryType': memberForm['beneficiaryType'],
      'maritalStatus': maritalStatus,
      'ageAtMarriage': memberForm['ageAtMarriage'],
      'spouseName': memberForm['spouseName'],
      'hasChildren': hasChildren,
      'isPregnant': memberForm['isPregnant'],
      'memberStatus': memberForm['memberStatus'],
      'relation_to_head': memberForm['relation'],
      'isFamilyhead': false,
      'isFamilyheadWife': false,
      'createdAt': memberForm['createdAt'] ?? DateTime.now().toIso8601String(),
    }..removeWhere((k, v) => v == null || (v is String && v.toString().trim().isEmpty));

    final memberPayload = {
      'server_id': null,
      'household_ref_key': householdRefKey,
      'unique_key': memberId,
      'beneficiary_state': beneficiaryState,
      'pregnancy_count': 0,
      'beneficiary_info': jsonEncode(memberInfo),
      'geo_location': geoLocationJson,
      'spouse_key': spouseKeyForMember,
      'mother_key': resolvedMotherKey,
      'father_key': resolvedFatherKey,
      'is_family_planning': 0,
      'is_adult': isAdult,
      'is_guest': 0,
      'is_death': 0,
      'death_details': jsonEncode({}),
      'is_migrated': 0,
      'is_separated': 0,
      'device_details': jsonEncode(_deviceDetails(deviceInfo)),
      'app_details': jsonEncode(_appDetails(deviceInfo)),
      'parent_user': jsonEncode({}),
      'current_user_key': ashaUniqueKey,
      'facility_id': facilityId,
      'created_date_time': ts,
      'modified_date_time': ts,
      'is_synced': 0,
      'is_deleted': 0,
    };

    await LocalStorageDao.instance.insertBeneficiary(memberPayload);

    // Optional: create spouse row for this member if married
    String? memberSpouseKeyInserted;
    if (spouseKeyForMember != null) {
      try {
        final spouseInfo = {
          'relation': 'spouse',
          'memberName': memberForm['spouseName'],
          'spouseName': name,
          'gender': memberGender.toLowerCase() == 'male'
              ? 'Female'
              : memberGender.toLowerCase() == 'female'
                  ? 'Male'
                  : null,
          'maritalStatus': 'Married',
          'relation_to_head': memberForm['relation'],
          'isFamilyhead': false,
          'isFamilyheadWife': false,
        }..removeWhere((k, v) => v == null || (v is String && v.toString().trim().isEmpty));

        final spousePayload = {
          'server_id': null,
          'household_ref_key': householdRefKey,
          'unique_key': spouseKeyForMember,
          'beneficiary_state': 'active',
          'pregnancy_count': 0,
          'beneficiary_info': jsonEncode(spouseInfo),
          'geo_location': geoLocationJson,
          'spouse_key': memberId,
          'mother_key': null,
          'father_key': null,
          'is_family_planning': 0,
          'is_adult': 1,
          'is_guest': 0,
          'is_death': 0,
          'death_details': jsonEncode({}),
          'is_migrated': 0,
          'is_separated': 0,
          'device_details': jsonEncode(_deviceDetails(deviceInfo)),
          'app_details': jsonEncode(_appDetails(deviceInfo)),
          'parent_user': jsonEncode({}),
          'current_user_key': ashaUniqueKey,
          'facility_id': facilityId,
          'created_date_time': ts,
          'modified_date_time': ts,
          'is_synced': 0,
          'is_deleted': 0,
        };

        await LocalStorageDao.instance.insertBeneficiary(spousePayload);
        memberSpouseKeyInserted = spouseKeyForMember;
      } catch (e) {
        print('Error inserting member spouse row: $e');
      }
    }

    // Sync member and its spouse if created
    await _syncBeneficiaryByUniqueKey(
      uniqueKey: memberId,
      deviceInfo: deviceInfo,
      ts: ts,
    );
    if (memberSpouseKeyInserted != null) {
      await _syncBeneficiaryByUniqueKey(
        uniqueKey: memberSpouseKeyInserted,
        deviceInfo: deviceInfo,
        ts: ts,
      );
    }
  }

  Future<void> _syncBeneficiaryByUniqueKey({
    required String uniqueKey,
    required dynamic deviceInfo,
    required String ts,
  }) async {
    final saved = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(uniqueKey);
    if (saved == null) return;

    final currentUser = await UserInfo.getCurrentUser();
    final userDetails = currentUser?['details'] is String
        ? jsonDecode(currentUser?['details'] ?? '{}')
        : currentUser?['details'] ?? {};
    final working = userDetails['working_location'] ?? {};
    final facilityId = working['asha_associated_with_facility_id'] ??
        userDetails['asha_associated_with_facility_id'] ?? 0;
    final ashaUniqueKey = userDetails['unique_key'] ?? {};

    final payload = _buildBeneficiaryApiPayload(
      Map<String, dynamic>.from(saved),
      Map<String, dynamic>.from(userDetails is Map ? userDetails : {}),
      Map<String, dynamic>.from(working is Map ? working : {}),
      deviceInfo,
      ts,
      ashaUniqueKey,
      facilityId,
    );

    try {
      final repo = AddBeneficiaryRepository();
      final reqUniqueKey = (saved['unique_key'] ?? '').toString();
      final resp = await repo.addBeneficiary(payload);
      try {
        if (resp is Map && (resp['success'] == true)) {
          if (resp['data'] is List && (resp['data'] as List).isNotEmpty) {
            final first = resp['data'][0];
            if (first is Map) {
              final sid = (first['_id'] ?? first['id'] ?? '').toString();
              if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
                final updated = await LocalStorageDao.instance
                    .updateBeneficiaryServerIdByUniqueKey(
                        uniqueKey: reqUniqueKey, serverId: sid);
                print('Updated beneficiary with server_id=$sid rows=$updated');
              }
            }
          } else if (resp['data'] is Map) {
            final map = Map<String, dynamic>.from(resp['data']);
            final sid = (map['_id'] ?? map['id'] ?? '').toString();
            if (sid.isNotEmpty && reqUniqueKey.isNotEmpty) {
              final updated = await LocalStorageDao.instance
                  .updateBeneficiaryServerIdByUniqueKey(
                      uniqueKey: reqUniqueKey, serverId: sid);
              print('Updated beneficiary with server_id=$sid rows=$updated');
            }
          }
        }
      } catch (e) {
        print('Error updating local beneficiary after API: $e');
      }
    } catch (apiErr) {
      print('add_beneficiary API failed, will sync later: $apiErr');
    }
  }

  Map<String, dynamic> _buildBeneficiaryApiPayload(
    Map<String, dynamic> row,
    Map<String, dynamic> userDetails,
    Map<String, dynamic> working,
    dynamic deviceInfo,
    String ts,
    dynamic ashaUniqueKey,
    dynamic facilityId,
  ) {
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
          final tsCap = m['captured_at'] ?? m['captured_datetime'] ?? m['timestamp'];
          return {
            'lat': (lat is num) ? lat : double.tryParse('${lat ?? ''}'),
            'lng': (lng is num) ? lng : double.tryParse('${lng ?? ''}'),
            'accuracy_m': (acc is num) ? acc : double.tryParse('${acc ?? ''}'),
            'captured_at': tsCap?.toString() ?? DateTime.now().toUtc().toIso8601String(),
          }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
        }
      } catch (_) {}
      return {
        'lat': null,
        'lng': null,
        'accuracy_m': null,
        'captured_at': DateTime.now().toUtc().toIso8601String(),
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));
    }

    final beneficiaryInfoApi = {
      'name': {
        'first_name': (info['headName'] ?? info['memberName'] ?? info['name'] ?? '').toString(),
        'middle_name': '',
        'last_name': '',
      },
      'gender': _genderCode(info['gender']?.toString()),
      'dob': _yyyyMMdd(info['dob']?.toString()),
      'marital_status': (info['maritalStatus'] ?? 'married').toString().toLowerCase(),
      'aadhaar': (info['aadhaar'] ?? info['aadhar'])?.toString(),
      'phone': (info['mobileNo'] ?? '').toString(),
      'address': {
        'state': working['state'] ?? userDetails['stateName'],
        'district': working['district'] ?? userDetails['districtName'],
        'block': working['block'] ?? userDetails['blockName'],
        'village': info['village'] ?? working['village'] ?? userDetails['villageName'],
        'pincode': working['pincode'] ?? userDetails['pincode'],
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
      'is_abha_verified': info['is_abha_verified'] ?? false,
      'is_rch_id_verified': info['is_rch_id_verified'] ?? false,
      'is_fetched_from_abha': info['is_fetched_from_abha'] ?? false,
      'is_fetched_from_rch': info['is_fetched_from_rch'] ?? false,
      'is_existing_father': info['is_existing_father'] ?? false,
      'is_existing_mother': info['is_existing_mother'] ?? false,
      'ben_type': info['ben_type'] ?? (info['memberType'] ?? 'adult'),
      'mother_ben_ref_key': info['mother_ben_ref_key'] ?? row['mother_key']?.toString() ?? '',
      'father_ben_ref_key': info['father_ben_ref_key'] ?? row['father_key']?.toString() ?? '',
      'relaton_with_family_head':
          info['relaton_with_family_head'] ?? info['relation_to_head'] ?? 'self',
      'member_status': info['member_status'] ?? 'alive',
      'member_name': info['member_name'] ?? info['headName'] ?? info['memberName'] ?? info['name'],
      'father_or_spouse_name':
          info['father_or_spouse_name'] ?? info['fatherName'] ?? info['spouseName'] ?? '',
      'have_children': info['have_children'] ?? info['hasChildren'],
      'is_family_planning': info['is_family_planning'] ?? row['is_family_planning'] ?? 0,
      'total_children': info['total_children'] ?? info['totalBorn'],
      'total_live_children': info['total_live_children'] ?? info['totalLive'],
      'total_male_children': info['total_male_children'] ?? info['totalMale'],
      'age_of_youngest_child':
          info['age_of_youngest_child'] ?? info['youngestAge'],
      'gender_of_younget_child':
          info['gender_of_younget_child'] ?? info['youngestGender'],
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
      'age_of_youngest_child_unit':
          info['age_of_youngest_child_unit'] ?? info['ageUnit'],
      'type_of_beneficiary':
          info['type_of_beneficiary'] ?? info['beneficiaryType'] ?? 'staying_in_house',
      'name_of_spouse': info['name_of_spouse'] ?? info['spouseName'] ?? '',
    }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty));

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
        'app_version': deviceInfo.appVersion.split('+').first,
      },
      'app_details': {
        'captured_by_user': userDetails['user_identifier'] ?? '',
        'captured_role_id': userDetails['role_id'] ?? userDetails['role'] ?? 0,
        'source': 'mobile',
      },
      'parent_user': {
        'user_key': userDetails['supervisor_user_key'] ?? '',
        'name': userDetails['supervisor_name'] ?? '',
      }..removeWhere((k, v) => v == null || (v is String && v.trim().isEmpty)),
      'current_user_key': row['current_user_key'] ?? ashaUniqueKey,
      'facility_id': row['facility_id'] ?? facilityId,
      'created_date_time': row['created_date_time'] ?? ts,
      'modified_date_time': row['modified_date_time'] ?? ts,
    };
  }
}
