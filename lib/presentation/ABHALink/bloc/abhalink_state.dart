part of 'abhalink_bloc.dart';

@immutable
class AbhaLinkState extends Equatable {
  final String? address;
  final bool submitting;
  final bool success;
  final String? errorMessage;

  const AbhaLinkState({
    this.address,
    this.submitting = false,
    this.success = false,
    this.errorMessage,
  });

  AbhaLinkState copyWith({
    String? address,
    bool? submitting,
    bool? success,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AbhaLinkState(
      address: address ?? this.address,
      submitting: submitting ?? this.submitting,
      success: success ?? this.success,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [address, submitting, success, errorMessage];
}

class AbhalinkInitial extends AbhaLinkState {
  const AbhalinkInitial() : super();
}