/// sCode : 200
/// sMessage : "Modes fetched successfully"
/// sData : {"healthIdNumber":"91-6166-8803-1734","abhaAddress":"sukrut_hindlekar@sbx","authMethods":["MOBILE_OTP","AADHAAR_OTP"],"blockedAuthMethods":[],"status":"ACTIVE","message":null,"fullName":"Sukrut Dattatray Hindlekar","mobile":"9552045547","status_code":200,"request-id":"9e73351b-c1a1-452c-9d44-e5cab4c82936"}

class FetchModesResponse {
  FetchModesResponse({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  FetchModesResponse.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
FetchModesResponse copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => FetchModesResponse(  sCode: sCode ?? _sCode,
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

/// healthIdNumber : "91-6166-8803-1734"
/// abhaAddress : "sukrut_hindlekar@sbx"
/// authMethods : ["MOBILE_OTP","AADHAAR_OTP"]
/// blockedAuthMethods : []
/// status : "ACTIVE"
/// message : null
/// fullName : "Sukrut Dattatray Hindlekar"
/// mobile : "9552045547"
/// status_code : 200
/// request-id : "9e73351b-c1a1-452c-9d44-e5cab4c82936"

class SData {
  SData({
      String? healthIdNumber, 
      String? abhaAddress, 
      List<String>? authMethods, 
      List<dynamic>? blockedAuthMethods, 
      String? status, 
      dynamic message, 
      String? fullName, 
      String? mobile, 
      num? statusCode, 
      String? requestid,}){
    _healthIdNumber = healthIdNumber;
    _abhaAddress = abhaAddress;
    _authMethods = authMethods;
    _blockedAuthMethods = blockedAuthMethods;
    _status = status;
    _message = message;
    _fullName = fullName;
    _mobile = mobile;
    _statusCode = statusCode;
    _requestid = requestid;
}

  SData.fromJson(dynamic json) {
    _healthIdNumber = json['healthIdNumber'];
    _abhaAddress = json['abhaAddress'];
    _authMethods = json['authMethods'] != null ? json['authMethods'].cast<String>() : [];
    if (json['blockedAuthMethods'] != null) {
      _blockedAuthMethods = [];
      json['blockedAuthMethods'].forEach((v) {
        //_blockedAuthMethods?.add(Dynamic.fromJson(v));
      });
    }
    _status = json['status'];
    _message = json['message'];
    _fullName = json['fullName'];
    _mobile = json['mobile'];
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
  }
  String? _healthIdNumber;
  String? _abhaAddress;
  List<String>? _authMethods;
  List<dynamic>? _blockedAuthMethods;
  String? _status;
  dynamic _message;
  String? _fullName;
  String? _mobile;
  num? _statusCode;
  String? _requestid;
SData copyWith({  String? healthIdNumber,
  String? abhaAddress,
  List<String>? authMethods,
  List<dynamic>? blockedAuthMethods,
  String? status,
  dynamic message,
  String? fullName,
  String? mobile,
  num? statusCode,
  String? requestid,
}) => SData(  healthIdNumber: healthIdNumber ?? _healthIdNumber,
  abhaAddress: abhaAddress ?? _abhaAddress,
  authMethods: authMethods ?? _authMethods,
  blockedAuthMethods: blockedAuthMethods ?? _blockedAuthMethods,
  status: status ?? _status,
  message: message ?? _message,
  fullName: fullName ?? _fullName,
  mobile: mobile ?? _mobile,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get healthIdNumber => _healthIdNumber;
  String? get abhaAddress => _abhaAddress;
  List<String>? get authMethods => _authMethods;
  List<dynamic>? get blockedAuthMethods => _blockedAuthMethods;
  String? get status => _status;
  dynamic get message => _message;
  String? get fullName => _fullName;
  String? get mobile => _mobile;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['healthIdNumber'] = _healthIdNumber;
    map['abhaAddress'] = _abhaAddress;
    map['authMethods'] = _authMethods;
    if (_blockedAuthMethods != null) {
      map['blockedAuthMethods'] = _blockedAuthMethods?.map((v) => v.toJson()).toList();
    }
    map['status'] = _status;
    map['message'] = _message;
    map['fullName'] = _fullName;
    map['mobile'] = _mobile;
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    return map;
  }

}