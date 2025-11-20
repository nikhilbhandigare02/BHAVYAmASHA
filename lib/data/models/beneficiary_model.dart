import 'dart:convert';

class GuestBeneficiary {
  final int? id; // Local DB ID
  final String? serverId; // _id from API
  final String? householdRefKey; // household_registration_ref_key
  final String? uniqueKey; // unique_key
  final String? beneficiaryState;
  final int? pregnancyCount;
  final Map<String, dynamic>? beneficiaryInfo; // form_json
  final String? geoLocation;
  final String? spouseKey;
  final String? motherKey;
  final String? fatherKey;
  final int? isFamilyPlanning;
  final int? isAdult;
  final int? isGuest;
  final int? isDeath;
  final String? deathDetails;
  final int? isMigrated;
  final int? isSeparated;
  final String? deviceDetails;
  final String? appDetails;
  final String? parentUser;
  final String? currentUserKey;
  final int? facilityId;
  final String? createdDateTime;
  final String? modifiedDateTime;
  final int? isSynced;
  final int? isDeleted;

  GuestBeneficiary({
    this.id,
    this.serverId,
    this.householdRefKey,
    this.uniqueKey,
    this.beneficiaryState,
    this.pregnancyCount,
    this.beneficiaryInfo,
    this.geoLocation,
    this.spouseKey,
    this.motherKey,
    this.fatherKey,
    this.isFamilyPlanning,
    this.isAdult,
    this.isGuest,
    this.isDeath,
    this.deathDetails,
    this.isMigrated,
    this.isSeparated,
    this.deviceDetails,
    this.appDetails,
    this.parentUser,
    this.currentUserKey,
    this.facilityId,
    this.createdDateTime,
    this.modifiedDateTime,
    this.isSynced,
    this.isDeleted,
  });

  // Create from API response
  factory GuestBeneficiary.fromJson(Map<String, dynamic> json) {
    return GuestBeneficiary(
      serverId: json['_id'] as String?,
      householdRefKey: json['household_registration_ref_key'] as String?,
      uniqueKey: json['unique_key'] as String?,
      beneficiaryInfo: json['form_json'] as Map<String, dynamic>?,
      isGuest: int.tryParse(json['is_guest']?.toString() ?? '1') ?? 1,
      isDeath: int.tryParse(json['is_death']?.toString() ?? '0') ?? 0,
      facilityId: int.tryParse(json['facility_id']?.toString() ?? '0'),
      createdDateTime: json['created_date_time'] as String?,
      modifiedDateTime: json['modified_date_time'] as String?,
      isDeleted: int.tryParse(json['is_deleted']?.toString() ?? '0') ?? 0,
      isSynced: 0, // Default to not synced
    );
  }

  // Create from local database
  factory GuestBeneficiary.fromDb(Map<String, dynamic> map) {
    return GuestBeneficiary(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      householdRefKey: map['household_ref_key'] as String?,
      uniqueKey: map['unique_key'] as String?,
      beneficiaryState: map['beneficiary_state'] as String?,
      pregnancyCount: map['pregnancy_count'] as int?,
      beneficiaryInfo: map['beneficiary_info'] != null
          ? jsonDecode(map['beneficiary_info'] as String)
          : null,
      geoLocation: map['geo_location'] as String?,
      spouseKey: map['spouse_key'] as String?,
      motherKey: map['mother_key'] as String?,
      fatherKey: map['father_key'] as String?,
      isFamilyPlanning: map['is_family_planning'] as int?,
      isAdult: map['is_adult'] as int?,
      isGuest: map['is_guest'] as int?,
      isDeath: map['is_death'] as int?,
      deathDetails: map['death_details'] as String?,
      isMigrated: map['is_migrated'] as int?,
      isSeparated: map['is_separated'] as int?,
      deviceDetails: map['device_details'] as String?,
      appDetails: map['app_details'] as String?,
      parentUser: map['parent_user'] as String?,
      currentUserKey: map['current_user_key'] as String?,
      facilityId: map['facility_id'] as int?,
      createdDateTime: map['created_date_time'] as String?,
      modifiedDateTime: map['modified_date_time'] as String?,
      isSynced: map['is_synced'] as int?,
      isDeleted: map['is_deleted'] as int?,
    );
  }

  // Convert to database map
  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'household_ref_key': householdRefKey,
      'unique_key': uniqueKey,
      'beneficiary_state': beneficiaryState,
      'pregnancy_count': pregnancyCount,
      'beneficiary_info': beneficiaryInfo != null
          ? jsonEncode(beneficiaryInfo)
          : null,
      'geo_location': geoLocation,
      'spouse_key': spouseKey,
      'mother_key': motherKey,
      'father_key': fatherKey,
      'is_family_planning': isFamilyPlanning,
      'is_adult': isAdult,
      'is_guest': isGuest,
      'is_death': isDeath,
      'death_details': deathDetails,
      'is_migrated': isMigrated,
      'is_separated': isSeparated,
      'device_details': deviceDetails,
      'app_details': appDetails,
      'parent_user': parentUser,
      'current_user_key': currentUserKey,
      'facility_id': facilityId,
      'created_date_time': createdDateTime,
      'modified_date_time': modifiedDateTime,
      'is_synced': isSynced ?? 0,
      'is_deleted': isDeleted ?? 0,
    };
  }

  GuestBeneficiary copyWith({
    int? id,
    String? serverId,
    String? householdRefKey,
    String? uniqueKey,
    String? beneficiaryState,
    int? pregnancyCount,
    Map<String, dynamic>? beneficiaryInfo,
    String? geoLocation,
    String? spouseKey,
    String? motherKey,
    String? fatherKey,
    int? isFamilyPlanning,
    int? isAdult,
    int? isGuest,
    int? isDeath,
    String? deathDetails,
    int? isMigrated,
    int? isSeparated,
    String? deviceDetails,
    String? appDetails,
    String? parentUser,
    String? currentUserKey,
    int? facilityId,
    String? createdDateTime,
    String? modifiedDateTime,
    int? isSynced,
    int? isDeleted,
  }) {
    return GuestBeneficiary(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      householdRefKey: householdRefKey ?? this.householdRefKey,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      beneficiaryState: beneficiaryState ?? this.beneficiaryState,
      pregnancyCount: pregnancyCount ?? this.pregnancyCount,
      beneficiaryInfo: beneficiaryInfo ?? this.beneficiaryInfo,
      geoLocation: geoLocation ?? this.geoLocation,
      spouseKey: spouseKey ?? this.spouseKey,
      motherKey: motherKey ?? this.motherKey,
      fatherKey: fatherKey ?? this.fatherKey,
      isFamilyPlanning: isFamilyPlanning ?? this.isFamilyPlanning,
      isAdult: isAdult ?? this.isAdult,
      isGuest: isGuest ?? this.isGuest,
      isDeath: isDeath ?? this.isDeath,
      deathDetails: deathDetails ?? this.deathDetails,
      isMigrated: isMigrated ?? this.isMigrated,
      isSeparated: isSeparated ?? this.isSeparated,
      deviceDetails: deviceDetails ?? this.deviceDetails,
      appDetails: appDetails ?? this.appDetails,
      parentUser: parentUser ?? this.parentUser,
      currentUserKey: currentUserKey ?? this.currentUserKey,
      facilityId: facilityId ?? this.facilityId,
      createdDateTime: createdDateTime ?? this.createdDateTime,
      modifiedDateTime: modifiedDateTime ?? this.modifiedDateTime,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}