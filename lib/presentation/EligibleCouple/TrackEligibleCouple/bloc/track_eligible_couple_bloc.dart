import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart' show FormStatus;

part 'track_eligible_couple_event.dart';
part 'track_eligible_couple_state.dart';

class TrackEligibleCoupleBloc extends Bloc<TrackEligibleCoupleEvent, TrackEligibleCoupleState> {
  TrackEligibleCoupleBloc() : super(TrackEligibleCoupleState.initial()) {
    on<VisitDateChanged>((event, emit) {
      final fy = _deriveFinancialYear(event.date);
      emit(state.copyWith(visitDate: event.date, financialYear: fy, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<IsPregnantChanged>((event, emit) {
      emit(state.copyWith(
        isPregnant: event.isPregnant,
        clearPregnantFields: !event.isPregnant,
        clearNonPregnantFields: event.isPregnant,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<LmpDateChanged>((event, emit) {
      emit(state.copyWith(lmpDate: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<EddDateChanged>((event, emit) {
      emit(state.copyWith(eddDate: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<FpMethodChanged>((event, emit) {
      emit(state.copyWith(fpMethod: event.method, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<FpAdoptingChanged>((event, emit) {
      emit(state.copyWith(
        fpAdopting: event.adopting,
        // If not adopting, clear method/adoption date
        fpMethod: event.adopting == true ? state.fpMethod : null,
        fpAdoptionDate: event.adopting == true ? state.fpAdoptionDate : null,
        status: state.isValid ? FormStatus.valid : FormStatus.initial,
        clearError: true,
      ));
    });

    on<FpAdoptionDateChanged>((event, emit) {
      emit(state.copyWith(fpAdoptionDate: event.date, status: state.isValid ? FormStatus.valid : FormStatus.initial, clearError: true));
    });

    on<SubmitTrackForm>((event, emit) async {
      if (!state.isValid) {
        emit(state.copyWith(status: FormStatus.failure, error: 'Please complete required fields.'));
        return;
      }
      emit(state.copyWith(status: FormStatus.submitting, clearError: true));
      await Future.delayed(const Duration(milliseconds: 600));
      emit(state.copyWith(status: FormStatus.success));
    });
  }

  String _deriveFinancialYear(DateTime? date) {
    if (date == null) return '';
    // Example FY: year portion only as per screenshot
    return date.year.toString();
  }
}
