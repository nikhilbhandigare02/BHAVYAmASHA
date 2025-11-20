import 'dart:async';

import 'package:dio/dio.dart';

import '../NetworkAPIServices/api_services/dio_client.dart';


class AbhaController extends DioClient {

  //Link Abha
  Future<Response?> fetch_modes(jsonData,String token) async {
    return await requestGET(
        path: "/abha/linking/fetch_modes",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> sendOtp(jsonData,String token) async {
    return await requestGET(
        path: "/abha/linking/auth/otp",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> verifyOtp(jsonData,String token) async {
    return await requestGET(
        path: "/abha/linking/auth/otp/verify",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> linkAbhaProfile(jsonData,String token) async {
    return await requestGET(
        path: "/abha/linking/auth/abha_profile",
        body: jsonData,
        token: token
    );
  }

  //Link Existing
  Future<Response?> searchAvailability(jsonData,String token) async {
    return await requestGET(
        path: "/abha/search_availability",
        body: jsonData,
        token: token
    );
  }



  Future<Response?> profileLinkExisting(jsonData,String token) async {
    return await requestGET(
        path: "/abha/profile",
        body: jsonData,
        token: token
    );
  }

  //Auto auth
  Future<Response?> initiateAuth(jsonData,String token) async {
    return await requestGET(
        path: "/abha/initiate/auth",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> fetchAuthStatus(jsonData,String token) async {
    return await requestGET(
        path: "/abha/fetch/auth/status",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> confirmAuth(jsonData,String token) async {
    return await requestGET(
        path: "/abha/confirm/auth",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> generateToken(jsonData,String token) async {
    return await requestGET(
        path: "/abha/generate/token",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> generateTokenStatus(jsonData,String token) async {
    return await requestGET(
        path: "/abha/generate/token/status",
        body: jsonData,
        token: token
    );
  }






  //Create aadhaar aadhar
  var aadharMobileUpdate = '/abha/aadhaar/mobile/update';
  var aadharMobileVerify = '/abha/aadhaar/mobile/verify';
 // static var aadhaarCreate = '/abha/aadhaar/create';


  static var mobileReSendotp = '/abha/mobile/resendotp';
  static var mobileLinkExisting = '/abha/mobile/link_existing';
  static var mobileHealthCard = '/abha/mobile/health_card';
  static var mobileSubmitDetails = '/abha/mobile/submit_details';



  //Existing
  Future<Response?> searchExistingAbha(jsonData,String token) async {
    return await requestPOST(
        path: "profile/account/abha/search",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> sendOTPLinkExisting(jsonData,String token) async {
    return await requestPOST(
        path: "profile/login/request/otp",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> verifyOTPLinkExisting(jsonData,String token) async {
    return await requestPOST(
        path: "profile/login/verify",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> healthCardLinkExisting(jsonData,String token) async {
    return await requestPOST(
        path: "health-ids/aadhaar/abha-address/get-card",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> healthCardLinkExistingMobile(jsonData,String token) async {
    return await requestPOST(
        path: "health-ids/mobile/profile/getABHACard",
        body: jsonData,
        token: token
    );
  }

  //Aadhaar
  static var aadharSendOTP = 'health-ids/aadhaar/generateOTP';
  static var aadharVerifyOTP = 'health-ids/aadhaar/verifyOTP';
  static var aadhaarProfile = 'health-ids/aadhaar/abha-address/profile';
  static var aadhaarCreate = 'health-ids/aadhaar/abha-address/create';
  static var aadhaarMobileUpdate = 'health-ids/aadhaar/mobile/update';
  static var aadhaarMobileVerify = 'health-ids/aadhaar/mobile/verifyOTP';


  //Mobile
  static var mobileSendotp = 'health-ids/mobile/generateOTP';
  static var mobileVerifyotp = 'health-ids/mobile/verifyOTP';
  static var mobileProfile = 'health-ids/mobile/profile';
  static var mobileABHAsuggestion = 'health-ids/mobile/suggestion';
  static var continueExisitingABHAMobile = 'health-ids/mobile/profile/verify/user';
  static var mobileCreateAbhaAddress = 'health-ids/mobile/createABHAWithDetails';
  static var mobileCreateABHACard = 'health-ids/mobile/profile/getABHACard';
  //Create New
  Future<Response?> aadhaarCreateABHA(path,jsonData,String token) async {
    return await requestPOST(
        path: path,
        body: jsonData,
        token: token
    );
  }

  Future<Response?> getStates(String token) async {
    return await requestGET(
        path: "phr/states",
        //  body: jsonData,
        token: token
    );
  }

  Future<Response?> getDistricts(jsonData,String token) async {
    return await requestGET(
        path: "phr/${jsonData['stateId']}/districts",
        body: jsonData,
        token: token
    );
  }


  Future<Response?> getABHASuggesstion(jsonData,String token) async {
    return await requestGET(
        path: "health-ids/aadhaar/suggestion/${jsonData['txnId']}",
        body: jsonData,
        token: token
    );
  }

  Future<Response?> getMobileABHASuggesstion(jsonData,String token) async {
    return await requestPOST(
        path: "health-ids/mobile/suggestion",
        body: jsonData,
        token: token
    );
  }


}
