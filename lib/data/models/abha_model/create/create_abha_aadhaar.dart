/// txnId : "414aa741-2074-4d69-9283-6cc57c278c51"
/// healthIdNumber : "91-1130-8436-0800"
/// preferredAbhaAddress : "rohitchavan1993@sbx"
/// status_code : 200
/// tracking_id : "6290ce0b-9f89-4e68-a092-491994406155"

class CreateAbhaAadhaar {
  CreateAbhaAadhaar({
      String? txnId, 
      String? healthIdNumber, 
      String? preferredAbhaAddress, 
      num? statusCode, 
      String? trackingId,}){
    _txnId = txnId;
    _healthIdNumber = healthIdNumber;
    _preferredAbhaAddress = preferredAbhaAddress;
    _statusCode = statusCode;
    _trackingId = trackingId;
}

  CreateAbhaAadhaar.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _healthIdNumber = json['healthIdNumber'];
    _preferredAbhaAddress = json['preferredAbhaAddress'];
    _statusCode = json['status_code'];
    _trackingId = json['tracking_id'];
  }
  String? _txnId;
  String? _healthIdNumber;
  String? _preferredAbhaAddress;
  num? _statusCode;
  String? _trackingId;
CreateAbhaAadhaar copyWith({  String? txnId,
  String? healthIdNumber,
  String? preferredAbhaAddress,
  num? statusCode,
  String? trackingId,
}) => CreateAbhaAadhaar(  txnId: txnId ?? _txnId,
  healthIdNumber: healthIdNumber ?? _healthIdNumber,
  preferredAbhaAddress: preferredAbhaAddress ?? _preferredAbhaAddress,
  statusCode: statusCode ?? _statusCode,
  trackingId: trackingId ?? _trackingId,
);
  String? get txnId => _txnId;
  String? get healthIdNumber => _healthIdNumber;
  String? get preferredAbhaAddress => _preferredAbhaAddress;
  num? get statusCode => _statusCode;
  String? get trackingId => _trackingId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['healthIdNumber'] = _healthIdNumber;
    map['preferredAbhaAddress'] = _preferredAbhaAddress;
    map['status_code'] = _statusCode;
    map['tracking_id'] = _trackingId;
    return map;
  }

}