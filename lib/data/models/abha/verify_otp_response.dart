/// sCode : 200
/// sMessage : "OTP verified successfully"
/// sData : {"message":"OTP verified successfully","authResult":"success","users":[{"abhaAddress":"91113084360800@sbx","fullName":"Rohit Mohan Chavan","abhaNumber":"91-1130-8436-0800","status":"ACTIVE","kycStatus":"VERIFIED"}],"tokens":{"token":"eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiI5MTExMzA4NDM2MDgwMEBzYngiLCJjbGllbnRJZCI6IlBUUExfMTYyNjk4IiwicmVxdWVzdGVySWQiOiJBQkhBLVdFQiIsInN5c3RlbSI6IkFCSEEtQSIsIm1vYmlsZSI6Ijk3MDI3MTMwNTciLCJ0eXAiOiJUcmFuc2FjdGlvbiIsImV4cCI6MTczOTI0NjgxNywiaGVhbHRoSWROdW1iZXIiOiI5MS0xMTMwLTg0MzYtMDgwMCIsImlhdCI6MTczOTI0NTAxNywicGhyQWRkcmVzcyI6IjkxMTEzMDg0MzYwODAwQHNieCIsImFiaGFBZGRyZXNzIjoiOTExMTMwODQzNjA4MDBAc2J4IiwidHhuSWQiOiIxZTZhZjM1MS05MGUwLTQyOGUtYmJiYi0wNmUyYWUxYjIxYTgifQ.NNy3JC3lphjjQVJz_frxqOenlAxU_yyd9hnwlCJDbbkirfRcbtH65QNYKKa7r0FqNaIFQKtuRutncznImkfGz6rgNat6aTV8vepdqK9nVrJ8STRQ3-RnZhHCT5kCzcfZ-w9hz1mo-3lGJ46o92jWbwmvJuztb6SnO5eGP8OXlXmplQmXydjgUgcXp9oS17L5WD8UfhyBIQWfLrmFwzdMNNGzGN80VSNKNLYSEb-r99SDNnaeT_tY4VefZ8Jd4Gnglyion1liTS6elfJK6uOqhyWdgDs24uGb_P2mFO6dtM2QSW0_sVXVJu8Y0d5nTl0K0J50-tyvNWNwI6JQKTLp38EMDp6F3WIkvCWLH21INUTo99RD0sFZVzLWtI-YH8zjB5LGBsSf4NY5F5hrCAuoly6c5XWtj43w-7-JFlaYb2xXIZryyncmwphaXfOHJd5-J_hj2iPWSkVzD7X2tD7Et_ZiePyTF-fbod8TBi8XJ8GUboheiKgHlRfq21D4xYkDyicB8-AcpcWQZciiIc6tIAi_vwW-TQN3hGePB_rMl6dycNlYkZCEzqgjMfHgOJzgCerB0Fc6HHGMPtYpAwxvThfPnr9raZQ5anS3yvARSmABh6MWHUmOPkgiLidpoeZWg9rhWcuOImtqElUF9T9DSELJ6zR_tZSq-QWXoF2dm6A","expiresIn":1800,"refreshToken":"eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiI5MTExMzA4NDM2MDgwMEBzYngiLCJjbGllbnRJZCI6IlBUUExfMTYyNjk4Iiwic3lzdGVtIjoiQUJIQS1BIiwidHlwIjoiUmVmcmVzaCIsImV4cCI6MTc0MDU0MTAxNywiaWF0IjoxNzM5MjQ1MDE3fQ.d6Sz3-bINwTGWCFwW6AHdDcCaWV1Q-ACirP0XK99lgKKoyyLJS1oIL24mbloMpGNhAuK6q9LYGAKMXBRWBCQuubeXJda85KHWCIXOWDzYWJe8bZa5BVHVJf99HqX1fXPr3XYwhOJx-P2o3S3wCBzA5srNDalVJCtwLruiBv-wyAFPmveXDmCNSBzwZ-A0_UxENpFf8tWjRs33t-G-ZixAfVtJJRPnADDtFuurX2Q4Sv5-dgF72O_n6JWRGkzdNDrnxJPz3RASEkJR6kXcpOmRJ8CmOMV7xs69lRYdi2jRM_pvdwkb9QUpD-sCAR17DCp--oYchqXdJG9o0JA-GSkv5xesDt92pkF8_ubdAGDEE9sbl0ztgV_OviXQ5hW9gd2I-LlezDQP79NrFXIei0b7MFyl_Aulxlxx6ynBfKLcEl_8TMlwtZjaAB7qBGR8FdPeAVJ938_cFsN6BoejQz0Rv6wZw6NFaibfuSnIDkpGy4ilKCSaXoSuRM5Db-mVkZTKUpv0zl75vBbRtf7fzaL4w7dEi1vXbtMCJ3JXnKeooZDS__srEQezdr2gUoh7JRTpzUg7ZYpIrXOxy96kjKZrkwPctm2SMioQwKgU84cnGshBc9nqW6NeYhor2HgLCuiEtcx59kA3D85MUfR5SAgQ4D2M5yGn869RQ0-jwrxiyM","refreshExpiresIn":1296000,"switchProfileEnabled":false},"status_code":200,"request-id":"7e3f9daa-4eb4-4d60-9554-0d5a0f8377d0"}

