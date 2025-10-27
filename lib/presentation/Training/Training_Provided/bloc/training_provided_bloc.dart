import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'training_provided_event.dart';
part 'training_provided_state.dart';

class TrainingProvidedBloc extends Bloc<TrainingProvidedEvent, TrainingProvidedState> {
  TrainingProvidedBloc() : super(TrainingProvidedInitial()) {
    on<TrainingProvidedEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
