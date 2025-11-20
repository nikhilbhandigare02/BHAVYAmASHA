/// txnId : "{{txnId}}"
/// message : "OTP Verified Successfully"
/// authResult : "success"
/// users : [{"abhaAddress":"ganesh12321@sbx","fullName":"Ganesh Uddhav Chavan","abhaNumber":"91-4281-1522-0611","status":"ACTIVE","kycStatus":"VERIFIED"},{"abhaAddress":"maheshtest56@sbx","fullName":"MAHESWAR SAHOO","abhaNumber":"91-4487-5718-6334","status":"ACTIVE","kycStatus":"VERIFIED"}]
/// tokens : {"token":"<token>","expiresIn":300,"switchProfileEnabled":false}
/// status_code : 200
/// request-id : "532bc91e-90e6-4ce5-bd4b-635c4b10fae2"

class VerifyOtpMobile {
  VerifyOtpMobile({
      String? txnId, 
      String? message, 
      String? authResult, 
      List<Users>? users, 
      Tokens? tokens, 
      num? statusCode, 
      String? requestid,}){
    _txnId = txnId;
    _message = message;
    _authResult = authResult;
    _users = users;
    _tokens = tokens;
    _statusCode = statusCode;
    _requestid = requestid;
}

  VerifyOtpMobile.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _message = json['message'];
    _authResult = json['authResult'];
    if (json['users'] != null) {
      _users = [];
      json['users'].forEach((v) {
        _users?.add(Users.fromJson(v));
      });
    }
    _tokens = json['tokens'] != null ? Tokens.fromJson(json['tokens']) : null;
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
  }
  String? _txnId;
  String? _message;
  String? _authResult;
  List<Users>? _users;
  Tokens? _tokens;
  num? _statusCode;
  String? _requestid;
VerifyOtpMobile copyWith({  String? txnId,
  String? message,
  String? authResult,
  List<Users>? users,
  Tokens? tokens,
  num? statusCode,
  String? requestid,
}) => VerifyOtpMobile(  txnId: txnId ?? _txnId,
  message: message ?? _message,
  authResult: authResult ?? _authResult,
  users: users ?? _users,
  tokens: tokens ?? _tokens,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get txnId => _txnId;
  String? get message => _message;
  String? get authResult => _authResult;
  List<Users>? get users => _users;
  Tokens? get tokens => _tokens;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['message'] = _message;
    map['authResult'] = _authResult;
    if (_users != null) {
      map['users'] = _users?.map((v) => v.toJson()).toList();
    }
    if (_tokens != null) {
      map['tokens'] = _tokens?.toJson();
    }
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    return map;
  }

}

/// token : "<token>"
/// expiresIn : 300
/// switchProfileEnabled : false

class Tokens {
  Tokens({
      String? token, 
      num? expiresIn, 
      bool? switchProfileEnabled,}){
    _token = token;
    _expiresIn = expiresIn;
    _switchProfileEnabled = switchProfileEnabled;
}

  Tokens.fromJson(dynamic json) {
    _token = json['token'];
    _expiresIn = json['expiresIn'];
    _switchProfileEnabled = json['switchProfileEnabled'];
  }
  String? _token;
  num? _expiresIn;
  bool? _switchProfileEnabled;
Tokens copyWith({  String? token,
  num? expiresIn,
  bool? switchProfileEnabled,
}) => Tokens(  token: token ?? _token,
  expiresIn: expiresIn ?? _expiresIn,
  switchProfileEnabled: switchProfileEnabled ?? _switchProfileEnabled,
);
  String? get token => _token;
  num? get expiresIn => _expiresIn;
  bool? get switchProfileEnabled => _switchProfileEnabled;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['token'] = _token;
    map['expiresIn'] = _expiresIn;
    map['switchProfileEnabled'] = _switchProfileEnabled;
    return map;
  }

}

/// abhaAddress : "ganesh12321@sbx"
/// fullName : "Ganesh Uddhav Chavan"
/// abhaNumber : "91-4281-1522-0611"
/// status : "ACTIVE"
/// kycStatus : "VERIFIED"

class Users {
  Users({
      String? abhaAddress, 
      String? fullName, 
      String? abhaNumber, 
      String? status, 
      String? kycStatus,}){
    _abhaAddress = abhaAddress;
    _fullName = fullName;
    _abhaNumber = abhaNumber;
    _status = status;
    _kycStatus = kycStatus;
}

  Users.fromJson(dynamic json) {
    _abhaAddress = json['abhaAddress'];
    _fullName = json['fullName'];
    _abhaNumber = json['abhaNumber'];
    _status = json['status'];
    _kycStatus = json['kycStatus'];
  }
  String? _abhaAddress;
  String? _fullName;
  String? _abhaNumber;
  String? _status;
  String? _kycStatus;
Users copyWith({  String? abhaAddress,
  String? fullName,
  String? abhaNumber,
  String? status,
  String? kycStatus,
}) => Users(  abhaAddress: abhaAddress ?? _abhaAddress,
  fullName: fullName ?? _fullName,
  abhaNumber: abhaNumber ?? _abhaNumber,
  status: status ?? _status,
  kycStatus: kycStatus ?? _kycStatus,
);
  String? get abhaAddress => _abhaAddress;
  String? get fullName => _fullName;
  String? get abhaNumber => _abhaNumber;
  String? get status => _status;
  String? get kycStatus => _kycStatus;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['abhaAddress'] = _abhaAddress;
    map['fullName'] = _fullName;
    map['abhaNumber'] = _abhaNumber;
    map['status'] = _status;
    map['kycStatus'] = _kycStatus;
    return map;
  }

}