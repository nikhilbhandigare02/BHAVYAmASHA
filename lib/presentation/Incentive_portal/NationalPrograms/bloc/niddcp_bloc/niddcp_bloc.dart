import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'niddcp_event.dart';
part 'niddcp_state.dart';

class NiddcpBloc extends Bloc<NiddcpEvent, NiddcpState> {
  NiddcpBloc() : super(const NiddcpState(value: "0", isSaved: false));

  @override
  Stream<NiddcpState> mapEventToState(NiddcpEvent event) async* {
    if (event is UpdateNiddcpValue) {
      yield state.copyWith(value: event.value, isSaved: false);
    } else if (event is SaveNiddcpData) {
      yield state.copyWith(isSaved: true);
    }
  }
}
