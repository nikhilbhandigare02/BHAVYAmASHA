part of 'track_eligible_couple_bloc.dart';

class TrackEligibleCoupleState extends Equatable {
   final String beneficiaryId;
   final DateTime? visitDate;
   final String financialYear; // derived from visitDate
   final bool? isPregnant; // null = not chosen
   // If pregnant == true
   final DateTime? lmpDate;
   final DateTime? eddDate;
   // If pregnant == false
   final bool? fpAdopting;
   final String? fpMethod;
   final DateTime? fpAdoptionDate;
   final FormStatus status;
   final String? error;

   const TrackEligibleCoupleState({
    required this.beneficiaryId,
    this.visitDate,
    this.financialYear = '',
    this.isPregnant,
    this.lmpDate,
    this.eddDate,
    this.fpAdopting,
    this.fpMethod,
    this.fpAdoptionDate,
    this.status = FormStatus.initial,
    this.error,
   });

   factory TrackEligibleCoupleState.initial({required String beneficiaryId}) => 
      TrackEligibleCoupleState(beneficiaryId: beneficiaryId);

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
     DateTime? visitDate,
     String? financialYear,
     bool? isPregnant,
     DateTime? lmpDate,
     DateTime? eddDate,
     bool? fpAdopting,
     String? fpMethod,
     DateTime? fpAdoptionDate,
     FormStatus? status,
     String? error,
     bool clearError = false,
     bool clearPregnantFields = false,
     bool clearNonPregnantFields = false,
   }) {
     return TrackEligibleCoupleState(
       beneficiaryId: beneficiaryId ?? this.beneficiaryId,
       visitDate: visitDate ?? this.visitDate,
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
     financialYear,
     isPregnant,
     lmpDate,
     eddDate,
     fpAdopting,
     fpMethod,
     fpAdoptionDate,
     status,
     error,
   ];
 }
