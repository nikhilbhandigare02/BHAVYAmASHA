import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState()) {
    on<AreaOfWorkingChanged>((e, emit) => emit(state.copyWith(areaOfWorking: e.value)));
    on<AshaIdChanged>((e, emit) => emit(state.copyWith(ashaId: e.value)));
    on<AshaNameChanged>((e, emit) => emit(state.copyWith(ashaName: e.value)));
    on<DobChanged>((e, emit) => emit(state.copyWith(dob: e.value)));
    on<MobileChanged>((e, emit) => emit(state.copyWith(mobile: e.value)));
    on<AltMobileChanged>((e, emit) => emit(state.copyWith(altMobile: e.value)));
    on<FatherSpouseChanged>((e, emit) => emit(state.copyWith(fatherSpouse: e.value)));
    on<DojChanged>((e, emit) => emit(state.copyWith(doj: e.value)));
    on<AccountNumberChanged>((e, emit) => emit(state.copyWith(accountNumber: e.value)));
    on<IfscChanged>((e, emit) => emit(state.copyWith(ifsc: e.value)));
    on<StateChanged>((e, emit) => emit(state.copyWith(stateName: e.value)));
    on<DivisionChanged>((e, emit) => emit(state.copyWith(division: e.value)));
    on<DistrictChanged>((e, emit) => emit(state.copyWith(district: e.value)));
    on<BlockChanged>((e, emit) => emit(state.copyWith(block: e.value)));
    on<PanchayatChanged>((e, emit) => emit(state.copyWith(panchayat: e.value)));
    on<VillageChanged>((e, emit) => emit(state.copyWith(village: e.value)));
    on<TolaChanged>((e, emit) => emit(state.copyWith(tola: e.value)));
    on<MukhiyaNameChanged>((e, emit) => emit(state.copyWith(mukhiyaName: e.value)));
    on<MukhiyaMobileChanged>((e, emit) => emit(state.copyWith(mukhiyaMobile: e.value)));
    on<HwcNameChanged>((e, emit) => emit(state.copyWith(hwcName: e.value)));
    on<HscNameChanged>((e, emit) => emit(state.copyWith(hscName: e.value)));
    on<FruNameChanged>((e, emit) => emit(state.copyWith(fruName: e.value)));
    on<PhcChcChanged>((e, emit) => emit(state.copyWith(phcChc: e.value)));
    on<RhSdhDhChanged>((e, emit) => emit(state.copyWith(rhSdhDh: e.value)));
    on<PopulationCoveredChanged>((e, emit) => emit(state.copyWith(populationCovered: e.value)));
    on<AshaFacilitatorNameChanged>((e, emit) => emit(state.copyWith(ashaFacilitatorName: e.value)));
    on<AshaFacilitatorMobileChanged>((e, emit) => emit(state.copyWith(ashaFacilitatorMobile: e.value)));
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
