/// error : {"code":"ABDM-1114","message":"User not found."}
/// status_code : 404
/// error_details : {"error":true,"exception":"Client error: `POST https://abhasbx.abdm.gov.in/abha/api/v3/profile/account/abha/search` resulted in a `404 Not Found` response:\n{\"error\":{\"code\":\"ABDM-1114\",\"message\":\"User not found.\"}}\n","error_at":"abdm","status_code":404,"reason_phrase":"Not Found","message":"ABDM service is not responding. Please try again after sometime."}
/// tracking_id : "4f7ab152-2c02-4ca6-9927-b553e261735a"

class Error400 {
  Error400({
      Error? error, 
      num? statusCode, 
      ErrorDetails? errorDetails, 
      String? trackingId,}){
    _error = error;
    _statusCode = statusCode;
    _errorDetails = errorDetails;
    _trackingId = trackingId;
}

  Error400.fromJson(dynamic json) {
    _error = json['error'] != null ? Error.fromJson(json['error']) : null;
    _statusCode = json['status_code'];
    _errorDetails = json['error_details'] != null ? ErrorDetails.fromJson(json['error_details']) : null;
    _trackingId = json['tracking_id'];
  }
  Error? _error;
  num? _statusCode;
  ErrorDetails? _errorDetails;
  String? _trackingId;
Error400 copyWith({  Error? error,
  num? statusCode,
  ErrorDetails? errorDetails,
  String? trackingId,
}) => Error400(  error: error ?? _error,
  statusCode: statusCode ?? _statusCode,
  errorDetails: errorDetails ?? _errorDetails,
  trackingId: trackingId ?? _trackingId,
);
  Error? get error => _error;
  num? get statusCode => _statusCode;
  ErrorDetails? get errorDetails => _errorDetails;
  String? get trackingId => _trackingId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_error != null) {
      map['error'] = _error?.toJson();
    }
    map['status_code'] = _statusCode;
    if (_errorDetails != null) {
      map['error_details'] = _errorDetails?.toJson();
    }
    map['tracking_id'] = _trackingId;
    return map;
  }

}

/// error : true
/// exception : "Client error: `POST https://abhasbx.abdm.gov.in/abha/api/v3/profile/account/abha/search` resulted in a `404 Not Found` response:\n{\"error\":{\"code\":\"ABDM-1114\",\"message\":\"User not found.\"}}\n"
/// error_at : "abdm"
/// status_code : 404
/// reason_phrase : "Not Found"
/// message : "ABDM service is not responding. Please try again after sometime."

class ErrorDetails {
  ErrorDetails({
      bool? error, 
      String? exception, 
      String? errorAt, 
      num? statusCode, 
      String? reasonPhrase, 
      String? message,}){
    _error = error;
    _exception = exception;
    _errorAt = errorAt;
    _statusCode = statusCode;
    _reasonPhrase = reasonPhrase;
    _message = message;
}

  ErrorDetails.fromJson(dynamic json) {
    _error = json['error'];
    _exception = json['exception'];
    _errorAt = json['error_at'];
    _statusCode = json['status_code'];
    _reasonPhrase = json['reason_phrase'];
    _message = json['message'];
  }
  bool? _error;
  String? _exception;
  String? _errorAt;
  num? _statusCode;
  String? _reasonPhrase;
  String? _message;
ErrorDetails copyWith({  bool? error,
  String? exception,
  String? errorAt,
  num? statusCode,
  String? reasonPhrase,
  String? message,
}) => ErrorDetails(  error: error ?? _error,
  exception: exception ?? _exception,
  errorAt: errorAt ?? _errorAt,
  statusCode: statusCode ?? _statusCode,
  reasonPhrase: reasonPhrase ?? _reasonPhrase,
  message: message ?? _message,
);
  bool? get error => _error;
  String? get exception => _exception;
  String? get errorAt => _errorAt;
  num? get statusCode => _statusCode;
  String? get reasonPhrase => _reasonPhrase;
  String? get message => _message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['error'] = _error;
    map['exception'] = _exception;
    map['error_at'] = _errorAt;
    map['status_code'] = _statusCode;
    map['reason_phrase'] = _reasonPhrase;
    map['message'] = _message;
    return map;
  }

}

/// code : "ABDM-1114"
/// message : "User not found."

class Error {
  Error({
      String? code, 
      String? message,}){
    _code = code;
    _message = message;
}

  Error.fromJson(dynamic json) {
    _code = json['code'];
    _message = json['message'];
  }
  String? _code;
  String? _message;
Error copyWith({  String? code,
  String? message,
}) => Error(  code: code ?? _code,
  message: message ?? _message,
);
  String? get code => _code;
  String? get message => _message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = _code;
    map['message'] = _message;
    return map;
  }

}