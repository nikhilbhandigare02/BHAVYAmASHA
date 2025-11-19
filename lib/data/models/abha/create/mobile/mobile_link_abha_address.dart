/// sCode : 200
/// sMessage : "ABHA address linked successfully"
/// sData : {"token":"eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJyb2hpdGNoYXZhbjA0MTRAc2J4IiwiZ2VuZGVyIjoiTSIsInR5cCI6IlRyYW5zYWN0aW9uIiwiaGVhbHRoSWROdW1iZXIiOm51bGwsImFiaGFBZGRyZXNzIjoicm9oaXRjaGF2YW4wNDE0QHNieCIsIm1vbnRoT2ZCaXJ0aCI6IjA0Iiwic3RhdGVOYW1lIjoiTUFIQVJBU0hUUkEiLCJkYXlPZkJpcnRoIjoiMTQiLCJwaHJNb2JpbGUiOiI5ODkyNDQ0OTUzIiwiZXhwIjoxNzQ0MzEwNDExLCJpYXQiOjE3NDQzMDg2MTEsInBockFkZHJlc3MiOiJyb2hpdGNoYXZhbjA0MTRAc2J4IiwiZW1haWwiOiJjaGF2YW5yb2hpdDE5OTNAZ21haWwuY29tIiwibG9naW5TdWJqZWN0IjoiTU9CSUxFX0xPR0lOIiwieWVhck9mQmlydGgiOiIyMDAwIiwiaXNLeWNWZXJpZmllZCI6IlBFTkRJTkciLCJwaW5jb2RlIjoiNDAwNzA5IiwiY2xpZW50SWQiOiJQVFBMXzE2MjY5OCIsInJlcXVlc3RlcklkIjoiUEhSLVdFQiIsImRpc3RyaWN0TmFtZSI6Ik1VTUJBSSIsIm1vYmlsZSI6Ijk4OTI0NDQ5NTMiLCJmdWxsTmFtZSI6InJvaGl0IGNoYXZhbiIsImFkZHJlc3NMaW5lIjoiTXVtYmFpIiwic3lzdGVtIjoiQUJIQS1BIiwidHhuSWQiOiIyNDQ4YjMxYS1lYWQ2LTQ2ZmItODg1Yy0zY2M3Zjk0YzE5NmEifQ.Vj--rvmYmElEPyKK0Ma0spHADGGlivUhy9HqOGhMi4ZBWd4v0XIg8IR6BewHP9W6DGOQMHQoQCSXu83u7rWAOveavqlnbudAjxDZKfZPbeonUZ1keU_LKWWR3_E7jjBYVo5MujFimpazU8HuK-6rgH2SaZgX6u4U6qXDc2p7YaqWwEzLTdYU4fBWvP9vV6F4mneWhUc7S5jTyumshHG5y3gP8m9NCk1HXO8I407zRDqw9TxHkfK6Ahca1Z8xpzWZiH2P8ZGAIH00PaRUdhWSHb2NMyuCIG8P92GYr2tzhxHWQV_zC95jxp0XxFI5mUQRyFY4OAhnmFxEE8pCpaZrFQ","expiresIn":1800,"refreshToken":"eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJyb2hpdGNoYXZhbjA0MTRAc2J4IiwiY2xpZW50SWQiOiJQVFBMXzE2MjY5OCIsInN5c3RlbSI6IkFCSEEtQSIsInR5cCI6IlJlZnJlc2giLCJleHAiOjE3NDU2MDQ2MTEsImlhdCI6MTc0NDMwODYxMSwibG9naW5TdWJqZWN0IjoiTU9CSUxFX0xPR0lOIn0.U9wxCvNQsFDQfIlEyVpGblBmw2-S_Xo42rAa5XBaAJyha3Q2vvPfnCoBcMsdkpEagpYwu92M2vY29iwZ-8AuOXqUEznfasSmJIkmkN31Tni_Z5fv7bM3zxoOrkolxfZjTQWSw9QAzkHZMKkgYMZTwbl0pPV1UINHCLirWFBWhyMkamFwCZn03OVunUTizv1MJwEFF8UG8OAPVNYVJwkPcpvhptu5CdIwe0cBLScttQ2MaWqDkXhPQdOnqVVjYiJtAYm68LLNUFlWgZn-vnF-YRFShp-9Vcl_JkkvYtYJXwln4AlhDsSUDFsyWy-qNmX0e3ZDn5KuMaaPI2d2CNxFIg","refreshExpiresIn":1296000,"switchProfileEnabled":true,"status_code":200,"tracking_id":"46c1b772-f868-43fb-b952-6862a87a6e07"}

