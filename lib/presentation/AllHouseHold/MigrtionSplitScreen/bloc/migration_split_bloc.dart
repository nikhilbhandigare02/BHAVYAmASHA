import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:medixcel_new/data/Database/local_storage_dao.dart';

part 'migration_split_event.dart';
part 'migration_split_state.dart';

class MigrationSplitBloc extends Bloc<MigrationSplitEvent, MigrationSplitState> {
  MigrationSplitBloc() : super(MigrationSplitInitial()) {
    on<PerformSplitUpdateBeneficiaries>(_onPerformSplitUpdateBeneficiaries);
  }

  Future<void> _onPerformSplitUpdateBeneficiaries(
    PerformSplitUpdateBeneficiaries event,
    Emitter<MigrationSplitState> emit,
  ) async {
    emit(MigrationSplitUpdating());
    int updated = 0;
    int notFound = 0;
    try {
      for (final uk in event.beneficiaryUniqueKeys.toSet()) {
        if (uk.isEmpty) continue;
        try {
          final row = await LocalStorageDao.instance.getBeneficiaryByUniqueKey(uk);
          if (row == null || row.isEmpty) {
            notFound++;
            continue;
          }
          final updatedRow = Map<String, dynamic>.from(row);
          updatedRow['household_ref_key'] = event.newHouseholdKey;
          updatedRow['is_separated'] = event.isSeparated;
          await LocalStorageDao.instance.updateBeneficiary(updatedRow);
          updated++;
        } catch (_) {
          notFound++;
        }
      }
      emit(MigrationSplitUpdated(updatedCount: updated, notFoundCount: notFound));
    } catch (e) {
      emit(MigrationSplitUpdated(updatedCount: updated, notFoundCount: notFound, error: e.toString()));
    }
  }
}
