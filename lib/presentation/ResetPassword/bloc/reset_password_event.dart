part of 'reset_password_bloc.dart';

abstract class ResetPasswordEvent extends Equatable{
  const ResetPasswordEvent();

  List<Object> get props=>[];
}

class UsernameChanged extends ResetPasswordEvent{
  final String username;
  const UsernameChanged({required this.username});

  List<Object> get props => [username];
}

class CurrentPasswordChange extends ResetPasswordEvent{
  final String currentPassword;
  const CurrentPasswordChange({required this.currentPassword});

  List<Object> get props => [currentPassword];
}
class NewPasswordChange extends ResetPasswordEvent{
  final String newPassword;
  const NewPasswordChange({required this.newPassword});

  List<Object> get props => [newPassword];
}

class ReEnterPasswordChange extends ResetPasswordEvent{
  final String reEnterPassword;
  const ReEnterPasswordChange({required this.reEnterPassword});

  List<Object> get props => [reEnterPassword];
}
class ResetPasswordButton extends ResetPasswordEvent{}

