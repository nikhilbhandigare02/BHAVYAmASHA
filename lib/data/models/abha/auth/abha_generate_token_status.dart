/// sCode : 200
/// sMessage : "Token status fetched successfully"
/// sData : {"id":6569,"request_id":"d41df2c7-988f-4a2d-bbad-82a71d76ed01","entity_id":"0","entity_type":"patient","abha_address":"sukrut_12929@sbx","abha_number":null,"generate_request":"{\"abhaAddress\":\"sukrut_12929@sbx\",\"name\":\"Sukrut Dattatray Hindlekar\",\"gender\":\"M\",\"yearOfBirth\":\"1997\",\"added_by\":12272,\"requestId\":\"d41df2c7-988f-4a2d-bbad-82a71d76ed01\"}","generate_response":"{\"status_code\":202,\"requestId\":\"d41df2c7-988f-4a2d-bbad-82a71d76ed01\",\"status\":\"pending\"}","on_generate_request":"{\"abhaAddress\":\"sukrut_12929@sbx\",\"linkToken\":\"eyJhbGciOiJSUzUxMiJ9.eyJoaXBJZCI6IklOMjcxMDAwMjAxOSIsInN1YiI6InN1a3J1dF8xMjkyOUBzYngiLCJhYmhhTnVtYmVyIjpudWxsLCJleHAiOjE3NTkxNzE1NTAsImlhdCI6MTc0MzQwMzU1MCwidHJhbnNhY3Rpb25JZCI6IjIxNWYwNmI1LTkxOGMtNDBhYi1iZGFiLTVmZGNhYWZkNGNhYiIsImFiaGFBZGRyZXNzIjoic3VrcnV0XzEyOTI5QHNieCJ9.ktkUd-IrelZLpjNllFLO_qQoYkJoYdl3ky6hmQCSgMqiRh8sBiv_r06R4z3IG6jU1AS_HNhpsCcH8xpQ2zl6exUvtNfdTSBPmFqwL_IfhCg2SvFxy2YkWaeL_wC9d6nBLrdZqjPoAiCFbiXeYrJ0oqdJKN8gOXMdjOJos5xTdAnPWApgIMDgLIe1nBEGVeeloojujZZ98cHNjDm1uPvFvFwIV3GF306INbYJXvNGR6bWg87evhdc4IQAu3zjOFj49i5rqBqxrbo9FH5SEhTLPcEXdq-fliHQO2N8kCsyWwT2AGhNHKDHeMA6gphnCfD0fq7abmbGYXhAJjo76N_lUQ\",\"response\":{\"requestId\":\"d41df2c7-988f-4a2d-bbad-82a71d76ed01\"},\"requestId\":\"d41df2c7-988f-4a2d-bbad-82a71d76ed01\"}","on_generate_response":"{\"success\":true}","access_token":"eyJhbGciOiJSUzUxMiJ9.eyJoaXBJZCI6IklOMjcxMDAwMjAxOSIsInN1YiI6InN1a3J1dF8xMjkyOUBzYngiLCJhYmhhTnVtYmVyIjpudWxsLCJleHAiOjE3NTkxNzE1NTAsImlhdCI6MTc0MzQwMzU1MCwidHJhbnNhY3Rpb25JZCI6IjIxNWYwNmI1LTkxOGMtNDBhYi1iZGFiLTVmZGNhYWZkNGNhYiIsImFiaGFBZGRyZXNzIjoic3VrcnV0XzEyOTI5QHNieCJ9.ktkUd-IrelZLpjNllFLO_qQoYkJoYdl3ky6hmQCSgMqiRh8sBiv_r06R4z3IG6jU1AS_HNhpsCcH8xpQ2zl6exUvtNfdTSBPmFqwL_IfhCg2SvFxy2YkWaeL_wC9d6nBLrdZqjPoAiCFbiXeYrJ0oqdJKN8gOXMdjOJos5xTdAnPWApgIMDgLIe1nBEGVeeloojujZZ98cHNjDm1uPvFvFwIV3GF306INbYJXvNGR6bWg87evhdc4IQAu3zjOFj49i5rqBqxrbo9FH5SEhTLPcEXdq-fliHQO2N8kCsyWwT2AGhNHKDHeMA6gphnCfD0fq7abmbGYXhAJjo76N_lUQ","hip_id":"IN2710002019","hfr_id":"IN2710002019","added_by":12272,"status":"completed","client_id":8,"created_at":"2025-03-31T06:45:50.000000Z","updated_at":"2025-03-31T06:45:51.000000Z"}

