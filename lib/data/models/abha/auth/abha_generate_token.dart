/// sCode : 200
/// sMessage : "Token generated successfully"
/// sData : {"id":5280,"request_id":"d41df2c7-988f-4a2d-bbad-82a71d76ed01","entity_type":"patient","entity_id":5127,"health_id":"sukrut_12929@sbx","is_primary":0,"status":"linked","linked_on":"2025-03-31 12:15:51","created_at":"2025-03-31T06:45:51.000000Z","updated_at":"2025-03-31T09:11:03.000000Z","deleted_at":null,"hip_id":"IN2710002019","added_by":12272,"profile_share_id":null,"access_token":"eyJhbGciOiJSUzUxMiJ9.eyJoaXBJZCI6IklOMjcxMDAwMjAxOSIsInN1YiI6InN1a3J1dF8xMjkyOUBzYngiLCJhYmhhTnVtYmVyIjpudWxsLCJleHAiOjE3NTkxNzE1NTAsImlhdCI6MTc0MzQwMzU1MCwidHJhbnNhY3Rpb25JZCI6IjIxNWYwNmI1LTkxOGMtNDBhYi1iZGFiLTVmZGNhYWZkNGNhYiIsImFiaGFBZGRyZXNzIjoic3VrcnV0XzEyOTI5QHNieCJ9.ktkUd-IrelZLpjNllFLO_qQoYkJoYdl3ky6hmQCSgMqiRh8sBiv_r06R4z3IG6jU1AS_HNhpsCcH8xpQ2zl6exUvtNfdTSBPmFqwL_IfhCg2SvFxy2YkWaeL_wC9d6nBLrdZqjPoAiCFbiXeYrJ0oqdJKN8gOXMdjOJos5xTdAnPWApgIMDgLIe1nBEGVeeloojujZZ98cHNjDm1uPvFvFwIV3GF306INbYJXvNGR6bWg87evhdc4IQAu3zjOFj49i5rqBqxrbo9FH5SEhTLPcEXdq-fliHQO2N8kCsyWwT2AGhNHKDHeMA6gphnCfD0fq7abmbGYXhAJjo76N_lUQ","client_id":8,"token_vallidation":"Record linking Token is valid as of 2025-03-31 15:15:43. It will be expired on 2025-09-30 00:15:50"}

