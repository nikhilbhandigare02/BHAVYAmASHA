/// content : "base64"
/// format : "image/png"
/// status_code : 200
/// request-id : "58bc8c49-e280-41cd-9f33-8584916eafe4"

class HealthCardResposne {
  HealthCardResposne({
      String? content, 
      String? format, 
      num? statusCode, 
      String? requestid,}){
    _content = content;
    _format = format;
    _statusCode = statusCode;
    _requestid = requestid;
}

  HealthCardResposne.fromJson(dynamic json) {
    _content = json['content'];
    _format = json['format'];
    _statusCode = json['status_code'];
    _requestid = json['request-id'];
  }
  String? _content;
  String? _format;
  num? _statusCode;
  String? _requestid;
HealthCardResposne copyWith({  String? content,
  String? format,
  num? statusCode,
  String? requestid,
}) => HealthCardResposne(  content: content ?? _content,
  format: format ?? _format,
  statusCode: statusCode ?? _statusCode,
  requestid: requestid ?? _requestid,
);
  String? get content => _content;
  String? get format => _format;
  num? get statusCode => _statusCode;
  String? get requestid => _requestid;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['content'] = _content;
    map['format'] = _format;
    map['status_code'] = _statusCode;
    map['request-id'] = _requestid;
    return map;
  }

}