class AbhaGenerateTokenStatus {
  AbhaGenerateTokenStatus({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  AbhaGenerateTokenStatus.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
AbhaGenerateTokenStatus copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => AbhaGenerateTokenStatus(  sCode: sCode ?? _sCode,
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

/// id : 6569
/// request_id : "d41df2c7-988f-4a2d-bbad-82a71d76ed01"
/// entity_id : "0"
/// entity_type : "patient"
/// abha_address : "sukrut_12929@sbx"
/// abha_number : null
/// generate_request : "{\"abhaAddress\":\"sukrut_12929@sbx\",\"name\":\"Sukrut Dattatray Hindlekar\",\"gender\":\"M\",\"yearOfBirth\":\"1997\",\"added_by\":12272,\"requestId\":\"d41df2c7-988f-4a2d-bbad-82a71d76ed01\"}"
/// generate_response : "{\"status_code\":202,\"requestId\":\"d41df2c7-988f-4a2d-bbad-82a71d76ed01\",\"status\":\"pending\"}"
/// on_generate_request : "{\"abhaAddress\":\"sukrut_12929@sbx\",\"linkToken\":\"eyJhbGciOiJSUzUxMiJ9.eyJoaXBJZCI6IklOMjcxMDAwMjAxOSIsInN1YiI6InN1a3J1dF8xMjkyOUBzYngiLCJhYmhhTnVtYmVyIjpudWxsLCJleHAiOjE3NTkxNzE1NTAsImlhdCI6MTc0MzQwMzU1MCwidHJhbnNhY3Rpb25JZCI6IjIxNWYwNmI1LTkxOGMtNDBhYi1iZGFiLTVmZGNhYWZkNGNhYiIsImFiaGFBZGRyZXNzIjoic3VrcnV0XzEyOTI5QHNieCJ9.ktkUd-IrelZLpjNllFLO_qQoYkJoYdl3ky6hmQCSgMqiRh8sBiv_r06R4z3IG6jU1AS_HNhpsCcH8xpQ2zl6exUvtNfdTSBPmFqwL_IfhCg2SvFxy2YkWaeL_wC9d6nBLrdZqjPoAiCFbiXeYrJ0oqdJKN8gOXMdjOJos5xTdAnPWApgIMDgLIe1nBEGVeeloojujZZ98cHNjDm1uPvFvFwIV3GF306INbYJXvNGR6bWg87evhdc4IQAu3zjOFj49i5rqBqxrbo9FH5SEhTLPcEXdq-fliHQO2N8kCsyWwT2AGhNHKDHeMA6gphnCfD0fq7abmbGYXhAJjo76N_lUQ\",\"response\":{\"requestId\":\"d41df2c7-988f-4a2d-bbad-82a71d76ed01\"},\"requestId\":\"d41df2c7-988f-4a2d-bbad-82a71d76ed01\"}"
/// on_generate_response : "{\"success\":true}"
/// access_token : "eyJhbGciOiJSUzUxMiJ9.eyJoaXBJZCI6IklOMjcxMDAwMjAxOSIsInN1YiI6InN1a3J1dF8xMjkyOUBzYngiLCJhYmhhTnVtYmVyIjpudWxsLCJleHAiOjE3NTkxNzE1NTAsImlhdCI6MTc0MzQwMzU1MCwidHJhbnNhY3Rpb25JZCI6IjIxNWYwNmI1LTkxOGMtNDBhYi1iZGFiLTVmZGNhYWZkNGNhYiIsImFiaGFBZGRyZXNzIjoic3VrcnV0XzEyOTI5QHNieCJ9.ktkUd-IrelZLpjNllFLO_qQoYkJoYdl3ky6hmQCSgMqiRh8sBiv_r06R4z3IG6jU1AS_HNhpsCcH8xpQ2zl6exUvtNfdTSBPmFqwL_IfhCg2SvFxy2YkWaeL_wC9d6nBLrdZqjPoAiCFbiXeYrJ0oqdJKN8gOXMdjOJos5xTdAnPWApgIMDgLIe1nBEGVeeloojujZZ98cHNjDm1uPvFvFwIV3GF306INbYJXvNGR6bWg87evhdc4IQAu3zjOFj49i5rqBqxrbo9FH5SEhTLPcEXdq-fliHQO2N8kCsyWwT2AGhNHKDHeMA6gphnCfD0fq7abmbGYXhAJjo76N_lUQ"
/// hip_id : "IN2710002019"
/// hfr_id : "IN2710002019"
/// added_by : 12272
/// status : "completed"
/// client_id : 8
/// created_at : "2025-03-31T06:45:50.000000Z"
/// updated_at : "2025-03-31T06:45:51.000000Z"

class SData {
  SData({
      num? id, 
      String? requestId, 
      String? entityId, 
      String? entityType, 
      String? abhaAddress, 
      dynamic abhaNumber, 
      String? generateRequest, 
      String? generateResponse, 
      String? onGenerateRequest, 
      String? onGenerateResponse, 
      String? accessToken, 
      String? hipId, 
      String? hfrId, 
      num? addedBy, 
      String? status, 
      num? clientId, 
      String? createdAt, 
      String? updatedAt,}){
    _id = id;
    _requestId = requestId;
    _entityId = entityId;
    _entityType = entityType;
    _abhaAddress = abhaAddress;
    _abhaNumber = abhaNumber;
    _generateRequest = generateRequest;
    _generateResponse = generateResponse;
    _onGenerateRequest = onGenerateRequest;
    _onGenerateResponse = onGenerateResponse;
    _accessToken = accessToken;
    _hipId = hipId;
    _hfrId = hfrId;
    _addedBy = addedBy;
    _status = status;
    _clientId = clientId;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
}

  SData.fromJson(dynamic json) {
    _id = json['id'];
    _requestId = json['request_id'];
    _entityId = json['entity_id'];
    _entityType = json['entity_type'];
    _abhaAddress = json['abha_address'];
    _abhaNumber = json['abha_number'];
    _generateRequest = json['generate_request'];
    _generateResponse = json['generate_response'];
    _onGenerateRequest = json['on_generate_request'];
    _onGenerateResponse = json['on_generate_response'];
    _accessToken = json['access_token'];
    _hipId = json['hip_id'];
    _hfrId = json['hfr_id'];
    _addedBy = json['added_by'];
    _status = json['status'];
    _clientId = json['client_id'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
  }
  num? _id;
  String? _requestId;
  String? _entityId;
  String? _entityType;
  String? _abhaAddress;
  dynamic _abhaNumber;
  String? _generateRequest;
  String? _generateResponse;
  String? _onGenerateRequest;
  String? _onGenerateResponse;
  String? _accessToken;
  String? _hipId;
  String? _hfrId;
  num? _addedBy;
  String? _status;
  num? _clientId;
  String? _createdAt;
  String? _updatedAt;
SData copyWith({  num? id,
  String? requestId,
  String? entityId,
  String? entityType,
  String? abhaAddress,
  dynamic abhaNumber,
  String? generateRequest,
  String? generateResponse,
  String? onGenerateRequest,
  String? onGenerateResponse,
  String? accessToken,
  String? hipId,
  String? hfrId,
  num? addedBy,
  String? status,
  num? clientId,
  String? createdAt,
  String? updatedAt,
}) => SData(  id: id ?? _id,
  requestId: requestId ?? _requestId,
  entityId: entityId ?? _entityId,
  entityType: entityType ?? _entityType,
  abhaAddress: abhaAddress ?? _abhaAddress,
  abhaNumber: abhaNumber ?? _abhaNumber,
  generateRequest: generateRequest ?? _generateRequest,
  generateResponse: generateResponse ?? _generateResponse,
  onGenerateRequest: onGenerateRequest ?? _onGenerateRequest,
  onGenerateResponse: onGenerateResponse ?? _onGenerateResponse,
  accessToken: accessToken ?? _accessToken,
  hipId: hipId ?? _hipId,
  hfrId: hfrId ?? _hfrId,
  addedBy: addedBy ?? _addedBy,
  status: status ?? _status,
  clientId: clientId ?? _clientId,
  createdAt: createdAt ?? _createdAt,
  updatedAt: updatedAt ?? _updatedAt,
);
  num? get id => _id;
  String? get requestId => _requestId;
  String? get entityId => _entityId;
  String? get entityType => _entityType;
  String? get abhaAddress => _abhaAddress;
  dynamic get abhaNumber => _abhaNumber;
  String? get generateRequest => _generateRequest;
  String? get generateResponse => _generateResponse;
  String? get onGenerateRequest => _onGenerateRequest;
  String? get onGenerateResponse => _onGenerateResponse;
  String? get accessToken => _accessToken;
  String? get hipId => _hipId;
  String? get hfrId => _hfrId;
  num? get addedBy => _addedBy;
  String? get status => _status;
  num? get clientId => _clientId;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['request_id'] = _requestId;
    map['entity_id'] = _entityId;
    map['entity_type'] = _entityType;
    map['abha_address'] = _abhaAddress;
    map['abha_number'] = _abhaNumber;
    map['generate_request'] = _generateRequest;
    map['generate_response'] = _generateResponse;
    map['on_generate_request'] = _onGenerateRequest;
    map['on_generate_response'] = _onGenerateResponse;
    map['access_token'] = _accessToken;
    map['hip_id'] = _hipId;
    map['hfr_id'] = _hfrId;
    map['added_by'] = _addedBy;
    map['status'] = _status;
    map['client_id'] = _clientId;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    return map;
  }

}