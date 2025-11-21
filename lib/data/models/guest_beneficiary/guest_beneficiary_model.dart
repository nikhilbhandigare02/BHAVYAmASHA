import 'dart:convert';

class GuestBeneficiary {
  final String? id;
  final String uniqueKey;
  final String? householdRefKey;
  final Map<String, dynamic> formJson;
  final String? beneficiaryState;
  final String? isGuest;
  final String? isDeath;
  final String? createdDateTime;
  final String? modifiedDateTime;
  final String? ashaName;
  final String? hscName;
  final int? isMigrated;
  final int? isSeparated;
  final Map<String, dynamic>? deviceDetails;
  final Map<String, dynamic>? appDetails;
  final Map<String, dynamic>? parentUser;
  final String? currentUserKey;
  final int? facilityId;
  final dynamic deathDetails;

  GuestBeneficiary({
    this.id,
    required this.uniqueKey,
    this.householdRefKey,
    required this.formJson,
    this.beneficiaryState,
    this.isGuest,
    this.isDeath,
    this.createdDateTime,
    this.modifiedDateTime,
    this.ashaName,
    this.hscName,
    this.isMigrated,
    this.isSeparated,
    this.deviceDetails,
    this.appDetails,
    this.parentUser,
    this.currentUserKey,
    this.facilityId,
    this.deathDetails,
  });

  factory GuestBeneficiary.fromJson(Map<String, dynamic> json) {
    return GuestBeneficiary(
      id: json['_id'] as String?,
      uniqueKey: json['unique_key'] as String? ?? '',
      householdRefKey: json['household_registration_ref_key'] as String?,
      formJson: _convertToMapStringDynamic(json['form_json'] ?? {}),
      beneficiaryState: json['beneficiary_status']?.toString(),
      isGuest: json['is_guest']?.toString() ?? '0',
      isDeath: json['is_death']?.toString() ?? '0',
      createdDateTime: json['created_date_time']?.toString(),
      modifiedDateTime: json['modified_date_time']?.toString() ?? DateTime.now().toIso8601String(),
      ashaName: json['asha_name']?.toString(),
      hscName: json['hsc_name']?.toString(),
      isMigrated: _toInt(json['is_migrated']),
      isSeparated: _toInt(json['is_separated']),
      deviceDetails: _convertToMapStringDynamic(json['device_details']),
      appDetails: _convertToMapStringDynamic(json['app_details']),
      parentUser: _convertToMapStringDynamic(json['parent_user'] ?? {
        'parent_added_by': json['parent_added_by'],
        'created_by': json['created_by'],
        'added_by': json['added_by'],
      }),
      currentUserKey: json['current_user_key']?.toString(),
      facilityId: _toInt(json['facility_id']),
      deathDetails: json['death_details'],
    );
  }

  static Map<String, dynamic> _convertToMapStringDynamic(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, val) {
        result[key.toString()] = val;
      });
      return result;
    }
    return {};
  }

  Map<String, dynamic> toMap() {
    return {
      'server_id': id,
      'unique_key': uniqueKey,
      'household_ref_key': householdRefKey,
      'beneficiary_state': beneficiaryState,
      'beneficiary_info': jsonEncode(formJson),
      'is_guest': 1,
      'is_death': isDeath == '1' ? 1 : 0,
      'death_details': deathDetails == null
          ? null
          : (deathDetails is String ? deathDetails : jsonEncode(deathDetails)),
      'is_migrated': isMigrated ?? 0,
      'is_separated': isSeparated ?? 0,
      'device_details': deviceDetails == null ? jsonEncode({
        'platform': 'mobile',
        'os': 'android',
      }) : jsonEncode(deviceDetails),
      'app_details': appDetails == null ? jsonEncode({
        'app_name': 'BHAVYAmASHA',
        'version': '1.0.0',
      }) : jsonEncode(appDetails),
      'parent_user': parentUser == null ? jsonEncode({}) : jsonEncode(parentUser),
      'current_user_key': currentUserKey ?? '',
      'facility_id': facilityId ?? 0,
      'created_date_time': createdDateTime ?? DateTime.now().toIso8601String(),
      'modified_date_time': modifiedDateTime ?? DateTime.now().toIso8601String(),
      'is_synced': 0,
      'is_deleted': 0,
    };
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }
    if (v is num) return v.toInt();
    return null;
  }
}