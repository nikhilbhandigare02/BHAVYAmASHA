import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'migration_split_event.dart';
part 'migration_split_state.dart';

class MigrationSplitBloc extends Bloc<MigrationSplitEvent, MigrationSplitState> {
  MigrationSplitBloc() : super(MigrationSplitInitial()) {
    on<MigrationSplitEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
