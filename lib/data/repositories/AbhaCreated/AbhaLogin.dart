import 'dart:convert';
import 'package:http/http.dart' as http;

class AbhaLoginRepository {
  Future<dynamic> fetchModes(String healthId) async {
    final String apiUrl =
        "https://mohhwc.bhavyabiharhealth.in/ABDM/Services/prodABDMAPIsMiddleware.php";

    final Map<String, dynamic> body = {
      "clinic_id": "",
      "user_id": "",
      "url": "https://ndhm-central.medixcel.in/v3/health-ids/fetch-modes",
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

  Future<dynamic> selectModes(String healthId, String authMode) async {
    final String apiUrl =
        "https://mohhwc.bhavyabiharhealth.in/ABDM/Services/prodABDMAPIsMiddleware.php";

    final Map<String, dynamic> body = {
      "clinic_id": "",
      "user_id": "",
      "url": "https://ndhm-central.medixcel.in/v3/health-ids/auth/request/otp",
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
        "https://mohhwc.bhavyabiharhealth.in/ABDM/Services/prodABDMAPIsMiddleware.php";

    final Map<String, dynamic> body = {
      "clinic_id": "",
      "user_id": "",
      "url": "https://ndhm-central.medixcel.in/v3/health-ids/auth/verify",
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

  Future<dynamic> abhaProfile(String token) async {
    const String apiUrl =
        "https://mohhwc.bhavyabiharhealth.in/ABDM/Services/prodABDMAPIsMiddleware.php";

    final Map<String, dynamic> body = {
      "clinic_id": "",
      "user_id": "",
      "url": "https://ndhm-central.medixcel.in/v3/health-ids/auth/profile/abha-profile",
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
