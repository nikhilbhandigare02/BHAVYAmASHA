part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable{
  const LoginEvent();

  List<Object> get props => [];
}

class UsernameChanged extends LoginEvent{
  final String username;
  const UsernameChanged({required this.username});

  List<Object> get props => [username];
}

class PasswordChange extends LoginEvent{
  final String password;
  const PasswordChange({required this.password});

  List<Object> get props => [password];
}

class LoginButton extends LoginEvent{}

