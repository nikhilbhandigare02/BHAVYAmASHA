/// sCode : 200
/// sMessage : "OTP sent successfully"
/// sData : {"txnId":"3bfc01c6-a5e7-41f6-9182-8a4368d05482","message":"OTP sent to Aadhaar registered mobile number ending with ******3057","status_code":200,"request-id":"4e033804-9001-46d2-bd0c-da007dea1387","sessionId":"02121157-f124-4c94-9adb-c7d6677a8282"}

class AadhaarSendOtp {
  AadhaarSendOtp({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  AadhaarSendOtp.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
AadhaarSendOtp copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => AadhaarSendOtp(  sCode: sCode ?? _sCode,
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

/// txnId : "3bfc01c6-a5e7-41f6-9182-8a4368d05482"
/// message : "OTP sent to Aadhaar registered mobile number ending with ******3057"
/// status_code : 200
/// request-id : "4e033804-9001-46d2-bd0c-da007dea1387"
/// sessionId : "02121157-f124-4c94-9adb-c7d6677a8282"

class SData {
  SData({
      String? txnId, 
      String? message, 
      num? statusCode, 
      String? requestid, 
      String? sessionId,}){
    _txnId = txnId;
    _message = message;
    _statusCode = statusCode;
    _requestid = requestid;
    _sessionId = sessionId;
}

  SData.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _message = json['message'];
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
    _sessionId = json['sessionId'];
  }
  String? _txnId;
  String? _message;
  num? _statusCode;
  String? _requestid;
  String? _sessionId;
SData copyWith({  String? txnId,
  String? message,
  num? statusCode,
  String? requestid,
  String? sessionId,
}) => SData(  txnId: txnId ?? _txnId,
  message: message ?? _message,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
  sessionId: sessionId ?? _sessionId,
);
  String? get txnId => _txnId;
  String? get message => _message;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;
  String? get sessionId => _sessionId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['message'] = _message;
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    map['sessionId'] = _sessionId;
    return map;
  }

}