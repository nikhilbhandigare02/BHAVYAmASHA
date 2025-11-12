import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/base_urls.dart';

class Endpoints {
  static const String login = '${BaseUrls.baseUrl}/login';
  static const String addHousehold = '${BaseUrls.baseUrl}/hsc/v4/add_household';
  static const String addBeneficiary = '${BaseUrls.baseUrl}/hsc/v4/add_beneficiary';
}
