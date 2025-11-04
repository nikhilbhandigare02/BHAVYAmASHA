part of 'registernewhousehold_bloc.dart';

@immutable
class RegisterHouseholdState {
  final bool headAdded;
  final int totalMembers;
  final List<Map<String, String>> members;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const RegisterHouseholdState({
    this.headAdded = false,
    this.totalMembers = 0,
    this.members = const [],
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  RegisterHouseholdState copyWith({
    bool? headAdded,
    int? totalMembers,
    List<Map<String, String>>? members,
    bool? isSaving,
    bool? isSaved,
    String? error,
  }) {
    return RegisterHouseholdState(
      headAdded: headAdded ?? this.headAdded,
      totalMembers: totalMembers ?? this.totalMembers,
      members: members ?? this.members,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      error: error,
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
