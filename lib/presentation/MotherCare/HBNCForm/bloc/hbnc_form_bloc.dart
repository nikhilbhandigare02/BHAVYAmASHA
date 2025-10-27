import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'hbnc_form_event.dart';
part 'hbnc_form_state.dart';

class HbncFormBloc extends Bloc<HbncFormEvent, HbncFormState> {
  HbncFormBloc() : super(HbncFormInitial()) {
    on<HbncFormEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
