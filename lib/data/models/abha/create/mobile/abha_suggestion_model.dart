/// sCode : 200
/// sMessage : "ABHA suggestions fetched successfully"
/// sData : {"txnId":"7771d2ba-58b3-40ff-b367-6249ed40c2f1","abhaAddressList":["rohitchavan199704","rohitchavan199702","rohitchavan0402","rohitchavan020404","rohitchavan020402","rohit_rohit.040404","rohit_rohit.040402","rohit_rohit.020404","rohit_rohit.020402","rohit_40204"],"status_code":200,"tracking_id":"80a07876-92ea-4707-9af2-57f66b4696ba"}

class AbhaSuggestionModel {
  AbhaSuggestionModel({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  AbhaSuggestionModel.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
AbhaSuggestionModel copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => AbhaSuggestionModel(  sCode: sCode ?? _sCode,
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

/// txnId : "7771d2ba-58b3-40ff-b367-6249ed40c2f1"
/// abhaAddressList : ["rohitchavan199704","rohitchavan199702","rohitchavan0402","rohitchavan020404","rohitchavan020402","rohit_rohit.040404","rohit_rohit.040402","rohit_rohit.020404","rohit_rohit.020402","rohit_40204"]
/// status_code : 200
/// tracking_id : "80a07876-92ea-4707-9af2-57f66b4696ba"

class SData {
  SData({
      String? txnId, 
      List<String>? abhaAddressList, 
      num? statusCode, 
      String? trackingId,}){
    _txnId = txnId;
    _abhaAddressList = abhaAddressList;
    _statusCode = statusCode;
    _trackingId = trackingId;
}

  SData.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _abhaAddressList = json['abhaAddressList'] != null ? json['abhaAddressList'].cast<String>() : [];
    _statusCode = json['status_code'];
    _trackingId = json['tracking_id'];
  }
  String? _txnId;
  List<String>? _abhaAddressList;
  num? _statusCode;
  String? _trackingId;
SData copyWith({  String? txnId,
  List<String>? abhaAddressList,
  num? statusCode,
  String? trackingId,
}) => SData(  txnId: txnId ?? _txnId,
  abhaAddressList: abhaAddressList ?? _abhaAddressList,
  statusCode: statusCode ?? _statusCode,
  trackingId: trackingId ?? _trackingId,
);
  String? get txnId => _txnId;
  List<String>? get abhaAddressList => _abhaAddressList;
  num? get statusCode => _statusCode;
  String? get trackingId => _trackingId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['abhaAddressList'] = _abhaAddressList;
    map['status_code'] = _statusCode;
    map['tracking_id'] = _trackingId;
    return map;
  }

}