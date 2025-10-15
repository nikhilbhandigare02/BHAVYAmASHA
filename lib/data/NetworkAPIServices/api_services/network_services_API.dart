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
    }on FetchDataException{
      throw NoInternetException('Data fetch error');
    }
    return jsonResponse;
  }

  @override
  Future postApi(String url,var data) async{
    dynamic jsonResponse;
    try{
      final response = await http.post(Uri.parse(url), body: data).timeout(Duration(seconds: 50));
      jsonResponse = returnResponse(response);
      if(response.statusCode == 200){}
    }on SocketException{
      throw NoInternetException('No Internet Exception');
    }on TimeoutException{
      throw NoInternetException('Request Timed out');
    }on FetchDataException{
      throw NoInternetException('Data fetch error');
    }
    return jsonResponse;
  }
  
}

dynamic returnResponse(http.Response response){
  switch(response){
    case 200:
      dynamic jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    case 400 :
      dynamic jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    case 401 :
      throw UnAuthorizedException();
    case 500 :
      throw FetchDataException('Error communicating with server' + response.statusCode.toString());
    default:
      throw UnAuthorizedException();
  }
}