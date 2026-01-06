import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/error/Exception/app_exception.dart';
import 'base_api_services.dart';
class NetworkServiceApi extends BaseApiServices{
  @override
  Future<dynamic> getApi(String url,
      {Map<String, String>? headers, Map<String, dynamic>? queryParams}) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
   //   print('🌍 GET Request → $uri');
   //   print('📦 Headers → $headers');

      final response = await http.get(uri, headers: headers);
     // print('📥 Response Code: ${response.statusCode}');
     // print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('🚫 SocketException: $e');
      throw Exception('No Internet Connection: ${e.message}');
    } on HandshakeException catch (e) {
      print('🔒 SSL Handshake failed: $e');
      throw Exception('SSL Error: $e');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<dynamic> getApiWithBody(String url, dynamic data, {Map<String, String>? headers}) async {
    try {
      final req = http.Request('GET', Uri.parse(url));
      final body = data is String ? data : jsonEncode(data);
      req.body = body;
      req.headers.addAll({
        ...?headers,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      print('🌍 GET (with body) Request → $url');
      print('📦 Headers → ${req.headers}');
      print('📝 Body → $body');

      final streamed = await req.send().timeout(const Duration(seconds: 50));
      final response = await http.Response.fromStream(streamed);

   //   print('📥 Response Code: ${response.statusCode}');
    //  print('📥 Response Body: ${response.body}');

      return returnResponse(response);
    } on SocketException {
      throw NoInternetException('No Internet Connection');
    } on TimeoutException {
      throw NoInternetException('Request Timed Out');
    } on FetchDataException catch (e) {
      throw e;
    }
  }
  @override
  Future<dynamic> postApi(String url, dynamic data, {Map<String, String>? headers}) async {
    try {
      print('🚀 Starting POST request to: $url');
      print('📦 Request data type: ${data.runtimeType}');

      // Ensure data is properly encoded
      final body = data is String ? data : jsonEncode(data);
      print('📝 Request body: $body');

      final reqHeaders = {
        ...?headers,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      print('🔑 Headers: $reqHeaders');

      final response = await http.post(
        Uri.parse(url),
        body: body,
        headers: reqHeaders,
      ).timeout(
        const Duration(seconds: 50),
        onTimeout: () {
          print('⏰ Request timed out after 50 seconds');
          throw TimeoutException('Request timed out after 50 seconds');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response body: ${response.body}');

      // Handle different status codes
      switch (response.statusCode) {
        case 200:
        case 201:
          try {
            return jsonDecode(response.body);
          } catch (e) {
            print('⚠️ Error parsing JSON response: $e');
            return response.body;
          }
        case 400:
          throw BadRequestException('Bad Request: ${response.body}');
        case 401:
          // Check if there's a valid JSON response with error message
          print('🔍 Processing 401 response: ${response.body}');
          try {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic> && data.containsKey('msg')) {
              print('✅ Found JSON with msg field, returning data: $data');
              // Return the JSON response so the error message can be handled properly
              return data;
            } else {
              print('❌ No msg field found in JSON, throwing exception');
              throw UnAuthorizedException('Unauthorized: ${response.body}');
            }
          } catch (e) {
            print('❌ Error parsing 401 response: $e');
            throw UnAuthorizedException('Unauthorized: ${response.body}');
          }
        case 403:
          throw UnAuthorizedException('Forbidden: ${response.body}');
        case 404:
          // Check if there's a valid JSON response with error message
          try {
            final data = jsonDecode(response.body);
            if (data is Map<String, dynamic> && data.containsKey('msg')) {
              // Return the JSON response so the error message can be handled properly
              return data;
            } else {
              throw FetchDataException('Not Found: $url');
            }
          } catch (_) {
            throw FetchDataException('Not Found: $url');
          }
        case 500:
        case 501:
        default:
          print('❌ Server error: ${response.statusCode}');
          print('Response body: ${response.body}');
          try {
            final data = jsonDecode(response.body);
            final message = (data is Map<String, dynamic>)
                ? (data['msg'] ?? data['message'] ?? 'Error occurred while communicating with server. Status code: ${response.statusCode}')
                : 'Error occurred while communicating with server. Status code: ${response.statusCode}';
            throw FetchDataException(message.toString());
          } catch (_) {
            final fallback = response.body.isNotEmpty
                ? response.body
                : 'Error occurred while communicating with server. Status code: ${response.statusCode}';
            throw FetchDataException(fallback);
          }
      }
    } on SocketException catch (e) {
      print('🌐 Network error: $e'
      );
      throw NoInternetException('No Internet Connection: $e');
    } on TimeoutException catch (e) {
      print('⏰ Request timeout: $e');
      throw NoInternetException('Request timed out: $e');
    } on FormatException catch (e) {
      print('📄 Format exception: $e');
      throw FetchDataException('Invalid response format: $e');
    } catch (e, stackTrace) {
      print('❌ Unexpected error: $e');
      print('Stack trace: $stackTrace');
      throw FetchDataException('Unexpected error occurred: $e');
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
        throw BadRequestException(
          responseJson['msg'] ?? responseJson['message'] ?? 'Invalid request',
        );
      case 401:
        throw UnAuthorizedException(
          responseJson['msg'] ?? responseJson['message'] ?? 'Unauthorized',
        );
      case 403:
        throw UnAuthorizedException(
          responseJson['msg'] ?? responseJson['message'] ?? 'Forbidden',
        );
      case 404:
        throw NotFoundException(
          responseJson['msg'] ?? responseJson['message'] ?? 'Resource not found',
        );
      case 500:
      default:
        throw FetchDataException(
          responseJson['msg'] ??
              responseJson['message'] ??
              'Error occurred while communicating with server. Status code: ${response.statusCode}',
        );
    }
  } on AppExceptions {
    // Preserve specific API error messages
    rethrow;
  } catch (e) {
    throw FetchDataException('Invalid response from server');
  }
}
