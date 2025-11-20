/// token : "eyJhbGciOiJA"
/// expiresIn : 1800
/// refreshToken : "eyJhbGciOiJSUzUxMiJ"
/// refreshExpiresIn : 1296000
/// switchProfileEnabled : true
/// status_code : 200
/// request-id : "fbc67dcc-95ee-48a2-a3d7-b3c7c079016c"

class ExistingMobileAbha {
  ExistingMobileAbha({
      String? token, 
      num? expiresIn, 
      String? refreshToken, 
      num? refreshExpiresIn, 
      bool? switchProfileEnabled, 
      num? statusCode, 
      String? requestid,}){
    _token = token;
    _expiresIn = expiresIn;
    _refreshToken = refreshToken;
    _refreshExpiresIn = refreshExpiresIn;
    _switchProfileEnabled = switchProfileEnabled;
    _statusCode = statusCode;
    _requestid = requestid;
}

  ExistingMobileAbha.fromJson(dynamic json) {
    _token = json['token'];
    _expiresIn = json['expiresIn'];
    _refreshToken = json['refreshToken'];
    _refreshExpiresIn = json['refreshExpiresIn'];
    _switchProfileEnabled = json['switchProfileEnabled'];
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
  }
  String? _token;
  num? _expiresIn;
  String? _refreshToken;
  num? _refreshExpiresIn;
  bool? _switchProfileEnabled;
  num? _statusCode;
  String? _requestid;
ExistingMobileAbha copyWith({  String? token,
  num? expiresIn,
  String? refreshToken,
  num? refreshExpiresIn,
  bool? switchProfileEnabled,
  num? statusCode,
  String? requestid,
}) => ExistingMobileAbha(  token: token ?? _token,
  expiresIn: expiresIn ?? _expiresIn,
  refreshToken: refreshToken ?? _refreshToken,
  refreshExpiresIn: refreshExpiresIn ?? _refreshExpiresIn,
  switchProfileEnabled: switchProfileEnabled ?? _switchProfileEnabled,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get token => _token;
  num? get expiresIn => _expiresIn;
  String? get refreshToken => _refreshToken;
  num? get refreshExpiresIn => _refreshExpiresIn;
  bool? get switchProfileEnabled => _switchProfileEnabled;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['token'] = _token;
    map['expiresIn'] = _expiresIn;
    map['refreshToken'] = _refreshToken;
    map['refreshExpiresIn'] = _refreshExpiresIn;
    map['switchProfileEnabled'] = _switchProfileEnabled;
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    return map;
  }

}