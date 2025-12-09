/// abhaAddress : "test2323@abdm"
/// fullName : "ram test test"
/// firstName : "ram"
/// middleName : "test"
/// lastName : "test"
/// dayOfBirth : "13"
/// monthOfBirth : "06"
/// yearOfBirth : "2002"
/// dateOfBirth : "13-6-2002"
/// gender : "F"
/// email : "test@gmail.com"
/// mobile : "9370248863"
/// address : "test"
/// stateName : "ANDHRA PRADESH"
/// districtName : "ANAKAPALLI"
/// pinCode : "536567"
/// stateCode : "28"
/// districtCode : "744"
/// authMethods : ["MOBILE_OTP","PASSWORD"]
/// status : "ACTIVE"
/// emailVerified : "false"
/// mobileVerified : "true"
/// kycStatus : "PENDING"
/// age : 0
/// status_code : 200
/// tracking_id : "66ee50c5-ce3a-4fe8-a369-5c59a0572d7b"

class AbhaProfileResponce {
  AbhaProfileResponce({
      String? abhaAddress, 
      String? fullName, 
      String? firstName, 
      String? middleName, 
      String? lastName, 
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
      String? stateCode, 
      String? districtCode, 
      List<String>? authMethods, 
      String? status, 
      String? emailVerified, 
      String? mobileVerified, 
      String? kycStatus, 
      num? age, 
      num? statusCode, 
      String? trackingId,}){
    _abhaAddress = abhaAddress;
    _fullName = fullName;
    _firstName = firstName;
    _middleName = middleName;
    _lastName = lastName;
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
    _stateCode = stateCode;
    _districtCode = districtCode;
    _authMethods = authMethods;
    _status = status;
    _emailVerified = emailVerified;
    _mobileVerified = mobileVerified;
    _kycStatus = kycStatus;
    _age = age;
    _statusCode = statusCode;
    _trackingId = trackingId;
}

  AbhaProfileResponce.fromJson(dynamic json) {
    _abhaAddress = json['abhaAddress'];
    _fullName = json['fullName'];
    _firstName = json['firstName'];
    _middleName = json['middleName'];
    _lastName = json['lastName'];
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
    _stateCode = json['stateCode'];
    _districtCode = json['districtCode'];
    _authMethods = json['authMethods'] != null ? json['authMethods'].cast<String>() : [];
    _status = json['status'];
    _emailVerified = json['emailVerified'];
    _mobileVerified = json['mobileVerified'];
    _kycStatus = json['kycStatus'];
    _age = json['age'];
    _statusCode = json['status_code'];
    _trackingId = json['tracking_id'];
  }
  String? _abhaAddress;
  String? _fullName;
  String? _firstName;
  String? _middleName;
  String? _lastName;
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
  String? _stateCode;
  String? _districtCode;
  List<String>? _authMethods;
  String? _status;
  String? _emailVerified;
  String? _mobileVerified;
  String? _kycStatus;
  num? _age;
  num? _statusCode;
  String? _trackingId;
AbhaProfileResponce copyWith({  String? abhaAddress,
  String? fullName,
  String? firstName,
  String? middleName,
  String? lastName,
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
  String? stateCode,
  String? districtCode,
  List<String>? authMethods,
  String? status,
  String? emailVerified,
  String? mobileVerified,
  String? kycStatus,
  num? age,
  num? statusCode,
  String? trackingId,
}) => AbhaProfileResponce(  abhaAddress: abhaAddress ?? _abhaAddress,
  fullName: fullName ?? _fullName,
  firstName: firstName ?? _firstName,
  middleName: middleName ?? _middleName,
  lastName: lastName ?? _lastName,
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
  stateCode: stateCode ?? _stateCode,
  districtCode: districtCode ?? _districtCode,
  authMethods: authMethods ?? _authMethods,
  status: status ?? _status,
  emailVerified: emailVerified ?? _emailVerified,
  mobileVerified: mobileVerified ?? _mobileVerified,
  kycStatus: kycStatus ?? _kycStatus,
  age: age ?? _age,
  statusCode: statusCode ?? _statusCode,
  trackingId: trackingId ?? _trackingId,
);
  String? get abhaAddress => _abhaAddress;
  String? get fullName => _fullName;
  String? get firstName => _firstName;
  String? get middleName => _middleName;
  String? get lastName => _lastName;
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
  String? get stateCode => _stateCode;
  String? get districtCode => _districtCode;
  List<String>? get authMethods => _authMethods;
  String? get status => _status;
  String? get emailVerified => _emailVerified;
  String? get mobileVerified => _mobileVerified;
  String? get kycStatus => _kycStatus;
  num? get age => _age;
  num? get statusCode => _statusCode;
  String? get trackingId => _trackingId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['abhaAddress'] = _abhaAddress;
    map['fullName'] = _fullName;
    map['firstName'] = _firstName;
    map['middleName'] = _middleName;
    map['lastName'] = _lastName;
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
    map['stateCode'] = _stateCode;
    map['districtCode'] = _districtCode;
    map['authMethods'] = _authMethods;
    map['status'] = _status;
    map['emailVerified'] = _emailVerified;
    map['mobileVerified'] = _mobileVerified;
    map['kycStatus'] = _kycStatus;
    map['age'] = _age;
    map['status_code'] = _statusCode;
    map['tracking_id'] = _trackingId;
    return map;
  }

}