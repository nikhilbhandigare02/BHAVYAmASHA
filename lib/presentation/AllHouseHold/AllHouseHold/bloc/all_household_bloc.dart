import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'all_household_event.dart';
part 'all_household_state.dart';

class AllHouseholdBloc extends Bloc<AllHouseholdEvent, AllHouseholdState> {
  AllHouseholdBloc() : super(AllHouseholdInitial()) {
    on<AllHouseholdEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
