/// txnId : "6a9950b3-7191-46d2-b0f9-9711b54fc46f"
/// message : "OTP is sent to Mobile number ending with ******3057"
/// status_code : 200
/// tracking_id : "d5255bc1-1a3c-400b-b0c4-653fe7631e49"

class AbhaSelectMode {
  AbhaSelectMode({
      String? txnId, 
      String? message, 
      num? statusCode, 
      String? trackingId,}){
    _txnId = txnId;
    _message = message;
    _statusCode = statusCode;
    _trackingId = trackingId;
}

  AbhaSelectMode.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _message = json['message'];
    _statusCode = json['status_code'];
    _trackingId = json['tracking_id'];
  }
  String? _txnId;
  String? _message;
  num? _statusCode;
  String? _trackingId;
AbhaSelectMode copyWith({  String? txnId,
  String? message,
  num? statusCode,
  String? trackingId,
}) => AbhaSelectMode(  txnId: txnId ?? _txnId,
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