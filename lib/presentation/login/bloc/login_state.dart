part of 'login_bloc.dart';

class LoginState extends Equatable{

  const LoginState({
    this.username = '',
    this.password = '',
    this.error = '',
    this.postApiStatus = PostApiStatus.initial,
    this.showValidationErrors = false,
    this.isNewUser = false,
  });

  final String username;
  final String password;
  final String error;
  final PostApiStatus postApiStatus;
  final bool showValidationErrors;
  final bool isNewUser;
  
  LoginState copyWith({
    String? username,
    String? password,
    String? error,
    PostApiStatus? postApiStatus,
    bool? showValidationErrors,
    bool? isNewUser,
  }){
    return LoginState(
        username: username ?? this.username,
        password: password ?? this.password,
        error: error ?? this.error,
        postApiStatus: postApiStatus ?? this.postApiStatus,
        showValidationErrors: showValidationErrors ?? this.showValidationErrors,
        isNewUser: isNewUser ?? this.isNewUser
    );
  }

  List<Object> get props => [username, password, postApiStatus, error, showValidationErrors, isNewUser];
}

