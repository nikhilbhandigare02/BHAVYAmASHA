/// txnId : "2b2779bc-241b-4f19-ad1a-d71e48404ce7"
/// message : "ABHA Address Created Successfully"
/// phrDetails : {"firstName":"Maheswar","middleName":"","lastName":"Sahoo","fullName":"Maheswar Sahoo","dayOfBirth":"10","monthOfBirth":"04","yearOfBirth":"1993","dateOfBirth":"10-04-1993","gender":"M","email":"maheswarsahoo47@gmail.com","mobile":"8658165625","address":"Chhiam, Garhmanatir","stateName":"Maharashtra","districtName":"Nashik","pinCode":"422003","abhaAddress":["ganesh12321@sbx","ganesh170624@sbx","maheswar-test-11@sbx","maheswa34@sbx","mahesh2sep@sbx","mahesh10oct21@sbx"],"stateCode":"27","districtCode":"123"}
/// tokens : {"token":"<token>","expiresIn":1800,"refreshToken":"eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJtYWhlc2gxMDEwMEBzYngiLCJjbGllbnRJZCI6IlBUUExfMTYyNjk4Iiwic3lzdGVtIjoiQUJIQS1BRERSRVNTLU4iLCJ0eXAiOiJSZWZyZXNoIiwiZXhwIjoxNzMyODc1MzQ5LCJpYXQiOjE3MzE1NzkzNDksImxvZ2luU3ViamVjdCI6Ik1PQklMRV9MT0dJTiJ9.5Y8ZXNsEBlb6dkrgQdJ40Bdd5r8gRk4qqPdk-3U7mERPPJ7a0gUuIPFaKI4Es2-nEMHjdkzCWiHLr5S7bb-TcMEqu-VTgyvxqxwQ5RBVd92QZFlp_IS3GqDndAVv_QSXQIL22F1EmPoOXO0IdwemuG9CqFm31WutNFkLgeYP0eh-tOPamX23iTxblqvNtMV0G90m5vEbvPqpAZpJ3mloTwbzyYWFsCIdBL--h3TlpUTyEbdoPrZoJdD23t4jtI5WTo_c92NeqqjxlVz4TwFXFzxpPHe-uoX-QBKa48oDSa0VtiUHTGbLAub_KG-oNQMrb3uSY96u-Ztmw5jww8JF_A","refreshExpiresIn":1296000,"switchProfileEnabled":true}
/// status_code : 200
/// request-id : "ef3ae4b8-962f-4cd9-ad81-893286bf3cf3"

class MobileCreateAddressResponse {
  MobileCreateAddressResponse({
      String? txnId, 
      String? message, 
      PhrDetails? phrDetails, 
      Tokens? tokens, 
      num? statusCode, 
      String? requestid,}){
    _txnId = txnId;
    _message = message;
    _phrDetails = phrDetails;
    _tokens = tokens;
    _statusCode = statusCode;
    _requestid = requestid;
}

  MobileCreateAddressResponse.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _message = json['message'];
    _phrDetails = json['phrDetails'] != null ? PhrDetails.fromJson(json['phrDetails']) : null;
    _tokens = json['tokens'] != null ? Tokens.fromJson(json['tokens']) : null;
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
  }
  String? _txnId;
  String? _message;
  PhrDetails? _phrDetails;
  Tokens? _tokens;
  num? _statusCode;
  String? _requestid;
