part of 'registernewhousehold_bloc.dart';

@immutable
class RegisterHouseholdState {
  final bool headAdded;
  final int totalMembers;
  final List<Map<String, String>> members;
  final bool isSaving;
  final bool isSaved;
  final String? error;
  final int unmarriedMemberCount;
  final int remainingChildrenCount;

  const RegisterHouseholdState({
    this.headAdded = false,
    this.totalMembers = 0,
    this.members = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.error,
    this.unmarriedMemberCount = 0,
    this.remainingChildrenCount = 0, // Start with count of 0 for children
  });

  RegisterHouseholdState copyWith({
    bool? headAdded,
    int? totalMembers,
    List<Map<String, String>>? members,
    bool? isSaving,
    bool? isSaved,
    String? error,
    int? unmarriedMemberCount,
    int? remainingChildrenCount,
  }) {
    return RegisterHouseholdState(
      headAdded: headAdded ?? this.headAdded,
      totalMembers: totalMembers ?? this.totalMembers,
      members: members ?? this.members,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      error: error,
      unmarriedMemberCount: unmarriedMemberCount ?? this.unmarriedMemberCount,
      remainingChildrenCount: remainingChildrenCount ?? this.remainingChildrenCount,
    );
  }

  // Helper methods for state transitions
  RegisterHouseholdState saving() => copyWith(isSaving: true, isSaved: false, error: null);
  RegisterHouseholdState saved() => copyWith(isSaving: false, isSaved: true);
  RegisterHouseholdState saveFailed(String error) => copyWith(
        isSaving: false,
        isSaved: false,
        error: error,
      );
}
