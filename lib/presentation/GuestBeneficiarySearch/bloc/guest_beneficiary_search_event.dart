import 'package:equatable/equatable.dart';

abstract class GuestBeneficiarySearchEvent extends Equatable {
  const GuestBeneficiarySearchEvent();
  @override
  List<Object?> get props => [];
}

class GbsToggleAdvanced extends GuestBeneficiarySearchEvent {
  const GbsToggleAdvanced();
}

class GbsUpdateBeneficiaryNo extends GuestBeneficiarySearchEvent {
  final String? value;
  const GbsUpdateBeneficiaryNo(this.value);
  @override
  List<Object?> get props => [value];
}

class GbsUpdateDistrict extends GuestBeneficiarySearchEvent {
  final String? value;
  const GbsUpdateDistrict(this.value);
  @override
  List<Object?> get props => [value];
}

class GbsUpdateBlock extends GuestBeneficiarySearchEvent {
  final String? value;
  const GbsUpdateBlock(this.value);
  @override
  List<Object?> get props => [value];
}

class GbsUpdateCategory extends GuestBeneficiarySearchEvent {
  final String? value;
  const GbsUpdateCategory(this.value);
  @override
  List<Object?> get props => [value];
}

class GbsUpdateGender extends GuestBeneficiarySearchEvent {
  final String? value;
  const GbsUpdateGender(this.value);
  @override
  List<Object?> get props => [value];
}

class GbsUpdateAge extends GuestBeneficiarySearchEvent {
  final String? value;
  const GbsUpdateAge(this.value);
  @override
  List<Object?> get props => [value];
}

class GbsUpdateMobile extends GuestBeneficiarySearchEvent {
  final String? value;
  const GbsUpdateMobile(this.value);
  @override
  List<Object?> get props => [value];
}

class GbsSubmitSearch extends GuestBeneficiarySearchEvent {
  const GbsSubmitSearch();
}
