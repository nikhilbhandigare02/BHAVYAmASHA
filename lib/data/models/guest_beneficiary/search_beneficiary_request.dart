class SearchBeneficiaryRequest {
  final String beneficiaryNumber;

  SearchBeneficiaryRequest({
    required this.beneficiaryNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'beneficiary_number': beneficiaryNumber,
    };
  }
}
