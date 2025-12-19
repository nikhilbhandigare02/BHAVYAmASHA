

import 'package:flutter/cupertino.dart';

import '../../../core/utils/enums.dart';
import '../../../data/models/guest_beneficiary/guest_beneficiary_model.dart';

@immutable
class GuestBeneficiarySearchState {
  final GbsStatus status;
  final String? errorMessage;
  final String? apiMessage;
  final bool showAdvanced;
  final String? beneficiaryNo;
  final String? district;
  final String? block;
  final String? category;
  final String? gender;
  final String? age;
  final String? mobileNo;
  final List<GuestBeneficiary> beneficiaries;
  final bool clearError;

  const GuestBeneficiarySearchState({
    this.status = GbsStatus.initial,
    this.errorMessage,
    this.apiMessage,
    this.showAdvanced = false,
    this.beneficiaryNo,
    this.district,
    this.block,
    this.category,
    this.gender,
    this.age,
    this.mobileNo,
    this.beneficiaries = const [],
    bool? clearError,
  }) : clearError = clearError ?? (errorMessage == null);

  GuestBeneficiarySearchState copyWith({
    GbsStatus? status,
    String? errorMessage,
    String? apiMessage,
    bool? showAdvanced,
    String? beneficiaryNo,
    String? district,
    String? block,
    String? category,
    String? gender,
    String? age,
    String? mobileNo,
    List<GuestBeneficiary>? beneficiaries,
    bool? clearError,
  }) {
    return GuestBeneficiarySearchState(
      status: status ?? this.status,
      errorMessage: clearError == true ? null : (errorMessage ?? this.errorMessage),
      apiMessage: apiMessage ?? this.apiMessage,
      showAdvanced: showAdvanced ?? this.showAdvanced,
      beneficiaryNo: beneficiaryNo ?? this.beneficiaryNo,
      district: district ?? this.district,
      block: block ?? this.block,
      category: category ?? this.category,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      mobileNo: mobileNo ?? this.mobileNo,
      beneficiaries: beneficiaries ?? this.beneficiaries,
      clearError: clearError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuestBeneficiarySearchState &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.apiMessage == apiMessage &&
        other.showAdvanced == showAdvanced &&
        other.beneficiaryNo == beneficiaryNo &&
        other.district == district &&
        other.block == block &&
        other.category == category &&
        other.gender == gender &&
        other.age == age &&
        other.mobileNo == mobileNo &&
        other.beneficiaries == beneficiaries &&
        other.clearError == clearError;
  }

  @override
  int get hashCode {
    return status.hashCode ^
    errorMessage.hashCode ^
    apiMessage.hashCode ^
    showAdvanced.hashCode ^
    beneficiaryNo.hashCode ^
    district.hashCode ^
    block.hashCode ^
    category.hashCode ^
    gender.hashCode ^
    age.hashCode ^
    mobileNo.hashCode ^
    beneficiaries.hashCode ^
    clearError.hashCode;
  }

  get beneficiaryData => null;

  @override
  String toString() {
    return 'GuestBeneficiarySearchState('
        'status: $status, '
        'errorMessage: $errorMessage, '
        'apiMessage: $apiMessage, '
        'showAdvanced: $showAdvanced, '
        'beneficiaryNo: $beneficiaryNo, '
        'district: $district, '
        'block: $block, '
        'category: $category, '
        'gender: $gender, '
        'age: $age, '
        'mobileNo: $mobileNo, '
        'beneficiaries: $beneficiaries, '
        'clearError: $clearError)';
  }
}
