part of 'registernewhousehold_bloc.dart';

@immutable
class RegisterHouseholdState {
  final bool headAdded;
  final int totalMembers;
  final List<Map<String, String>> members;

  const RegisterHouseholdState({
    this.headAdded = false,
    this.totalMembers = 0,
    this.members = const [],
  });

  RegisterHouseholdState copyWith({
    bool? headAdded,
    int? totalMembers,
    List<Map<String, String>>? members,
  }) {
    return RegisterHouseholdState(
      headAdded: headAdded ?? this.headAdded,
      totalMembers: totalMembers ?? this.totalMembers,
      members: members ?? this.members,
    );
  }
}
