import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer';
import '../../../core/config/Constant/constant.dart';
import 'api_endpoints.dart';



class DioClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseAbdmUrl,
      connectTimeout: const Duration(seconds: 30000),
      receiveTimeout: const Duration(seconds: 30000),
    ),
  );
  final Dio dioBase = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30000),
      receiveTimeout: const Duration(seconds: 30000),
    ),
  );

  Future<Response?> requestGETBase({
    required String path,
    required String token,
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      var response = await dioBase.get(
        path,
        queryParameters: queryParameters,
        data: body,
        options: Options(
         /* headers: {
            "Authorization": "Bearer ${Constant.abhaToken}",
          },*/
        ),
      );

      return response;
    } on DioError catch (ex) {
      if (ex.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection Timeout Exception");
      }
      print('dioError: ${ex.message}');
      var res = ex.response;
      return res;
    }
  }

  Future<Response?> requestPOSTBase({required String path,
    dynamic body
  }) async {
    try {
      var response = await dioBase.post(path,
          data: body,
          options: Options(headers:{'Content-Type': 'application/json',},));

      if (kDebugMode) {
        log(jsonEncode(response.data), name: '$path - ${response.statusCode}');
      }
      return response;
    } on DioError catch (ex) {
      if (ex.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection Timeout Exception");
      }
      print('dioError${ex.message}');
      var res = ex.response;
      return res;
    }
  }

  Future<Response?> requestPOSTSync({
    required String path,
    dynamic body,
    String? token, // make optional
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };

      // Use passed token OR Constant.abhaToken if available
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      } else if (Constant.abhaToken.isNotEmpty) {
        headers["Authorization"] = "Bearer ${Constant.abhaToken}";
      }

      var response = await dioBase.post(
        path,
        queryParameters: queryParameters,
        data: body,
        options: Options(headers: headers),
      );

      if (kDebugMode) {
        log(jsonEncode(response.data), name: '$path - ${response.statusCode}');
      }
      return response;
    } on DioError catch (ex) {
      if (ex.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection Timeout Exception");
      }
      print('dioError${ex.message}');
      return ex.response;
    }
  }

  Future<Response?> requestPOST({required String path,
    dynamic body, required String token,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      var response = await dio.post(path,
          queryParameters: queryParameters,
          data: body,
          options: Options(headers:{'Content-Type': 'application/json',
            "Authorization":"Bearer ${Constant.abhaToken}"},));

      if (kDebugMode) {
        log(jsonEncode(response.data), name: '$path - ${response.statusCode}');
      }
      return response;
    } on DioError catch (ex) {
      if (ex.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection Timeout Exception");
      }
      print('dioError${ex.message}');
      var res = ex.response;
      return res;
    }
  }

  Future<Response?> requestGET({
    required String path,
    required String token,
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      var response = await dio.get(
        path,
        queryParameters: queryParameters,
        data: body,
        options: Options(
          headers: {
            "Authorization": "Bearer ${Constant.abhaToken}",
          },
        ),
      );

      return response;
    } on DioError catch (ex) {
      if (ex.type == DioExceptionType.connectionTimeout) {
        throw Exception("Connection Timeout Exception");
      }
      print('dioError: ${ex.message}');
      var res = ex.response;
      return res;
    }
  }


}
