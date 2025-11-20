/// txnId : "2b2779bc-241b-4f19-ad1a-d71e48404ce7"
/// abhaAddressList : ["sahoomaheswar10","sahoomaheswar05","sahoo_1993051993","sahoo_1993","sahoo_10199310","sahoo_10199305","sahoo_101005","sahoo_10051993","sahoo_100510","sahoo_10"]
/// status_code : 200
/// request-id : "62c6b50c-67a0-484d-bf7e-db51ba5853e1"

class AbhaSuggestionMobile {
  AbhaSuggestionMobile({
      String? txnId, 
      List<String>? abhaAddressList, 
      num? statusCode, 
      String? requestid,}){
    _txnId = txnId;
    _abhaAddressList = abhaAddressList;
    _statusCode = statusCode;
    _requestid = requestid;
}

  AbhaSuggestionMobile.fromJson(dynamic json) {
    _txnId = json['txnId'];
    _abhaAddressList = json['abhaAddressList'] != null ? json['abhaAddressList'].cast<String>() : [];
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
  }
  String? _txnId;
  List<String>? _abhaAddressList;
  num? _statusCode;
  String? _requestid;
AbhaSuggestionMobile copyWith({  String? txnId,
  List<String>? abhaAddressList,
  num? statusCode,
  String? requestid,
}) => AbhaSuggestionMobile(  txnId: txnId ?? _txnId,
  abhaAddressList: abhaAddressList ?? _abhaAddressList,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get txnId => _txnId;
  List<String>? get abhaAddressList => _abhaAddressList;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['txnId'] = _txnId;
    map['abhaAddressList'] = _abhaAddressList;
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    return map;
  }

}