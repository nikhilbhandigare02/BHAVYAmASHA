import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'register_child_form_event.dart';
part 'register_child_form_state.dart';

class RegisterChildFormBloc extends Bloc<RegisterChildFormEvent, RegisterChildFormState> {
  RegisterChildFormBloc() : super(RegisterChildFormState.initial()) {
    on<RchIdChildChanged>((e, emit) => emit(state.copyWith(rchIdChild: e.value, clearError: true)));
    on<SerialNumberChanged>((e, emit) => emit(state.copyWith(serialNumber: e.value, clearError: true)));
    on<DateOfBirthChanged>((e, emit) => emit(state.copyWith(dateOfBirth: e.value, clearError: true)));
    on<DateOfRegistrationChanged>((e, emit) => emit(state.copyWith(dateOfRegistration: e.value, clearError: true)));
    on<ChildNameChanged>((e, emit) => emit(state.copyWith(childName: e.value, clearError: true)));
    on<GenderChanged>((e, emit) => emit(state.copyWith(gender: e.value, clearError: true)));
    on<MotherNameChanged>((e, emit) => emit(state.copyWith(motherName: e.value, clearError: true)));
    on<FatherNameChanged>((e, emit) => emit(state.copyWith(fatherName: e.value, clearError: true)));
    on<AddressChanged>((e, emit) => emit(state.copyWith(address: e.value, clearError: true)));
    on<WhoseMobileNumberChanged>((e, emit) => emit(state.copyWith(whoseMobileNumber: e.value, clearError: true)));
    on<MobileNumberChanged>((e, emit) => emit(state.copyWith(mobileNumber: e.value, clearError: true)));
    on<MothersRchIdNumberChanged>((e, emit) => emit(state.copyWith(mothersRchIdNumber: e.value, clearError: true)));
    on<BirthCertificateIssuedChanged>((e, emit) => emit(state.copyWith(birthCertificateIssued: e.value, clearError: true)));
    on<BirthCertificateNumberChanged>((e, emit) => emit(state.copyWith(birthCertificateNumber: e.value, clearError: true)));
    on<WeightGramsChanged>((e, emit) => emit(state.copyWith(weightGrams: e.value, clearError: true)));
    on<ReligionChanged>((e, emit) => emit(state.copyWith(religion: e.value, clearError: true)));
    on<CasteChanged>((e, emit) => emit(state.copyWith(caste: e.value, clearError: true)));
    on<SerialNumberOFRegister>((e, emit) => emit(state.copyWith(registerSerialNumber: e.value, clearError: true)));

    on<SubmitPressed>(_onSubmit);
  }

  void _onSubmit(SubmitPressed event, Emitter<RegisterChildFormState> emit) async {
    // Minimal validation based on screenshots
    final missing = <String>[];
    if (state.dateOfBirth == null) missing.add('Date of Birth');
    if (state.dateOfRegistration == null) missing.add('Date of Registration');
    if (state.childName.isEmpty) missing.add("Child's name");
    if (state.motherName.isEmpty) missing.add("Mother's name");
    if (state.mobileNumber.isEmpty) missing.add('Mobile number');

    if (missing.isNotEmpty) {
      emit(state.copyWith(error: 'Please fill: ' + missing.join(', ')));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true, isSuccess: false));
    await Future.delayed(const Duration(milliseconds: 600));
    emit(state.copyWith(isSubmitting: false, isSuccess: true));
  }
}
