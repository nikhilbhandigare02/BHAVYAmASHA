class AppExceptions implements Exception {
  final String? _message;
  final String? _prefix;

  AppExceptions([this._message, this._prefix]);

  @override
  String toString() {
    return '$_prefix$_message';
  }
}

class NoInternetException extends AppExceptions {
  NoInternetException([String? message])
      : super(message, 'No Internet Connection: ');
}

class RequestTimeoutException extends AppExceptions {
  RequestTimeoutException([String? message])
      : super(message, 'Request Timed Out: ');
}

class BadRequestException extends AppExceptions {
  BadRequestException([String? message])
      : super(message, 'Invalid Request: ');
}

class UnAuthorizedException extends AppExceptions {
  UnAuthorizedException([String? message])
      : super(message, 'Unauthorized: ');
}

class ForbiddenException extends AppExceptions {
  ForbiddenException([String? message])
      : super(message, 'Forbidden Access: ');
}

class NotFoundException extends AppExceptions {
  NotFoundException([String? message])
      : super(message, 'Resource Not Found: ');
}

class InternalServerErrorException extends AppExceptions {
  InternalServerErrorException([String? message])
      : super(message, 'Internal Server Error: ');
}

class BadGatewayException extends AppExceptions {
  BadGatewayException([String? message])
      : super(message, 'Bad Gateway: ');
}

class ServiceUnavailableException extends AppExceptions {
  ServiceUnavailableException([String? message])
      : super(message, 'Service Unavailable: ');
}

class InvalidInputException extends AppExceptions {
  InvalidInputException([String? message])
      : super(message, 'Invalid Input: ');
}

class FormatExceptionCustom extends AppExceptions {
  FormatExceptionCustom([String? message])
      : super(message, 'Data Format Error: ');
}

class FetchDataException extends AppExceptions {
  FetchDataException([String? message])
      : super(message, 'Error During Communication: ');
}
