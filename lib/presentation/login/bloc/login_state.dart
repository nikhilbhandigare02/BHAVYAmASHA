part of 'login_bloc.dart';

class LoginState extends Equatable{

  const LoginState({
    this.username = '',
    this.password = '',
    this.error = '',
    this.postApiStatus = PostApiStatus.initial,
  });

  final String username;
  final String password ;
  final String error ;
  final PostApiStatus postApiStatus;
  LoginState copyWith({
    String? username,
    String?password,
    String?error,
    PostApiStatus? postApiStatus
  }){
    return LoginState(
        username: username ?? this.username,
        password: password ?? this.password,
        error: error ?? this.error,
        postApiStatus: postApiStatus ?? this.postApiStatus
    );
  }

  List<Object> get props => [username, password, postApiStatus, error];
}

