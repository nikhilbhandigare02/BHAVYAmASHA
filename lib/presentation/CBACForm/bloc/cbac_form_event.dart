part of 'cbac_form_bloc.dart';

abstract class CBACFormEvent extends Equatable {
  const CBACFormEvent();
  @override
  List<Object?> get props => [];
}

class CbacOpened extends CBACFormEvent {
  final String? beneficiaryId;
  final String? hhid;
  
  const CbacOpened({
    this.beneficiaryId,
    this.hhid,
  });
  
  @override
  List<Object?> get props => [beneficiaryId, hhid];
}

class CbacBeneficiaryLoaded extends CBACFormEvent {
  final Map<String, dynamic> beneficiaryData;
  
  const CbacBeneficiaryLoaded(this.beneficiaryData);
  
  @override
  List<Object?> get props => [beneficiaryData];
}

class CbacConsentDialogShown extends CBACFormEvent {
  const CbacConsentDialogShown();
}

class CbacConsentAgreed extends CBACFormEvent {
  const CbacConsentAgreed();
}

class CbacConsentDisagreed extends CBACFormEvent {
  const CbacConsentDisagreed();
}

class CbacNextTab extends CBACFormEvent {
  const CbacNextTab();
}

class CbacPrevTab extends CBACFormEvent {
  const CbacPrevTab();
}

class CbacFieldChanged extends CBACFormEvent {
  final String keyPath;
  final dynamic value;
  const CbacFieldChanged(this.keyPath, this.value);
  @override
  List<Object?> get props => [keyPath, value];
}

class CbacSubmitted extends CBACFormEvent {
  const CbacSubmitted();
}

class CbacTabChanged extends CBACFormEvent {
  final int tabIndex;
  const CbacTabChanged(this.tabIndex);
  @override
  List<Object?> get props => [tabIndex];
}

class CbacClearValidationError extends CBACFormEvent {
  const CbacClearValidationError();
}
