part of 'register_child_form_bloc.dart';

class RegisterChildFormState extends Equatable {
  final String rchIdChild;
  final bool isRchIdButtonEnabled;
  final String serialNumber;
  final DateTime? dateOfBirth;
  final DateTime? dateOfRegistration;
  final String childName;
  final String registerSerialNumber;
  final String gender; // Male/Female/Other
  final String motherName;
  final String fatherName;
  final String address;
  final String whoseMobileNumber; // Head of the family/Mother/Father/Other
  final String mobileNumber;
  final String mothersRchIdNumber;
  final String birthCertificateIssued; // Yes/No
  final String birthCertificateNumber;
  final String weightGrams;
  final String birthWeightGrams;
  final String religion;
  final String customReligion;
  final String caste;
  final String customCaste;

  final bool isSubmitting;
  final bool isSuccess;
  final String? error;

  const RegisterChildFormState({
    this.rchIdChild = '',
    this.isRchIdButtonEnabled = false,
    this.serialNumber = '',
    this.registerSerialNumber = '',
    this.dateOfBirth,
    this.dateOfRegistration,
    this.childName = '',
    this.gender = '',
    this.motherName = '',
    this.fatherName = '',
    this.address = '',
    this.whoseMobileNumber = '',
    this.mobileNumber = '',
    this.mothersRchIdNumber = '',
    this.birthCertificateIssued = '',
    this.birthCertificateNumber = '',
    this.weightGrams = '',
    this.birthWeightGrams = '',
    this.religion = '',
    this.customReligion = '',
    this.caste = '',
    this.customCaste = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
  });

  factory RegisterChildFormState.initial() => const RegisterChildFormState();

  RegisterChildFormState copyWith({
    String? rchIdChild,
    bool? isRchIdButtonEnabled,
    String? serialNumber,
    DateTime? dateOfBirth,
    DateTime? dateOfRegistration,
    String? childName,
    String? registerSerialNumber,
    String? gender,
    String? motherName,
    String? fatherName,
    String? address,
    String? whoseMobileNumber,
    String? mobileNumber,
    String? mothersRchIdNumber,
    String? birthCertificateIssued,
    String? birthCertificateNumber,
    String? weightGrams,
    String? birthWeightGrams,
    String? religion,
    String? customReligion,
    String? caste,
    String? customCaste,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return RegisterChildFormState(
      rchIdChild: rchIdChild ?? this.rchIdChild,
      isRchIdButtonEnabled: isRchIdButtonEnabled ?? this.isRchIdButtonEnabled,
      serialNumber: serialNumber ?? this.serialNumber,
      registerSerialNumber: registerSerialNumber ?? this.registerSerialNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfRegistration: dateOfRegistration ?? this.dateOfRegistration,
      childName: childName ?? this.childName,
      gender: gender ?? this.gender,
      motherName: motherName ?? this.motherName,
      fatherName: fatherName ?? this.fatherName,
      address: address ?? this.address,
      whoseMobileNumber: whoseMobileNumber ?? this.whoseMobileNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      mothersRchIdNumber: mothersRchIdNumber ?? this.mothersRchIdNumber,
      birthCertificateIssued: birthCertificateIssued ?? this.birthCertificateIssued,
      birthCertificateNumber: birthCertificateNumber ?? this.birthCertificateNumber,
      weightGrams: weightGrams ?? this.weightGrams,
      birthWeightGrams: birthWeightGrams ?? this.birthWeightGrams,
      religion: religion ?? this.religion,
      customReligion: customReligion ?? this.customReligion,
      caste: caste ?? this.caste,
      customCaste: customCaste ?? this.customCaste,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        rchIdChild,
        isRchIdButtonEnabled,
        serialNumber,
        dateOfBirth,
        dateOfRegistration,
        childName,
        registerSerialNumber,
        gender,
        motherName,
        fatherName,
        address,
        whoseMobileNumber,
        mobileNumber,
        mothersRchIdNumber,
        birthCertificateIssued,
        birthCertificateNumber,
        weightGrams,
        birthWeightGrams,
        religion,
        customReligion,
        caste,
        customCaste,
        isSubmitting,
        isSuccess,
        error,
      ];
}
