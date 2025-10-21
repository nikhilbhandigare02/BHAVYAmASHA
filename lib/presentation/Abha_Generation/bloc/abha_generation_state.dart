part of 'abha_generation_bloc.dart';

class AbhaGenerationState extends Equatable {
  const AbhaGenerationState({
    this.mobile = '',
    this.aadhaar = '',
    this.consents = const [],
    this.postApiStatus = PostApiStatus.initial,
    this.errorMessage,
  });

  final String mobile;
  final String aadhaar;
  final List<bool> consents;
  final PostApiStatus postApiStatus;
  final String? errorMessage;

  bool get isFormValid {
    final mobileOk = mobile.trim().length == 10;
    final aadhaarOk = aadhaar.trim().length == 12;
    final consentOk = consents.isNotEmpty && consents.every((e) => e);
    return mobileOk && aadhaarOk && consentOk;
  }

  AbhaGenerationState copyWith({
    String? mobile,
    String? aadhaar,
    List<bool>? consents,
    PostApiStatus? postApiStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AbhaGenerationState(
      mobile: mobile ?? this.mobile,
      aadhaar: aadhaar ?? this.aadhaar,
      consents: consents ?? this.consents,
      postApiStatus: postApiStatus ?? this.postApiStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [mobile, aadhaar, consents, postApiStatus, errorMessage];
}
