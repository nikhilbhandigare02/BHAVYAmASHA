import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState()) {
    // Add a method to log state changes
    void logStateChanges(ProfileState oldState, ProfileState newState) {
      if (oldState.stateName != newState.stateName) {
        print('StateName changed from "${oldState.stateName}" to "${newState.stateName}"');
      }
      if (oldState.division != newState.division) {
        print('Division changed from "${oldState.division}" to "${newState.division}"');
      }
      if (oldState.district != newState.district) {
        print('District changed from "${oldState.district}" to "${newState.district}"');
      }
      if (oldState.block != newState.block) {
        print('Block changed from "${oldState.block}" to "${newState.block}"');
      }
    }

    // Individual event handlers with logging
    on<StateChanged>((event, emit) {
      print('Processing StateChanged event: ${event.value}');
      final newState = state.copyWith(stateName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DivisionChanged>((event, emit) {
      print('Processing DivisionChanged event: ${event.value}');
      final newState = state.copyWith(division: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DistrictChanged>((event, emit) {
      print('Processing DistrictChanged event: ${event.value}');
      final newState = state.copyWith(district: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<BlockChanged>((event, emit) {
      print('Processing BlockChanged event: ${event.value}');
      final newState = state.copyWith(block: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    // Handle bulk state update - only one handler for UpdateProfileState
    on<UpdateProfileState>((event, emit) {
      print('Processing UpdateProfileState event');
      print('New state values - State: ${event.newState.stateName}, District: ${event.newState.district}');
      logStateChanges(state, event.newState);
      emit(event.newState);
    });
    
    // Other event handlers
    on<ChoNameChanged>((e, emit) => emit(state.copyWith(choName: e.value)));
    on<ChoMobileChanged>((e, emit) => emit(state.copyWith(choMobile: e.value)));
    on<AwwNameChanged>((e, emit) => emit(state.copyWith(awwName: e.value)));
    on<AwwMobileChanged>((e, emit) => emit(state.copyWith(awwMobile: e.value)));
    on<AnganwadiCenterNoChanged>((e, emit) => emit(state.copyWith(anganwadiCenterNo: e.value)));
    on<Anm1NameChanged>((e, emit) => emit(state.copyWith(anm1Name: e.value)));
    on<Anm1MobileChanged>((e, emit) => emit(state.copyWith(anm1Mobile: e.value)));
    on<Anm2NameChanged>((e, emit) => emit(state.copyWith(anm2Name: e.value)));
    on<Anm2MobileChanged>((e, emit) => emit(state.copyWith(anm2Mobile: e.value)));
    on<BcmNameChanged>((e, emit) => emit(state.copyWith(bcmName: e.value)));
    on<BcmMobileChanged>((e, emit) => emit(state.copyWith(bcmMobile: e.value)));
    on<DcmNameChanged>((e, emit) => emit(state.copyWith(dcmName: e.value)));
    on<DcmMobileChanged>((e, emit) => emit(state.copyWith(dcmMobile: e.value)));
    on<SubmitProfile>(_onSubmit);
  }

  Future<void> _onSubmit(SubmitProfile event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(submitting: true, success: false, error: null));
    try {
      // Placeholder for API call or persistence.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(submitting: false, success: true));
    } catch (e) {
      emit(state.copyWith(submitting: false, success: false, error: e.toString()));
    }
  }
}