class VerifyOtpResponse {
  VerifyOtpResponse({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  VerifyOtpResponse.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
VerifyOtpResponse copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => VerifyOtpResponse(  sCode: sCode ?? _sCode,
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

/// message : "OTP verified successfully"
/// authResult : "success"
/// users : [{"abhaAddress":"91113084360800@sbx","fullName":"Rohit Mohan Chavan","abhaNumber":"91-1130-8436-0800","status":"ACTIVE","kycStatus":"VERIFIED"}]
/// tokens : {"token":"eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiI5MTExMzA4NDM2MDgwMEBzYngiLCJjbGllbnRJZCI6IlBUUExfMTYyNjk4IiwicmVxdWVzdGVySWQiOiJBQkhBLVdFQiIsInN5c3RlbSI6IkFCSEEtQSIsIm1vYmlsZSI6Ijk3MDI3MTMwNTciLCJ0eXAiOiJUcmFuc2FjdGlvbiIsImV4cCI6MTczOTI0NjgxNywiaGVhbHRoSWROdW1iZXIiOiI5MS0xMTMwLTg0MzYtMDgwMCIsImlhdCI6MTczOTI0NTAxNywicGhyQWRkcmVzcyI6IjkxMTEzMDg0MzYwODAwQHNieCIsImFiaGFBZGRyZXNzIjoiOTExMTMwODQzNjA4MDBAc2J4IiwidHhuSWQiOiIxZTZhZjM1MS05MGUwLTQyOGUtYmJiYi0wNmUyYWUxYjIxYTgifQ.NNy3JC3lphjjQVJz_frxqOenlAxU_yyd9hnwlCJDbbkirfRcbtH65QNYKKa7r0FqNaIFQKtuRutncznImkfGz6rgNat6aTV8vepdqK9nVrJ8STRQ3-RnZhHCT5kCzcfZ-w9hz1mo-3lGJ46o92jWbwmvJuztb6SnO5eGP8OXlXmplQmXydjgUgcXp9oS17L5WD8UfhyBIQWfLrmFwzdMNNGzGN80VSNKNLYSEb-r99SDNnaeT_tY4VefZ8Jd4Gnglyion1liTS6elfJK6uOqhyWdgDs24uGb_P2mFO6dtM2QSW0_sVXVJu8Y0d5nTl0K0J50-tyvNWNwI6JQKTLp38EMDp6F3WIkvCWLH21INUTo99RD0sFZVzLWtI-YH8zjB5LGBsSf4NY5F5hrCAuoly6c5XWtj43w-7-JFlaYb2xXIZryyncmwphaXfOHJd5-J_hj2iPWSkVzD7X2tD7Et_ZiePyTF-fbod8TBi8XJ8GUboheiKgHlRfq21D4xYkDyicB8-AcpcWQZciiIc6tIAi_vwW-TQN3hGePB_rMl6dycNlYkZCEzqgjMfHgOJzgCerB0Fc6HHGMPtYpAwxvThfPnr9raZQ5anS3yvARSmABh6MWHUmOPkgiLidpoeZWg9rhWcuOImtqElUF9T9DSELJ6zR_tZSq-QWXoF2dm6A","expiresIn":1800,"refreshToken":"eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiI5MTExMzA4NDM2MDgwMEBzYngiLCJjbGllbnRJZCI6IlBUUExfMTYyNjk4Iiwic3lzdGVtIjoiQUJIQS1BIiwidHlwIjoiUmVmcmVzaCIsImV4cCI6MTc0MDU0MTAxNywiaWF0IjoxNzM5MjQ1MDE3fQ.d6Sz3-bINwTGWCFwW6AHdDcCaWV1Q-ACirP0XK99lgKKoyyLJS1oIL24mbloMpGNhAuK6q9LYGAKMXBRWBCQuubeXJda85KHWCIXOWDzYWJe8bZa5BVHVJf99HqX1fXPr3XYwhOJx-P2o3S3wCBzA5srNDalVJCtwLruiBv-wyAFPmveXDmCNSBzwZ-A0_UxENpFf8tWjRs33t-G-ZixAfVtJJRPnADDtFuurX2Q4Sv5-dgF72O_n6JWRGkzdNDrnxJPz3RASEkJR6kXcpOmRJ8CmOMV7xs69lRYdi2jRM_pvdwkb9QUpD-sCAR17DCp--oYchqXdJG9o0JA-GSkv5xesDt92pkF8_ubdAGDEE9sbl0ztgV_OviXQ5hW9gd2I-LlezDQP79NrFXIei0b7MFyl_Aulxlxx6ynBfKLcEl_8TMlwtZjaAB7qBGR8FdPeAVJ938_cFsN6BoejQz0Rv6wZw6NFaibfuSnIDkpGy4ilKCSaXoSuRM5Db-mVkZTKUpv0zl75vBbRtf7fzaL4w7dEi1vXbtMCJ3JXnKeooZDS__srEQezdr2gUoh7JRTpzUg7ZYpIrXOxy96kjKZrkwPctm2SMioQwKgU84cnGshBc9nqW6NeYhor2HgLCuiEtcx59kA3D85MUfR5SAgQ4D2M5yGn869RQ0-jwrxiyM","refreshExpiresIn":1296000,"switchProfileEnabled":false}
/// status_code : 200
/// request-id : "7e3f9daa-4eb4-4d60-9554-0d5a0f8377d0"

class SData {
  SData({
      String? message, 
      String? authResult, 
      List<Users>? users, 
      Tokens? tokens, 
      num? statusCode, 
      String? requestid,}){
    _message = message;
    _authResult = authResult;
    _users = users;
    _tokens = tokens;
    _statusCode = statusCode;
    _requestid = requestid;
}

  SData.fromJson(dynamic json) {
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
  String? _message;
  String? _authResult;
  List<Users>? _users;
  Tokens? _tokens;
  num? _statusCode;
  String? _requestid;
SData copyWith({  String? message,
  String? authResult,
  List<Users>? users,
  Tokens? tokens,
  num? statusCode,
  String? requestid,
}) => SData(  message: message ?? _message,
  authResult: authResult ?? _authResult,
  users: users ?? _users,
  tokens: tokens ?? _tokens,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get message => _message;
  String? get authResult => _authResult;
  List<Users>? get users => _users;
  Tokens? get tokens => _tokens;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
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

/// token : "eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiI5MTExMzA4NDM2MDgwMEBzYngiLCJjbGllbnRJZCI6IlBUUExfMTYyNjk4IiwicmVxdWVzdGVySWQiOiJBQkhBLVdFQiIsInN5c3RlbSI6IkFCSEEtQSIsIm1vYmlsZSI6Ijk3MDI3MTMwNTciLCJ0eXAiOiJUcmFuc2FjdGlvbiIsImV4cCI6MTczOTI0NjgxNywiaGVhbHRoSWROdW1iZXIiOiI5MS0xMTMwLTg0MzYtMDgwMCIsImlhdCI6MTczOTI0NTAxNywicGhyQWRkcmVzcyI6IjkxMTEzMDg0MzYwODAwQHNieCIsImFiaGFBZGRyZXNzIjoiOTExMTMwODQzNjA4MDBAc2J4IiwidHhuSWQiOiIxZTZhZjM1MS05MGUwLTQyOGUtYmJiYi0wNmUyYWUxYjIxYTgifQ.NNy3JC3lphjjQVJz_frxqOenlAxU_yyd9hnwlCJDbbkirfRcbtH65QNYKKa7r0FqNaIFQKtuRutncznImkfGz6rgNat6aTV8vepdqK9nVrJ8STRQ3-RnZhHCT5kCzcfZ-w9hz1mo-3lGJ46o92jWbwmvJuztb6SnO5eGP8OXlXmplQmXydjgUgcXp9oS17L5WD8UfhyBIQWfLrmFwzdMNNGzGN80VSNKNLYSEb-r99SDNnaeT_tY4VefZ8Jd4Gnglyion1liTS6elfJK6uOqhyWdgDs24uGb_P2mFO6dtM2QSW0_sVXVJu8Y0d5nTl0K0J50-tyvNWNwI6JQKTLp38EMDp6F3WIkvCWLH21INUTo99RD0sFZVzLWtI-YH8zjB5LGBsSf4NY5F5hrCAuoly6c5XWtj43w-7-JFlaYb2xXIZryyncmwphaXfOHJd5-J_hj2iPWSkVzD7X2tD7Et_ZiePyTF-fbod8TBi8XJ8GUboheiKgHlRfq21D4xYkDyicB8-AcpcWQZciiIc6tIAi_vwW-TQN3hGePB_rMl6dycNlYkZCEzqgjMfHgOJzgCerB0Fc6HHGMPtYpAwxvThfPnr9raZQ5anS3yvARSmABh6MWHUmOPkgiLidpoeZWg9rhWcuOImtqElUF9T9DSELJ6zR_tZSq-QWXoF2dm6A"
/// expiresIn : 1800
/// refreshToken : "eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiI5MTExMzA4NDM2MDgwMEBzYngiLCJjbGllbnRJZCI6IlBUUExfMTYyNjk4Iiwic3lzdGVtIjoiQUJIQS1BIiwidHlwIjoiUmVmcmVzaCIsImV4cCI6MTc0MDU0MTAxNywiaWF0IjoxNzM5MjQ1MDE3fQ.d6Sz3-bINwTGWCFwW6AHdDcCaWV1Q-ACirP0XK99lgKKoyyLJS1oIL24mbloMpGNhAuK6q9LYGAKMXBRWBCQuubeXJda85KHWCIXOWDzYWJe8bZa5BVHVJf99HqX1fXPr3XYwhOJx-P2o3S3wCBzA5srNDalVJCtwLruiBv-wyAFPmveXDmCNSBzwZ-A0_UxENpFf8tWjRs33t-G-ZixAfVtJJRPnADDtFuurX2Q4Sv5-dgF72O_n6JWRGkzdNDrnxJPz3RASEkJR6kXcpOmRJ8CmOMV7xs69lRYdi2jRM_pvdwkb9QUpD-sCAR17DCp--oYchqXdJG9o0JA-GSkv5xesDt92pkF8_ubdAGDEE9sbl0ztgV_OviXQ5hW9gd2I-LlezDQP79NrFXIei0b7MFyl_Aulxlxx6ynBfKLcEl_8TMlwtZjaAB7qBGR8FdPeAVJ938_cFsN6BoejQz0Rv6wZw6NFaibfuSnIDkpGy4ilKCSaXoSuRM5Db-mVkZTKUpv0zl75vBbRtf7fzaL4w7dEi1vXbtMCJ3JXnKeooZDS__srEQezdr2gUoh7JRTpzUg7ZYpIrXOxy96kjKZrkwPctm2SMioQwKgU84cnGshBc9nqW6NeYhor2HgLCuiEtcx59kA3D85MUfR5SAgQ4D2M5yGn869RQ0-jwrxiyM"
/// refreshExpiresIn : 1296000
/// switchProfileEnabled : false

class Tokens {
  Tokens({
      String? token, 
      num? expiresIn, 
      String? refreshToken, 
      num? refreshExpiresIn, 
      bool? switchProfileEnabled,}){
    _token = token;
    _expiresIn = expiresIn;
    _refreshToken = refreshToken;
    _refreshExpiresIn = refreshExpiresIn;
    _switchProfileEnabled = switchProfileEnabled;
}

  Tokens.fromJson(dynamic json) {
    _token = json['token'];
    _expiresIn = json['expiresIn'];
    _refreshToken = json['refreshToken'];
    _refreshExpiresIn = json['refreshExpiresIn'];
    _switchProfileEnabled = json['switchProfileEnabled'];
  }
  String? _token;
  num? _expiresIn;
  String? _refreshToken;
  num? _refreshExpiresIn;
  bool? _switchProfileEnabled;
Tokens copyWith({  String? token,
  num? expiresIn,
  String? refreshToken,
  num? refreshExpiresIn,
  bool? switchProfileEnabled,
}) => Tokens(  token: token ?? _token,
  expiresIn: expiresIn ?? _expiresIn,
  refreshToken: refreshToken ?? _refreshToken,
  refreshExpiresIn: refreshExpiresIn ?? _refreshExpiresIn,
  switchProfileEnabled: switchProfileEnabled ?? _switchProfileEnabled,
);
  String? get token => _token;
  num? get expiresIn => _expiresIn;
  String? get refreshToken => _refreshToken;
  num? get refreshExpiresIn => _refreshExpiresIn;
  bool? get switchProfileEnabled => _switchProfileEnabled;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['token'] = _token;
    map['expiresIn'] = _expiresIn;
    map['refreshToken'] = _refreshToken;
    map['refreshExpiresIn'] = _refreshExpiresIn;
    map['switchProfileEnabled'] = _switchProfileEnabled;
    return map;
  }

}

/// abhaAddress : "91113084360800@sbx"
/// fullName : "Rohit Mohan Chavan"
/// abhaNumber : "91-1130-8436-0800"
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