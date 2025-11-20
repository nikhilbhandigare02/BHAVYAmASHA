/// sCode : 200
/// sMessage : "Auth initiated successfully"
/// sData : {"request_id":"8f66852b-c34d-4bc5-bd7d-0cfd3d599a83"}

class AbhaAuthInitiate {
  AbhaAuthInitiate({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  AbhaAuthInitiate.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
AbhaAuthInitiate copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => AbhaAuthInitiate(  sCode: sCode ?? _sCode,
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

/// request_id : "8f66852b-c34d-4bc5-bd7d-0cfd3d599a83"

class SData {
  SData({
      String? requestId,}){
    _requestId = requestId;
}

  SData.fromJson(dynamic json) {
    _requestId = json['request_id'];
  }
  String? _requestId;
SData copyWith({  String? requestId,
}) => SData(  requestId: requestId ?? _requestId,
);
  String? get requestId => _requestId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['request_id'] = _requestId;
    return map;
  }

}