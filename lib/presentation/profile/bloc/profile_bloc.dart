import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../../../data/Database/User_Info.dart';
part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState()) {

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

    // Individual event handlers
    on<StateChanged>((event, emit) {
      final newState = state.copyWith(stateName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DivisionChanged>((event, emit) {
      final newState = state.copyWith(division: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DistrictChanged>((event, emit) {
      final newState = state.copyWith(district: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<BlockChanged>((event, emit) {
      final newState = state.copyWith(block: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<PanchayatChanged>((event, emit) {
      final newState = state.copyWith(panchayat: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<VillageChanged>((event, emit) {
      final newState = state.copyWith(village: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<TolaChanged>((event, emit) {
      final newState = state.copyWith(tola: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    // Handle bulk state update - only one handler for UpdateProfileState
    on<UpdateProfileState>((event, emit) {
      logStateChanges(state, event.newState);
      emit(event.newState);
    });
    
    // Form field event handlers
    on<AshaIdChanged>((event, emit) {
      final newState = state.copyWith(ashaId: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AshaNameChanged>((event, emit) {
      final newState = state.copyWith(ashaName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<FatherSpouseChanged>((event, emit) {
      final newState = state.copyWith(fatherSpouse: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<MobileChanged>((event, emit) {
      final newState = state.copyWith(mobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AltMobileChanged>((event, emit) {
      final newState = state.copyWith(altMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DobChanged>((event, emit) {
      final newState = state.copyWith(dob: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<HscNameChanged>((event, emit) {
      final newState = state.copyWith(hscName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<HwcNameChanged>((event, emit) {
      final newState = state.copyWith(hwcName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AccountNumberChanged>((event, emit) {
      final newState = state.copyWith(accountNumber: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<IfscChanged>((event, emit) {
      final newState = state.copyWith(ifsc: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<PopulationCoveredChanged>((event, emit) {
      final newState = state.copyWith(populationCovered: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    // Other event handlers
    on<ChoNameChanged>((event, emit) {
      final newState = state.copyWith(choName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<ChoMobileChanged>((event, emit) {
      final newState = state.copyWith(choMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AwwNameChanged>((event, emit) {
      final newState = state.copyWith(awwName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AwwMobileChanged>((event, emit) {
      final newState = state.copyWith(awwMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AnganwadiCenterNoChanged>((event, emit) {
      final newState = state.copyWith(anganwadiCenterNo: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<Anm1NameChanged>((event, emit) {
      final newState = state.copyWith(anm1Name: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<Anm1MobileChanged>((event, emit) {
      final newState = state.copyWith(anm1Mobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<Anm2NameChanged>((event, emit) {
      final newState = state.copyWith(anm2Name: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<Anm2MobileChanged>((event, emit) {
      final newState = state.copyWith(anm2Mobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<BcmNameChanged>((event, emit) {
      final newState = state.copyWith(bcmName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<BcmMobileChanged>((event, emit) {
      final newState = state.copyWith(bcmMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DcmNameChanged>((event, emit) {
      final newState = state.copyWith(dcmName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DcmMobileChanged>((event, emit) {
      final newState = state.copyWith(dcmMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    // Missing event handlers
    on<AreaOfWorkingChanged>((event, emit) {
      final newState = state.copyWith(areaOfWorking: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<MukhiyaNameChanged>((event, emit) {
      final newState = state.copyWith(mukhiyaName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<MukhiyaMobileChanged>((event, emit) {
      final newState = state.copyWith(mukhiyaMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AshaFacilitatorNameChanged>((event, emit) {
      final newState = state.copyWith(ashaFacilitatorName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<AshaFacilitatorMobileChanged>((event, emit) {
      final newState = state.copyWith(ashaFacilitatorMobile: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<FruNameChanged>((event, emit) {
      final newState = state.copyWith(fruName: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<PhcChcChanged>((event, emit) {
      final newState = state.copyWith(phcChc: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<RhSdhDhChanged>((event, emit) {
      final newState = state.copyWith(rhSdhDh: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<DojChanged>((event, emit) {
      final newState = state.copyWith(doj: event.value);
      logStateChanges(state, newState);
      emit(newState);
    });
    
    on<SubmitProfile>(_onSubmit);
  }

  Future<void> _onSubmit(SubmitProfile event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(submitting: true, success: false, error: null));
    try {
      await UserInfo.updatePopulationCovered(state.populationCovered);
      // Placeholder for API call or persistence.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(submitting: false, success: true));
    } catch (e) {
      emit(state.copyWith(submitting: false, success: false, error: e.toString()));
    }
  }
}
