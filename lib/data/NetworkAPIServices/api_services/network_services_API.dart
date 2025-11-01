import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/error/Exception/app_exception.dart';
import 'base_api_services.dart';
class NetworkServiceApi extends BaseApiServices{
  @override
  Future getApi(String url) async{
    dynamic jsonResponse;
    try{
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 50));
      jsonResponse = returnResponse(response);
      if(response.statusCode == 200){}
    }on SocketException{
      throw NoInternetException('No Internet Exception');
    }on TimeoutException{
      throw NoInternetException('Request Timed out');
    } on FetchDataException {
      throw NoInternetException('Data fetch error');
    }
    return jsonResponse;
  }

  @override
  Future<dynamic> postApi(String url, dynamic data, {Map<String, String>? headers}) async {
    try {
      final body = data is String ? data : jsonEncode(data);
      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: {
          ...?headers,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 50));

      return returnResponse(response);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    } on TimeoutException {
      throw NoInternetException('Request Timed Out');
    } on FetchDataException {
      throw FetchDataException('Error fetching data');
    }
  }
}

dynamic returnResponse(http.Response response) {
  try {
    final responseJson = jsonDecode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return responseJson;
      case 400:
        throw BadRequestException(responseJson['message'] ?? 'Invalid request');
      case 401:
        throw UnAuthorizedException(responseJson['message'] ?? 'Unauthorized');
      case 403:
        throw UnAuthorizedException(responseJson['message'] ?? 'Forbidden');
      case 404:
        throw NotFoundException(responseJson['message'] ?? 'Resource not found');
      case 500:
      default:
        throw FetchDataException(
          responseJson['message'] ??
              'Error occurred while communication with server. Status code: ${response.statusCode}',
        );
    }
  } catch (e) {
    throw FetchDataException('Invalid response from server');
  }
}