/// healthIdNumber : "91-6835-7556-6628"
/// abhaAddress : "rohit_72607@abdm"
/// authMethods : ["AADHAAR_OTP","MOBILE_OTP"]
/// status : "ACTIVE"
/// message : null
/// fullName : "Rohit Mohan Chavan"
/// mobile : "9702713057"
/// status_code : 200
/// tracking_id : "2fa51f62-c40f-43a5-b4fa-17be24e57494"

class AbhaFetchModes {
  AbhaFetchModes({
      String? healthIdNumber, 
      String? abhaAddress, 
      List<String>? authMethods, 
      String? status, 
      dynamic message, 
      String? fullName, 
      String? mobile, 
      num? statusCode, 
      String? trackingId,}){
    _healthIdNumber = healthIdNumber;
    _abhaAddress = abhaAddress;
    _authMethods = authMethods;
    _status = status;
    _message = message;
    _fullName = fullName;
    _mobile = mobile;
    _statusCode = statusCode;
    _trackingId = trackingId;
}

  AbhaFetchModes.fromJson(dynamic json) {
    _healthIdNumber = json['healthIdNumber'];
    _abhaAddress = json['abhaAddress'];
    _authMethods = json['authMethods'] != null ? json['authMethods'].cast<String>() : [];
    _status = json['status'];
    _message = json['message'];
    _fullName = json['fullName'];
    _mobile = json['mobile'];
    _statusCode = json['status_code'];
    _trackingId = json['tracking_id'];
  }
  String? _healthIdNumber;
  String? _abhaAddress;
  List<String>? _authMethods;
  String? _status;
  dynamic _message;
  String? _fullName;
  String? _mobile;
  num? _statusCode;
  String? _trackingId;
AbhaFetchModes copyWith({  String? healthIdNumber,
  String? abhaAddress,
  List<String>? authMethods,
  String? status,
  dynamic message,
  String? fullName,
  String? mobile,
  num? statusCode,
  String? trackingId,
}) => AbhaFetchModes(  healthIdNumber: healthIdNumber ?? _healthIdNumber,
  abhaAddress: abhaAddress ?? _abhaAddress,
  authMethods: authMethods ?? _authMethods,
  status: status ?? _status,
  message: message ?? _message,
  fullName: fullName ?? _fullName,
  mobile: mobile ?? _mobile,
  statusCode: statusCode ?? _statusCode,
  trackingId: trackingId ?? _trackingId,
);
  String? get healthIdNumber => _healthIdNumber;
  String? get abhaAddress => _abhaAddress;
  List<String>? get authMethods => _authMethods;
  String? get status => _status;
  dynamic get message => _message;
  String? get fullName => _fullName;
  String? get mobile => _mobile;
  num? get statusCode => _statusCode;
  String? get trackingId => _trackingId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['healthIdNumber'] = _healthIdNumber;
    map['abhaAddress'] = _abhaAddress;
    map['authMethods'] = _authMethods;
    map['status'] = _status;
    map['message'] = _message;
    map['fullName'] = _fullName;
    map['mobile'] = _mobile;
    map['status_code'] = _statusCode;
    map['tracking_id'] = _trackingId;
    return map;
  }

}