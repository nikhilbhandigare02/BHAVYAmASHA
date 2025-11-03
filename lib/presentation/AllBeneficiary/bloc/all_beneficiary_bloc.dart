import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'all_beneficiary_event.dart';
part 'all_beneficiary_state.dart';

class AllBeneficiaryBloc extends Bloc<AllBeneficiaryEvent, AllBeneficiaryState> {
  AllBeneficiaryBloc() : super(AllBeneficiaryInitial()) {
    on<AllBeneficiaryEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
