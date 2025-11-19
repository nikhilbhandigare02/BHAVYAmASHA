/// txnId : "b08cccd1-57c1-4ca0-aeb4-0998b6fa0add"
/// message : "OTP sent to mobile number ending with ******3158"
/// status_code : 200
/// request-id : "6e2bb805-98bc-4933-8384-02ca275b289e"

class UpdateAadhaarMobile {
  UpdateAadhaarMobile({
      String? txnId, 
      String? message, 
      num? statusCode, 
      String? requestid,}){
    _txnId = txnId;
    _message = message;
    _statusCode = statusCode;
    _requestid = requestid;
}

  UpdateAadhaarMobile.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _message = json['message'];
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
  }
  String? _txnId;
  String? _message;
  num? _statusCode;
  String? _requestid;
UpdateAadhaarMobile copyWith({  String? txnId,
  String? message,
  num? statusCode,
  String? requestid,
}) => UpdateAadhaarMobile(  txnId: txnId ?? _txnId,
  message: message ?? _message,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get txnId => _txnId;
  String? get message => _message;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['message'] = _message;
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    return map;
  }

}