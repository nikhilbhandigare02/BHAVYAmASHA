part of 'reset_password_bloc.dart';

class ResetPasswordState extends Equatable{

  const ResetPasswordState({
    this.username = '',
    this.currentPassword = '',
    this.newPasswordPassword = '',
    this.reEnterPassword = '',
    this.error = '',
    this.postApiStatus = PostApiStatus.initial,
});
  final String username;
  final String currentPassword ;
  final String newPasswordPassword ;
  final String reEnterPassword ;
  final String error ;
  final PostApiStatus postApiStatus;

  ResetPasswordState copyWith({
    String? username,
    String?currentPassword,
    String?reEnterPassword,
    String?newPasswordPassword,
    String?error,
    PostApiStatus? postApiStatus
  }){
    return ResetPasswordState(
        username: username ?? this.username,
        currentPassword: currentPassword ?? this.currentPassword,
        reEnterPassword: reEnterPassword ?? this.reEnterPassword,
        newPasswordPassword: newPasswordPassword ?? this.newPasswordPassword,
        error: error ?? this.error,
        postApiStatus: postApiStatus ?? this.postApiStatus
    );
  }
  @override
  List<Object?> get props => [username, currentPassword, reEnterPassword, newPasswordPassword, postApiStatus, error];

}
