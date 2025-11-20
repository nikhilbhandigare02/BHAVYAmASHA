/// sCode : 200
/// sMessage : "ABHA address created successfully"
/// sData : {"txnId":"2df6e071-1435-4312-af91-b8c1c67204b6","healthIdNumber":"91-1130-8436-0800","preferredAbhaAddress":"rohit_chavan@sbx","status_code":200,"request-id":"3141a3e3-8e0d-4447-b0ed-299bc929d764"}

class CreateAadhaarResponse {
  CreateAadhaarResponse({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  CreateAadhaarResponse.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
CreateAadhaarResponse copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => CreateAadhaarResponse(  sCode: sCode ?? _sCode,
  sMessage: sMessage ?? _sMessage,
  sData: sData ?? _sData,
);
  num? get sCode => _sCode;
  String? get sMessage => _sMessage;
  SData? get sData => _sData;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['sCode'] = _sCode;
    map['sMessage'] = _sMessage;
    if (_sData != null) {
      map['sData'] = _sData?.toJson();
    }
    return map;
  }

}

/// txnId : "2df6e071-1435-4312-af91-b8c1c67204b6"
/// healthIdNumber : "91-1130-8436-0800"
/// preferredAbhaAddress : "rohit_chavan@sbx"
/// status_code : 200
/// request-id : "3141a3e3-8e0d-4447-b0ed-299bc929d764"

class SData {
  SData({
      String? txnId, 
      String? healthIdNumber, 
      String? preferredAbhaAddress, 
      num? statusCode, 
      String? requestid,}){
    _txnId = txnId;
    _healthIdNumber = healthIdNumber;
    _preferredAbhaAddress = preferredAbhaAddress;
    _statusCode = statusCode;
    _requestid = requestid;
}

  SData.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _healthIdNumber = json['healthIdNumber'];
    _preferredAbhaAddress = json['preferredAbhaAddress'];
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
  }
  String? _txnId;
  String? _healthIdNumber;
  String? _preferredAbhaAddress;
  num? _statusCode;
  String? _requestid;
SData copyWith({  String? txnId,
  String? healthIdNumber,
  String? preferredAbhaAddress,
  num? statusCode,
  String? requestid,
}) => SData(  txnId: txnId ?? _txnId,
  healthIdNumber: healthIdNumber ?? _healthIdNumber,
  preferredAbhaAddress: preferredAbhaAddress ?? _preferredAbhaAddress,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get txnId => _txnId;
  String? get healthIdNumber => _healthIdNumber;
  String? get preferredAbhaAddress => _preferredAbhaAddress;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['healthIdNumber'] = _healthIdNumber;
    map['preferredAbhaAddress'] = _preferredAbhaAddress;
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    return map;
  }

}