class MobileLinkAbhaAddress {
  MobileLinkAbhaAddress({
      num? sCode, 
      String? sMessage, 
      SData? sData,}){
    _sCode = sCode;
    _sMessage = sMessage;
    _sData = sData;
}

  MobileLinkAbhaAddress.fromJson(dynamic json) {
    _sCode = json['sCode'];
    _sMessage = json['sMessage'];
    _sData = json['sData'] != null ? SData.fromJson(json['sData']) : null;
  }
  num? _sCode;
  String? _sMessage;
  SData? _sData;
MobileLinkAbhaAddress copyWith({  num? sCode,
  String? sMessage,
  SData? sData,
}) => MobileLinkAbhaAddress(  sCode: sCode ?? _sCode,
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

/// token : "eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJyb2hpdGNoYXZhbjA0MTRAc2J4IiwiZ2VuZGVyIjoiTSIsInR5cCI6IlRyYW5zYWN0aW9uIiwiaGVhbHRoSWROdW1iZXIiOm51bGwsImFiaGFBZGRyZXNzIjoicm9oaXRjaGF2YW4wNDE0QHNieCIsIm1vbnRoT2ZCaXJ0aCI6IjA0Iiwic3RhdGVOYW1lIjoiTUFIQVJBU0hUUkEiLCJkYXlPZkJpcnRoIjoiMTQiLCJwaHJNb2JpbGUiOiI5ODkyNDQ0OTUzIiwiZXhwIjoxNzQ0MzEwNDExLCJpYXQiOjE3NDQzMDg2MTEsInBockFkZHJlc3MiOiJyb2hpdGNoYXZhbjA0MTRAc2J4IiwiZW1haWwiOiJjaGF2YW5yb2hpdDE5OTNAZ21haWwuY29tIiwibG9naW5TdWJqZWN0IjoiTU9CSUxFX0xPR0lOIiwieWVhck9mQmlydGgiOiIyMDAwIiwiaXNLeWNWZXJpZmllZCI6IlBFTkRJTkciLCJwaW5jb2RlIjoiNDAwNzA5IiwiY2xpZW50SWQiOiJQVFBMXzE2MjY5OCIsInJlcXVlc3RlcklkIjoiUEhSLVdFQiIsImRpc3RyaWN0TmFtZSI6Ik1VTUJBSSIsIm1vYmlsZSI6Ijk4OTI0NDQ5NTMiLCJmdWxsTmFtZSI6InJvaGl0IGNoYXZhbiIsImFkZHJlc3NMaW5lIjoiTXVtYmFpIiwic3lzdGVtIjoiQUJIQS1BIiwidHhuSWQiOiIyNDQ4YjMxYS1lYWQ2LTQ2ZmItODg1Yy0zY2M3Zjk0YzE5NmEifQ.Vj--rvmYmElEPyKK0Ma0spHADGGlivUhy9HqOGhMi4ZBWd4v0XIg8IR6BewHP9W6DGOQMHQoQCSXu83u7rWAOveavqlnbudAjxDZKfZPbeonUZ1keU_LKWWR3_E7jjBYVo5MujFimpazU8HuK-6rgH2SaZgX6u4U6qXDc2p7YaqWwEzLTdYU4fBWvP9vV6F4mneWhUc7S5jTyumshHG5y3gP8m9NCk1HXO8I407zRDqw9TxHkfK6Ahca1Z8xpzWZiH2P8ZGAIH00PaRUdhWSHb2NMyuCIG8P92GYr2tzhxHWQV_zC95jxp0XxFI5mUQRyFY4OAhnmFxEE8pCpaZrFQ"
/// expiresIn : 1800
/// refreshToken : "eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJyb2hpdGNoYXZhbjA0MTRAc2J4IiwiY2xpZW50SWQiOiJQVFBMXzE2MjY5OCIsInN5c3RlbSI6IkFCSEEtQSIsInR5cCI6IlJlZnJlc2giLCJleHAiOjE3NDU2MDQ2MTEsImlhdCI6MTc0NDMwODYxMSwibG9naW5TdWJqZWN0IjoiTU9CSUxFX0xPR0lOIn0.U9wxCvNQsFDQfIlEyVpGblBmw2-S_Xo42rAa5XBaAJyha3Q2vvPfnCoBcMsdkpEagpYwu92M2vY29iwZ-8AuOXqUEznfasSmJIkmkN31Tni_Z5fv7bM3zxoOrkolxfZjTQWSw9QAzkHZMKkgYMZTwbl0pPV1UINHCLirWFBWhyMkamFwCZn03OVunUTizv1MJwEFF8UG8OAPVNYVJwkPcpvhptu5CdIwe0cBLScttQ2MaWqDkXhPQdOnqVVjYiJtAYm68LLNUFlWgZn-vnF-YRFShp-9Vcl_JkkvYtYJXwln4AlhDsSUDFsyWy-qNmX0e3ZDn5KuMaaPI2d2CNxFIg"
/// refreshExpiresIn : 1296000
/// switchProfileEnabled : true
/// status_code : 200
/// tracking_id : "46c1b772-f868-43fb-b952-6862a87a6e07"

class SData {
  SData({
      String? token, 
      num? expiresIn, 
      String? refreshToken, 
      num? refreshExpiresIn, 
      bool? switchProfileEnabled, 
      num? statusCode, 
      String? trackingId,}){
    _token = token;
    _expiresIn = expiresIn;
    _refreshToken = refreshToken;
    _refreshExpiresIn = refreshExpiresIn;
    _switchProfileEnabled = switchProfileEnabled;
    _statusCode = statusCode;
    _trackingId = trackingId;
}

  SData.fromJson(dynamic json) {
    _token = json['token'];
    _expiresIn = json['expiresIn'];
    _refreshToken = json['refreshToken'];
    _refreshExpiresIn = json['refreshExpiresIn'];
    _switchProfileEnabled = json['switchProfileEnabled'];
    _statusCode = json['status_code'];
    _trackingId = json['tracking_id'];
  }
  String? _token;
  num? _expiresIn;
  String? _refreshToken;
  num? _refreshExpiresIn;
  bool? _switchProfileEnabled;
  num? _statusCode;
  String? _trackingId;
SData copyWith({  String? token,
  num? expiresIn,
  String? refreshToken,
  num? refreshExpiresIn,
  bool? switchProfileEnabled,
  num? statusCode,
  String? trackingId,
}) => SData(  token: token ?? _token,
  expiresIn: expiresIn ?? _expiresIn,
  refreshToken: refreshToken ?? _refreshToken,
  refreshExpiresIn: refreshExpiresIn ?? _refreshExpiresIn,
  switchProfileEnabled: switchProfileEnabled ?? _switchProfileEnabled,
  statusCode: statusCode ?? _statusCode,
  trackingId: trackingId ?? _trackingId,
);
  String? get token => _token;
  num? get expiresIn => _expiresIn;
  String? get refreshToken => _refreshToken;
  num? get refreshExpiresIn => _refreshExpiresIn;
  bool? get switchProfileEnabled => _switchProfileEnabled;
  num? get statusCode => _statusCode;
  String? get trackingId => _trackingId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['token'] = _token;
    map['expiresIn'] = _expiresIn;
    map['refreshToken'] = _refreshToken;
    map['refreshExpiresIn'] = _refreshExpiresIn;
    map['switchProfileEnabled'] = _switchProfileEnabled;
    map['status_code'] = _statusCode;
    map['tracking_id'] = _trackingId;
    return map;
  }

}