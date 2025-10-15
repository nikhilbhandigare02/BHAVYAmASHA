import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'registernewhousehold_event.dart';
part 'registernewhousehold_state.dart';

class RegisterNewHouseholdBloc extends Bloc<RegisternewhouseholdEvent, RegisternewhouseholdState> {
  RegisterNewHouseholdBloc() : super(RegisternewhouseholdInitial()) {
    on<RegisternewhouseholdEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
