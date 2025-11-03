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

final class SaveHousehold extends RegisternewhouseholdEvent {
  final Map<String, dynamic>? headForm;
  final List<Map<String, dynamic>> memberForms;
  final HouseholdDetailsAmenitiesBloc hhBloc;
  
   SaveHousehold({
    required this.headForm,
    required this.memberForms,
    required this.hhBloc,
  });
}
