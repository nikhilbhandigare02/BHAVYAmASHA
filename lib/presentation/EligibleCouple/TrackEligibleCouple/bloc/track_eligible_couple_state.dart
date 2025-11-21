part of 'track_eligible_couple_bloc.dart';

class TrackEligibleCoupleState extends Equatable {
  final String beneficiaryId;
  final String? beneficiaryRefKey;
  final DateTime? visitDate;
  final DateTime? removalDAteChange;
  final DateTime? antraInjectionDateChanged;
  final String financialYear; // derived from visitDate
  final bool? isPregnant; // null = not chosen
  final bool? beneficiaryAbsentCHanged; // null = not chosen
  // If pregnant == true
  final DateTime? lmpDate;
  final DateTime? eddDate;
  // If pregnant == false
  final bool? fpAdopting;
  final String? fpMethod;
  final String? ecp;
  final String? chhaya;
  final String? condom;
  final String? mala;
  final String? removalReasonChanged;
  final String? beneficiaryAbsentReason;
  final DateTime? fpAdoptionDate;
  final FormStatus status;
  final String? error;

  const TrackEligibleCoupleState({
    required this.beneficiaryId,
    this.beneficiaryRefKey,
    this.visitDate,
    this.removalDAteChange,
    this.antraInjectionDateChanged,
    this.beneficiaryAbsentCHanged,
    this.financialYear = '',
    this.removalReasonChanged,
    this.isPregnant,
    this.lmpDate,
    this.eddDate,
    this.fpAdopting,
    this.fpMethod,
    this.ecp,
    this.chhaya,
    this.condom,
    this.mala,
    this.fpAdoptionDate,
    this.status = FormStatus.initial,
    this.error,
    this.beneficiaryAbsentReason,
  });

  factory TrackEligibleCoupleState.initial({
    required String beneficiaryId,
    String? beneficiaryRefKey,
    bool isProtected = false,
    Map<String, dynamic>? previousFormData,
  }) {
    final now = DateTime.now();
    final financialYear = now.month >= 4
        ? '${now.year}-${(now.year + 1).toString().substring(2)}'
        : '${now.year - 1}-${now.year.toString().substring(2)}';

    if (previousFormData != null) {
      // Parse previous form data if available
      final formData = previousFormData['form_data'] as Map<String, dynamic>? ?? {};
      return TrackEligibleCoupleState(
        beneficiaryId: beneficiaryId,
        beneficiaryRefKey: beneficiaryRefKey,
        visitDate: now,
        financialYear: formData['financial_year']?.toString() ?? financialYear,
        isPregnant: formData['is_pregnant'] as bool?,
        lmpDate: formData['lmp_date'] != null ? DateTime.parse(formData['lmp_date']) : null,
        eddDate: formData['edd_date'] != null ? DateTime.parse(formData['edd_date']) : null,
        fpAdopting: formData['fp_adopting'] as bool? ?? isProtected,
        fpMethod: formData['fp_method']?.toString(),
        condom: formData['condom_quantity']?.toString(),
        mala: formData['mala_quantity']?.toString(),
        chhaya: formData['chhaya_quantity']?.toString(),
        ecp: formData['ecp_quantity']?.toString(),
        removalReasonChanged: formData['removal_reason']?.toString(),
        beneficiaryAbsentReason: formData['beneficiary_absent_reason']?.toString(),
        fpAdoptionDate: formData['fp_adoption_date'] != null
            ? DateTime.parse(formData['fp_adoption_date'])
            : null,
        antraInjectionDateChanged: formData['antra_injection_date'] != null
            ? DateTime.parse(formData['antra_injection_date'])
            : null,
      );
    }

    return TrackEligibleCoupleState(
      beneficiaryId: beneficiaryId,
      beneficiaryRefKey: beneficiaryRefKey,
      visitDate: now,
      financialYear: financialYear,
      fpAdopting: isProtected,
    );
  }

  bool get isValid {
    if (visitDate == null || financialYear.isEmpty || isPregnant == null) return false;
    if (isPregnant == true) {
      return lmpDate != null && eddDate != null;
    } else {
      // Require decision on adopting
      if (fpAdopting == null) return false;
      if (fpAdopting == true) {
        return (fpMethod != null && fpMethod!.isNotEmpty);
      }
      return true;
    }
  }

  TrackEligibleCoupleState copyWith({
    String? beneficiaryId,
    String? beneficiaryRefKey,
    DateTime? visitDate,
    DateTime? removalDAteChange,
    DateTime? antraInjectionDateChanged,
    String? financialYear,
    bool? isPregnant,
    bool? beneficiaryAbsentCHanged,
    DateTime? lmpDate,
    DateTime? eddDate,
    bool? fpAdopting,
    String? fpMethod,
    String? ecp,
    String? chhaya,
    String? condom,
    String? mala,
    String? removalReasonChanged,
    String? beneficiaryAbsentReason,
    DateTime? fpAdoptionDate,
    FormStatus? status,
    String? error,
    bool clearError = false,
    bool clearPregnantFields = false,
    bool clearNonPregnantFields = false,
  }) {
    return TrackEligibleCoupleState(
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      beneficiaryRefKey: beneficiaryRefKey ?? this.beneficiaryRefKey,
      visitDate: visitDate ?? this.visitDate,
      chhaya: chhaya ?? this.chhaya,
      ecp: ecp ?? this.ecp,
      condom: condom ?? this.condom,
      mala: mala ?? this.mala,
      removalReasonChanged: removalReasonChanged ?? this.removalReasonChanged,
      beneficiaryAbsentReason: beneficiaryAbsentReason ?? this.beneficiaryAbsentReason,
      removalDAteChange: removalDAteChange ?? this.removalDAteChange,
      beneficiaryAbsentCHanged: beneficiaryAbsentCHanged ?? this.beneficiaryAbsentCHanged,
      antraInjectionDateChanged: antraInjectionDateChanged ?? this.antraInjectionDateChanged,
      financialYear: financialYear ?? this.financialYear,
      isPregnant: isPregnant ?? this.isPregnant,
      lmpDate: clearPregnantFields ? null : (lmpDate ?? this.lmpDate),
      eddDate: clearPregnantFields ? null : (eddDate ?? this.eddDate),
      fpAdopting: clearNonPregnantFields ? null : (fpAdopting ?? this.fpAdopting),
      fpMethod: clearNonPregnantFields ? null : (fpMethod ?? this.fpMethod),
      fpAdoptionDate: clearNonPregnantFields ? null : (fpAdoptionDate ?? this.fpAdoptionDate),
      status: status ?? (isValid ? FormStatus.valid : this.status),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    beneficiaryId,
    visitDate,
    removalDAteChange,
    financialYear,
    isPregnant,
    antraInjectionDateChanged,
    lmpDate,
    eddDate,
    mala,
    ecp,
    condom,
    chhaya,
    fpAdopting,
    fpMethod,
    beneficiaryAbsentCHanged,
    beneficiaryAbsentReason,
    fpAdoptionDate,
    status,
    removalReasonChanged,
    error,
  ];
}