part of 'migration_split_bloc.dart';

@immutable
sealed class MigrationSplitEvent {}

final class PerformSplitUpdateBeneficiaries extends MigrationSplitEvent {
  final String newHouseholdKey;
  final List<String> beneficiaryUniqueKeys;
  final int isSeparated;
  final String houseNo;

  PerformSplitUpdateBeneficiaries({
    required this.newHouseholdKey,
    required this.beneficiaryUniqueKeys,
    this.isSeparated = 1,
    required this.houseNo,
  });
}
