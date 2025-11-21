class SearchBeneficiaryResponse {
  final bool success;
  final String? message;
  final dynamic data;

  SearchBeneficiaryResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory SearchBeneficiaryResponse.fromJson(Map<String, dynamic> json) {
    return SearchBeneficiaryResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
    );
  }
}
