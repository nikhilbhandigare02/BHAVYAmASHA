/// 0 : {"txnId":"71a9a979-b136-4bb4-97de-68b4a2c4b0ae","ABHA":[{"index":1,"ABHANumber":"xx-xxxx-xxxx-0800","name":"Rohit Mohan Chavan","gender":"M","kycVerified":"true","authMethods":["AADHAAR_OTP","AADHAAR_BIO","DEMOGRAPHICS","MOBILE_OTP"]}]}
/// status_code : 200
/// tracking_id : "65d111a4-a1ec-4542-8993-053c8b243bd4"

class SearchAbhaResponse {
  final String txnId;
  final List<AvailableAbhaNumbers> abha;
  final int statusCode;
  final String trackingId;

  SearchAbhaResponse({
    required this.txnId,
    required this.abha,
    required this.statusCode,
    required this.trackingId,
  });

  factory SearchAbhaResponse.fromJson(Map<String, dynamic> json) {
    return SearchAbhaResponse(
      txnId: json["0"]["txnId"],
      abha: (json["0"]["ABHA"] as List<dynamic>)
          .map((e) => AvailableAbhaNumbers.fromJson(e))
          .toList(),
      statusCode: json["status_code"],
      trackingId: json["tracking_id"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "0": {
        "txnId": txnId,
        "ABHA": abha.map((e) => e.toJson()).toList(),
      },
      "status_code": statusCode,
      "tracking_id": trackingId,
    };
  }
}

class AvailableAbhaNumbers {
  final int index;
  final String abhaNumber;
  final String name;
  final String gender;
  final bool kycVerified;
  final List<String> authMethods;

  AvailableAbhaNumbers({
    required this.index,
    required this.abhaNumber,
    required this.name,
    required this.gender,
    required this.kycVerified,
    required this.authMethods,
  });

  factory AvailableAbhaNumbers.fromJson(Map<String, dynamic> json) {
    return AvailableAbhaNumbers(
      index: json["index"],
      abhaNumber: json["ABHANumber"],
      name: json["name"],
      gender: json["gender"],
      kycVerified: json["kycVerified"].toString().toLowerCase() == "true",
      authMethods: List<String>.from(json["authMethods"] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "index": index,
      "ABHANumber": abhaNumber,
      "name": name,
      "gender": gender,
      "kycVerified": kycVerified.toString(),
      "authMethods": authMethods,
    };
  }
}
