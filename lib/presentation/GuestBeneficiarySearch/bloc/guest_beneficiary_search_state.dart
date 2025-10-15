import 'package:equatable/equatable.dart';

enum GbsStatus { initial, submitting, success, failure }

class GuestBeneficiarySearchState extends Equatable {
  final bool showAdvanced;
  final String? beneficiaryNo;
  final String? district;
  final String? block;
  final String? category;
  final String? gender;
  final String? age;
  final String? mobileNo;
  final GbsStatus status;
  final String? errorMessage;

  const GuestBeneficiarySearchState({
    this.showAdvanced = false,
    this.beneficiaryNo,
    this.district,
    this.block,
    this.category,
    this.gender,
    this.age,
    this.mobileNo,
    this.status = GbsStatus.initial,
    this.errorMessage,
  });

  GuestBeneficiarySearchState copyWith({
    bool? showAdvanced,
    String? beneficiaryNo,
    String? district,
    String? block,
    String? category,
    String? gender,
    String? age,
    String? mobileNo,
    GbsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) => GuestBeneficiarySearchState(
        showAdvanced: showAdvanced ?? this.showAdvanced,
        beneficiaryNo: beneficiaryNo ?? this.beneficiaryNo,
        district: district ?? this.district,
        block: block ?? this.block,
        category: category ?? this.category,
        gender: gender ?? this.gender,
        age: age ?? this.age,
        mobileNo: mobileNo ?? this.mobileNo,
        status: status ?? this.status,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        showAdvanced,
        beneficiaryNo,
        district,
        block,
        category,
        gender,
        age,
        mobileNo,
        status,
        errorMessage,
      ];

  @override
  bool get stringify => true;
}
