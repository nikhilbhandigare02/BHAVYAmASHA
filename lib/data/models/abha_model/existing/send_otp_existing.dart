/// txnId : "944f55ed-d8a0-4c14-ad46-868a27948124"
/// message : "OTP sent to mobile number ending with ******3057"
/// status_code : 200
/// tracking_id : "e7e7aeda-1be5-47cd-ae22-e12c16187462"

class SendOtpExisting {
  SendOtpExisting({
      String? txnId, 
      String? message, 
      num? statusCode, 
      String? trackingId,}){
    _txnId = txnId;
    _message = message;
    _statusCode = statusCode;
    _trackingId = trackingId;
}

  SendOtpExisting.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _message = json['message'];
    _statusCode = json['status_code'];
    _trackingId = json['tracking_id'];
  }
  String? _txnId;
  String? _message;
  num? _statusCode;
  String? _trackingId;
SendOtpExisting copyWith({  String? txnId,
  String? message,
  num? statusCode,
  String? trackingId,
}) => SendOtpExisting(  txnId: txnId ?? _txnId,
  message: message ?? _message,
  statusCode: statusCode ?? _statusCode,
  trackingId: trackingId ?? _trackingId,
);
  String? get txnId => _txnId;
  String? get message => _message;
  num? get statusCode => _statusCode;
  String? get trackingId => _trackingId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['message'] = _message;
    map['status_code'] = _statusCode;
    map['tracking_id'] = _trackingId;
    return map;
  }

}