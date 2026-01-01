import 'dart:convert';
import 'package:http/http.dart' as http;

class AbhaLoginRepository {

  // String baseUrl = "https://mohhwc.bhavyabiharhealth.in/ABDM/Services/";
  String baseUrl = "https://mohhwc.medixcel.in/ABDM/Services/";
  String abdmbaseUrl = "https://abdm-central-uat.medixcel.in";
  // String abdmbaseUrl = "https://ndhm-central.medixcel.in";
  Future<dynamic> fetchModes(String healthId) async {
    final String apiUrl = "${baseUrl}sandBoxABDMAPIsMiddleware.php";
    // final String apiUrl = "${baseUrl}prodABDMAPIsMiddleware.php";
   try{
     final Map<String, dynamic> body = {
       "clinic_id": "",
       "user_id": "",
       "url": "${abdmbaseUrl}/v3/health-ids/fetch-modes",
       "data": {"health_id": healthId},
       "requestType": "POST",
     };

     final response = await http.post(
       Uri.parse(apiUrl),
       headers: {"Content-Type": "application/json"},
       body: jsonEncode(body),
     );
     return jsonDecode(response.body);
   }
   catch(e){
     print('print');
   }
  }

  Future<dynamic> selectModes(String healthId, String authMode) async {
    final String apiUrl = "${baseUrl}sandBoxABDMAPIsMiddleware.php";
    // final String apiUrl = "${baseUrl}prodABDMAPIsMiddleware.php";
    final Map<String, dynamic> body = {
      "clinic_id": "",
      "user_id": "",
      "url": "${abdmbaseUrl}/v3/health-ids/auth/request/otp",
      "data": {"health_id": healthId, "auth_mode": authMode},
      "requestType": "POST",
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  Future<dynamic> verifyOtp({
    required String txnId,
    required String otp,
    required String authMode,
  }) async {
    final String apiUrl =
        "${baseUrl}sandBoxABDMAPIsMiddleware.php";
    // final String apiUrl = "${baseUrl}prodABDMAPIsMiddleware.php";

    try {

      final Map<String, dynamic> body = {
        "clinic_id": "",
        "user_id": "",
        "url": "${abdmbaseUrl}/v3/health-ids/auth/verify",
        "data": {"txnId": txnId, "otp": otp, "auth_mode": authMode},
        "requestType": "POST",
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    }
    catch(e){
      print('print');
    }

  }

  Future<dynamic> abhaProfile(String token) async {
     String apiUrl = "${baseUrl}sandBoxABDMAPIsMiddleware.php";
    // final String apiUrl = "${baseUrl}prodABDMAPIsMiddleware.php";
    final Map<String, dynamic> body = {
      "clinic_id": "",
      "user_id": "",
      "url": "${abdmbaseUrl}/v3/health-ids/auth/profile/abha-profile",
      "data": {
        "X-Token": "Bearer $token",
      },
      "requestType": "POST",
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

}
