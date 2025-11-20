/// abhaAddress : "mahesh2sep@sbx"
/// fullName : "MAHESWAR SAHOO"
/// firstName : "MAHESWAR"
/// middleName : ""
/// lastName : "SAHOO"
/// dayOfBirth : "10"
/// monthOfBirth : "4"
/// yearOfBirth : "1993"
/// dateOfBirth : "10-4-1993"
/// gender : "M"
/// mobile : "9777333158"
/// abhaNumber : "91-4487-5718-6334"
/// address : "GADAMANATIR, Chhiam, Khordha, Odisha"
/// stateName : "ODISHA"
/// districtName : "KHORDHA"
/// pinCode : "752062"
/// stateCode : "21"
/// districtCode : "362"
/// authMethods : ["DEMOGRAPHICS","MOBILE_OTP","AADHAAR_OTP","AADHAAR_BIO"]
/// status : "ACTIVE"
/// townName : "Chhiam"
/// emailVerified : "false"
/// mobileVerified : "true"
/// kycStatus : "VERIFIED"
/// abhaLinkedCount : "88"
/// preferredAbhaAddress : "sahoo_10041993@sbx"
/// status_code : 200
/// request-id : "2e102a9b-113d-4711-bbaa-388a84b7535b"

class ProfileMobile {
  ProfileMobile({
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
      String? mobile, 
      String? abhaNumber, 
      String? address, 
      String? stateName, 
      String? districtName, 
      String? pinCode, 
      String? stateCode, 
      String? districtCode, 
      List<String>? authMethods, 
      String? status, 
      String? townName, 
      String? emailVerified, 
      String? mobileVerified, 
      String? kycStatus, 
      String? abhaLinkedCount, 
      String? preferredAbhaAddress, 
      num? statusCode, 
      String? requestid,}){
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
    _mobile = mobile;
    _abhaNumber = abhaNumber;
    _address = address;
    _stateName = stateName;
    _districtName = districtName;
    _pinCode = pinCode;
    _stateCode = stateCode;
    _districtCode = districtCode;
    _authMethods = authMethods;
    _status = status;
    _townName = townName;
    _emailVerified = emailVerified;
    _mobileVerified = mobileVerified;
    _kycStatus = kycStatus;
    _abhaLinkedCount = abhaLinkedCount;
    _preferredAbhaAddress = preferredAbhaAddress;
    _statusCode = statusCode;
    _requestid = requestid;
}

  ProfileMobile.fromJson(dynamic json) {
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
    _mobile = json['mobile'];
    _abhaNumber = json['abhaNumber'];
    _address = json['address'];
    _stateName = json['stateName'];
    _districtName = json['districtName'];
    _pinCode = json['pinCode'];
    _stateCode = json['stateCode'];
    _districtCode = json['districtCode'];
    _authMethods = json['authMethods'] != null ? json['authMethods'].cast<String>() : [];
    _status = json['status'];
    _townName = json['townName'];
    _emailVerified = json['emailVerified'];
    _mobileVerified = json['mobileVerified'];
    _kycStatus = json['kycStatus'];
    _abhaLinkedCount = json['abhaLinkedCount'];
    _preferredAbhaAddress = json['preferredAbhaAddress'];
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
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
  String? _mobile;
  String? _abhaNumber;
  String? _address;
  String? _stateName;
  String? _districtName;
  String? _pinCode;
  String? _stateCode;
  String? _districtCode;
  List<String>? _authMethods;
  String? _status;
  String? _townName;
  String? _emailVerified;
  String? _mobileVerified;
  String? _kycStatus;
  String? _abhaLinkedCount;
  String? _preferredAbhaAddress;
  num? _statusCode;
  String? _requestid;
ProfileMobile copyWith({  String? abhaAddress,
  String? fullName,
  String? firstName,
  String? middleName,
  String? lastName,
  String? dayOfBirth,
  String? monthOfBirth,
  String? yearOfBirth,
  String? dateOfBirth,
  String? gender,
  String? mobile,
  String? abhaNumber,
  String? address,
  String? stateName,
  String? districtName,
  String? pinCode,
  String? stateCode,
  String? districtCode,
  List<String>? authMethods,
  String? status,
  String? townName,
  String? emailVerified,
  String? mobileVerified,
  String? kycStatus,
  String? abhaLinkedCount,
  String? preferredAbhaAddress,
  num? statusCode,
  String? requestid,
}) => ProfileMobile(  abhaAddress: abhaAddress ?? _abhaAddress,
  fullName: fullName ?? _fullName,
  firstName: firstName ?? _firstName,
  middleName: middleName ?? _middleName,
  lastName: lastName ?? _lastName,
  dayOfBirth: dayOfBirth ?? _dayOfBirth,
  monthOfBirth: monthOfBirth ?? _monthOfBirth,
  yearOfBirth: yearOfBirth ?? _yearOfBirth,
  dateOfBirth: dateOfBirth ?? _dateOfBirth,
  gender: gender ?? _gender,
  mobile: mobile ?? _mobile,
  abhaNumber: abhaNumber ?? _abhaNumber,
  address: address ?? _address,
  stateName: stateName ?? _stateName,
  districtName: districtName ?? _districtName,
  pinCode: pinCode ?? _pinCode,
  stateCode: stateCode ?? _stateCode,
  districtCode: districtCode ?? _districtCode,
  authMethods: authMethods ?? _authMethods,
  status: status ?? _status,
  townName: townName ?? _townName,
  emailVerified: emailVerified ?? _emailVerified,
  mobileVerified: mobileVerified ?? _mobileVerified,
  kycStatus: kycStatus ?? _kycStatus,
  abhaLinkedCount: abhaLinkedCount ?? _abhaLinkedCount,
  preferredAbhaAddress: preferredAbhaAddress ?? _preferredAbhaAddress,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
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
  String? get mobile => _mobile;
  String? get abhaNumber => _abhaNumber;
  String? get address => _address;
  String? get stateName => _stateName;
  String? get districtName => _districtName;
  String? get pinCode => _pinCode;
  String? get stateCode => _stateCode;
  String? get districtCode => _districtCode;
  List<String>? get authMethods => _authMethods;
  String? get status => _status;
  String? get townName => _townName;
  String? get emailVerified => _emailVerified;
  String? get mobileVerified => _mobileVerified;
  String? get kycStatus => _kycStatus;
  String? get abhaLinkedCount => _abhaLinkedCount;
  String? get preferredAbhaAddress => _preferredAbhaAddress;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

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
    map['mobile'] = _mobile;
    map['abhaNumber'] = _abhaNumber;
    map['address'] = _address;
    map['stateName'] = _stateName;
    map['districtName'] = _districtName;
    map['pinCode'] = _pinCode;
    map['stateCode'] = _stateCode;
    map['districtCode'] = _districtCode;
    map['authMethods'] = _authMethods;
    map['status'] = _status;
    map['townName'] = _townName;
    map['emailVerified'] = _emailVerified;
    map['mobileVerified'] = _mobileVerified;
    map['kycStatus'] = _kycStatus;
    map['abhaLinkedCount'] = _abhaLinkedCount;
    map['preferredAbhaAddress'] = _preferredAbhaAddress;
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    return map;
  }

}