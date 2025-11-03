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
    
    on<PanchayatChanged>((event, emit) {
      print('Processing PanchayatChanged event: ${event.value}');
      final newState = state.copyWith(panchayat: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<VillageChanged>((event, emit) {
      print('Processing VillageChanged event: ${event.value}');
      final newState = state.copyWith(village: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<TolaChanged>((event, emit) {
      print('Processing TolaChanged event: ${event.value}');
      final newState = state.copyWith(tola: event.value);
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
    
    // Form field event handlers with logging
    on<AshaIdChanged>((event, emit) {
      print('Processing AshaIdChanged event: ${event.value}');
      final newState = state.copyWith(ashaId: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AshaNameChanged>((event, emit) {
      print('Processing AshaNameChanged event: ${event.value}');
      final newState = state.copyWith(ashaName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<FatherSpouseChanged>((event, emit) {
      print('Processing FatherSpouseChanged event: ${event.value}');
      final newState = state.copyWith(fatherSpouse: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<MobileChanged>((event, emit) {
      print('Processing MobileChanged event: ${event.value}');
      final newState = state.copyWith(mobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AltMobileChanged>((event, emit) {
      print('Processing AltMobileChanged event: ${event.value}');
      final newState = state.copyWith(altMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DobChanged>((event, emit) {
      print('Processing DobChanged event: ${event.value}');
      final newState = state.copyWith(dob: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<HscNameChanged>((event, emit) {
      print('Processing HscNameChanged event: ${event.value}');
      final newState = state.copyWith(hscName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<HwcNameChanged>((event, emit) {
      print('Processing HwcNameChanged event: ${event.value}');
      final newState = state.copyWith(hwcName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AccountNumberChanged>((event, emit) {
      print('Processing AccountNumberChanged event: ${event.value}');
      final newState = state.copyWith(accountNumber: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<IfscChanged>((event, emit) {
      print('Processing IfscChanged event: ${event.value}');
      final newState = state.copyWith(ifsc: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<PopulationCoveredChanged>((event, emit) {
      print('Processing PopulationCoveredChanged event: ${event.value}');
      final newState = state.copyWith(populationCovered: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    // Other event handlers
    on<ChoNameChanged>((event, emit) {
      print('Processing ChoNameChanged event: ${event.value}');
      final newState = state.copyWith(choName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<ChoMobileChanged>((event, emit) {
      print('Processing ChoMobileChanged event: ${event.value}');
      final newState = state.copyWith(choMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AwwNameChanged>((event, emit) {
      print('Processing AwwNameChanged event: ${event.value}');
      final newState = state.copyWith(awwName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AwwMobileChanged>((event, emit) {
      print('Processing AwwMobileChanged event: ${event.value}');
      final newState = state.copyWith(awwMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AnganwadiCenterNoChanged>((event, emit) {
      print('Processing AnganwadiCenterNoChanged event: ${event.value}');
      final newState = state.copyWith(anganwadiCenterNo: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<Anm1NameChanged>((event, emit) {
      print('Processing Anm1NameChanged event: ${event.value}');
      final newState = state.copyWith(anm1Name: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<Anm1MobileChanged>((event, emit) {
      print('Processing Anm1MobileChanged event: ${event.value}');
      final newState = state.copyWith(anm1Mobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<Anm2NameChanged>((event, emit) {
      print('Processing Anm2NameChanged event: ${event.value}');
      final newState = state.copyWith(anm2Name: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<Anm2MobileChanged>((event, emit) {
      print('Processing Anm2MobileChanged event: ${event.value}');
      final newState = state.copyWith(anm2Mobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<BcmNameChanged>((event, emit) {
      print('Processing BcmNameChanged event: ${event.value}');
      final newState = state.copyWith(bcmName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<BcmMobileChanged>((event, emit) {
      print('Processing BcmMobileChanged event: ${event.value}');
      final newState = state.copyWith(bcmMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DcmNameChanged>((event, emit) {
      print('Processing DcmNameChanged event: ${event.value}');
      final newState = state.copyWith(dcmName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DcmMobileChanged>((event, emit) {
      print('Processing DcmMobileChanged event: ${event.value}');
      final newState = state.copyWith(dcmMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
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
