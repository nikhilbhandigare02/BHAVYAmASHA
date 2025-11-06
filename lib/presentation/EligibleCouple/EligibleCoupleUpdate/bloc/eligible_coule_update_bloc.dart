import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'eligible_coule_update_event.dart';
part 'eligible_coule_update_state.dart';

class EligibleCouleUpdateBloc
    extends Bloc<EligibleCouleUpdateEvent, EligibleCouleUpdateState> {
  EligibleCouleUpdateBloc() : super(EligibleCouleUpdateState.initial()) {
    on<InitializeForm>(_onInitializeForm);
    on<RegistrationDateChanged>((e, emit) =>
        emit(state.copyWith(registrationDate: e.date, clearError: true)));
    on<RchIdChanged>((e, emit) => emit(state.copyWith(rchId: e.rchId, clearError: true)));
    on<WomanNameChanged>((e, emit) => emit(state.copyWith(womanName: e.name, clearError: true)));
    on<CurrentAgeChanged>((e, emit) => emit(state.copyWith(currentAge: e.age, clearError: true)));
    on<AgeAtMarriageChanged>((e, emit) => emit(state.copyWith(ageAtMarriage: e.age, clearError: true)));
    on<AddressChanged>((e, emit) => emit(state.copyWith(address: e.address, clearError: true)));
    on<WhoseMobileChanged>((e, emit) => emit(state.copyWith(whoseMobile: e.whose, clearError: true)));
    on<MobileNoChanged>((e, emit) => emit(state.copyWith(mobileNo: e.mobile, clearError: true)));
    on<ReligionChanged>((e, emit) => emit(state.copyWith(religion: e.religion, clearError: true)));
    on<CategoryChanged>((e, emit) => emit(state.copyWith(category: e.category, clearError: true)));
    on<TotalChildrenBornChanged>((e, emit) => emit(state.copyWith(totalChildrenBorn: e.value, clearError: true)));
    on<TotalLiveChildrenChanged>((e, emit) => emit(state.copyWith(totalLiveChildren: e.value, clearError: true)));
    on<TotalMaleChildrenChanged>((e, emit) => emit(state.copyWith(totalMaleChildren: e.value, clearError: true)));
    on<TotalFemaleChildrenChanged>((e, emit) => emit(state.copyWith(totalFemaleChildren: e.value, clearError: true)));
    on<YoungestChildAgeChanged>((e, emit) => emit(state.copyWith(youngestChildAge: e.value, clearError: true)));
    on<YoungestChildAgeUnitChanged>((e, emit) =>
        emit(state.copyWith(youngestChildAgeUnit: e.unit, clearError: true)));
    on<YoungestChildGenderChanged>((e, emit) =>
        emit(state.copyWith(youngestChildGender: e.gender, clearError: true)));
    on<SubmitPressed>(_onSubmit);
  }

  void _onInitializeForm(InitializeForm event, Emitter<EligibleCouleUpdateState> emit) {
    final data = event.initialData;
    print('🚀 Initializing form with data: $data');

    try {
      // Log all keys in the incoming data
      print('📋 Available data keys: ${data.keys.join(', ')}');
      emit(state.copyWith(
        // Basic info
        rchId: data['rchId']?.toString() ?? '',
        womanName: data['womanName']?.toString() ?? '',
        currentAge: data['currentAge']?.toString() ?? '',
        ageAtMarriage: data['ageAtMarriage']?.toString() ?? '',
        
        // Address and contact
        address: data['address']?.toString() ?? '',
        whoseMobile: data['whoseMobile']?.toString() ?? 'Self',
        mobileNo: data['mobileNo']?.toString() ?? '',
        
        // Personal details
        religion: data['religion']?.toString() ?? '',
        category: data['category']?.toString() ?? '',
        
        // Children details
        totalChildrenBorn: data['totalChildrenBorn']?.toString() ?? '0',
        totalLiveChildren: data['totalLiveChildren']?.toString() ?? '0',
        totalMaleChildren: data['totalMaleChildren']?.toString() ?? '0',
        totalFemaleChildren: data['totalFemaleChildren']?.toString() ?? '0',
        youngestChildAge: data['youngestChildAge']?.toString() ?? '0',
        youngestChildAgeUnit: data['youngestChildAgeUnit']?.toString() ?? 'Years',
        youngestChildGender: data['youngestChildGender']?.toString() ?? '',
        
        // Set registration date to now if not provided
        registrationDate: data['registrationDate'] != null 
            ? DateTime.tryParse(data['registrationDate']) ?? DateTime.now()
            : DateTime.now(),
      ));
    } catch (e, stackTrace) {
      print('Error initializing form: $e');
      print('Stack trace: $stackTrace');
      // Emit error state if needed
      emit(state.copyWith(
        error: 'Failed to initialize form: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSubmit(
    SubmitPressed event,
    Emitter<EligibleCouleUpdateState> emit,
  ) async {
    if (!state.isValid) {
      emit(state.copyWith(error: 'Please fill required fields', isSubmitting: false));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));
    await Future.delayed(const Duration(milliseconds: 400));
    emit(state.copyWith(isSubmitting: false, isSuccess: true));
  }
}
