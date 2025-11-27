part of 'migration_split_bloc.dart';

@immutable
sealed class MigrationSplitEvent {}

final class PerformSplitUpdateBeneficiaries extends MigrationSplitEvent {
  final String newHouseholdKey;
  final List<String> beneficiaryUniqueKeys;
  final int isSeparated;

  PerformSplitUpdateBeneficiaries({
    required this.newHouseholdKey,
    required this.beneficiaryUniqueKeys,
    this.isSeparated = 1,
  });
}
