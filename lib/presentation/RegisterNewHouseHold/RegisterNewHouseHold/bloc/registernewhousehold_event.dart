part of 'registernewhousehold_bloc.dart';

@immutable
sealed class RegisternewhouseholdEvent {}

final class RegisterAddHead extends RegisternewhouseholdEvent {
  final Map<String, String> data;
  RegisterAddHead(this.data);
}

final class RegisterAddMember extends RegisternewhouseholdEvent {
  final Map<String, String> data;
  RegisterAddMember(this.data);
}

final class RegisterReset extends RegisternewhouseholdEvent {}
