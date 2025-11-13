import 'package:medixcel_new/data/NetworkAPIServices/APIs_Urls/base_urls.dart';

class Endpoints {
  static const String login = '${BaseUrls.baseUrl}/login';
  static const String addHousehold = '${BaseUrls.baseUrl}/hsc/v4/add_household';
  static const String addBeneficiary = '${BaseUrls.baseUrl}/hsc/v4/add_beneficiary';
  static const String trackEligibleCouple = '${BaseUrls.baseUrl}/add_eligible_couple_activity';
  static const String addChildCareActivity = '${BaseUrls.baseUrl}/add_child_care_activity';
  static const String getTimeStamp = '${BaseUrls.baseUrl}/app/v3/timestamp';
  static const String abhaCreated = '${BaseUrls.baseUrl}/app/v3/user_info/abha_created';
  static const String existingAbhaCreated = '${BaseUrls.baseUrl}/app/v3/user_info/existing_abha_created';
  static const String getEligibleCoupleActivityDataByFal3 = '${BaseUrls.baseUrl}/get_eligible_couple_activity_data_by_fal3';
  static const String getChildCareActivityDataByFal3 = '${BaseUrls.baseUrl}/get_child_care_activity_data_by_fal3';
  static const String getBeneficiary = '${BaseUrls.baseUrl}/hsc/v4/get_beneficiary';

}
