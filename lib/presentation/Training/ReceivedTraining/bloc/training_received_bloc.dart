import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'training_received_event.dart';
part 'training_received_state.dart';

class TrainingReceivedBloc extends Bloc<TrainingReceivedEvent, TrainingReceivedState> {
  TrainingReceivedBloc() : super(TrainingReceivedInitial()) {
    on<TrainingReceivedEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