class AbhaGenerateToken {
  AbhaGenerateToken({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  AbhaGenerateToken.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
AbhaGenerateToken copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => AbhaGenerateToken(  sCode: sCode ?? _sCode,
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

/// id : 5280
/// request_id : "d41df2c7-988f-4a2d-bbad-82a71d76ed01"
/// entity_type : "patient"
/// entity_id : 5127
/// health_id : "sukrut_12929@sbx"
/// is_primary : 0
/// status : "linked"
/// linked_on : "2025-03-31 12:15:51"
/// created_at : "2025-03-31T06:45:51.000000Z"
/// updated_at : "2025-03-31T09:11:03.000000Z"
/// deleted_at : null
/// hip_id : "IN2710002019"
/// added_by : 12272
/// profile_share_id : null
/// access_token : "eyJhbGciOiJSUzUxMiJ9.eyJoaXBJZCI6IklOMjcxMDAwMjAxOSIsInN1YiI6InN1a3J1dF8xMjkyOUBzYngiLCJhYmhhTnVtYmVyIjpudWxsLCJleHAiOjE3NTkxNzE1NTAsImlhdCI6MTc0MzQwMzU1MCwidHJhbnNhY3Rpb25JZCI6IjIxNWYwNmI1LTkxOGMtNDBhYi1iZGFiLTVmZGNhYWZkNGNhYiIsImFiaGFBZGRyZXNzIjoic3VrcnV0XzEyOTI5QHNieCJ9.ktkUd-IrelZLpjNllFLO_qQoYkJoYdl3ky6hmQCSgMqiRh8sBiv_r06R4z3IG6jU1AS_HNhpsCcH8xpQ2zl6exUvtNfdTSBPmFqwL_IfhCg2SvFxy2YkWaeL_wC9d6nBLrdZqjPoAiCFbiXeYrJ0oqdJKN8gOXMdjOJos5xTdAnPWApgIMDgLIe1nBEGVeeloojujZZ98cHNjDm1uPvFvFwIV3GF306INbYJXvNGR6bWg87evhdc4IQAu3zjOFj49i5rqBqxrbo9FH5SEhTLPcEXdq-fliHQO2N8kCsyWwT2AGhNHKDHeMA6gphnCfD0fq7abmbGYXhAJjo76N_lUQ"
/// client_id : 8
/// token_vallidation : "Record linking Token is valid as of 2025-03-31 15:15:43. It will be expired on 2025-09-30 00:15:50"

class SData {
  SData({
      num? id, 
      String? requestId, 
      String? entityType, 
      num? entityId, 
      String? healthId, 
      num? isPrimary, 
      String? status, 
      String? linkedOn, 
      String? createdAt, 
      String? updatedAt, 
      dynamic deletedAt, 
      String? hipId, 
      num? addedBy, 
      dynamic profileShareId, 
      String? accessToken, 
      num? clientId, 
      String? tokenVallidation,}){
    _id = id;
    _requestId = requestId;
    _entityType = entityType;
    _entityId = entityId;
    _healthId = healthId;
    _isPrimary = isPrimary;
    _status = status;
    _linkedOn = linkedOn;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _deletedAt = deletedAt;
    _hipId = hipId;
    _addedBy = addedBy;
    _profileShareId = profileShareId;
    _accessToken = accessToken;
    _clientId = clientId;
    _tokenVallidation = tokenVallidation;
}

  SData.fromJson(dynamic json) {
    _id = json['id'];
    _requestId = json['request_id'];
    _entityType = json['entity_type'];
    _entityId = json['entity_id'];
    _healthId = json['health_id'];
    _isPrimary = json['is_primary'];
    _status = json['status'];
    _linkedOn = json['linked_on'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _deletedAt = json['deleted_at'];
    _hipId = json['hip_id'];
    _addedBy = json['added_by'];
    _profileShareId = json['profile_share_id'];
    _accessToken = json['access_token'];
    _clientId = json['client_id'];
    _tokenVallidation = json['token_vallidation'];
  }
  num? _id;
  String? _requestId;
  String? _entityType;
  num? _entityId;
  String? _healthId;
  num? _isPrimary;
  String? _status;
  String? _linkedOn;
  String? _createdAt;
  String? _updatedAt;
  dynamic _deletedAt;
  String? _hipId;
  num? _addedBy;
  dynamic _profileShareId;
  String? _accessToken;
  num? _clientId;
  String? _tokenVallidation;
SData copyWith({  num? id,
  String? requestId,
  String? entityType,
  num? entityId,
  String? healthId,
  num? isPrimary,
  String? status,
  String? linkedOn,
  String? createdAt,
  String? updatedAt,
  dynamic deletedAt,
  String? hipId,
  num? addedBy,
  dynamic profileShareId,
  String? accessToken,
  num? clientId,
  String? tokenVallidation,
}) => SData(  id: id ?? _id,
  requestId: requestId ?? _requestId,
  entityType: entityType ?? _entityType,
  entityId: entityId ?? _entityId,
  healthId: healthId ?? _healthId,
  isPrimary: isPrimary ?? _isPrimary,
  status: status ?? _status,
  linkedOn: linkedOn ?? _linkedOn,
  createdAt: createdAt ?? _createdAt,
  updatedAt: updatedAt ?? _updatedAt,
  deletedAt: deletedAt ?? _deletedAt,
  hipId: hipId ?? _hipId,
  addedBy: addedBy ?? _addedBy,
  profileShareId: profileShareId ?? _profileShareId,
  accessToken: accessToken ?? _accessToken,
  clientId: clientId ?? _clientId,
  tokenVallidation: tokenVallidation ?? _tokenVallidation,
);
  num? get id => _id;
  String? get requestId => _requestId;
  String? get entityType => _entityType;
  num? get entityId => _entityId;
  String? get healthId => _healthId;
  num? get isPrimary => _isPrimary;
  String? get status => _status;
  String? get linkedOn => _linkedOn;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;
  dynamic get deletedAt => _deletedAt;
  String? get hipId => _hipId;
  num? get addedBy => _addedBy;
  dynamic get profileShareId => _profileShareId;
  String? get accessToken => _accessToken;
  num? get clientId => _clientId;
  String? get tokenVallidation => _tokenVallidation;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['request_id'] = _requestId;
    map['entity_type'] = _entityType;
    map['entity_id'] = _entityId;
    map['health_id'] = _healthId;
    map['is_primary'] = _isPrimary;
    map['status'] = _status;
    map['linked_on'] = _linkedOn;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    map['deleted_at'] = _deletedAt;
    map['hip_id'] = _hipId;
    map['added_by'] = _addedBy;
    map['profile_share_id'] = _profileShareId;
    map['access_token'] = _accessToken;
    map['client_id'] = _clientId;
    map['token_vallidation'] = _tokenVallidation;
    return map;
  }

}