import 'dart:convert';

class GuestBeneficiary {
  final String? id;
  final String uniqueKey;
  final String? householdRefKey;
  final Map<String, dynamic> formJson;
  final String? isGuest;
  final String? isDeath;
  final String? createdDateTime;
  final String? modifiedDateTime;
  final String? ashaName;
  final String? hscName;

  GuestBeneficiary({
    this.id,
    required this.uniqueKey,
    this.householdRefKey,
    required this.formJson,
    this.isGuest,
    this.isDeath,
    this.createdDateTime,
    this.modifiedDateTime,
    this.ashaName,
    this.hscName,
  });

  factory GuestBeneficiary.fromJson(Map<String, dynamic> json) {
    return GuestBeneficiary(
      id: json['_id'] as String?,
      uniqueKey: json['unique_key'] as String? ?? '',
      householdRefKey: json['household_registration_ref_key'] as String?,
      formJson: _convertToMapStringDynamic(json['form_json'] ?? {}),
      isGuest: json['is_guest']?.toString() ?? '0',
      isDeath: json['is_death']?.toString() ?? '0',
      createdDateTime: json['created_date_time']?.toString(),
      modifiedDateTime: json['modified_date_time']?.toString() ?? DateTime.now().toIso8601String(),
      ashaName: json['asha_name']?.toString(),
      hscName: json['hsc_name']?.toString(),
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
      'beneficiary_info': jsonEncode(formJson),
      'is_guest': isGuest == '1' ? 1 : 0,
      'is_death': isDeath == '1' ? 1 : 0,
      'created_date_time': createdDateTime ?? DateTime.now().toIso8601String(),
      'modified_date_time': modifiedDateTime ?? DateTime.now().toIso8601String(),
      'is_synced': 0,
      'is_deleted': 0,
      'current_user_key': '',
      'facility_id': 0,
      'parent_user': '',
      'device_details': jsonEncode({
        'platform': 'mobile',
        'os': 'android',
      }),
      'app_details': jsonEncode({
        'app_name': 'BHAVYAmASHA',
        'version': '1.0.0',
      }),
    };
  }
}