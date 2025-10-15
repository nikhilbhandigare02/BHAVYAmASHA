
import '../NetworkAPIServices/api_services/network_services_API.dart';

class LoginRepository{
  final _api = NetworkServiceApi();

  Future<Map<String, dynamic>> loginApi(dynamic data) async{
    final response = await _api.postApi('url', data)  ;
    return response;
  }


}