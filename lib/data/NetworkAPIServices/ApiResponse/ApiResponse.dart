import '../../../core/utils/enums.dart';

class ApiResponse<T> {
  Status? status;
  T? data;
  String? message;

  ApiResponse(this.data, this.message, this.status);

  ApiResponse.loading() : status = Status.loading;

  ApiResponse.complete(this.data) : status = Status.complete;

  ApiResponse.error(this.message) : status = Status.error;
}