MobileCreateAddressResponse copyWith({  String? txnId,
  String? message,
  PhrDetails? phrDetails,
  Tokens? tokens,
  num? statusCode,
  String? requestid,
}) => MobileCreateAddressResponse(  txnId: txnId ?? _txnId,
  message: message ?? _message,
  phrDetails: phrDetails ?? _phrDetails,
  tokens: tokens ?? _tokens,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get txnId => _txnId;
  String? get message => _message;
  PhrDetails? get phrDetails => _phrDetails;
  Tokens? get tokens => _tokens;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['message'] = _message;
    if (_phrDetails != null) {
      map['phrDetails'] = _phrDetails?.toJson();
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
/// expiresIn : 1800
/// refreshToken : "eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJtYWhlc2gxMDEwMEBzYngiLCJjbGllbnRJZCI6IlBUUExfMTYyNjk4Iiwic3lzdGVtIjoiQUJIQS1BRERSRVNTLU4iLCJ0eXAiOiJSZWZyZXNoIiwiZXhwIjoxNzMyODc1MzQ5LCJpYXQiOjE3MzE1NzkzNDksImxvZ2luU3ViamVjdCI6Ik1PQklMRV9MT0dJTiJ9.5Y8ZXNsEBlb6dkrgQdJ40Bdd5r8gRk4qqPdk-3U7mERPPJ7a0gUuIPFaKI4Es2-nEMHjdkzCWiHLr5S7bb-TcMEqu-VTgyvxqxwQ5RBVd92QZFlp_IS3GqDndAVv_QSXQIL22F1EmPoOXO0IdwemuG9CqFm31WutNFkLgeYP0eh-tOPamX23iTxblqvNtMV0G90m5vEbvPqpAZpJ3mloTwbzyYWFsCIdBL--h3TlpUTyEbdoPrZoJdD23t4jtI5WTo_c92NeqqjxlVz4TwFXFzxpPHe-uoX-QBKa48oDSa0VtiUHTGbLAub_KG-oNQMrb3uSY96u-Ztmw5jww8JF_A"
/// refreshExpiresIn : 1296000
/// switchProfileEnabled : true

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

/// firstName : "Maheswar"
/// middleName : ""
/// lastName : "Sahoo"
/// fullName : "Maheswar Sahoo"
/// dayOfBirth : "10"
/// monthOfBirth : "04"
/// yearOfBirth : "1993"
/// dateOfBirth : "10-04-1993"
/// gender : "M"
/// email : "maheswarsahoo47@gmail.com"
/// mobile : "8658165625"
/// address : "Chhiam, Garhmanatir"
/// stateName : "Maharashtra"
/// districtName : "Nashik"
/// pinCode : "422003"
/// abhaAddress : ["ganesh12321@sbx","ganesh170624@sbx","maheswar-test-11@sbx","maheswa34@sbx","mahesh2sep@sbx","mahesh10oct21@sbx"]
/// stateCode : "27"
/// districtCode : "123"

class PhrDetails {
  PhrDetails({
      String? firstName, 
      String? middleName, 
      String? lastName, 
      String? fullName, 
      String? dayOfBirth, 
      String? monthOfBirth, 
      String? yearOfBirth, 
      String? dateOfBirth, 
      String? gender, 
      String? email, 
      String? mobile, 
      String? address, 
      String? stateName, 
      String? districtName, 
      String? pinCode, 
      List<String>? abhaAddress, 
      String? stateCode, 
      String? districtCode,}){
    _firstName = firstName;
    _middleName = middleName;
    _lastName = lastName;
    _fullName = fullName;
    _dayOfBirth = dayOfBirth;
    _monthOfBirth = monthOfBirth;
    _yearOfBirth = yearOfBirth;
    _dateOfBirth = dateOfBirth;
    _gender = gender;
    _email = email;
    _mobile = mobile;
    _address = address;
    _stateName = stateName;
    _districtName = districtName;
    _pinCode = pinCode;
    _abhaAddress = abhaAddress;
    _stateCode = stateCode;
    _districtCode = districtCode;
}

  PhrDetails.fromJson(dynamic json) {
    _firstName = json['firstName'];
    _middleName = json['middleName'];
    _lastName = json['lastName'];
    _fullName = json['fullName'];
    _dayOfBirth = json['dayOfBirth'];
    _monthOfBirth = json['monthOfBirth'];
    _yearOfBirth = json['yearOfBirth'];
    _dateOfBirth = json['dateOfBirth'];
    _gender = json['gender'];
    _email = json['email'];
    _mobile = json['mobile'];
    _address = json['address'];
    _stateName = json['stateName'];
    _districtName = json['districtName'];
    _pinCode = json['pinCode'];
    _abhaAddress = json['abhaAddress'] != null ? json['abhaAddress'].cast<String>() : [];
    _stateCode = json['stateCode'];
    _districtCode = json['districtCode'];
  }
  String? _firstName;
  String? _middleName;
  String? _lastName;
  String? _fullName;
  String? _dayOfBirth;
  String? _monthOfBirth;
  String? _yearOfBirth;
  String? _dateOfBirth;
  String? _gender;
  String? _email;
  String? _mobile;
  String? _address;
  String? _stateName;
  String? _districtName;
  String? _pinCode;
  List<String>? _abhaAddress;
  String? _stateCode;
  String? _districtCode;
PhrDetails copyWith({  String? firstName,
  String? middleName,
  String? lastName,
  String? fullName,
  String? dayOfBirth,
  String? monthOfBirth,
  String? yearOfBirth,
  String? dateOfBirth,
  String? gender,
  String? email,
  String? mobile,
  String? address,
  String? stateName,
  String? districtName,
  String? pinCode,
  List<String>? abhaAddress,
  String? stateCode,
  String? districtCode,
}) => PhrDetails(  firstName: firstName ?? _firstName,
  middleName: middleName ?? _middleName,
  lastName: lastName ?? _lastName,
  fullName: fullName ?? _fullName,
  dayOfBirth: dayOfBirth ?? _dayOfBirth,
  monthOfBirth: monthOfBirth ?? _monthOfBirth,
  yearOfBirth: yearOfBirth ?? _yearOfBirth,
  dateOfBirth: dateOfBirth ?? _dateOfBirth,
  gender: gender ?? _gender,
  email: email ?? _email,
  mobile: mobile ?? _mobile,
  address: address ?? _address,
  stateName: stateName ?? _stateName,
  districtName: districtName ?? _districtName,
  pinCode: pinCode ?? _pinCode,
  abhaAddress: abhaAddress ?? _abhaAddress,
  stateCode: stateCode ?? _stateCode,
  districtCode: districtCode ?? _districtCode,
);
  String? get firstName => _firstName;
  String? get middleName => _middleName;
  String? get lastName => _lastName;
  String? get fullName => _fullName;
  String? get dayOfBirth => _dayOfBirth;
  String? get monthOfBirth => _monthOfBirth;
  String? get yearOfBirth => _yearOfBirth;
  String? get dateOfBirth => _dateOfBirth;
  String? get gender => _gender;
  String? get email => _email;
  String? get mobile => _mobile;
  String? get address => _address;
  String? get stateName => _stateName;
  String? get districtName => _districtName;
  String? get pinCode => _pinCode;
  List<String>? get abhaAddress => _abhaAddress;
  String? get stateCode => _stateCode;
  String? get districtCode => _districtCode;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['firstName'] = _firstName;
    map['middleName'] = _middleName;
    map['lastName'] = _lastName;
    map['fullName'] = _fullName;
    map['dayOfBirth'] = _dayOfBirth;
    map['monthOfBirth'] = _monthOfBirth;
    map['yearOfBirth'] = _yearOfBirth;
    map['dateOfBirth'] = _dateOfBirth;
    map['gender'] = _gender;
    map['email'] = _email;
    map['mobile'] = _mobile;
    map['address'] = _address;
    map['stateName'] = _stateName;
    map['districtName'] = _districtName;
    map['pinCode'] = _pinCode;
    map['abhaAddress'] = _abhaAddress;
    map['stateCode'] = _stateCode;
    map['districtCode'] = _districtCode;
    return map;
  }

}