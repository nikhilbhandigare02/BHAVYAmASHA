part of 'cbac_form_bloc.dart';

@immutable
class CbacFormState extends Equatable {
  final bool consentDialogShown;
  final bool consentAgreed;
  final int activeTab; // 0..5 for 6 tabs
  final Map<String, dynamic> data;
  final bool submitting;
  final String? errorMessage;
  final List<String> missingKeys;
  final bool isSuccess;
  final int? validationFailedTab;

  const CbacFormState({
    this.consentDialogShown = false,
    this.consentAgreed = false,
    this.activeTab = 0,
    this.data = const {},
    this.submitting = false,
    this.errorMessage,
    this.missingKeys = const [],
    this.isSuccess = false,
    this.validationFailedTab,
  });

  CbacFormState copyWith({
    bool? consentDialogShown,
    bool? consentAgreed,
    int? activeTab,
    Map<String, dynamic>? data,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
    List<String>? missingKeys,
    bool? isSuccess,
    int? validationFailedTab,
    bool clearValidationFailedTab = false,
  }) {
    return CbacFormState(
      consentDialogShown: consentDialogShown ?? this.consentDialogShown,
      consentAgreed: consentAgreed ?? this.consentAgreed,
      activeTab: activeTab ?? this.activeTab,
      data: data ?? this.data,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      missingKeys: clearError ? const [] : (missingKeys ?? this.missingKeys),
      isSuccess: isSuccess ?? this.isSuccess,
      validationFailedTab: clearValidationFailedTab
          ? null
          : (validationFailedTab ?? this.validationFailedTab),
    );
  }

  @override
  List<Object?> get props => [
        consentDialogShown,
        consentAgreed,
        activeTab,
        data,
        submitting,
        errorMessage,
        missingKeys,
        isSuccess,
        validationFailedTab,
      ];
}

class CbacFormInitial extends CbacFormState {
  const CbacFormInitial() : super();
}
