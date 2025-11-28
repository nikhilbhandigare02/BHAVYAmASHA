// Update the imports and class in reset_password_state.dart
part of 'reset_password_bloc.dart';

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.username = '',
    this.currentPassword = '',
    this.newPasswordPassword = '',
    this.reEnterPassword = '',
    this.error = '',
    this.successMessage = '',
    this.postApiStatus = PostApiStatus.initial,
  });

  final String username;
  final String currentPassword;
  final String newPasswordPassword;
  final String reEnterPassword;
  final String error;
  final String successMessage;
  final PostApiStatus postApiStatus;

  ResetPasswordState copyWith({
    String? username,
    String? currentPassword,
    String? reEnterPassword,
    String? newPasswordPassword,
    String? error,
    String? successMessage,
    PostApiStatus? postApiStatus,
  }) {
    return ResetPasswordState(
      username: username ?? this.username,
      currentPassword: currentPassword ?? this.currentPassword,
      reEnterPassword: reEnterPassword ?? this.reEnterPassword,
      newPasswordPassword: newPasswordPassword ?? this.newPasswordPassword,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      postApiStatus: postApiStatus ?? this.postApiStatus,
    );
  }

  @override
  List<Object?> get props => [
    username,
    currentPassword,
    reEnterPassword,
    newPasswordPassword,
    error,
    successMessage,
    postApiStatus,
  ];
}