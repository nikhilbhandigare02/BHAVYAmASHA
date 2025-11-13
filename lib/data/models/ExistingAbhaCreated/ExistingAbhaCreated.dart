/// msg : "Successfully Get ABHA Created Count"
/// success : true
/// data : {"abha_created":7}

class ExistingAbhaCreated {
  ExistingAbhaCreated({
    String? msg,
    bool? success,
    Data? data,}){
    _msg = msg;
    _success = success;
    _data = data;
  }

  ExistingAbhaCreated.fromJson(dynamic json) {
    _msg = json['msg'];
    _success = json['success'];
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  String? _msg;
  bool? _success;
  Data? _data;
  ExistingAbhaCreated copyWith({  String? msg,
    bool? success,
    Data? data,
  }) => ExistingAbhaCreated(  msg: msg ?? _msg,
    success: success ?? _success,
    data: data ?? _data,
  );
  String? get msg => _msg;
  bool? get success => _success;
  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['msg'] = _msg;
    map['success'] = _success;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }

}

/// abha_created : 7

class Data {
  Data({
    num? abhaCreated,}){
    _abhaCreated = abhaCreated;
  }

  Data.fromJson(dynamic json) {
    _abhaCreated = json['abha_created'];
  }
  num? _abhaCreated;
  Data copyWith({  num? abhaCreated,
  }) => Data(  abhaCreated: abhaCreated ?? _abhaCreated,
  );
  num? get abhaCreated => _abhaCreated;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['abha_created'] = _abhaCreated;
    return map;
  }

}