part of 'migration_split_bloc.dart';

@immutable
sealed class MigrationSplitState {}

final class MigrationSplitInitial extends MigrationSplitState {}

final class MigrationSplitUpdating extends MigrationSplitState {}

final class MigrationSplitUpdated extends MigrationSplitState {
  final int updatedCount;
  final int notFoundCount;
  final String? error;

  MigrationSplitUpdated({
    required this.updatedCount,
    required this.notFoundCount,
    this.error,
  });
}
