/// sCode : 200
/// sMessage : "ABHA available numbers fetched successfully"
/// sData : {"available_abha_numbers":[{"ABHANumber":"xx-xxxx-xxxx-1734","name":"Sukrut Dattatray Hindlekar","gender":"M","index":1}],"txnId":"d9e5dc3b-0a96-4f0c-82fe-cad49fdb466b"}

class SearchAvailabilityResponse {
  SearchAvailabilityResponse({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  SearchAvailabilityResponse.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
SearchAvailabilityResponse copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => SearchAvailabilityResponse(  sCode: sCode ?? _sCode,
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

/// available_abha_numbers : [{"ABHANumber":"xx-xxxx-xxxx-1734","name":"Sukrut Dattatray Hindlekar","gender":"M","index":1}]
/// txnId : "d9e5dc3b-0a96-4f0c-82fe-cad49fdb466b"

class SData {
  SData({
      List<AvailableAbhaNumbers>? availableAbhaNumbers, 
      String? txnId,}){
    _availableAbhaNumbers = availableAbhaNumbers;
    _txnId = txnId;
}

  SData.fromJson(dynamic json) {
    if (json['available_abha_numbers'] != null) {
      _availableAbhaNumbers = [];
      json['available_abha_numbers'].forEach((v) {
        _availableAbhaNumbers?.add(AvailableAbhaNumbers.fromJson(v));
      });
    }
    _txnId = json['txnId'];
  }
  List<AvailableAbhaNumbers>? _availableAbhaNumbers;
  String? _txnId;
SData copyWith({  List<AvailableAbhaNumbers>? availableAbhaNumbers,
  String? txnId,
}) => SData(  availableAbhaNumbers: availableAbhaNumbers ?? _availableAbhaNumbers,
  txnId: txnId ?? _txnId,
);
  List<AvailableAbhaNumbers>? get availableAbhaNumbers => _availableAbhaNumbers;
  String? get txnId => _txnId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_availableAbhaNumbers != null) {
      map['available_abha_numbers'] = _availableAbhaNumbers?.map((v) => v.toJson()).toList();
    }
    map['txnId'] = _txnId;
    return map;
  }

}

/// ABHANumber : "xx-xxxx-xxxx-1734"
/// name : "Sukrut Dattatray Hindlekar"
/// gender : "M"
/// index : 1

class AvailableAbhaNumbers {
  AvailableAbhaNumbers({
      String? aBHANumber, 
      String? name, 
      String? gender, 
      num? index,}){
    _aBHANumber = aBHANumber;
    _name = name;
    _gender = gender;
    _index = index;
}

  AvailableAbhaNumbers.fromJson(dynamic json) {
    _aBHANumber = json['ABHANumber'];
    _name = json['name'];
    _gender = json['gender'];
    _index = json['index'];
  }
  String? _aBHANumber;
  String? _name;
  String? _gender;
  num? _index;
AvailableAbhaNumbers copyWith({  String? aBHANumber,
  String? name,
  String? gender,
  num? index,
}) => AvailableAbhaNumbers(  aBHANumber: aBHANumber ?? _aBHANumber,
  name: name ?? _name,
  gender: gender ?? _gender,
  index: index ?? _index,
);
  String? get aBHANumber => _aBHANumber;
  String? get name => _name;
  String? get gender => _gender;
  num? get index => _index;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ABHANumber'] = _aBHANumber;
    map['name'] = _name;
    map['gender'] = _gender;
    map['index'] = _index;
    return map;
  }

}