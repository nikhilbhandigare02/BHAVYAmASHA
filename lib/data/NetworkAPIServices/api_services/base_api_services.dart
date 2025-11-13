abstract class BaseApiServices {
  Future<dynamic> getApi(String url, {Map<String, String>? headers, Map<String, dynamic>? queryParams});
  Future<dynamic> getApiWithBody(String url, dynamic data, {Map<String, String>? headers});
  Future<dynamic> postApi(String url, var data, {Map<String, String>? headers});
}