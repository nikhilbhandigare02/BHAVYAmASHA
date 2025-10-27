part of 'cbac_form_bloc.dart';

abstract class CBACFormEvent extends Equatable {
  const CBACFormEvent();
  @override
  List<Object?> get props => [];
}

class CbacOpened extends CBACFormEvent {
  const CbacOpened();
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
