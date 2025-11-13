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
    } on FetchDataException catch (e) {
      // Re-throw original message instead of masking it
      throw e;
    }
  }
}

dynamic returnResponse(http.Response response) {
  final status = response.statusCode;
  final text = response.body ?? '';

  Map<String, dynamic>? asJson;
  try {
    if (text.isNotEmpty) asJson = jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {
    asJson = null;
  }

  if (status == 200 || status == 201) {
    return asJson ?? text;
  }

  final message = asJson?['message'] ??
      'HTTP $status: ' + (text.length > 300 ? text.substring(0, 300) : text);

  switch (status) {
    case 400:
      throw BadRequestException(message);
    case 401:
    case 403:
      throw UnAuthorizedException(message);
    case 404:
      throw NotFoundException(message);
    default:
      throw FetchDataException(message);
  }
}